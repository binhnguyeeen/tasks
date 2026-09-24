import SwiftUI

struct Sidebar: View {
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window

    var body: some View {
        @Bindable var window = window
        List(selection: $window.selection) {
            SmartListGrid()
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .selectionDisabled()

            Section("Lists") {
                ForEach(store.lists) { list in
                    ListRow(list: list)
                        .tag(SidebarItem.list(list.id))
                        .contextMenu {
                            Button("Rename") { window.renamingListID = list.id }
                                .disabled(!store.canEdit || list.id.hasPrefix("local-"))
                            Divider()
                            Picker("Color", selection: Binding(
                                get: { store.listColor(list.id) },
                                set: { store.setListColor($0, for: list.id) }
                            )) {
                                ForEach(ListColor.allCases) { color in
                                    Label(color.name, systemImage: "circle.fill")
                                        .tint(color.color)
                                        .help(color.name)
                                        .tag(color)
                                }
                            }
                            .pickerStyle(.palette)
                            Divider()
                            Button("Delete List…") { window.listPendingDeletion = list }
                                .disabled(!store.canEdit || list.id == store.defaultListID || list.id.hasPrefix("local-"))
                        }
                }
                if window.isAddingList {
                    NewListRow()
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    window.newList()
                } label: {
                    Label("Add List", systemImage: "text.badge.plus")
                }
                .help("Add List")
                .disabled(!store.canEdit)
            }
        }
    }
}

private struct SmartListGrid: View {
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window

    var body: some View {
        let query = store.query
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                tile(.today, query)
                tile(.scheduled, query)
            }
            GridRow {
                tile(.all, query)
                tile(.completed, query)
            }
        }
    }

    private func tile(_ smart: SmartList, _ query: TaskQuery) -> some View {
        SmartListTile(smart: smart, count: query.count(for: smart), isSelected: window.selection == .smart(smart)) {
            window.searchText = ""
            window.selection = .smart(smart)
        }
    }
}

extension SmartList {
    var color: Color {
        switch self {
        case .today: .blue
        case .scheduled: .red
        case .all: .gray.mix(with: .black, by: 0.45)
        case .completed: .gray
        }
    }

    var headerColor: Color {
        self == .all ? .primary : color
    }
}

private struct SmartListTile: View {
    let smart: SmartList
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: smart.symbol)
                        .font(.title3)
                    Spacer()
                    Text(count, format: .number)
                        .font(.title2.bold())
                        .monospacedDigit()
                }
                Text(smart.title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(smart.color.gradient, in: .tileSquircle)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12 + 3, style: .continuous)
                        .strokeBorder(smart.color.opacity(0.45), lineWidth: 2.5)
                        .padding(-3)
                }
            }
            .contentShape(.tileSquircle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(smart.title), \(count)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ListRow: View {
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    let list: TaskList
    @State private var title = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        Label {
            if window.renamingListID == list.id {
                TextField("List Name", text: $title)
                    .textFieldStyle(.plain)
                    .focused($isEditing)
                    .onAppear {
                        title = list.title
                        isEditing = true
                    }
                    .onSubmit(commit)
                    .onChange(of: isEditing) { _, editing in if !editing { commit() } }
                    .onExitCommand { window.renamingListID = nil }
            } else {
                Text(list.title)
            }
        } icon: {
            ListIcon(color: store.color(forList: list.id))
        }
        .badge(store.openCount(inList: list.id))
    }

    private func commit() {
        guard window.renamingListID == list.id else { return }
        window.renamingListID = nil
        store.renameList(list.id, to: title)
    }
}

private struct NewListRow: View {
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    @State private var title = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        Label {
            TextField("New List", text: $title)
                .textFieldStyle(.plain)
                .focused($isEditing)
                .onAppear { isEditing = true }
                .onSubmit(commit)
                .onChange(of: isEditing) { _, editing in if !editing { commit() } }
                .onExitCommand { window.isAddingList = false }
        } icon: {
            ListIcon(color: .gray)
        }
    }

    private func commit() {
        guard window.isAddingList else { return }
        window.isAddingList = false
        if let id = store.createList(title: title) {
            window.selection = .list(id)
        }
    }
}

struct ListIcon: View {
    let color: Color

    var body: some View {
        Image(systemName: "list.bullet.circle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, color)
            .imageScale(.large)
    }
}
