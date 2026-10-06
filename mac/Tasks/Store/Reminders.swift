import AppKit
import Foundation
import Observation
import UserNotifications

@Observable
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    static let category = "dueReminder"
    static let markDoneAction = "markDone"

    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Keys.enabled)
            scheduleSync()
        }
    }

    var minutes: Int {
        didSet {
            defaults.set(minutes, forKey: Keys.minutes)
            scheduleSync()
        }
    }

    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    private let store: TaskStore
    private let window: WindowModel
    private let defaults: UserDefaults
    @ObservationIgnored private var scheduled: [DueReminder]?
    @ObservationIgnored private var pendingSync: Task<Void, Never>?

    private enum Keys {
        static let enabled = "remindersEnabled"
        static let minutes = "reminderMinutes"
    }

    init(store: TaskStore, window: WindowModel, defaults: UserDefaults = .standard) {
        self.store = store
        self.window = window
        self.defaults = defaults
        isEnabled = defaults.object(forKey: Keys.enabled) as? Bool ?? true
        minutes = defaults.object(forKey: Keys.minutes) as? Int ?? DueReminderPlan.defaultMinutes
        super.init()
    }

    func start() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: Self.category,
                actions: [UNNotificationAction(identifier: Self.markDoneAction, title: "Mark as Done", options: [])],
                intentIdentifiers: [],
                options: []
            ),
        ])
        observeStore()
        scheduleSync()
    }

    var time: Date {
        get {
            DueReminderPlan.fireDate(on: .today(), minutes: minutes) ?? .now
        }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            minutes = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
        }
    }

    func refreshAuthorization() async {
        authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func observeStore() {
        withObservationTracking {
            _ = store.tasks
            _ = store.lists
            _ = store.hasLoaded
            _ = store.auth.isSignedIn
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observeStore()
                self?.scheduleSync()
            }
        }
    }

    private func scheduleSync() {
        pendingSync?.cancel()
        pendingSync = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await sync()
        }
    }

    private var isActive: Bool {
        isEnabled && store.auth.isSignedIn && store.hasLoaded && !store.usesSampleData
    }

    private func sync() async {
        let center = UNUserNotificationCenter.current()
        await refreshAuthorization()
        guard isActive else {
            if scheduled != nil || !isEnabled {
                center.removeAllPendingNotificationRequests()
                scheduled = nil
            }
            return
        }
        if authorization == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            await refreshAuthorization()
        }
        guard authorization == .authorized || authorization == .provisional else { return }

        let listTitles = Dictionary(store.lists.map { ($0.id, $0.title) }) { first, _ in first }
        let plan = DueReminderPlan.reminders(for: store.tasks, listTitles: listTitles, minutes: minutes, now: .now)
        if plan != scheduled {
            center.removeAllPendingNotificationRequests()
            for reminder in plan {
                try? await center.add(request(for: reminder))
            }
            scheduled = plan
        }
        await removeFinishedNotifications()
    }

    private func request(for reminder: DueReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.categoryIdentifier = Self.category
        content.threadIdentifier = "due-" + reminder.day.googleDue.prefix(10)
        content.userInfo = ["taskID": reminder.taskID]
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
        return UNNotificationRequest(
            identifier: reminder.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    private func removeFinishedNotifications() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        let finished = delivered.compactMap { notification -> String? in
            guard let id = notification.request.content.userInfo["taskID"] as? String else { return nil }
            let task = store.task(store.currentID(id))
            return task == nil || task?.isDone == true ? notification.request.identifier : nil
        }
        if !finished.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: finished)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let taskID = response.notification.request.content.userInfo["taskID"] as? String else { return }
        let action = response.actionIdentifier
        await respond(to: action, taskID: taskID)
    }

    private func respond(to action: String, taskID: String) async {
        switch action {
        case Self.markDoneAction:
            if !store.hasLoaded { await store.refresh() }
            store.setDone(store.currentID(taskID), true)
        case UNNotificationDefaultActionIdentifier:
            if !store.hasLoaded { await store.refresh() }
            if let task = store.task(store.currentID(taskID)) { window.reveal(task) }
            MainWindowRequest.isPendingAtLaunch = true
            NotificationCenter.default.post(name: MainWindowRequest.notification, object: nil)
        default:
            break
        }
    }
}
