import Foundation
import Observation
import WidgetKit

final class WidgetBridge {
    static let itemLimit = 40

    private let store: TaskStore
    private var written: WidgetSnapshot?
    private var pendingWrite: Task<Void, Never>?

    init(store: TaskStore) {
        self.store = store
    }

    func start() {
        observeStore()
        scheduleWrite()
    }

    static func snapshot(of store: TaskStore) -> WidgetSnapshot {
        let horizon = store.today.adding(days: 1)
        let order = Dictionary(store.lists.enumerated().map { ($1.id, $0) }) { first, _ in first }
        let open = store.tasks
            .filter { !$0.isDone && !$0.isPending }
            .sorted { a, b in
                switch (a.due, b.due) {
                case let (x?, y?) where x != y: return x < y
                case (.some, nil): return true
                case (nil, .some): return false
                default: break
                }
                if a.listID != b.listID { return (order[a.listID] ?? .max) < (order[b.listID] ?? .max) }
                if a.position != b.position { return TaskQuery.byPosition(a, b) }
                if (a.parentID == nil) != (b.parentID == nil) { return a.parentID == nil }
                return a.id < b.id
            }
        let item = { (task: TaskItem) in
            WidgetSnapshot.Item(
                id: task.id,
                title: task.title,
                listTitle: store.listTitle(task.listID),
                color: store.listColor(task.listID).rawValue,
                due: task.due?.googleDue ?? ""
            )
        }
        return WidgetSnapshot(
            isSignedIn: store.auth.isSignedIn,
            showsLists: store.spansSeveralLists,
            items: open.filter { $0.due.map { $0 <= horizon } ?? false }.prefix(itemLimit).map(item),
            open: open.prefix(itemLimit).map(item),
            openCount: open.count
        )
    }

    private func observeStore() {
        withObservationTracking {
            _ = store.tasks
            _ = store.lists
            _ = store.today
            _ = store.hasLoaded
            _ = store.auth.isSignedIn
            _ = store.chosenListColors
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observeStore()
                self?.scheduleWrite()
            }
        }
    }

    private func scheduleWrite() {
        pendingWrite?.cancel()
        pendingWrite = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            write()
        }
    }

    private func write() {
        guard store.hasLoaded || !store.auth.isSignedIn else { return }
        let snapshot = Self.snapshot(of: store)
        guard snapshot != written else { return }
        do {
            try snapshot.save()
            written = snapshot
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
        }
    }
}
