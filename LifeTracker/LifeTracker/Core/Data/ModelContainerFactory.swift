import Foundation
import SwiftData

/// Single source of truth for the on-device SwiftData schema. Everything here
/// stays local: no CloudKit container, no remote sync configuration.
enum ModelContainerFactory {
    static let schema = Schema([
        CustomTracker.self,
        TrackerEntry.self,
        Goal.self,
        FoodEntry.self,
        InvestmentSnapshot.self,
        InvestmentHolding.self
    ])

    static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create on-device SwiftData store: \(error)")
        }
    }
}
