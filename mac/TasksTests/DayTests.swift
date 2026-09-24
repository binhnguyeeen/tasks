import Foundation
import Testing
@testable import Tasks

struct DayTests {
    @Test func readsTheFirstTenCharactersOnly() {
        #expect(Day(googleDue: "2026-09-26T00:00:00.000Z") == Day(year: 2026, month: 9, day: 26))
    }

    @Test func writesUTCMidnight() {
        #expect(Day(year: 2026, month: 9, day: 26)?.googleDue == "2026-09-26T00:00:00.000Z")
    }

    @Test func rejectsImpossibleDates() {
        #expect(Day(googleDue: "2026-02-30T00:00:00.000Z") == nil)
        #expect(Day(googleDue: "soon") == nil)
    }

    @Test(arguments: ["America/Los_Angeles", "Pacific/Honolulu", "Asia/Tokyo", "Pacific/Kiritimati"])
    func roundTripsThroughLocalDatesInAnyTimeZone(_ identifier: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        let day = try #require(Day(googleDue: "2026-01-01T00:00:00.000Z"))
        let local = day.date(in: calendar)
        #expect(Day(local, calendar: calendar) == day)
        #expect(Day(local, calendar: calendar).googleDue == "2026-01-01T00:00:00.000Z")
    }

    @Test func addsDaysAcrossMonthAndYearEnds() throws {
        let day = try #require(Day(year: 2026, month: 12, day: 30))
        #expect(day.adding(days: 3) == Day(year: 2027, month: 1, day: 2))
        #expect(day.adding(days: 3).days(since: day) == 3)
        #expect(day.adding(days: -30) == Day(year: 2026, month: 11, day: 30))
    }
}

struct DueTextTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()
    private let locale = Locale(identifier: "en_US")
    private let today = Day(year: 2026, month: 9, day: 19)!

    private func text(_ offset: Int) -> String {
        DueText.text(for: today.adding(days: offset), today: today, calendar: calendar, locale: locale)
    }

    @Test func namesTheNearDays() {
        #expect(text(0) == "Today")
        #expect(text(1) == "Tomorrow")
        #expect(text(-1) == "Yesterday")
    }

    @Test func usesWeekdaysOnlyForTheNextSixDays() {
        #expect(text(2) == "Monday")
        #expect(text(6) == "Friday")
        #expect(text(7) == "Sep 26")
    }

    @Test func neverUsesWeekdaysForPastDates() {
        #expect(text(-2) == "Sep 17")
        #expect(text(-7) == "Sep 12")
    }

    @Test func addsTheYearWhenItDiffers() {
        #expect(DueText.text(for: Day(year: 2027, month: 1, day: 4)!, today: today, calendar: calendar, locale: locale) == "Jan 4, 2027")
    }
}
