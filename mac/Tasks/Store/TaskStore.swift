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
    @ObservationIgnored weak var undoManager: UndoManager?

    let auth: GoogleAuth
    let connectivity: Connectivity
    private let api: TasksAPI
    private var inFlight: [String: Int] = [:]
    private var lastRefresh = Date.distantPast
    private var observers: [NSObjectProtocol] = []
    private var replacedIDs: [String: String] = [:]
    private(set) var usesSampleData = false

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
        guard Date.now.timeIntervalSince(lastRefresh) > 5 else { return }
        await refresh()
    }

    func reset() {
        lists = []
        tasks = []
        defaultListID = nil
        lingering = []
        hasLoaded = false
        lastRefresh = .distantPast
        replacedIDs = [:]
        undoManager?.removeAllActions()
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
        guard canEdit, let task = task(id), !task.isPending, task.isDone != done else { return }
        let family = done ? descendantIDs(of: id).subtracting([id]) : []
        let subtasks = tasks.filter { family.contains($0.id) && !$0.isDone && !$0.isPending }
        let changes = Dictionary(uniqueKeysWithValues: ([task] + subtasks).map { ($0.id, done) })
        applyDone(changes, title: task.title, actionName: done ? "Mark as Done" : "Mark as Not Done")
    }

    private func applyDone(_ changes: [String: Bool], title: String, actionName: String) {
        guard canEdit else { return }
        let before = tasks.filter { task in
            guard let done = changes[task.id] else { return false }
            return !task.isPending && task.isDone != done
        }
        guard !before.isEmpty else { return }
        let now = Date.now
        for task in before {
            guard let i = index(of: task.id), let done = changes[task.id] else { continue }
            tasks[i].isDone = done
            tasks[i].completedAt = done ? now : nil
            if done { linger(task.id) }
        }
        registerUndo(actionName) { store in
            let restored = Dictionary(before.map { (store.currentID($0.id), $0.isDone) }) { first, _ in first }
            store.applyDone(restored, title: title, actionName: actionName)
        }
        let patches = before.map { task in
            (task, changes[task.id] == true
                ? TaskPatch(status: .completed)
                : TaskPatch(status: .needsAction, completed: .some(nil)))
        }
        mutate(before.map(\.id), failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            try await withThrowingTaskGroup(of: (GoogleTask, String).self) { group in
                for (task, patch) in patches {
                    group.addTask { (try await api.patchTask(task.id, in: task.listID, patch: patch), task.listID) }
                }
                for try await (saved, listID) in group {
                    self.replace(saved.id, with: TaskItem(saved, listID: listID))
                }
            }
        } rollback: {
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
        let localID = newLocalID()
        tasks.append(TaskItem(
            id: localID, listID: listID, title: title, due: due, parentID: parentID,
            position: "", isPending: !usesSampleData
        ))
        registerUndo("Add Task") { store in store.deleteTask(store.currentID(localID)) }
        mutate([localID], failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            let saved = try await api.insertTask(
                NewTask(title: title, due: due?.googleDue), in: listID, parent: parentID, previous: nil
            )
            self.replaceLocal(localID, with: TaskItem(saved, listID: listID))
        } rollback: {
            self.tasks.removeAll { $0.id == localID }
        }
        return localID
    }

    func updateTask(_ id: String, title: String? = nil, notes: String? = nil, due: Day?? = nil) {
        guard canEdit, let index = index(of: id), !tasks[index].isPending else { return }
        let before = tasks[index]
        var patch = TaskPatch()
        var changed: [String] = []
        if let title, title != before.title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                patch.title = trimmed
                tasks[index].title = trimmed
                changed.append("Rename Task")
            }
        }
        if let notes, notes != before.notes {
            patch.notes = .some(notes.isEmpty ? nil : notes)
            tasks[index].notes = notes
            changed.append("Edit Notes")
        }
        if let due, due != before.due {
            patch.due = .some(due?.googleDue)
            tasks[index].due = due
            changed.append("Change Due Date")
        }
        guard !patch.isEmpty else { return }
        registerUndo(changed.count == 1 ? changed[0] : "Edit Task") { store in
            store.updateTask(store.currentID(id), title: before.title, notes: before.notes, due: .some(before.due))
        }
        mutate([id], failure: "Couldn’t save “\(before.title)”. Check your connection.") { [api] in
            let saved = try await api.patchTask(id, in: before.listID, patch: patch)
            self.replace(id, with: TaskItem(saved, listID: before.listID))
        } rollback: {
            self.replace(id, with: before)
        }
    }

    func reorderTask(_ id: String, after previousID: String?) {
        guard canEdit, let task = task(id), !task.isPending, previousID != id else { return }
        let siblings = tasks
            .filter { $0.listID == task.listID && $0.parentID == task.parentID && $0.id != id }
            .sorted(by: TaskQuery.byPosition)
        let oldPreviousID = previousSibling(of: task)?.id
        guard oldPreviousID != previousID else { return }
        let before = tasks.filter { $0.listID == task.listID && $0.parentID == task.parentID }
        var order = siblings.map(\.id)
        let insertAt = previousID.flatMap { order.firstIndex(of: $0).map { $0 + 1 } } ?? 0
        order.insert(id, at: insertAt)
        for (rank, siblingID) in order.enumerated() {
            guard let i = index(of: siblingID) else { continue }
            tasks[i].position = String(format: "%020d", rank)
        }
        registerUndo("Move Task") { store in
            store.reorderTask(store.currentID(id), after: oldPreviousID.map(store.currentID))
        }
        mutate([id], failure: "Couldn’t move “\(task.title)”. Check your connection.") { [api] in
            _ = try await api.moveTask(id, from: task.listID, parent: task.parentID, previous: previousID)
            await self.reloadList(task.listID)
        } rollback: {
            for sibling in before { self.replace(sibling.id, with: sibling) }
        }
    }

    private func reloadList(_ listID: String) async {
        guard let fetched = try? await api.tasks(in: listID) else { return }
        let busy = Set(inFlight.keys)
        let local = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        let fresh = fetched.map { TaskItem($0, listID: listID) }.map { busy.contains($0.id) ? (local[$0.id] ?? $0) : $0 }
        tasks = tasks.filter { $0.listID != listID || ($0.isPending && busy.contains($0.id)) } + fresh
    }

    private func descendantIDs(of parentID: String) -> Set<String> {
        let children = Dictionary(grouping: tasks.filter { $0.parentID != nil }) { $0.parentID ?? "" }
        var result: Set<String> = [parentID]
        var stack = [parentID]
        while let current = stack.popLast() {
            for child in children[current] ?? [] where result.insert(child.id).inserted {
                stack.append(child.id)
            }
        }
        return result
    }

    private func previousSibling(of task: TaskItem) -> TaskItem? {
        let siblings = tasks
            .filter { $0.listID == task.listID && $0.parentID == task.parentID }
            .sorted(by: TaskQuery.byPosition)
        guard let index = siblings.firstIndex(where: { $0.id == task.id }), index > 0 else { return nil }
        return siblings[index - 1]
    }

    func moveTask(_ id: String, to destinationID: String) {
        move(id, toList: destinationID, parent: nil, after: nil)
    }

    private func move(_ id: String, toList destinationID: String, parent parentID: String?, after previousID: String?) {
        guard canEdit, let task = task(id), !task.isPending, task.listID != destinationID,
              !destinationID.hasPrefix("local-"), list(destinationID) != nil
        else { return }
        let parentID = parentID.flatMap { self.task($0)?.listID == destinationID ? $0 : nil }
        let previous = previousID.flatMap(self.task).flatMap {
            $0.listID == destinationID && $0.parentID == parentID ? $0 : nil
        }
        let oldPreviousID = previousSibling(of: task)?.id
        let toMove = descendantIDs(of: id)
        let before = tasks.filter { toMove.contains($0.id) }
        for moved in before {
            guard let i = index(of: moved.id) else { continue }
            tasks[i].listID = destinationID
            if moved.id == id {
                tasks[i].parentID = parentID
                tasks[i].position = previous.map { $0.position + "~" } ?? ""
            }
        }
        registerUndo("Move Task") { store in
            store.move(
                store.currentID(id),
                toList: task.listID,
                parent: task.parentID.map(store.currentID),
                after: oldPreviousID.map(store.currentID)
            )
        }
        mutate(before.map(\.id), failure: "Couldn’t move “\(task.title)”. Check your connection.") { [api] in
            let saved = try await api.moveTask(
                id, from: task.listID, to: destinationID, parent: parentID, previous: previous?.id
            )
            self.replace(id, with: TaskItem(saved, listID: destinationID))
        } rollback: {
            for moved in before { self.replace(moved.id, with: moved) }
        }
    }

    func deleteTask(_ id: String) {
        guard canEdit, let task = task(id), !task.isPending else { return }
        let toRemove = descendantIDs(of: id)
        let removed = tasks.filter { toRemove.contains($0.id) }
        let previousID = previousSibling(of: task)?.id
        tasks.removeAll { toRemove.contains($0.id) }
        registerUndo("Delete Task") { store in store.restore(removed, rootID: id, after: previousID) }
        mutate(Array(toRemove), failure: "Couldn’t delete “\(task.title)”. Check your connection.") { [api] in
            try await api.deleteTask(id, in: task.listID)
        } rollback: {
            self.tasks += removed
        }
    }

    private func restore(_ removed: [TaskItem], rootID: String, after previousID: String?) {
        guard canEdit, let root = removed.first(where: { $0.id == rootID }), list(root.listID) != nil,
              task(currentID(rootID)) == nil
        else { return }
        let children = Dictionary(grouping: removed.filter { $0.id != rootID }) { $0.parentID ?? "" }
        var ordered: [TaskItem] = []
        var stack = [root]
        while let item = stack.popLast() {
            ordered.append(item)
            stack += (children[item.id] ?? []).sorted(by: TaskQuery.byPosition).reversed()
        }
        let localIDs = Dictionary(uniqueKeysWithValues: ordered.map { ($0.id, newLocalID()) })
        let rootParentID = root.parentID.map(currentID).flatMap { task($0) == nil ? nil : $0 }
        let rootPreviousID = previousID.map(currentID).flatMap { id in
            task(id).flatMap { $0.listID == root.listID && $0.parentID == rootParentID ? id : nil }
        }
        let recreated = ordered.map { item in
            var copy = item
            copy.id = localIDs[item.id] ?? item.id
            copy.parentID = item.id == rootID ? rootParentID : item.parentID.flatMap { localIDs[$0] }
            copy.isPending = !usesSampleData
            return copy
        }
        tasks += recreated
        for (old, new) in localIDs { replacedIDs[old] = new }
        let rootLocalID = localIDs[rootID] ?? rootID
        registerUndo("Delete Task") { store in store.deleteTask(store.currentID(rootLocalID)) }
        let pendingIDs = Set(recreated.map(\.id))
        mutate(recreated.map(\.id), failure: "Couldn’t restore “\(root.title)”. Check your connection.") { [api] in
            var savedIDs: [String: String] = [:]
            var lastChild: [String: String] = [:]
            for item in recreated {
                let parent = item.id == rootLocalID ? rootParentID : item.parentID.flatMap { savedIDs[$0] }
                let previous = item.id == rootLocalID ? rootPreviousID : lastChild[parent ?? ""]
                let saved = try await api.insertTask(
                    NewTask(
                        title: item.title,
                        notes: item.notes.isEmpty ? nil : item.notes,
                        due: item.due?.googleDue,
                        status: item.isDone ? .completed : nil
                    ),
                    in: item.listID, parent: parent, previous: previous
                )
                savedIDs[item.id] = saved.id
                lastChild[parent ?? ""] = saved.id
                self.replaceLocal(item.id, with: TaskItem(saved, listID: item.listID))
            }
        } rollback: {
            self.tasks.removeAll { pendingIDs.contains($0.id) }
        }
    }

    @discardableResult
    func createList(title: String) -> String? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canEdit, !title.isEmpty else { return nil }
        let localID = newLocalID()
        lists.append(TaskList(id: localID, title: title))
        mutate([localID], failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            let saved = try await api.insertList(title: title)
            if let index = self.lists.firstIndex(where: { $0.id == localID }) {
                self.lists[index] = saved
            }
            self.replacedIDs[localID] = saved.id
            self.onIDChange?(localID, saved.id)
        } rollback: {
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
        registerUndo("Rename List") { store in store.renameList(store.currentID(id), to: before.title) }
        mutate([id], failure: "Couldn’t save “\(title)”. Check your connection.") { [api] in
            _ = try await api.renameList(id, title: title)
        } rollback: {
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
        } rollback: {
            self.lists.insert(list, at: min(index, self.lists.count))
            self.tasks += removed
        }
    }

    private func mutate(
        _ ids: [String],
        failure: String,
        _ operation: @escaping () async throws -> Void,
        rollback: @escaping () -> Void
    ) {
        if usesSampleData { return }
        for id in ids { inFlight[id, default: 0] += 1 }
        Task {
            do {
                try await operation()
            } catch {
                withAnimation(.snappy) { rollback() }
                showNotice(failure)
            }
            for id in ids {
                inFlight[id, default: 1] -= 1
                if inFlight[id] == 0 { inFlight[id] = nil }
            }
        }
    }

    private func registerUndo(_ actionName: String, _ action: @escaping (TaskStore) -> Void) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { store in
            withAnimation(.snappy) { action(store) }
        }
        undoManager.setActionName(actionName)
    }

    func currentID(_ id: String) -> String {
        var id = id
        var seen: Set<String> = [id]
        while let next = replacedIDs[id], seen.insert(next).inserted { id = next }
        return id
    }

    private func newLocalID() -> String {
        (usesSampleData ? "sample-" : "local-") + UUID().uuidString
    }

    private func replaceLocal(_ localID: String, with saved: TaskItem) {
        replace(localID, with: saved)
        for i in tasks.indices where tasks[i].parentID == localID {
            tasks[i].parentID = saved.id
        }
        replacedIDs[localID] = saved.id
        onIDChange?(localID, saved.id)
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
                try? await Task.sleep(for: .seconds(60))
                guard let self else { return }
                if NSApp.isActive || Date.now.timeIntervalSince(self.lastRefresh) >= 300 {
                    await self.refresh()
                }
            }
        }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                _ = Task { await self?.refreshIfStale() }
            }
        })
        observers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                _ = Task { await self?.refreshIfStale() }
            }
        })
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
