import SwiftUI

struct MainWindow: View {
    @Environment(GoogleAuth.self) private var auth
    @Environment(TaskStore.self) private var store
    @Environment(WindowModel.self) private var window
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Group {
            if auth.isSignedIn {
                content
            } else {
                SignInView(size: .window)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 720, minHeight: 440)
        .onAppear {
            DockPolicy.mainWindowDidOpen()
            Task { await store.refreshIfStale() }
        }
        .onDisappear(perform: DockPolicy.mainWindowDidClose)
    }

    private var content: some View {
        @Bindable var window = window
        return NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 340)
        } detail: {
            HStack(spacing: 0) {
                detail
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if !store.isOnline {
                            VStack(spacing: 0) {
                                OfflineBanner()
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 6)
                                Divider()
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if let notice = store.notice {
                            NoticeBanner(notice: notice)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                        }
                    }
                    .frame(minWidth: 320)
                InspectorPanel(isShown: window.showInspector)
            }
            .clipped()
            .toolbar { toolbar }
        }
        .searchable(text: $window.searchText, placement: .toolbar, prompt: "Search")
        .searchFocused($isSearchFocused)
        .navigationTitle(window.title(in: store))
        .toolbar(removing: .title)
        .onChange(of: window.searchFocusRequest) { isSearchFocused = true }
        .onChange(of: store.hasLoaded, initial: true) { window.ensureSelection(in: store) }
        .confirmationDialog(
            "Delete “\(window.taskPendingDeletion?.title ?? "")”?",
            isPresented: Binding(get: { window.taskPendingDeletion != nil }, set: { if !$0 { window.taskPendingDeletion = nil } }),
            titleVisibility: .visible,
            presenting: window.taskPendingDeletion
        ) { task in
            Button("Delete", role: .destructive) {
                if window.selectedTaskID == task.id { window.selectedTaskID = nil }
                withAnimation(.snappy) { store.deleteTask(task.id) }
            }
        } message: { _ in
            Text("This deletes it everywhere you use Google Tasks.")
        }
        .confirmationDialog(
            "Delete “\(window.listPendingDeletion?.title ?? "")”?",
            isPresented: Binding(get: { window.listPendingDeletion != nil }, set: { if !$0 { window.listPendingDeletion = nil } }),
            titleVisibility: .visible,
            presenting: window.listPendingDeletion
        ) { list in
            Button("Delete List", role: .destructive) {
                if window.selection == .list(list.id) { window.selection = store.defaultListID.map { .list($0) } }
                withAnimation(.snappy) { store.deleteList(list.id) }
            }
        } message: { _ in
            Text("This deletes the list and all of its tasks everywhere you use Google Tasks.")
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let scope = window.scope {
            TaskListView(scope: scope)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarSpacer(.flexible, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
            Menu {
                if let item = window.selection {
                    Picker("Sort By", selection: Binding(
                        get: { window.sortMode(item) },
                        set: { window.setSortMode($0, for: item) }
                    )) {
                        ForEach(window.sortOptions(item), id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                }
            } label: {
                Label("Sort By", systemImage: "arrow.up.arrow.down")
            }
            .menuIndicator(.hidden)
            .help("Sort By")
            .disabled(window.isSearching || window.selection == nil)
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
            Button {
                window.newTask(in: store)
            } label: {
                Label("New Task", systemImage: "plus")
            }
            .help("New Task")
            .disabled(!store.canEdit)
        }
        ToolbarSpacer(.fixed, placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
            Button {
                window.toggleInspector()
            } label: {
                Label(window.showInspector ? "Hide Inspector" : "Show Inspector", systemImage: "info.circle")
            }
            .help(window.showInspector ? "Hide Inspector" : "Show Inspector")
        }
    }
}
