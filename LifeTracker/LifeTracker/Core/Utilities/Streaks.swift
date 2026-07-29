import Foundation

enum Streaks {
    /// Counts consecutive daily entries ending today or yesterday (yesterday
    /// still counts so the streak doesn't visually die the moment midnight
    /// passes before you've logged today). `entryDates` need not be sorted or
    /// deduplicated.
    static func currentStreak(entryDates: [Date], calendar: Calendar = .current) -> Int {
        let days = Set(entryDates.map { calendar.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: .now)
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            guard days.contains(cursor) else { return 0 }
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
