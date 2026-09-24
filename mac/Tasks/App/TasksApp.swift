import SwiftUI

@main
struct TasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var auth: GoogleAuth
    @State private var store: TaskStore
    @State private var window: WindowModel

    init() {
        let auth = GoogleAuth()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        let window = WindowModel()
        store.onIDChange = { [weak window] old, new in window?.idChanged(from: old, to: new) }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "sampleData") || !auth.isConfigured {
            auth.useSampleAccount()
            store.loadSampleData()
        }
        #endif
        _auth = State(initialValue: auth)
        _store = State(initialValue: store)
        _window = State(initialValue: window)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(auth)
                .environment(store)
                .environment(window)
        } label: {
            MenuBarLabel(count: store.menuBarCount)
        }
        .menuBarExtraStyle(.window)

        Window("Tasks", id: WindowModel.mainWindowID) {
            MainWindow()
                .environment(auth)
                .environment(store)
                .environment(window)
        }
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentMinSize)
        .commands {
            TasksCommands(store: store, window: window)
        }

        Settings {
            SettingsView()
                .environment(auth)
                .environment(store)
        }
        .windowResizability(.contentSize)
    }
}
