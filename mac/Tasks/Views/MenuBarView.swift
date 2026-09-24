import SwiftUI

struct MenuBarView: View {
    @Environment(GoogleAuth.self) private var auth
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if auth.isSignedIn {
                QuickAddBar()
                if !store.isOnline {
                    OfflineBanner()
                        .padding(.horizontal, 4)
                }
                Divider()
                DueList(openTask: open)
                if let notice = store.notice {
                    NoticeBanner(notice: notice)
                        .padding(.horizontal, 4)
                }
                Divider()
                MenuItemRow(title: "Open Tasks", shortcut: "⌘O") { open(nil) }
                    .keyboardShortcut("o")
                MenuItemRow(title: "Refresh", shortcut: "⌘R") { Task { await store.refresh() } }
                    .keyboardShortcut("r")
                    .disabled(!store.isOnline)
                quitItem
            } else {
                SignInView(size: .dropdown)
                    .padding(.vertical, 12)
                Divider()
                quitItem
            }
        }
        .padding(12)
        .frame(width: 340)
        .task { await store.refreshIfStale() }
    }

    private var quitItem: some View {
        MenuItemRow(title: "Quit Tasks") {
            QuitPolicy.allowQuit = true
            NSApp.terminate(nil)
        }
    }

    private func open(_ task: TaskItem?) {
        if let task { window.reveal(task) }
        dismiss()
        openWindow(id: WindowModel.mainWindowID)
        NSApp.activate()
    }
}

private struct QuickAddBar: View {
    @Environment(TaskStore.self) private var store
    @State private var text = ""
    @State private var confirmation: String?

    var body: some View {
        let parse = QuickAddParser.parse(text)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                QuickAddField(text: $text, highlight: parse.dateRange, placeholder: "New Task") {
                    submit(parse)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(.quaternary, in: .fieldSquircle)
            if let due = parse.due {
                Label(DueText.text(for: due, today: store.today), systemImage: "calendar")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .transition(.opacity)
            } else if let confirmation {
                Label(confirmation, systemImage: "checkmark")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .transition(.opacity)
            }
        }
        .disabled(!store.canEdit)
        .animation(.snappy, value: parse.due)
        .animation(.snappy, value: confirmation)
    }

    private func submit(_ parse: QuickAddParse) {
        guard let listID = store.defaultListID,
              store.addTask(title: parse.title, listID: listID, due: parse.due) != nil
        else { return }
        text = ""
        let message = "Added “\(parse.title)” to \(store.listTitle(listID))"
        confirmation = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            if confirmation == message { confirmation = nil }
        }
    }
}

private struct DueList: View {
    @Environment(TaskStore.self) private var store
    let openTask: (TaskItem) -> Void
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        let overdue = store.overdue
        let today = store.dueToday
        if !store.hasLoaded {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else if overdue.isEmpty && today.isEmpty {
            ContentUnavailableView {
                Label("Nothing Due", systemImage: "checkmark.circle")
                    .symbolRenderingMode(.hierarchical)
            } description: {
                Text("Tasks due today and overdue show up here.")
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    DueSection(title: "Overdue", tasks: overdue, openTask: openTask)
                    DueSection(title: "Today", tasks: today, openTask: openTask)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: min(contentHeight, 380))
        }
    }
}

private struct DueSection: View {
    @Environment(TaskStore.self) private var store
    let title: String
    let tasks: [TaskItem]
    let openTask: (TaskItem) -> Void

    var body: some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(tasks.count, format: .number)
                        .monospacedDigit()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
                .accessibilityAddTraits(.isHeader)
                ForEach(tasks) { task in
                    DropdownRow(task: task, showsList: store.spansSeveralLists) { openTask(task) }
                        .transition(.opacity)
                }
            }
        }
    }
}

private struct DropdownRow: View {
    @Environment(TaskStore.self) private var store
    let task: TaskItem
    let showsList: Bool
    let open: () -> Void
    @State private var isHovering = false

    var body: some View {
        let due = task.due.map { DueText.text(for: $0, today: store.today) }
        let overdue = task.isOverdue(today: store.today)
        let listTitle = store.listTitle(task.listID)
        HStack(spacing: 8) {
            Checkbox(isDone: task.isDone, tint: store.color(forList: task.listID)) {
                store.toggleDone(task.id)
            }
            .disabled(!store.canEdit || task.isPending)
            Button(action: open) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .lineLimit(1)
                        .foregroundStyle(task.isDone ? .secondary : .primary)
                    Spacer(minLength: 8)
                    if let due {
                        DueLabel(text: due, isOverdue: overdue)
                    }
                    if showsList {
                        Text(listTitle)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .frame(minHeight: 30)
        .background {
            if isHovering {
                Rectangle().fill(.quaternary).clipShape(.rowSquircle)
            }
        }
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TaskRow.accessibilityText(task, due: due, overdue: overdue, list: listTitle))
        .accessibilityAction(named: task.isDone ? "Mark as Not Done" : "Mark as Done") { store.toggleDone(task.id) }
        .accessibilityAction(named: "Show Details", open)
    }
}

struct MenuItemRow: View {
    let title: String
    var shortcut: String?
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if let shortcut {
                    Text(shortcut)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(isEnabled ? .primary : .tertiary)
            .padding(.horizontal, 8)
            .frame(minHeight: 28)
            .background {
                if isHovering && isEnabled {
                    Rectangle().fill(.quaternary).clipShape(.rowSquircle)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
