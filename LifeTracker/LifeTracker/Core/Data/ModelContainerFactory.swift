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
            let container = try ModelContainer(for: schema, configurations: [configuration])
            seedDefaultTrackersIfNeeded(in: container)
            return container
        } catch {
            fatalError("Failed to create on-device SwiftData store: \(error)")
        }
    }

    /// Creates Mood and Energy as ordinary CustomTracker rows the first time the
    /// app launches, so Today isn't empty and there's a worked example to copy
    /// when you build your own tracker. Marked isSystemSeeded so Settings hides
    /// the delete affordance by default, but you're free to archive or edit them.
    private static func seedDefaultTrackersIfNeeded(in container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<CustomTracker>()
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else { return }

        let mood = CustomTracker(
            name: "Mood",
            valueType: .scale,
            cadence: .daily,
            sortOrder: 0,
            isSystemSeeded: true
        )
        let energy = CustomTracker(
            name: "Energy",
            valueType: .scale,
            cadence: .daily,
            sortOrder: 1,
            isSystemSeeded: true
        )
        context.insert(mood)
        context.insert(energy)
        try? context.save()
    }
}
