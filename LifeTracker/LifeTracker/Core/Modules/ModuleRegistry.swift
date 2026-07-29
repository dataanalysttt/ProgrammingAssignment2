import Foundation

/// The list of every module in the app. To add a new module:
/// 1. Add a case to ModuleID.
/// 2. Add a descriptor for it below.
/// 3. Create `Modules/<YourModule>/` with its SwiftUI views.
/// 4. Add an `if ModuleSettingsStore.shared.isEnabled(.yourModule)` check
///    wherever it should appear (Today, Insights, a new tab, etc.).
/// Nothing else in the app needs to know your module exists ahead of time.
enum ModuleRegistry {
    static let all: [ModuleDescriptor] = [
        ModuleDescriptor(
            id: .goals,
            name: "Goals",
            summary: "Track progress toward things you're working on.",
            systemImage: "target",
            defaultEnabled: true
        ),
        ModuleDescriptor(
            id: .insights,
            name: "Insights",
            summary: "Charts, trends, and correlations across your data.",
            systemImage: "chart.xyaxis.line",
            defaultEnabled: true
        ),
        ModuleDescriptor(
            id: .customTrackers,
            name: "Custom Trackers",
            summary: "Your own metrics: mood, habits, anything you define.",
            systemImage: "slider.horizontal.3",
            defaultEnabled: true
        ),
        ModuleDescriptor(
            id: .calendar,
            name: "Calendar",
            summary: "Today's and this week's events from your iOS calendar.",
            systemImage: "calendar",
            defaultEnabled: true
        ),
        ModuleDescriptor(
            id: .health,
            name: "Health & Fitness",
            summary: "Steps, workouts, sleep, and heart data from Apple Health (including Whoop).",
            systemImage: "heart.text.square",
            defaultEnabled: true
        ),
        ModuleDescriptor(
            id: .food,
            name: "Food Intake",
            summary: "Quick meal logging, plus nutrition data from Health.",
            systemImage: "fork.knife",
            defaultEnabled: true
        ),
        ModuleDescriptor(
            id: .investments,
            name: "Investments",
            summary: "Zerodha Kite Connect holdings, positions, and funds. Off by default.",
            systemImage: "indianrupeesign.circle",
            defaultEnabled: false
        )
    ]

    static func descriptor(for id: ModuleID) -> ModuleDescriptor {
        all.first { $0.id == id }!
    }
}
