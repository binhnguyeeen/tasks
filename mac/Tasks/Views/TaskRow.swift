import SwiftUI

struct TaskRow: View {
    struct Options {
        var showsDue: Bool
        var showsList: Bool
        var showsParent: Bool
    }

    let item: TaskRowItem
    let options: Options
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window

    static let indent: CGFloat = 28

    var body: some View {
        let task = item.task
        let due = task.due.map { DueText.text(for: $0, today: store.today) }
        let overdue = task.isOverdue(today: store.today)
        let listTitle = store.listTitle(task.listID)
        let expanded = !window.collapsed.contains(task.id)

        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Checkbox(isDone: task.isDone, tint: store.color(forList: task.listID)) {
                store.toggleDone(task.id)
            }
            .disabled(!store.canEdit || task.isPending)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if options.showsParent, item.depth == 0, let parent = store.parentTitle(of: task) {
                    Label(parent, systemImage: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if options.showsList, item.depth == 0 {
                    Text(listTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

            Spacer(minLength: 8)

            if options.showsDue, let due {
                DueLabel(text: due, isOverdue: overdue)
                    .font(.callout)
            }
            if item.hasChildren {
                Button {
                    withAnimation(.snappy) { window.toggleCollapsed(task.id) }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, minHeight: 20)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help(expanded ? "Collapse Subtasks" : "Expand Subtasks")
                .accessibilityLabel(expanded ? "Collapse Subtasks" : "Expand Subtasks")
            }
        }
        .padding(.leading, CGFloat(item.depth) * Self.indent)
        .padding(.vertical, 4)
        .opacity(task.isPending ? 0.6 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.accessibilityText(task, due: due, overdue: overdue, list: listTitle))
        .accessibilityAction(named: task.isDone ? "Mark as Not Done" : "Mark as Done") { store.toggleDone(task.id) }
    }

    static func accessibilityText(_ task: TaskItem, due: String?, overdue: Bool, list: String) -> String {
        var parts = [task.title]
        if let due { parts.append("due \(due)") }
        if overdue { parts.append("overdue") }
        if task.isDone { parts.append("completed") }
        parts.append(list)
        return parts.joined(separator: ", ")
    }
}

struct DraftRow: View {
    let draft: TaskDraft
    let depth: Int
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Checkbox(isDone: false, tint: store.color(forList: draft.listID)) {}
                .disabled(true)
            TextField("New Task", text: $title)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(commit)
                .onExitCommand { window.draft = nil }
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
        .padding(.leading, CGFloat(depth) * TaskRow.indent)
        .padding(.vertical, 4)
        .task {
            isFocused = true
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { commit() }
        }
    }

    private func commit() {
        guard window.draft?.id == draft.id else { return }
        window.draft = nil
        if let id = store.addTask(title: title, listID: draft.listID, due: draft.due, parentID: draft.parentID) {
            window.pinnedTaskIDs.insert(id, at: 0)
            window.selectedTaskID = id
        }
    }
}
