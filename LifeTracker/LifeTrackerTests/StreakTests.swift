import XCTest
@testable import LifeTracker

final class StreakTests: XCTestCase {
    func testEmptyEntriesHaveNoStreak() {
        XCTAssertEqual(Streaks.currentStreak(entryDates: []), 0)
    }

    func testConsecutiveDaysEndingTodayCountCorrectly() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let dates = (0..<5).map { calendar.date(byAdding: .day, value: -$0, to: today)! }
        XCTAssertEqual(Streaks.currentStreak(entryDates: dates), 5)
    }

    func testStreakStillCountsIfYesterdayWasLastEntry() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        XCTAssertEqual(Streaks.currentStreak(entryDates: [yesterday, twoDaysAgo]), 2)
    }

    func testGapBreaksStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        XCTAssertEqual(Streaks.currentStreak(entryDates: [today, threeDaysAgo]), 1)
    }
}
