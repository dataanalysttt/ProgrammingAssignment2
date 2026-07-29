import Foundation
import SwiftData

/// A manually-logged meal. HealthKit nutrition/water samples (written by other
/// apps you use) are read live via HealthKitManager rather than duplicated here.
@Model
final class FoodEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealName: String
    var calories: Double?
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?
    var note: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mealName: String,
        calories: Double? = nil,
        proteinGrams: Double? = nil,
        carbsGrams: Double? = nil,
        fatGrams: Double? = nil,
        note: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.mealName = mealName
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.note = note
        self.createdAt = createdAt
    }
}
