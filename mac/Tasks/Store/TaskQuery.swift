import Foundation

nonisolated enum SortMode: String, CaseIterable, Sendable {
    case manual
    case date
}

nonisolated enum SmartList: String, CaseIterable, Identifiable, Sendable {
    case today
    case scheduled
    case all
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .scheduled: "Scheduled"
        case .all: "All"
        case .completed: "Completed"
        }
    }

    var symbol: String {
        switch self {
        case .today: "calendar"
        case .scheduled: "calendar.badge.clock"
        case .all: "tray.fill"
        case .completed: "checkmark"
        }
    }

    var sortsByDateOnly: Bool {
        self == .today || self == .scheduled || self == .completed
    }
}

nonisolated enum Scope: Hashable, Sendable {
    case list(String)
    case smart(SmartList)
    case search(String)
}

nonisolated struct TaskRowItem: Identifiable, Hashable, Sendable {
    var task: TaskItem
    var depth = 0
    var hasChildren = false
    var id: String { task.id }
}

nonisolated struct TaskSection: Identifiable, Hashable, Sendable {
    var id: String
    var title: String?
    var listID: String?
    var rows: [TaskRowItem]
}

nonisolated struct TaskQuery: Sendable {
    var tasks: [TaskItem]
    var lists: [TaskList]
    var today: Day
    var lingering: Set<String> = []
    var pinned: [String] = []
    var calendar: Calendar = .current
    var locale: Locale = .current

    func sections(for scope: Scope, showCompleted: Bool, sort: SortMode, collapsed: Set<String>) -> [TaskSection] {
        let visible = { (task: TaskItem) in !task.isDone || showCompleted || lingering.contains(task.id) }
        switch scope {
        case .list(let listID):
            let rows = outline(tasks.filter { $0.listID == listID && visible($0) }, sort: sort, collapsed: collapsed)
            return rows.isEmpty ? [] : [TaskSection(id: listID, rows: rows)]
        case .smart(.today):
            return todaySections(visible: visible, collapsed: collapsed)
        case .smart(.scheduled):
            return scheduledSections(visible: visible, collapsed: collapsed)
        case .smart(.all):
            return lists.compactMap { list in
                let rows = outline(tasks.filter { $0.listID == list.id && visible($0) }, sort: sort, collapsed: collapsed)
                return rows.isEmpty ? nil : TaskSection(id: list.id, title: list.title, listID: list.id, rows: rows)
            }
        case .smart(.completed):
            return lists.compactMap { list in
                let done = tasks
                    .filter { $0.listID == list.id && $0.isDone }
                    .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
                return done.isEmpty ? nil : TaskSection(id: list.id, title: list.title, listID: list.id, rows: done.map { TaskRowItem(task: $0) })
            }
        case .search(let text):
            return searchSections(text)
        }
    }

    func completedCount(for scope: Scope) -> Int {
        switch scope {
        case .list(let listID): tasks.count { $0.listID == listID && $0.isDone }
        case .smart(.today): tasks.count { $0.isDone && $0.due == today }
        case .smart(.scheduled): tasks.count { $0.isDone && $0.due != nil }
        case .smart(.all), .smart(.completed): tasks.count(where: \.isDone)
        case .search: 0
        }
    }

    func count(for smart: SmartList) -> Int {
        switch smart {
        case .today: tasks.count { !$0.isDone && ($0.due.map { $0 <= today } ?? false) }
        case .scheduled: tasks.count { !$0.isDone && $0.due != nil }
        case .all: tasks.count { !$0.isDone }
        case .completed: tasks.count(where: \.isDone)
        }
    }

    func outline(_ items: [TaskItem], sort: SortMode, collapsed: Set<String>) -> [TaskRowItem] {
        let ids = Set(items.map(\.id))
        let isRoot = { (task: TaskItem) in task.parentID.map { !ids.contains($0) } ?? true }
        let children = Dictionary(grouping: items.filter { !isRoot($0) }) { $0.parentID ?? "" }
            .mapValues { pinnedFirst($0.sorted(by: Self.byPosition)) }
        let roots = pinnedFirst(items.filter(isRoot).sorted(by: sort == .date ? Self.byDate : Self.byPosition))

        var rows: [TaskRowItem] = []
        func append(_ task: TaskItem, depth: Int) {
            let kids = children[task.id] ?? []
            rows.append(TaskRowItem(task: task, depth: depth, hasChildren: !kids.isEmpty))
            guard !collapsed.contains(task.id) else { return }
            for kid in kids { append(kid, depth: depth + 1) }
        }
        for root in roots { append(root, depth: 0) }
        return rows
    }

    private func todaySections(visible: (TaskItem) -> Bool, collapsed: Set<String>) -> [TaskSection] {
        let dated = tasks.filter { task in
            guard let due = task.due, visible(task) else { return false }
            return task.isDone && !lingering.contains(task.id) ? due == today : due <= today
        }
        let overdue = pinnedFirst(dated.filter { $0.due! < today }.sorted(by: byDateThenList))
        let dueToday = pinnedFirst(dated.filter { $0.due == today }.sorted(by: byDateThenList))
        return [
            section("overdue", "Overdue", overdue, collapsed: collapsed),
            section("today", "Today", dueToday, collapsed: collapsed),
        ].compactMap { $0 }
    }

    private func scheduledSections(visible: (TaskItem) -> Bool, collapsed: Set<String>) -> [TaskSection] {
        let dated = tasks.filter { $0.due != nil && visible($0) }.sorted(by: byDateThenList)
        var order: [String] = []
        var groups: [String: (title: String, tasks: [TaskItem])] = [:]
        for task in dated {
            let (key, title) = scheduledGroup(for: task.due!)
            if groups[key] == nil {
                order.append(key)
                groups[key] = (title, [])
            }
            groups[key]?.tasks.append(task)
        }
        return order.compactMap { key in groups[key].flatMap { section(key, $0.title, pinnedFirst($0.tasks), collapsed: collapsed) } }
    }

    private func scheduledGroup(for due: Day) -> (String, String) {
        switch due.days(since: today) {
        case ..<0: ("overdue", "Overdue")
        case 0: ("today", "Today")
        case 1: ("tomorrow", "Tomorrow")
        case 2...6: ("day-\(due.googleDue.prefix(10))", DueText.weekday(due, calendar: calendar, locale: locale))
        default: ("month-\(due.year)-\(due.month)", DueText.monthTitle(due, today: today, calendar: calendar, locale: locale))
        }
    }

    private func searchSections(_ text: String) -> [TaskSection] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        let matches = { (task: TaskItem) in
            task.title.localizedStandardContains(needle) || task.notes.localizedStandardContains(needle)
        }
        return lists.compactMap { list in
            let found = tasks
                .filter { $0.listID == list.id && matches($0) }
                .sorted { ($0.isDone ? 1 : 0, $0.position) < ($1.isDone ? 1 : 0, $1.position) }
            return found.isEmpty ? nil : TaskSection(id: list.id, title: list.title, listID: list.id, rows: found.map { TaskRowItem(task: $0) })
        }
    }

    private func section(_ id: String, _ title: String, _ items: [TaskItem], collapsed: Set<String>) -> TaskSection? {
        items.isEmpty ? nil : TaskSection(id: id, title: title, rows: nested(items, collapsed: collapsed))
    }

    func nested(_ items: [TaskItem], collapsed: Set<String>) -> [TaskRowItem] {
        let ids = Set(items.map(\.id))
        let isChild = { (task: TaskItem) in task.parentID.map(ids.contains) ?? false }
        let children = Dictionary(grouping: items.filter(isChild)) { $0.parentID ?? "" }
            .mapValues { pinnedFirst($0.sorted(by: Self.byPosition)) }
        return items.filter { !isChild($0) }.flatMap { task in
            let kids = children[task.id] ?? []
            let row = TaskRowItem(task: task, hasChildren: !kids.isEmpty)
            guard !collapsed.contains(task.id) else { return [row] }
            return [row] + kids.map { TaskRowItem(task: $0, depth: 1) }
        }
    }

    private func pinnedFirst(_ items: [TaskItem]) -> [TaskItem] {
        guard !pinned.isEmpty else { return items }
        let rank = Dictionary(uniqueKeysWithValues: pinned.enumerated().map { ($1, $0) })
        let top = items.filter { rank[$0.id] != nil }.sorted { rank[$0.id]! < rank[$1.id]! }
        return top + items.filter { rank[$0.id] == nil }
    }

    private var listOrder: [String: Int] {
        Dictionary(uniqueKeysWithValues: lists.enumerated().map { ($1.id, $0) })
    }

    private func byDateThenList(_ a: TaskItem, _ b: TaskItem) -> Bool {
        let order = listOrder
        if a.due != b.due { return Self.dueKey(a) < Self.dueKey(b) }
        let (la, lb) = (order[a.listID] ?? .max, order[b.listID] ?? .max)
        if la != lb { return la < lb }
        return a.position < b.position
    }

    static func byPosition(_ a: TaskItem, _ b: TaskItem) -> Bool {
        (a.position, a.id) < (b.position, b.id)
    }

    static func byDate(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.due != b.due { return dueKey(a) < dueKey(b) }
        return byPosition(a, b)
    }

    private static func dueKey(_ task: TaskItem) -> String {
        task.due.map { String($0.googleDue.prefix(10)) } ?? "9999"
    }
}
