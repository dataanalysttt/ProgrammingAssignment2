import SwiftUI

struct ModuleTogglesView: View {
    @ObservedObject private var moduleSettings = ModuleSettingsStore.shared

    var body: some View {
        List {
            Section {
                Text("Turn modules on or off. Disabling one hides it everywhere but keeps its data on your phone.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            }
            ForEach(ModuleRegistry.all) { descriptor in
                Section {
                    Toggle(isOn: Binding(
                        get: { moduleSettings.isEnabled(descriptor.id) },
                        set: { moduleSettings.setEnabled($0, for: descriptor.id) }
                    )) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(descriptor.name)
                                Text(descriptor.summary)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.ColorToken.secondaryText)
                            }
                        } icon: {
                            Image(systemName: descriptor.systemImage)
                                .foregroundStyle(Theme.ColorToken.accent)
                        }
                    }

                    if moduleSettings.isEnabled(descriptor.id) {
                        destination(for: descriptor.id)
                    }
                }
            }
        }
        .navigationTitle("Modules")
    }

    @ViewBuilder
    private func destination(for id: ModuleID) -> some View {
        switch id {
        case .customTrackers:
            NavigationLink("Manage Trackers") { CustomTrackerListView() }
        case .calendar:
            NavigationLink("View This Week") { CalendarUpcomingView() }
        case .health:
            NavigationLink("View Health Data") { HealthMetricsView() }
        case .food:
            NavigationLink("View Food Log") { FoodLogView() }
        case .investments:
            NavigationLink("View Investments") { InvestmentsView() }
        case .goals, .insights, .assistant:
            EmptyView()
        }
    }
}
