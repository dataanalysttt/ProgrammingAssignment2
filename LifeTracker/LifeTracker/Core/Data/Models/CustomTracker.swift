import Foundation
import SwiftData

/// The definition of a trackable metric: either one you created yourself in
/// Settings > Custom Trackers, or one of the small set of "seeded" trackers
/// (Mood, Energy) that the Today module creates on first launch so the app
/// isn't empty. Both are the exact same model — there is no special-casing
/// for built-ins beyond `isSystemSeeded`, which only affects whether the
/// delete button is offered.
///
/// Actual logged values live in `TrackerEntry`, one row per day (or week).
@Model
final class CustomTracker {
    @Attribute(.unique) var id: UUID
    var name: String
    var unit: String?
    var valueTypeRaw: String
    var cadenceRaw: String
    /// Optional per-entry target, e.g. "8" for a "Glasses of water" number tracker.
    var goalTarget: Double?
    var sortOrder: Int
    var isArchived: Bool
    var isSystemSeeded: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        unit: String? = nil,
        valueType: TrackerValueType,
        cadence: TrackerCadence = .daily,
        goalTarget: Double? = nil,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        isSystemSeeded: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.valueTypeRaw = valueType.rawValue
        self.cadenceRaw = cadence.rawValue
        self.goalTarget = goalTarget
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.isSystemSeeded = isSystemSeeded
        self.createdAt = createdAt
    }

    var valueType: TrackerValueType {
        get { TrackerValueType(rawValue: valueTypeRaw) ?? .number }
        set { valueTypeRaw = newValue.rawValue }
    }

    var cadence: TrackerCadence {
        get { TrackerCadence(rawValue: cadenceRaw) ?? .daily }
        set { cadenceRaw = newValue.rawValue }
    }
}
