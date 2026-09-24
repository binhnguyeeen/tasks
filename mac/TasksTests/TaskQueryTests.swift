import Foundation
import Testing
@testable import Tasks

struct TaskQueryTests {
    private let today = Day(year: 2026, month: 9, day: 19)!
    private let lists = [TaskList(id: "mine", title: "My Tasks"), TaskList(id: "work", title: "Work")]

    private func task(
        _ id: String,
        list: String = "mine",
        due: Int? = nil,
        done: Bool = false,
        parent: String? = nil,
        position: String
    ) -> TaskItem {
        TaskItem(
            id: id, listID: list, title: id, due: due.map { today.adding(days: $0) },
            isDone: done, parentID: parent, position: position
        )
    }

    private var sample: [TaskItem] {
        [
            task("hotel", parent: "trip", position: "00000000000000000001"),
            task("trip", due: 1, position: "00000000000000000002"),
            task("rent", due: -1, position: "00000000000000000001"),
            task("flights", parent: "trip", position: "00000000000000000000"),
            task("ink", position: "00000000000000000003"),
            task("invoice", list: "work", due: 0, position: "00000000000000000000"),
            task("passport", list: "work", due: -7, position: "00000000000000000001"),
            task("old", list: "work", due: 0, done: true, position: "00000000000000000002"),
        ]
    }

    private var query: TaskQuery {
        TaskQuery(tasks: sample, lists: lists, today: today, locale: Locale(identifier: "en_US"))
    }

    @Test func nestsSubtasksUnderTheirParentInPositionOrder() {
        let rows = query.sections(for: .list("mine"), showCompleted: false, sort: .manual, collapsed: []).first?.rows ?? []
        #expect(rows.map(\.id) == ["rent", "trip", "flights", "hotel", "ink"])
        #expect(rows.map(\.depth) == [0, 0, 1, 1, 0])
        #expect(rows.first { $0.id == "trip" }?.hasChildren == true)
    }

    @Test func collapsingHidesChildren() {
        let rows = query.sections(for: .list("mine"), showCompleted: false, sort: .manual, collapsed: ["trip"]).first?.rows ?? []
        #expect(rows.map(\.id) == ["rent", "trip", "ink"])
    }

    @Test func dateSortPutsUndatedTasksLast() {
        let rows = query.sections(for: .list("mine"), showCompleted: false, sort: .date, collapsed: []).first?.rows ?? []
        #expect(rows.map(\.id) == ["rent", "trip", "flights", "hotel", "ink"])
    }

    @Test func orphanedSubtasksBecomeTopLevel() {
        let rows = query.outline([task("flights", parent: "gone", position: "1")], sort: .manual, collapsed: [])
        #expect(rows.map(\.depth) == [0])
    }

    @Test func todayGroupsOverdueThenToday() {
        let sections = query.sections(for: .smart(.today), showCompleted: false, sort: .date, collapsed: [])
        #expect(sections.map(\.title) == ["Overdue", "Today"])
        #expect(sections[0].rows.map(\.id) == ["passport", "rent"])
        #expect(sections[1].rows.map(\.id) == ["invoice"])
    }

    @Test func todayShowsCompletedOnlyWhenAsked() {
        let sections = query.sections(for: .smart(.today), showCompleted: true, sort: .date, collapsed: [])
        #expect(sections[1].rows.map(\.id) == ["invoice", "old"])
    }

    @Test func scheduledGroupsByRelativeDay() {
        let sections = query.sections(for: .smart(.scheduled), showCompleted: false, sort: .date, collapsed: [])
        #expect(sections.map(\.title) == ["Overdue", "Today", "Tomorrow"])
    }

    @Test func allGroupsByListAndSkipsCompleted() {
        let sections = query.sections(for: .smart(.all), showCompleted: false, sort: .manual, collapsed: [])
        #expect(sections.map(\.title) == ["My Tasks", "Work"])
        #expect(sections[1].rows.map(\.id) == ["invoice", "passport"])
    }

    @Test func countsMatchTheTiles() {
        #expect(query.count(for: .today) == 3)
        #expect(query.count(for: .scheduled) == 4)
        #expect(query.count(for: .all) == 7)
        #expect(query.count(for: .completed) == 1)
        #expect(query.completedCount(for: .list("work")) == 1)
    }

    @Test func lingeringTasksStayVisibleBriefly() {
        var lingering = query
        lingering.lingering = ["old"]
        let sections = lingering.sections(for: .list("work"), showCompleted: false, sort: .manual, collapsed: [])
        #expect(sections.first?.rows.map(\.id) == ["invoice", "passport", "old"])
    }

    @Test func searchFindsTasksAcrossLists() {
        let sections = query.sections(for: .search("IN"), showCompleted: false, sort: .manual, collapsed: [])
        #expect(sections.map(\.title) == ["My Tasks", "Work"])
        #expect(sections[0].rows.map(\.id) == ["ink"])
        #expect(sections[1].rows.map(\.id) == ["invoice"])
    }
}

@MainActor
struct SampleStoreTests {
    private func makeStore() -> TaskStore {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        return store
    }

    @Test func newTasksCanBeTickedStraightAway() throws {
        let store = makeStore()
        let id = try #require(store.addTask(title: "Water plants", listID: "sample-my-tasks"))
        #expect(store.task(id)?.isPending == false)
        store.setDone(id, true)
        #expect(store.task(id)?.isDone == true)
    }

    @Test func subtasksNestUnderTheirParent() throws {
        let store = makeStore()
        let id = try #require(store.addTask(title: "Pack", listID: "sample-my-tasks", parentID: "sample-plan-trip"))
        let rows = store.query.sections(for: .list("sample-my-tasks"), showCompleted: false, sort: .manual, collapsed: []).first?.rows ?? []
        let row = try #require(rows.first { $0.id == id })
        #expect(row.depth == 1)
        let parentIndex = try #require(rows.firstIndex { $0.id == "sample-plan-trip" })
        let index = try #require(rows.firstIndex { $0.id == id })
        #expect(index == parentIndex + 1)
    }

    @Test func subtasksOfNewTasksNestToo() throws {
        let store = makeStore()
        let parent = try #require(store.addTask(title: "Move house", listID: "sample-my-tasks"))
        let child = try #require(store.addTask(title: "Book van", listID: "sample-my-tasks", parentID: parent))
        let rows = store.query.sections(for: .list("sample-my-tasks"), showCompleted: false, sort: .manual, collapsed: []).first?.rows ?? []
        #expect(rows.first { $0.id == child }?.depth == 1)
    }
}

struct DateViewNestingTests {
    private let today = Day(year: 2026, month: 9, day: 19)!

    @Test func subtasksSitUnderTheirParentInToday() {
        let tasks = [
            TaskItem(id: "mom", listID: "home", title: "Call mom", due: today, position: "1"),
            TaskItem(id: "invoice", listID: "home", title: "Invoice", due: today, position: "2"),
            TaskItem(id: "flowers", listID: "home", title: "Buy flowers", due: today, parentID: "mom", position: "0"),
        ]
        let query = TaskQuery(tasks: tasks, lists: [TaskList(id: "home", title: "Home")], today: today)
        let rows = query.sections(for: .smart(.today), showCompleted: false, sort: .date, collapsed: []).first?.rows ?? []
        #expect(rows.map(\.id) == ["mom", "flowers", "invoice"])
        #expect(rows.map(\.depth) == [0, 1, 0])
        #expect(rows.first?.hasChildren == true)
    }
}

@MainActor
struct CompletionTests {
    @Test func completingAParentCompletesItsSubtasks() throws {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        store.setDone("sample-plan-trip", true)
        #expect(store.task("sample-plan-trip")?.isDone == true)
        #expect(store.task("sample-book-flights")?.isDone == true)
        #expect(store.task("sample-book-hotel")?.isDone == true)
        store.setDone("sample-plan-trip", false)
        #expect(store.task("sample-plan-trip")?.isDone == false)
        #expect(store.task("sample-book-hotel")?.isDone == true)
    }
}

@MainActor
struct MoveTests {
    @Test func movingATaskTakesItsSubtasksAlong() {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        store.moveTask("sample-plan-trip", to: "sample-work")
        #expect(store.task("sample-plan-trip")?.listID == "sample-work")
        #expect(store.task("sample-book-flights")?.listID == "sample-work")
        #expect(store.task("sample-book-flights")?.parentID == "sample-plan-trip")
    }

    @Test func movingASubtaskMakesItTopLevel() {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        store.moveTask("sample-book-hotel", to: "sample-home")
        #expect(store.task("sample-book-hotel")?.listID == "sample-home")
        #expect(store.task("sample-book-hotel")?.parentID == nil)
    }
}

struct PinnedTests {
    @Test func newTasksStayOnTopUntilSortedLater() {
        let today = Day(year: 2026, month: 9, day: 19)!
        let tasks = [
            TaskItem(id: "a", listID: "l", title: "A", due: today, position: "1"),
            TaskItem(id: "b", listID: "l", title: "B", due: today.adding(days: 3), position: "2"),
            TaskItem(id: "new", listID: "l", title: "New", due: today.adding(days: 9), position: ""),
        ]
        var query = TaskQuery(tasks: tasks, lists: [TaskList(id: "l", title: "L")], today: today)
        query.pinned = ["new"]
        let pinnedRows = query.sections(for: .list("l"), showCompleted: false, sort: .date, collapsed: []).first?.rows ?? []
        #expect(pinnedRows.map(\.id) == ["new", "a", "b"])
        query.pinned = []
        let sortedRows = query.sections(for: .list("l"), showCompleted: false, sort: .date, collapsed: []).first?.rows ?? []
        #expect(sortedRows.map(\.id) == ["a", "b", "new"])
    }
}

struct SortTests {
    private let today = Day(year: 2026, month: 9, day: 19)!
    private let lists = [TaskList(id: "mine", title: "My Tasks"), TaskList(id: "work", title: "Work")]

    private var query: TaskQuery {
        TaskQuery(
            tasks: [
                TaskItem(id: "rent", listID: "mine", title: "Rent", due: today.adding(days: -1), position: "1"),
                TaskItem(id: "ink", listID: "mine", title: "Ink", position: "2"),
                TaskItem(id: "trip", listID: "mine", title: "Trip", due: today.adding(days: 3), position: "3"),
                TaskItem(id: "passport", listID: "work", title: "Passport", due: today.adding(days: -7), position: "1"),
                TaskItem(id: "invoice", listID: "work", title: "Invoice", due: today, position: "2"),
            ],
            lists: lists,
            today: today
        )
    }

    @Test func allByDateIsOneTimelineAcrossLists() {
        let sections = query.sections(for: .smart(.all), showCompleted: false, sort: .date, collapsed: [])
        #expect(sections.count == 1)
        #expect(sections[0].title == nil)
        #expect(sections[0].rows.map(\.id) == ["passport", "rent", "invoice", "trip", "ink"])
    }

    @Test func todayByListGroupsUnderEachList() {
        let sections = query.sections(for: .smart(.today), showCompleted: false, sort: .list, collapsed: [])
        #expect(sections.map(\.title) == ["My Tasks", "Work"])
        #expect(sections[1].rows.map(\.id) == ["passport", "invoice"])
    }

    @Test func eachViewOffersItsOwnSorts() {
        #expect(SmartList.today.sortOptions == [.date, .list])
        #expect(SmartList.all.sortOptions == [.list, .date])
    }
}

struct TimelineTests {
    @Test func subtasksSitAtTheirOwnDateInTheTimeline() {
        let today = Day(year: 2026, month: 9, day: 19)!
        let query = TaskQuery(
            tasks: [
                TaskItem(id: "trip", listID: "l", title: "Trip", position: "1"),
                TaskItem(id: "flights", listID: "l", title: "Flights", due: today.adding(days: 1), parentID: "trip", position: "0"),
                TaskItem(id: "rent", listID: "l", title: "Rent", due: today, position: "2"),
            ],
            lists: [TaskList(id: "l", title: "L")],
            today: today
        )
        let rows = query.sections(for: .smart(.all), showCompleted: false, sort: .date, collapsed: []).first?.rows ?? []
        #expect(rows.map(\.id) == ["rent", "flights", "trip"])
        #expect(rows.allSatisfy { $0.depth == 0 })
    }
}

@MainActor
struct ReorderTests {
    private func makeStore() -> TaskStore {
        let auth = GoogleAuth(keychain: Keychain(service: "com.binhnguyen.tasks.tests"))
        auth.useSampleAccount()
        let store = TaskStore(auth: auth, connectivity: Connectivity())
        store.loadSampleData()
        return store
    }

    private func order(_ store: TaskStore) -> [String] {
        let rows = store.query.sections(for: .list("sample-my-tasks"), showCompleted: false, sort: .manual, collapsed: []).first?.rows ?? []
        return rows.map(\.id)
    }

    @Test func movesATaskWithItsSubtasks() {
        let store = makeStore()
        store.reorderTask("sample-plan-trip", after: "sample-return-library-books")
        #expect(order(store) == [
            "sample-pay-rent", "sample-buy-printer-ink", "sample-return-library-books",
            "sample-plan-trip", "sample-book-flights", "sample-book-hotel",
        ])
    }

    @Test func movesATaskToTheTop() {
        let store = makeStore()
        store.reorderTask("sample-buy-printer-ink", after: nil)
        #expect(order(store).first == "sample-buy-printer-ink")
    }

    @Test func reordersSubtasksWithinTheirParent() {
        let store = makeStore()
        store.reorderTask("sample-book-flights", after: "sample-book-hotel")
        #expect(order(store) == [
            "sample-pay-rent", "sample-plan-trip", "sample-book-hotel", "sample-book-flights",
            "sample-buy-printer-ink", "sample-return-library-books",
        ])
    }
}
