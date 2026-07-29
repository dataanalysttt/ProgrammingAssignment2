import Foundation
import SwiftData

/// One logged value for one CustomTracker on one day. Only the field matching
/// the tracker's `valueType` is expected to be populated, but nothing enforces
/// that at the model layer — the UI (TrackerQuickEntryRow) is what keeps them
/// in sync, which keeps this type simple and query-friendly.
@Model
final class TrackerEntry {
    @Attribute(.unique) var id: UUID
    /// Matches CustomTracker.id. Not a SwiftData relationship on purpose: entries
    /// should survive and remain inspectable even if a tracker definition is deleted.
    var trackerID: UUID
    /// Normalized to the start of the day (or week) this entry belongs to.
    var date: Date
    var numberValue: Double?
    var boolValue: Bool?
    var scaleValue: Int?
    var durationSeconds: Double?
    var textValue: String?
    var note: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        trackerID: UUID,
        date: Date,
        numberValue: Double? = nil,
        boolValue: Bool? = nil,
        scaleValue: Int? = nil,
        durationSeconds: Double? = nil,
        textValue: String? = nil,
        note: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.trackerID = trackerID
        self.date = date
        self.numberValue = numberValue
        self.boolValue = boolValue
        self.scaleValue = scaleValue
        self.durationSeconds = durationSeconds
        self.textValue = textValue
        self.note = note
        self.createdAt = createdAt
    }

    /// A single display/analytics value regardless of the tracker's type, using
    /// the convention 1 = yes / 0 = no for yes-no trackers and minutes for duration.
    var numericRepresentation: Double? {
        if let numberValue { return numberValue }
        if let boolValue { return boolValue ? 1 : 0 }
        if let scaleValue { return Double(scaleValue) }
        if let durationSeconds { return durationSeconds / 60 }
        return nil
    }
}
