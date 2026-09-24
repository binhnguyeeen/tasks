import Foundation

nonisolated struct TaskList: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var title: String
}

nonisolated struct GoogleTask: Codable, Sendable {
    enum Status: String, Codable, Sendable {
        case needsAction
        case completed
    }

    var id: String
    var title: String?
    var notes: String?
    var status: Status?
    var due: String?
    var completed: String?
    var parent: String?
    var position: String?
    var deleted: Bool?
    var hidden: Bool?
}

nonisolated struct TaskItem: Identifiable, Hashable, Sendable {
    var id: String
    var listID: String
    var title: String
    var notes: String
    var due: Day?
    var isDone: Bool
    var completedAt: Date?
    var parentID: String?
    var position: String
    var isPending = false

    init(
        id: String,
        listID: String,
        title: String,
        notes: String = "",
        due: Day? = nil,
        isDone: Bool = false,
        completedAt: Date? = nil,
        parentID: String? = nil,
        position: String = "",
        isPending: Bool = false
    ) {
        self.id = id
        self.listID = listID
        self.title = title
        self.notes = notes
        self.due = due
        self.isDone = isDone
        self.completedAt = completedAt
        self.parentID = parentID
        self.position = position
        self.isPending = isPending
    }

    init(_ task: GoogleTask, listID: String) {
        self.init(
            id: task.id,
            listID: listID,
            title: task.title ?? "",
            notes: task.notes ?? "",
            due: task.due.flatMap(Day.init(googleDue:)),
            isDone: task.status == .completed,
            completedAt: task.completed.flatMap(Self.parseTimestamp),
            parentID: task.parent,
            position: task.position ?? ""
        )
    }

    func isOverdue(today: Day) -> Bool {
        guard !isDone, let due else { return false }
        return due < today
    }

    static func parseTimestamp(_ text: String) -> Date? {
        (try? Date(text, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true)))
            ?? (try? Date(text, strategy: .iso8601))
    }
}

nonisolated struct NewTask: Encodable, Sendable {
    var title: String
    var notes: String?
    var due: String?
}

nonisolated struct TaskPatch: Encodable, Sendable {
    var title: String?
    var notes: String??
    var due: String??
    var status: GoogleTask.Status?
    var completed: String??

    var isEmpty: Bool {
        title == nil && notes == nil && due == nil && status == nil && completed == nil
    }

    enum CodingKeys: String, CodingKey {
        case title, notes, due, status, completed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let title { try container.encode(title, forKey: .title) }
        if let notes { try container.encode(notes, forKey: .notes) }
        if let due { try container.encode(due, forKey: .due) }
        if let status { try container.encode(status, forKey: .status) }
        if let completed { try container.encode(completed, forKey: .completed) }
    }
}

nonisolated struct ListTitle: Encodable, Sendable {
    var title: String
}
