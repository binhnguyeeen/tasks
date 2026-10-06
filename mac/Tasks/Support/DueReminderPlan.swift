import Foundation

nonisolated struct DueReminder: Hashable, Sendable {
    var taskID: String
    var title: String
    var listTitle: String
    var day: Day
    var fireDate: Date

    var identifier: String { "due-" + taskID }

    var body: String {
        listTitle.isEmpty ? "Due today" : "Due today in \(listTitle)"
    }
}

nonisolated enum DueReminderPlan {
    static let limit = 60
    static let defaultMinutes = 9 * 60

    static func reminders(
        for tasks: [TaskItem],
        listTitles: [String: String],
        minutes: Int,
        now: Date,
        calendar: Calendar = .current
    ) -> [DueReminder] {
        let planned = tasks.compactMap { task -> DueReminder? in
            guard !task.isDone, !task.isPending, let due = task.due,
                  let fireDate = fireDate(on: due, minutes: minutes, calendar: calendar), fireDate > now
            else { return nil }
            let title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return DueReminder(
                taskID: task.id,
                title: title.isEmpty ? "Untitled Task" : title,
                listTitle: listTitles[task.listID] ?? "",
                day: due,
                fireDate: fireDate
            )
        }
        let sorted = planned.sorted { a, b in
            if a.fireDate != b.fireDate { return a.fireDate < b.fireDate }
            if a.title != b.title { return a.title.localizedStandardCompare(b.title) == .orderedAscending }
            return a.taskID < b.taskID
        }
        return Array(sorted.prefix(limit))
    }

    static func fireDate(on day: Day, minutes: Int, calendar: Calendar = .current) -> Date? {
        let clamped = min(max(minutes, 0), 24 * 60 - 1)
        return calendar.date(from: DateComponents(
            year: day.year, month: day.month, day: day.day, hour: clamped / 60, minute: clamped % 60
        ))
    }
}
