import Foundation
import SwiftData

/// The definition of a trackable metric you create yourself from Settings >
/// Custom Trackers. `isSystemSeeded` exists for any tracker the app itself
/// might create in the future (none currently ship by default) — it just
/// hides the delete affordance so a built-in can be archived but not deleted.
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
