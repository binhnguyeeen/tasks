import SwiftUI

struct TasksCommands: Commands {
    let store: TaskStore
    let window: WindowModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Task") { window.newTask(in: store) }
                .keyboardShortcut("n")
                .disabled(!store.canEdit)
            Button("New List") { window.newList() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(!store.canEdit)
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Delete…") {
                if let id = window.selectedTaskID { window.taskPendingDeletion = store.task(id) }
            }
            .keyboardShortcut(.delete)
            .disabled(!store.canEdit || window.selectedTaskID == nil)
        }

        CommandGroup(after: .textEditing) {
            Button("Find") { window.searchFocusRequest += 1 }
                .keyboardShortcut("f")
        }

        CommandGroup(before: .sidebar) {
            if let item = window.selection {
                if window.canChooseSort(item) {
                    Picker("Sort By", selection: Binding(
                        get: { window.sortMode(item) },
                        set: { window.setSortMode($0, for: item) }
                    )) {
                        Text("My Order").tag(SortMode.manual)
                        Text("Date").tag(SortMode.date)
                    }
                }
                if item != .smart(.completed) {
                    Button(window.showsCompleted(item) ? "Hide Completed" : "Show Completed") {
                        window.toggleCompleted(item)
                    }
                }
                Divider()
            }
            Button("Refresh") { Task { await store.refresh() } }
                .keyboardShortcut("r")
            Button(window.showInspector ? "Hide Inspector" : "Show Inspector") { window.toggleInspector() }
                .keyboardShortcut("i")
            Divider()
        }

        SidebarCommands()
    }
}
