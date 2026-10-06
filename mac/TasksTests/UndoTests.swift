import Foundation
import Testing
@testable import Tasks

@MainActor
struct UndoTests {
    private let store: TaskStore
    private let undo = UndoManager()

    init() {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        undo.groupsByEvent = false
        store.undoManager = undo
    }

    private func step(_ action: () -> Void) {
        undo.beginUndoGrouping()
        action()
        undo.endUndoGrouping()
    }

    private func order() -> [String] {
        let rows = store.query.sections(for: .list("sample-my-tasks"), showCompleted: false, sort: .manual, collapsed: []).first?.rows ?? []
        return rows.map { store.task($0.id)?.title ?? "" }
    }

    @Test func undoingADeleteBringsBackTheTaskAndItsSubtasksInPlace() throws {
        let before = order()
        step { store.deleteTask("sample-plan-trip") }
        #expect(undo.undoActionName == "Delete Task")
        #expect(!order().contains("Plan trip"))

        undo.undo()
        #expect(order() == before)
        let trip = try #require(store.tasks.first { $0.title == "Plan trip" })
        let children = store.tasks.filter { $0.parentID == trip.id }.map(\.title).sorted()
        #expect(children == ["Book flights", "Book hotel"])
        #expect(store.tasks.first { $0.title == "Book flights" }?.due == store.today.adding(days: 1))

        undo.redo()
        #expect(!order().contains("Plan trip"))
        #expect(!order().contains("Book hotel"))

        undo.undo()
        #expect(order() == before)
    }

    @Test func undoingATickReopensTheTaskAndTheSubtasksItTicked() {
        step { store.setDone("sample-plan-trip", true) }
        #expect(undo.undoActionName == "Mark as Done")
        #expect(store.task("sample-book-hotel")?.isDone == true)

        undo.undo()
        #expect(store.task("sample-plan-trip")?.isDone == false)
        #expect(store.task("sample-book-flights")?.isDone == false)
        #expect(store.task("sample-book-hotel")?.isDone == false)

        undo.redo()
        #expect(store.task("sample-plan-trip")?.isDone == true)
        #expect(store.task("sample-book-hotel")?.isDone == true)
    }

    @Test func undoingAMovePutsASubtaskBackUnderItsParent() {
        step { store.moveTask("sample-book-hotel", to: "sample-home") }
        #expect(store.task("sample-book-hotel")?.parentID == nil)

        undo.undo()
        #expect(store.task("sample-book-hotel")?.listID == "sample-my-tasks")
        #expect(store.task("sample-book-hotel")?.parentID == "sample-plan-trip")
        #expect(order() == ["Pay rent", "Plan trip", "Book flights", "Book hotel", "Buy printer ink", "Return library books"])

        undo.redo()
        #expect(store.task("sample-book-hotel")?.listID == "sample-home")
    }

    @Test func undoingAReorderRestoresTheOrder() {
        let before = order()
        step { store.reorderTask("sample-buy-printer-ink", after: nil) }
        #expect(order().first == "Buy printer ink")
        undo.undo()
        #expect(order() == before)
    }

    @Test func undoingAnEditRestoresEveryField() {
        step { store.updateTask("sample-pay-rent", title: "Pay the rent", notes: "", due: .some(nil)) }
        #expect(undo.undoActionName == "Edit Task")
        undo.undo()
        let rent = store.task("sample-pay-rent")
        #expect(rent?.title == "Pay rent")
        #expect(rent?.notes == "Transfer before noon")
        #expect(rent?.due == store.today.adding(days: -1))
    }

    @Test func undoingAnAddRemovesTheTask() throws {
        var id: String?
        step { id = store.addTask(title: "Water plants", listID: "sample-my-tasks") }
        #expect(store.task(try #require(id)) != nil)
        undo.undo()
        #expect(store.tasks.first { $0.title == "Water plants" } == nil)
        undo.redo()
        #expect(store.tasks.first { $0.title == "Water plants" } != nil)
    }

    @Test func olderStepsFollowATaskThatWasRecreated() {
        step { store.updateTask("sample-pay-rent", title: "Pay the rent") }
        step { store.deleteTask("sample-pay-rent") }
        undo.undo()
        undo.undo()
        #expect(store.tasks.first { $0.title == "Pay rent" } != nil)
        #expect(store.tasks.first { $0.title == "Pay the rent" } == nil)
    }

    @Test func renamingAListCanBeUndone() {
        step { store.renameList("sample-work", to: "Office") }
        undo.undo()
        #expect(store.listTitle("sample-work") == "Work")
    }
}
