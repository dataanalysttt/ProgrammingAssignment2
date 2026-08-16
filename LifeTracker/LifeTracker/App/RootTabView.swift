import SwiftUI

/// The tab shell described in the design brief: Today, Goals, Insights,
/// Assistant, Settings. Goals, Insights, and Assistant are themselves
/// toggleable modules — if you switch one off, its tab disappears; Today and
/// Settings are always present since they're the daily hub and the place to
/// turn things back on.
struct RootTabView: View {
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "sun.max.fill") }

            if moduleSettings.isEnabled(.goals) {
                NavigationStack {
                    GoalsListView()
                }
                .tabItem { Label("Goals", systemImage: "target") }
            }

            if moduleSettings.isEnabled(.insights) {
                NavigationStack {
                    InsightsView()
                }
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
            }

            if moduleSettings.isEnabled(.assistant) {
                NavigationStack {
                    AssistantChatView()
                }
                .tabItem { Label("Assistant", systemImage: "bubble.left.and.bubble.right.fill") }
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
