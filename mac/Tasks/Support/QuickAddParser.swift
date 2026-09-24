import Foundation

nonisolated struct QuickAddParse: Equatable, Sendable {
    var title: String
    var due: Day?
    var dateRange: NSRange?
}

nonisolated enum QuickAddParser {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    private static let joiningWords: Set<String> = ["on", "by", "due", "for", "at"]

    static func parse(_ text: String, calendar: Calendar = .current) -> QuickAddParse {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let whole = NSRange(text.startIndex..., in: text)
        guard let match = detector?.firstMatch(in: text, options: [], range: whole),
              let date = match.date,
              let range = Range(match.range, in: text)
        else { return QuickAddParse(title: trimmed) }

        var before = String(text[..<range.lowerBound])
        let after = String(text[range.upperBound...])
        if let last = before.split(separator: " ").last, joiningWords.contains(last.lowercased()) {
            let trailing = before.reversed().prefix { $0 == " " }.count
            before = String(before.dropLast(trailing + last.count))
        }
        let title = (before + " " + after)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        guard !title.isEmpty else { return QuickAddParse(title: trimmed) }
        return QuickAddParse(title: title, due: Day(date, calendar: calendar), dateRange: match.range)
    }
}
