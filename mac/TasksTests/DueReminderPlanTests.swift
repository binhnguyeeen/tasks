import Foundation
import Testing
@testable import Tasks

struct DueReminderPlanTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()
    private let today = Day(year: 2026, month: 10, day: 6)!

    private func at(_ day: Day, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day, hour: hour, minute: minute))!
    }

    private func plan(_ tasks: [TaskItem], now: Date, minutes: Int = 9 * 60) -> [DueReminder] {
        DueReminderPlan.reminders(
            for: tasks, listTitles: ["mine": "My Tasks", "work": "Work"], minutes: minutes, now: now, calendar: calendar
        )
    }

    @Test func remindsAtTheChosenTimeOnTheDueDay() {
        let tasks = [TaskItem(id: "rent", listID: "mine", title: "Pay rent", due: today.adding(days: 1))]
        let reminders = plan(tasks, now: at(today, 20), minutes: 8 * 60 + 30)
        #expect(reminders.map(\.fireDate) == [at(today.adding(days: 1), 8, 30)])
        #expect(reminders.first?.body == "Due today in My Tasks")
        #expect(reminders.first?.identifier == "due-rent")
    }

    @Test func skipsDoneUndatedPendingAndPastReminders() {
        let tasks = [
            TaskItem(id: "done", listID: "mine", title: "Done", due: today.adding(days: 1), isDone: true),
            TaskItem(id: "undated", listID: "mine", title: "Undated"),
            TaskItem(id: "pending", listID: "mine", title: "Pending", due: today.adding(days: 1), isPending: true),
            TaskItem(id: "earlier", listID: "mine", title: "Earlier today", due: today),
            TaskItem(id: "overdue", listID: "mine", title: "Overdue", due: today.adding(days: -2)),
            TaskItem(id: "later", listID: "work", title: "Later today", due: today),
        ]
        #expect(plan(tasks, now: at(today, 10)).isEmpty)
        #expect(plan(tasks, now: at(today, 8)).map(\.taskID) == ["earlier", "later"])
    }

    @Test func ordersByTimeThenTitleAndStopsAtTheLimit() {
        let tasks = (0..<80).map { n in
            TaskItem(id: "t\(n)", listID: "work", title: "Task \(n)", due: today.adding(days: 1 + n % 3))
        }
        let reminders = plan(tasks, now: at(today, 12))
        #expect(reminders.count == DueReminderPlan.limit)
        #expect(reminders.map(\.fireDate) == reminders.map(\.fireDate).sorted())
        #expect(reminders.prefix(3).map(\.title) == ["Task 0", "Task 3", "Task 6"])
    }

    @Test func namesUntitledTasks() {
        let tasks = [TaskItem(id: "blank", listID: "elsewhere", title: "  ", due: today.adding(days: 1))]
        let reminder = plan(tasks, now: at(today, 12)).first
        #expect(reminder?.title == "Untitled Task")
        #expect(reminder?.body == "Due today")
    }
}
