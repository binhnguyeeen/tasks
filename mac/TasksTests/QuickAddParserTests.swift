import Foundation
import Testing
@testable import Tasks

struct QuickAddParserTests {
    @Test func findsAWeekdayAndStripsIt() throws {
        let parse = QuickAddParser.parse("pay rent friday")
        #expect(parse.title == "pay rent")
        let due = try #require(parse.due)
        let weekday = Calendar.current.component(.weekday, from: due.date())
        #expect(weekday == 6)
        let ahead = due.days(since: .today())
        #expect((0...7).contains(ahead))
        #expect(parse.dateRange == NSRange(location: 9, length: 6))
    }

    @Test func findsTomorrow() {
        let parse = QuickAddParser.parse("call mom tomorrow")
        #expect(parse.title == "call mom")
        #expect(parse.due == Day.today().adding(days: 1))
    }

    @Test func dropsAJoiningWordBeforeTheDate() {
        let parse = QuickAddParser.parse("book car service on friday")
        #expect(parse.title == "book car service")
        #expect(parse.due != nil)
    }

    @Test func leavesPlainTitlesAlone() {
        let parse = QuickAddParser.parse("  buy printer ink ")
        #expect(parse == QuickAddParse(title: "buy printer ink"))
    }

    @Test func keepsTheTextWhenTheDateIsAllThereIs() {
        let parse = QuickAddParser.parse("tomorrow")
        #expect(parse.title == "tomorrow")
        #expect(parse.due == nil)
    }
}
