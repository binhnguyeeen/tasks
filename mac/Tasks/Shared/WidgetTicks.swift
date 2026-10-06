import Foundation

nonisolated struct WidgetTicks: Equatable, Sendable {
    static let hold: TimeInterval = 5

    var times: [String: Date]

    func ticked(at date: Date) -> Set<String> {
        Set(times.filter { $0.value <= date && date < $0.value.addingTimeInterval(Self.hold) }.keys)
    }

    func hidden(at date: Date) -> Set<String> {
        Set(times.filter { $0.value.addingTimeInterval(Self.hold) <= date }.keys)
    }

    func changeDates(after date: Date) -> [Date] {
        Set(times.values.map { $0.addingTimeInterval(Self.hold) }.filter { $0 > date }).sorted()
    }

    static var folderURL: URL? {
        WidgetSnapshot.folderURL?.appending(path: "ticks", directoryHint: .isDirectory)
    }

    static func load() -> WidgetTicks {
        guard let folder = folderURL,
              let files = try? FileManager.default.contentsOfDirectory(
                  at: folder, includingPropertiesForKeys: [.contentModificationDateKey]
              )
        else { return WidgetTicks(times: [:]) }
        var times: [String: Date] = [:]
        for file in files {
            guard let id = file.lastPathComponent.removingPercentEncoding,
                  let date = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            else { continue }
            times[id] = date
        }
        return WidgetTicks(times: times)
    }

    static func toggle(_ id: String) {
        guard let url = fileURL(for: id) else { return }
        let manager = FileManager.default
        if manager.fileExists(atPath: url.path(percentEncoded: false)) {
            try? manager.removeItem(at: url)
        } else {
            try? manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? Data().write(to: url, options: .atomic)
        }
    }

    static func remove(_ ids: some Sequence<String>) {
        for id in ids {
            guard let url = fileURL(for: id) else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static let fileNameCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))

    private static func fileURL(for id: String) -> URL? {
        guard let name = id.addingPercentEncoding(withAllowedCharacters: fileNameCharacters) else { return nil }
        return folderURL?.appending(path: name)
    }
}
