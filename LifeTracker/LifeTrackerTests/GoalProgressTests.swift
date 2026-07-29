import XCTest
import SwiftData
@testable import LifeTracker

@MainActor
final class GoalProgressTests: XCTestCase {
    func testManualProgressGoalReturnsPercentAsFraction() async throws {
        let context = TestSupport.makeInMemoryContext()
        let goal = Goal(title: "Read more", manualProgressPercent: 40)
        context.insert(goal)

        let progress = await GoalProgressCalculator.progress(for: goal, context: context)
        XCTAssertEqual(progress, 0.4)
    }

    func testTrackerLinkedGoalSumsEntriesTowardTarget() async throws {
        let context = TestSupport.makeInMemoryContext()
        let tracker = CustomTracker(name: "Distance", valueType: .number)
        context.insert(tracker)

        let goal = Goal(
            title: "Run 100km",
            createdAt: DateUtils.daysAgo(10),
            metricReference: .tracker(tracker.id),
            targetValue: 100,
            aggregation: .sum
        )
        context.insert(goal)

        for daysAgo in [1, 3, 5] {
            let entry = TrackerEntry(trackerID: tracker.id, date: DateUtils.daysAgo(daysAgo), numberValue: 10)
            context.insert(entry)
        }
        try context.save()

        let progress = await GoalProgressCalculator.progress(for: goal, context: context)
        XCTAssertEqual(progress, 0.3, accuracy: 0.0001)
    }

    func testTrackerLinkedGoalIgnoresEntriesBeforeGoalCreation() async throws {
        let context = TestSupport.makeInMemoryContext()
        let tracker = CustomTracker(name: "Distance", valueType: .number)
        context.insert(tracker)

        let goal = Goal(
            title: "Run 100km",
            createdAt: DateUtils.daysAgo(2),
            metricReference: .tracker(tracker.id),
            targetValue: 100,
            aggregation: .sum
        )
        context.insert(goal)

        // Entry predates the goal and should not count.
        context.insert(TrackerEntry(trackerID: tracker.id, date: DateUtils.daysAgo(20), numberValue: 50))
        // Entry after goal creation counts.
        context.insert(TrackerEntry(trackerID: tracker.id, date: DateUtils.daysAgo(1), numberValue: 20))
        try context.save()

        let progress = await GoalProgressCalculator.progress(for: goal, context: context)
        XCTAssertEqual(progress, 0.2, accuracy: 0.0001)
    }
}
