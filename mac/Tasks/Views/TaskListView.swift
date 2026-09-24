import SwiftUI

struct TaskListView: View {
    let scope: Scope
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window

    var body: some View {
        @Bindable var window = window
        let sections = placeDraft(in: query.sections(
            for: scope,
            showCompleted: item.map(window.showsCompleted) ?? false,
            sort: sort,
            collapsed: window.collapsed
        ))
        List(selection: $window.selectedTaskID) {
            if let item {
                ContentHeader(item: item, scope: scope)
                    .selectionDisabled()
                    .listRowSeparator(.hidden)
            }
            ForEach(sections) { section in
                if let title = section.title {
                    Section {
                        rows(section)
                    } header: {
                        Text(title)
                            .font(.title3.bold())
                            .foregroundStyle(section.listID.map { AnyShapeStyle(store.color(forList: $0)) } ?? AnyShapeStyle(.primary))
                            .padding(.top, 8)
                    }
                } else {
                    rows(section)
                }
            }
        }
        .listStyle(.inset)
        .animation(.snappy, value: sections)
        .overlay {
            if sections.isEmpty {
                emptyState
            }
        }
        .contextMenu(forSelectionType: String.self) { ids in
            if let id = ids.first, let task = store.task(id) {
                if task.parentID == nil {
                    Button("Add Subtask") { window.addSubtask(to: task, in: store) }
                        .disabled(!store.canEdit || task.isPending)
                }
                Button("Show Details") { window.showDetails(for: id) }
                Divider()
                Button("Delete…") { window.taskPendingDeletion = task }
                    .disabled(!store.canEdit || task.isPending)
            }
        } primaryAction: { ids in
            if let id = ids.first { window.showDetails(for: id) }
        }
        .onKeyPress(.space) {
            guard let id = window.selectedTaskID else { return .ignored }
            store.toggleDone(id)
            return .handled
        }
    }

    private var sort: SortMode {
        item.map(window.sortMode) ?? .manual
    }

    private var query: TaskQuery {
        var query = store.query
        query.pinned = window.pinnedTaskIDs
        return query
    }

    private var item: SidebarItem? {
        switch scope {
        case .list(let id): .list(id)
        case .smart(let smart): .smart(smart)
        case .search: nil
        }
    }

    @ViewBuilder
    private func rows(_ section: DisplaySection) -> some View {
        ForEach(section.rows) { row in
            switch row {
            case .task(let item):
                TaskRow(item: item, options: options)
                    .tag(item.id)
            case .draft(let draft, let depth):
                DraftRow(draft: draft, depth: depth)
                    .selectionDisabled()
            }
        }
        .onMove(perform: canReorder ? { source, destination in reorder(section.rows, source, destination) } : nil)
    }

    private var canReorder: Bool {
        guard case .list = scope else { return false }
        return sort == .manual && window.draft == nil && store.canEdit
    }

    private func reorder(_ rows: [DisplayRow], _ source: IndexSet, _ destination: Int) {
        guard let from = source.first, case .task(let moved) = rows[from] else { return }
        let parentID = moved.task.parentID
        let siblings = rows.enumerated().compactMap { index, row -> (Int, String)? in
            guard case .task(let item) = row, item.id != moved.id, item.task.parentID == parentID else { return nil }
            return (index, item.id)
        }
        if parentID != nil {
            let blockStart = rows.firstIndex { $0.id == parentID } ?? 0
            let blockEnd = (siblings.map(\.0) + [from]).max() ?? from
            guard destination > blockStart, destination <= blockEnd + 1 else { return }
        }
        let previous = siblings.last { $0.0 < destination }?.1
        window.pinnedTaskIDs = []
        withAnimation(.snappy) { store.reorderTask(moved.id, after: previous) }
    }

    private var options: TaskRow.Options {
        let groupedByList = sort == .list
        switch scope {
        case .smart(.today), .smart(.scheduled):
            return TaskRow.Options(showsDue: groupedByList, showsList: !groupedByList, showsParent: true)
        case .smart(.all), .smart(.completed):
            return TaskRow.Options(showsDue: true, showsList: !groupedByList, showsParent: !groupedByList)
        case .search:
            return TaskRow.Options(showsDue: true, showsList: false, showsParent: true)
        case .list:
            return TaskRow.Options(showsDue: true, showsList: false, showsParent: false)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if case .search(let text) = scope {
            ContentUnavailableView.search(text: text)
        } else if window.draft == nil {
            ContentUnavailableView("No Tasks", systemImage: "checklist", description: Text("Press ⌘N to add one."))
        }
    }

    private func placeDraft(in sections: [TaskSection]) -> [DisplaySection] {
        var display = sections.map { DisplaySection(id: $0.id, title: $0.title, listID: $0.listID, rows: $0.rows.map { .task($0) }) }
        guard let draft = window.draft else { return display }

        if let parentID = draft.parentID {
            for (s, section) in display.enumerated() {
                guard let parentIndex = section.rows.firstIndex(where: { $0.id == parentID }) else { continue }
                display[s].rows.insert(.draft(draft, depth: 1), at: parentIndex + 1)
                return display
            }
        }

        let targetID: String
        let title: String?
        let byList = sort == .list && scope != .list(draft.listID)
        switch scope {
        case .smart(.today) where !byList:
            targetID = "today"
            title = "Today"
        case .smart where byList:
            targetID = draft.listID
            title = store.listTitle(draft.listID)
        case .smart:
            targetID = "timeline"
            title = nil
        default:
            targetID = draft.listID
            title = nil
        }
        if let index = display.firstIndex(where: { $0.id == targetID }) {
            display[index].rows.insert(.draft(draft, depth: 0), at: 0)
        } else {
            let listID = byList ? draft.listID : nil
            let section = DisplaySection(id: targetID, title: title, listID: listID, rows: [.draft(draft, depth: 0)])
            let order = { (id: String) in store.lists.firstIndex { $0.id == id } ?? .max }
            if byList, let index = display.firstIndex(where: { order($0.id) > order(draft.listID) }) {
                display.insert(section, at: index)
            } else {
                display.append(section)
            }
        }
        return display
    }
}

private struct DisplaySection: Identifiable, Hashable {
    var id: String
    var title: String?
    var listID: String?
    var rows: [DisplayRow]
}

private enum DisplayRow: Identifiable, Hashable {
    case task(TaskRowItem)
    case draft(TaskDraft, depth: Int)

    var id: String {
        switch self {
        case .task(let item): item.id
        case .draft(let draft, _): "draft-" + draft.id.uuidString
        }
    }
}

private struct ContentHeader: View {
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    let item: SidebarItem
    let scope: Scope

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(color)
                .lineLimit(1)
            if item != .smart(.completed) {
                let completed = store.query.completedCount(for: scope)
                let isShowing = window.showsCompleted(item)
                HStack(spacing: 4) {
                    Text("\(completed) Completed")
                        .foregroundStyle(.secondary)
                    if completed > 0 || isShowing {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Button(isShowing ? "Hide" : "Show") {
                            withAnimation(.snappy) { window.toggleCompleted(item) }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(color)
                    }
                }
            }
            Divider()
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var title: String {
        switch item {
        case .smart(let smart): smart.title
        case .list(let id): store.listTitle(id)
        }
    }

    private var color: Color {
        switch item {
        case .smart(let smart): smart.headerColor
        case .list(let id): store.color(forList: id)
        }
    }
}
