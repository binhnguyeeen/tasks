import Foundation
import Observation
import WidgetKit

final class WidgetBridge {
    static let itemLimit = 40

    private let store: TaskStore
    private var written: WidgetSnapshot?
    private var pendingWrite: Task<Void, Never>?
    private var tickSource: DispatchSourceFileSystemObject?
    private var savedTicks: Set<String> = []
    private var pendingTickCheck: Task<Void, Never>?

    init(store: TaskStore) {
        self.store = store
    }

    func start() {
        observeStore()
        watchTicks()
        processTicks()
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
                self?.processTicks()
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
        if snapshot != written {
            do {
                try snapshot.save()
                written = snapshot
            } catch {
                return
            }
        } else if savedTicks.isEmpty {
            return
        }
        if !savedTicks.isEmpty {
            WidgetTicks.remove(savedTicks)
            savedTicks = []
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func watchTicks() {
        guard let folder = WidgetTicks.folderURL else { return }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let descriptor = open(folder.path(percentEncoded: false), O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.processTicks() }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        tickSource = source
    }

    private func processTicks() {
        let ticks = WidgetTicks.load()
        let now = Date.now
        savedTicks.formIntersection(ticks.times.keys)
        for id in ticks.hidden(at: now).subtracting(savedTicks) {
            let currentID = store.currentID(id)
            guard let task = store.task(currentID), !task.isDone else {
                if store.hasLoaded { savedTicks.insert(id) }
                continue
            }
            guard store.canEdit, !task.isPending else { continue }
            store.setDone(currentID, true)
            savedTicks.insert(id)
        }
        pendingTickCheck?.cancel()
        if let next = ticks.changeDates(after: now).first {
            pendingTickCheck = Task { [weak self] in
                try? await Task.sleep(for: .seconds(max(next.timeIntervalSinceNow, 0) + 0.1))
                guard !Task.isCancelled else { return }
                self?.processTicks()
            }
        }
        scheduleWrite()
    }
}
