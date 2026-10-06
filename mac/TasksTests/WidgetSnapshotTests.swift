import Foundation
import Testing
@testable import Tasks

@MainActor
struct WidgetSnapshotTests {
    private func makeStore() -> TaskStore {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        return store
    }

    @Test func openTasksListEveryUnfinishedTaskSoonestFirstUndatedLast() {
        let store = makeStore()
        let snapshot = WidgetBridge.snapshot(of: store)
        let open = snapshot.open.map(\.title)
        #expect(snapshot.openCount == store.tasks.count { !$0.isDone })
        #expect(open.prefix(5) == ["Renew passport", "Pay rent", "Send September invoice", "Call mom", "Book flights"])
        #expect(Array(open.suffix(4)) == ["Plan trip", "Book hotel", "Buy printer ink", "Oat milk"])
        #expect(!open.contains("Back up photos"))
    }

    @Test func dueTasksStopAtTomorrowAndSplitByDay() {
        let store = makeStore()
        let snapshot = WidgetBridge.snapshot(of: store)
        #expect(snapshot.items.map(\.title) == ["Renew passport", "Pay rent", "Send September invoice", "Call mom", "Book flights"])
        let due = snapshot.due(on: store.today)
        #expect(due.overdue.map(\.title) == ["Renew passport", "Pay rent"])
        #expect(due.today.map(\.title) == ["Send September invoice", "Call mom"])
    }
}
