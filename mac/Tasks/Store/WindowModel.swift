import Foundation
import Observation
import SwiftUI

nonisolated enum SidebarItem: Hashable, Sendable {
    case smart(SmartList)
    case list(String)

    var scope: Scope {
        switch self {
        case .smart(let smart): .smart(smart)
        case .list(let id): .list(id)
        }
    }

    var storageKey: String {
        switch self {
        case .smart(let smart): "smart:" + smart.rawValue
        case .list(let id): "list:" + id
        }
    }

    init?(storageKey: String) {
        if storageKey.hasPrefix("smart:"), let smart = SmartList(rawValue: String(storageKey.dropFirst(6))) {
            self = .smart(smart)
        } else if storageKey.hasPrefix("list:") {
            self = .list(String(storageKey.dropFirst(5)))
        } else {
            return nil
        }
    }
}

nonisolated struct TaskDraft: Identifiable, Hashable, Sendable {
    let id = UUID()
    var listID: String
    var parentID: String?
    var due: Day?
}

@Observable
final class WindowModel {
    static let mainWindowID = "main"

    var selection: SidebarItem? {
        didSet {
            guard selection != oldValue else { return }
            selectedTaskID = nil
            draft = nil
            pinnedTaskIDs = []
            defaults.set(selection?.storageKey, forKey: Keys.selection)
        }
    }
    var selectedTaskID: String?
    var showInspector = false
    var searchText = "" {
        didSet {
            if searchText != oldValue { selectedTaskID = nil }
        }
    }
    var searchFocusRequest = 0
    var draft: TaskDraft?
    var isAddingList = false
    var renamingListID: String?
    var taskPendingDeletion: TaskItem?
    var listPendingDeletion: TaskList?
    var collapsed: Set<String> = []
    var pinnedTaskIDs: [String] = []
    private(set) var completedShown: Set<String>
    private(set) var sortModes: [String: SortMode]

    private let defaults: UserDefaults

    private enum Keys {
        static let selection = "selection"
        static let completedShown = "completedShown"
        static let sortModes = "sortModes"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selection = defaults.string(forKey: Keys.selection).flatMap(SidebarItem.init(storageKey:))
        completedShown = Set(defaults.stringArray(forKey: Keys.completedShown) ?? [])
        let stored = defaults.dictionary(forKey: Keys.sortModes) as? [String: String] ?? [:]
        sortModes = stored.compactMapValues(SortMode.init(rawValue:))
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var scope: Scope? {
        isSearching ? .search(searchText) : selection?.scope
    }

    func showsCompleted(_ item: SidebarItem) -> Bool {
        completedShown.contains(item.storageKey)
    }

    func toggleCompleted(_ item: SidebarItem) {
        if completedShown.contains(item.storageKey) {
            completedShown.remove(item.storageKey)
        } else {
            completedShown.insert(item.storageKey)
        }
        defaults.set(Array(completedShown), forKey: Keys.completedShown)
    }

    func sortOptions(_ item: SidebarItem) -> [SortMode] {
        switch item {
        case .smart(let smart): smart.sortOptions
        case .list: [.manual, .date]
        }
    }

    func sortMode(_ item: SidebarItem) -> SortMode {
        let options = sortOptions(item)
        if let stored = sortModes[item.storageKey], options.contains(stored) { return stored }
        return options[0]
    }

    func setSortMode(_ mode: SortMode, for item: SidebarItem) {
        sortModes[item.storageKey] = mode
        defaults.set(sortModes.mapValues(\.rawValue), forKey: Keys.sortModes)
    }

    func ensureSelection(in store: TaskStore) {
        switch selection {
        case .smart:
            return
        case .list(let id) where store.list(id) != nil:
            return
        default:
            if let id = store.defaultListID { selection = .list(id) }
        }
    }

    func newTask(in store: TaskStore) {
        guard store.canEdit, let defaultID = store.defaultListID else { return }
        searchText = ""
        switch selection {
        case .list(let id):
            draft = TaskDraft(listID: id)
        case .smart(.today):
            draft = TaskDraft(listID: defaultID, due: store.today)
        case .smart(.all):
            draft = TaskDraft(listID: defaultID)
        default:
            selection = .list(defaultID)
            draft = TaskDraft(listID: defaultID)
        }
    }

    func addSubtask(to task: TaskItem, in store: TaskStore) {
        guard store.canEdit, task.parentID == nil, !task.isPending else { return }
        collapsed.remove(task.id)
        let inheritsDue = selection == .smart(.today) || selection == .smart(.scheduled)
        draft = TaskDraft(listID: task.listID, parentID: task.id, due: inheritsDue ? task.due : nil)
    }

    func newList() {
        searchText = ""
        isAddingList = true
    }

    func reveal(_ task: TaskItem) {
        searchText = ""
        selection = .list(task.listID)
        selectedTaskID = task.id
    }

    func showDetails(for id: String) {
        selectedTaskID = id
        setInspector(visible: true)
    }

    func toggleInspector() {
        setInspector(visible: !showInspector)
    }

    private func setInspector(visible: Bool) {
        withAnimation(.smooth(duration: 0.35)) { showInspector = visible }
    }

    func toggleCollapsed(_ id: String) {
        if collapsed.contains(id) {
            collapsed.remove(id)
        } else {
            collapsed.insert(id)
        }
    }

    func idChanged(from old: String, to new: String) {
        if selectedTaskID == old { selectedTaskID = new }
        pinnedTaskIDs = pinnedTaskIDs.map { $0 == old ? new : $0 }
        if selection == .list(old) { selection = .list(new) }
        if draft?.parentID == old { draft?.parentID = new }
        if draft?.listID == old { draft?.listID = new }
    }

    func title(in store: TaskStore) -> String {
        if isSearching { return "Search" }
        switch selection {
        case .smart(let smart): return smart.title
        case .list(let id): return store.listTitle(id)
        case nil: return "Tasks"
        }
    }
}
