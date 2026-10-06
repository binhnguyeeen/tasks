import Foundation

nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    static let folder = "Library/Application Support/com.binhnguyen.tasks.widget"
    static let dueKind = "Due"
    static let openKind = "Open"
    static let fileName = "widget.json"

    struct Item: Codable, Equatable, Identifiable, Sendable {
        var id: String
        var title: String
        var listTitle: String
        var color: String
        var due: String
    }

    var isSignedIn: Bool
    var showsLists: Bool
    var items: [Item]
    var open: [Item]
    var openCount: Int

    static var fileURL: URL? {
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { return nil }
        return URL(filePath: String(cString: home), directoryHint: .isDirectory)
            .appending(path: folder, directoryHint: .isDirectory)
            .appending(path: fileName)
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() throws {
        guard let url = Self.fileURL else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }

    func due(on today: Day) -> (overdue: [Item], today: [Item]) {
        let dated = items.compactMap { item in Day(googleDue: item.due).map { (item, $0) } }
        return (
            dated.filter { $0.1 < today }.map(\.0),
            dated.filter { $0.1 == today }.map(\.0)
        )
    }
}
