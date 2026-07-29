import Foundation

enum DateUtils {
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func daysAgo(_ count: Int, from date: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -count, to: startOfDay(date, calendar: calendar)) ?? date
    }

    static func isSameDay(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    static func daysBetween(_ start: Date, _ end: Date, calendar: Calendar = .current) -> Int {
        let start = startOfDay(start, calendar: calendar)
        let end = startOfDay(end, calendar: calendar)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
