import SwiftUI
import SwiftData

struct InsightsView: View {
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore
    @Query(filter: #Predicate<CustomTracker> { $0.isArchived == false }, sort: \CustomTracker.sortOrder)
    private var trackers: [CustomTracker]

    private let featuredHealthMetrics: [HealthMetricKind] = [.steps, .sleepHours, .activeEnergy]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if moduleSettings.isEnabled(.goals) {
                    GoalsSummaryCard()
                }

                if trackers.isEmpty && !moduleSettings.isEnabled(.health) {
                    EmptyStateView(
                        systemImage: "chart.xyaxis.line",
                        title: "Nothing to show yet",
                        message: "Once you've logged a few days of data, trends and correlations will appear here."
                    )
                    .padding(.top, Theme.Spacing.xl)
                } else {
                    ForEach(trackers) { tracker in
                        MetricTrendChartView(source: .tracker(tracker))
                    }

                    if moduleSettings.isEnabled(.health) {
                        ForEach(featuredHealthMetrics) { kind in
                            MetricTrendChartView(source: .health(kind))
                        }
                    }

                    CorrelationCard()
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Insights")
    }
}
