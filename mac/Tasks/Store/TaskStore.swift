import AppKit
import Foundation
import Observation
import SwiftUI

@Observable
final class TaskStore {
    struct Notice: Identifiable, Equatable {
        let id = UUID()
        let message: String
    }

    private(set) var lists: [TaskList] = []
    private(set) var defaultListID: String?
    private(set) var tasks: [TaskItem] = []
    private(set) var lingering: Set<String> = []
    private(set) var hasLoaded = false
    private(set) var isRefreshing = false
    private(set) var notice: Notice?
    private(set) var today = Day.today()

    var onIDChange: ((_ old: String, _ new: String) -> Void)?

    let auth: GoogleAuth
    let connectivity: Connectivity
    private let api: TasksAPI
    private var inFlight: [String: Int] = [:]
    private var lastRefresh = Date.distantPast
    private var observers: [NSObjectProtocol] = []
    private var usesSampleData = false

    init(auth: GoogleAuth, connectivity: Connectivity) {
        self.auth = auth
        self.connectivity = connectivity
        api = TasksAPI { [auth] forceRefresh in
            try await auth.accessToken(forceRefresh: forceRefresh)
        }
        startBackgroundRefresh()
    }

    var isOnline: Bool { connectivity.isOnline }
    var canEdit: Bool { isOnline && auth.isSignedIn && hasLoaded }

    var query: TaskQuery {
        TaskQuery(tasks: tasks, lists: lists, today: today, lingering: lingering)
    }

    var dueCount: Int {
        tasks.count { !$0.isDone && ($0.due.map { $0 <= today } ?? false) }
    }

    var menuBarCount: Int {
        auth.isSignedIn && isOnline && hasLoaded ? dueCount : 0
    }

    var overdue: [TaskItem] {
        dropdownTasks.filter { $0.due! < today }
    }

    var dueToday: [TaskItem] {
        dropdownTasks.filter { $0.due == today }
    }

    var spansSeveralLists: Bool {
        Set(tasks.lazy.filter { !$0.isDone }.map(\.listID)).count > 1
    }

    private var dropdownTasks: [TaskItem] {
        let order = Dictionary(uniqueKeysWithValues: lists.enumerated().map { ($1.id, $0) })
        return tasks
            .filter { task in
                guard let due = task.due, due <= today else { return false }
                return !task.isDone || lingering.contains(task.id)
            }
            .sorted { a, b in
                if a.due != b.due { return a.due! < b.due! }
                if a.listID != b.listID { return (order[a.listID] ?? .max) < (order[b.listID] ?? .max) }
                return TaskQuery.byPosition(a, b)
            }
    }

    func task(_ id: String) -> TaskItem? {
        tasks.first { $0.id == id }
    }

    func list(_ id: String) -> TaskList? {
        lists.first { $0.id == id }
    }

    func listTitle(_ id: String) -> String {
        list(id)?.title ?? ""
    }

    private(set) var chosenListColors: [String: ListColor] = UserDefaults.standard
        .dictionary(forKey: "listColors")
        .flatMap { $0 as? [String: String] }?
        .compactMapValues(ListColor.init(rawValue:)) ?? [:]

    func listColor(_ id: String) -> ListColor {
        chosenListColors[id] ?? ListPalette.automaticColor(for: id, isDefault: id == defaultListID)
    }

    func setListColor(_ color: ListColor, for id: String) {
        chosenListColors[id] = color
        UserDefaults.standard.set(chosenListColors.mapValues(\.rawValue), forKey: "listColors")
    }

    func color(forList id: String) -> Color {
        listColor(id).color
    }

    func openCount(inList id: String) -> Int {
        tasks.count { $0.listID == id && !$0.isDone }
    }

    func parentTitle(of task: TaskItem) -> String? {
        task.parentID.flatMap { self.task($0)?.title }
    }

    func refresh() async {
        guard auth.isSignedIn, !isRefreshing, !usesSampleData else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        today = .today()
        let api = api
        do {
            async let fetchedLists = api.taskLists()
            async let fetchedDefault = api.defaultTaskList()
            let (allLists, defaultList) = try await (fetchedLists, fetchedDefault)
            let fetched = try await withThrowingTaskGroup(of: (String, [GoogleTask]).self) { group in
                for list in allLists {
                    group.addTask { (list.id, try await api.tasks(in: list.id)) }
                }
                var results: [String: [GoogleTask]] = [:]
                for try await (listID, items) in group {
                    results[listID] = items
                }
                return results
            }
            apply(lists: allLists, defaultID: defaultList.id, fetched: fetched)
            lastRefresh = .now
        } catch GoogleAuth.AuthError.signedOut {
            reset()
        } catch {
        }
    }

    func refreshIfStale() async {
        guard Date.now.timeIntervalSince(lastRefresh) > 20 else { return }
        await refresh()
    }

    func reset() {
        lists = []
        tasks = []
        defaultListID = nil
        lingering = []
        hasLoaded = false
        lastRefresh = .distantPast
    }

    private func apply(lists newLists: [TaskList], defaultID: String, fetched: [String: [GoogleTask]]) {
        let busy = Set(inFlight.keys)
        let local = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        var merged = newLists.flatMap { list in
            (fetched[list.id] ?? []).map { TaskItem($0, listID: list.id) }
        }
        merged = merged.map { busy.contains($0.id) ? (local[$0.id] ?? $0) : $0 }
        merged += tasks.filter { $0.isPending && busy.contains($0.id) }

        let pendingLists = lists.filter { busy.contains($0.id) && !newLists.contains($0) && $0.id.hasPrefix("local-") }
        var ordered = newLists
        if let index = ordered.firstIndex(where: { $0.id == defaultID }) {
            ordered.insert(ordered.remove(at: index), at: 0)
        }
        lists = ordered + pendingLists
        defaultListID = defaultID
        tasks = merged
        hasLoaded = true
    }

    func setDone(_ id: String, _ done: Bool) {
        guard canEdit, let index = index(of: id), !tasks[index].isPending, tasks[index].isDone != done else { return }
        let parent = tasks[index]
        let subtasks = done ? tasks.filter { $0.parentID == id && !$0.isDone && !$0.isPending } : []
        let before = [parent] + subtasks
        let now = Date.now
        for task in before {
            guard let i = self.index(of: task.id) else { continue }
            tasks[i].isDone = done
            tasks[i].completedAt = done ? now : nil
            if done { linger(task.id) }
        }
        let patch = done
            ? TaskPatch(status: .completed)
            : TaskPatch(status: .needsAction, completed: .some(nil))
        mutate(before.map(\.id), failure: "Couldn’t save “\(parent.title)”. Check your connection.") { [api] in
            try await withThrowingTaskGroup(of: GoogleTask.self) { group in
                for task in before {
                    group.addTask { try await api.patchTask(task.id, in: task.listID, patch: patch) }
                }
                for try await saved in group {
                    self.replace(saved.id, with: TaskItem(saved, listID: parent.listID))
                }
            }
        } undo: {
            for task in before { self.replace(task.id, with: task) }
        }
    }

    func toggleDone(_ id: String) {
        guard let task = task(id) else { return }
        setDone(id, !task.isDone)
    }

    @discardableResult
    func addTask(title: String, listID: String, due: Day? = nil, parentID: String? = nil) -> String? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canEdit, !title.isEmpty else { return nil }
        let localID = (usesSampleData ? "sample-" : "local-") + UUID().uuidString
        tasks.append(TaskItem(
            id: localID, listID: listID, title: title, due: due, parentID: parentID,
            position: "", isPending: !usesSampleData
        ))
        mutate([localID], failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            let saved = try await api.insertTask(
                NewTask(title: title, due: due?.googleDue), in: listID, parent: parentID, previous: nil
            )
            self.replace(localID, with: TaskItem(saved, listID: listID))
            self.onIDChange?(localID, saved.id)
        } undo: {
            self.tasks.removeAll { $0.id == localID }
        }
        return localID
    }

    func updateTask(_ id: String, title: String? = nil, notes: String? = nil, due: Day?? = nil) {
        guard canEdit, let index = index(of: id), !tasks[index].isPending else { return }
        let before = tasks[index]
        var patch = TaskPatch()
        if let title, title != before.title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                patch.title = trimmed
                tasks[index].title = trimmed
            }
        }
        if let notes, notes != before.notes {
            patch.notes = .some(notes.isEmpty ? nil : notes)
            tasks[index].notes = notes
        }
        if let due, due != before.due {
            patch.due = .some(due?.googleDue)
            tasks[index].due = due
        }
        guard !patch.isEmpty else { return }
        mutate([id], failure: "Couldn’t save “\(before.title)”. Check your connection.") { [api] in
            let saved = try await api.patchTask(id, in: before.listID, patch: patch)
            self.replace(id, with: TaskItem(saved, listID: before.listID))
        } undo: {
            self.replace(id, with: before)
        }
    }

    func moveTask(_ id: String, to destinationID: String) {
        guard canEdit, let task = task(id), !task.isPending, task.listID != destinationID,
              !destinationID.hasPrefix("local-"), list(destinationID) != nil
        else { return }
        let before = tasks.filter { $0.id == id || $0.parentID == id }
        for moved in before {
            guard let i = index(of: moved.id) else { continue }
            tasks[i].listID = destinationID
            if moved.id == id {
                tasks[i].parentID = nil
                tasks[i].position = "~" + id
            }
        }
        mutate(before.map(\.id), failure: "Couldn’t move “\(task.title)”. Check your connection.") { [api] in
            let saved = try await api.moveTask(id, from: task.listID, to: destinationID)
            self.replace(id, with: TaskItem(saved, listID: destinationID))
        } undo: {
            for moved in before { self.replace(moved.id, with: moved) }
        }
    }

    func deleteTask(_ id: String) {
        guard canEdit, let task = task(id), !task.isPending else { return }
        let removed = tasks.filter { $0.id == id || $0.parentID == id }
        tasks.removeAll { $0.id == id || $0.parentID == id }
        mutate([id], failure: "Couldn’t delete “\(task.title)”. Check your connection.") { [api] in
            try await api.deleteTask(id, in: task.listID)
        } undo: {
            self.tasks += removed
        }
    }

    @discardableResult
    func createList(title: String) -> String? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canEdit, !title.isEmpty else { return nil }
        let localID = (usesSampleData ? "sample-" : "local-") + UUID().uuidString
        lists.append(TaskList(id: localID, title: title))
        mutate([localID], failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            let saved = try await api.insertList(title: title)
            if let index = self.lists.firstIndex(where: { $0.id == localID }) {
                self.lists[index] = saved
            }
            self.onIDChange?(localID, saved.id)
        } undo: {
            self.lists.removeAll { $0.id == localID }
        }
        return localID
    }

    func renameList(_ id: String, to title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canEdit, !id.hasPrefix("local-"), let index = lists.firstIndex(where: { $0.id == id }),
              !title.isEmpty, lists[index].title != title
        else { return }
        let before = lists[index]
        lists[index].title = title
        mutate([id], failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            _ = try await api.renameList(id, title: title)
        } undo: {
            if let index = self.lists.firstIndex(where: { $0.id == id }) { self.lists[index] = before }
        }
    }

    func deleteList(_ id: String) {
        guard canEdit, id != defaultListID, !id.hasPrefix("local-"),
              let index = lists.firstIndex(where: { $0.id == id })
        else { return }
        let list = lists[index]
        let removed = tasks.filter { $0.listID == id }
        lists.remove(at: index)
        tasks.removeAll { $0.listID == id }
        mutate([id], failure: "Couldn’t delete “\(list.title)”. Check your connection.") { [api] in
            try await api.deleteList(id)
        } undo: {
            self.lists.insert(list, at: min(index, self.lists.count))
            self.tasks += removed
        }
    }

    private func mutate(
        _ ids: [String],
        failure: String,
        _ operation: @escaping () async throws -> Void,
        undo: @escaping () -> Void
    ) {
        if usesSampleData { return }
        for id in ids { inFlight[id, default: 0] += 1 }
        Task {
            do {
                try await operation()
            } catch {
                withAnimation(.snappy) { undo() }
                showNotice(failure)
            }
            for id in ids {
                inFlight[id, default: 1] -= 1
                if inFlight[id] == 0 { inFlight[id] = nil }
            }
        }
    }

    private func replace(_ id: String, with task: TaskItem) {
        guard let index = index(of: id) else { return }
        tasks[index] = task
    }

    private func index(of id: String) -> Int? {
        tasks.firstIndex { $0.id == id }
    }

    private func linger(_ id: String) {
        lingering.insert(id)
        Task {
            try? await Task.sleep(for: .seconds(1))
            _ = withAnimation(.snappy) { lingering.remove(id) }
        }
    }

    #if DEBUG
    func loadSampleData() {
        usesSampleData = true
        let sample = SampleData(today: today)
        lists = sample.lists
        defaultListID = sample.lists.first?.id
        tasks = sample.tasks
        hasLoaded = true
    }
    #endif

    func showNotice(_ message: String) {
        let notice = Notice(message: message)
        withAnimation(.snappy) { self.notice = notice }
        Task {
            try? await Task.sleep(for: .seconds(4))
            if self.notice?.id == notice.id {
                withAnimation(.snappy) { self.notice = nil }
            }
        }
    }

    private func startBackgroundRefresh() {
        Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                await self?.refresh()
            }
        }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.today = .today() }
        })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.today = .today()
                Task { await self?.refresh() }
            }
        })
        withObservationTracking {
            _ = connectivity.isOnline
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.connectivityChanged()
            }
        }
    }

    private func connectivityChanged() {
        if connectivity.isOnline {
            Task { await refresh() }
        }
        withObservationTracking {
            _ = connectivity.isOnline
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.connectivityChanged()
            }
        }
    }
}
