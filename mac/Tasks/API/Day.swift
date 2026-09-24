import Foundation

nonisolated struct Day: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(calendar: Self.utc, year: year, month: month, day: day)
        guard components.isValidDate(in: Self.utc) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    init?(googleDue: String) {
        let parts = googleDue.prefix(10).split(separator: "-")
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year ?? 2000
        month = parts.month ?? 1
        day = parts.day ?? 1
    }

    static func today(calendar: Calendar = .current) -> Day {
        Day(.now, calendar: calendar)
    }

    var googleDue: String {
        String(format: "%04d-%02d-%02dT00:00:00.000Z", year, month, day)
    }

    func date(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    func adding(days: Int) -> Day {
        let moved = Self.utc.date(byAdding: .day, value: days, to: date(in: Self.utc)) ?? date(in: Self.utc)
        return Day(moved, calendar: Self.utc)
    }

    func days(since other: Day) -> Int {
        Self.utc.dateComponents([.day], from: other.date(in: Self.utc), to: date(in: Self.utc)).day ?? 0
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
}
