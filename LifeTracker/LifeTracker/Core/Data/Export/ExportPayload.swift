import Foundation

/// Plain-Codable mirrors of the SwiftData models, used only for JSON export/import.
/// Kept separate from the @Model types so the on-device schema can evolve without
/// having to also be a wire format, and vice versa.
struct ExportPayload: Codable {
    var exportedAt: Date
    var appVersion: String
    var trackers: [TrackerDTO]
    var entries: [TrackerEntryDTO]
    var goals: [GoalDTO]
    var foodEntries: [FoodEntryDTO]
    var investmentSnapshots: [InvestmentSnapshotDTO]

    struct TrackerDTO: Codable {
        var id: UUID
        var name: String
        var unit: String?
        var valueType: String
        var cadence: String
        var goalTarget: Double?
        var sortOrder: Int
        var isArchived: Bool
        var isSystemSeeded: Bool
        var createdAt: Date
    }

    struct TrackerEntryDTO: Codable {
        var id: UUID
        var trackerID: UUID
        var date: Date
        var numberValue: Double?
        var boolValue: Bool?
        var scaleValue: Int?
        var durationSeconds: Double?
        var textValue: String?
        var note: String?
        var createdAt: Date
    }

    struct GoalDTO: Codable {
        var id: UUID
        var title: String
        var goalDescription: String?
        var category: String
        var targetDate: Date?
        var status: String
        var createdAt: Date
        var completedAt: Date?
        var metricReference: MetricReference
        var targetValue: Double?
        var aggregation: String
        var manualProgressPercent: Double?
        var linkedCalendarEventIdentifier: String?
    }

    struct FoodEntryDTO: Codable {
        var id: UUID
        var date: Date
        var mealName: String
        var calories: Double?
        var proteinGrams: Double?
        var carbsGrams: Double?
        var fatGrams: Double?
        var note: String?
        var createdAt: Date
    }

    struct InvestmentSnapshotDTO: Codable {
        var id: UUID
        var capturedAt: Date
        var totalValue: Double
        var totalInvested: Double
        var totalPnL: Double
        var holdings: [HoldingDTO]
    }

    struct HoldingDTO: Codable {
        var id: UUID
        var symbol: String
        var quantity: Double
        var averagePrice: Double
        var lastPrice: Double
        var currentValue: Double
        var pnl: Double
    }
}
