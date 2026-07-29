import Foundation
import SwiftData

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var goalDescription: String?
    var categoryRaw: String
    var targetDate: Date?
    var statusRaw: String
    var createdAt: Date
    var completedAt: Date?

    /// What drives the progress bar. `.none` means the goal is a manual
    /// checkoff/percentage rather than something auto-computed from data.
    var metricReference: MetricReference
    /// The value that counts as "100% done" for the linked metric, e.g. 100 (km).
    var targetValue: Double?
    var aggregationRaw: String
    /// Used only when metricReference is .none.
    var manualProgressPercent: Double?
    /// Identifier of a calendar event created from this goal's target date, if any.
    var linkedCalendarEventIdentifier: String?

    init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String? = nil,
        category: GoalCategory = .personal,
        targetDate: Date? = nil,
        status: GoalStatus = .active,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        metricReference: MetricReference = .none,
        targetValue: Double? = nil,
        aggregation: GoalAggregation = .sum,
        manualProgressPercent: Double? = nil,
        linkedCalendarEventIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.categoryRaw = category.rawValue
        self.targetDate = targetDate
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.metricReference = metricReference
        self.targetValue = targetValue
        self.aggregationRaw = aggregation.rawValue
        self.manualProgressPercent = manualProgressPercent
        self.linkedCalendarEventIdentifier = linkedCalendarEventIdentifier
    }

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var aggregation: GoalAggregation {
        get { GoalAggregation(rawValue: aggregationRaw) ?? .sum }
        set { aggregationRaw = newValue.rawValue }
    }
}
