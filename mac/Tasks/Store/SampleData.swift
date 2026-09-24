#if DEBUG
import Foundation

struct SampleData {
    let lists = [
        TaskList(id: "sample-my-tasks", title: "My Tasks"),
        TaskList(id: "sample-work", title: "Work"),
        TaskList(id: "sample-home", title: "Home"),
        TaskList(id: "sample-groceries", title: "Groceries"),
        TaskList(id: "sample-reading", title: "Reading"),
    ]
    let tasks: [TaskItem]

    init(today: Day) {
        func task(
            _ title: String, _ list: String, due: Int? = nil, notes: String = "",
            done: Bool = false, parent: String? = nil, position: Int
        ) -> TaskItem {
            TaskItem(
                id: "sample-" + title.lowercased().replacingOccurrences(of: " ", with: "-"),
                listID: "sample-" + list,
                title: title,
                notes: notes,
                due: due.map { today.adding(days: $0) },
                isDone: done,
                completedAt: done ? Date.now.addingTimeInterval(TimeInterval(-3600 * position)) : nil,
                parentID: parent.map { "sample-" + $0 },
                position: String(format: "%020d", position)
            )
        }
        tasks = [
            task("Pay rent", "my-tasks", due: -1, notes: "Transfer before noon", position: 0),
            task("Plan trip", "my-tasks", position: 1),
            task("Book flights", "my-tasks", due: 1, parent: "plan-trip", position: 0),
            task("Book hotel", "my-tasks", parent: "plan-trip", position: 1),
            task("Buy printer ink", "my-tasks", position: 2),
            task("Return library books", "my-tasks", due: 4, position: 3),
            task("Back up photos", "my-tasks", done: true, position: 4),
            task("Renew car insurance", "my-tasks", done: true, position: 5),
            task("Renew passport", "work", due: -7, position: 0),
            task("Send September invoice", "work", due: 0, position: 1),
            task("Prepare slides for review", "work", due: 2, position: 2),
            task("File expenses", "work", done: true, position: 3),
            task("Call mom", "home", due: 0, position: 0),
            task("Fix the tap", "home", done: true, position: 1),
            task("Oat milk", "groceries", position: 0),
            task("Coffee beans", "groceries", due: 12, position: 1),
        ]
    }
}
#endif
