import Foundation

nonisolated enum DueText {
    static func text(for day: Day, today: Day, calendar: Calendar = .current, locale: Locale = .current) -> String {
        switch day.days(since: today) {
        case 0: "Today"
        case 1: "Tomorrow"
        case -1: "Yesterday"
        case 2...6: day.date(in: calendar).formatted(style(calendar, locale).weekday(.wide))
        default: monthDay(day, today: today, calendar: calendar, locale: locale)
        }
    }

    static func monthDay(_ day: Day, today: Day, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let base = style(calendar, locale).month(.abbreviated).day()
        return day.date(in: calendar).formatted(day.year == today.year ? base : base.year())
    }

    static func monthTitle(_ day: Day, today: Day, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let base = style(calendar, locale).month(.wide)
        return day.date(in: calendar).formatted(day.year == today.year ? base : base.year())
    }

    static func weekday(_ day: Day, calendar: Calendar = .current, locale: Locale = .current) -> String {
        day.date(in: calendar).formatted(style(calendar, locale).weekday(.wide))
    }

    private static func style(_ calendar: Calendar, _ locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }
}
