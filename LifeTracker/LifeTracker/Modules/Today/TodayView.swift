import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore
    @Query(
        filter: #Predicate<CustomTracker> { $0.isArchived == false && $0.cadenceRaw == "daily" },
        sort: \CustomTracker.sortOrder
    )
    private var dailyTrackers: [CustomTracker]

    @State private var showingAddTracker = false
    @State private var showingAddFood = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                header

                if moduleSettings.isEnabled(.calendar) {
                    TodayCalendarSection()
                }

                if moduleSettings.isEnabled(.health) {
                    TodayHealthSection()
                }

                trackersCard

                if moduleSettings.isEnabled(.food) {
                    Card {
                        SectionHeader(title: "Food", actionTitle: "Log a meal") {
                            showingAddFood = true
                        }
                        Text("Quick-log a meal, or see today's nutrition from Health.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.ColorToken.secondaryText)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Today")
        .sheet(isPresented: $showingAddTracker) { CustomTrackerEditView(tracker: nil) }
        .sheet(isPresented: $showingAddFood) { FoodEntryEditView() }
    }

    private var header: some View {
        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            .font(Theme.Typography.largeTitle)
            .padding(.top, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var trackersCard: some View {
        if moduleSettings.isEnabled(.customTrackers) {
            Card {
                SectionHeader(title: "Daily Check-in", actionTitle: "New Tracker") {
                    showingAddTracker = true
                }
                if dailyTrackers.isEmpty {
                    EmptyStateView(
                        systemImage: "slider.horizontal.3",
                        title: "No daily trackers yet",
                        message: "Add a metric — mood, habit, anything — and it'll show up here every day.",
                        actionTitle: "Add a Tracker"
                    ) {
                        showingAddTracker = true
                    }
                } else {
                    ForEach(Array(dailyTrackers.enumerated()), id: \.element.id) { index, tracker in
                        if index > 0 { Divider() }
                        TrackerQuickEntryRow(tracker: tracker)
                    }
                }
            }
        }
    }
}
