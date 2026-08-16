import SwiftUI

/// Today's glance at the metrics that actually come from your wearable (via
/// HealthKit — this is also where anything Whoop writes into Health shows up),
/// standing in for a manual mood/energy check-in with real physiological signal.
struct TodayHealthSection: View {
    @ObservedObject private var health = HealthKitManager.shared
    @State private var steps: Double = 0
    @State private var sleepHours: Double = 0
    @State private var hrv: Double = 0
    @State private var restingHeartRate: Double = 0

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Card {
            SectionHeader(title: "Health Today")
            if !health.isAuthorized {
                Button("Allow Health Access") {
                    Task {
                        try? await health.requestAuthorization()
                        await refresh()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.md) {
                    metric(value: steps, label: "Steps", format: "%.0f")
                    metric(value: sleepHours, label: "hr Sleep", format: "%.1f")
                    metric(value: hrv, label: "ms HRV", format: "%.0f")
                    metric(value: restingHeartRate, label: "bpm Resting HR", format: "%.0f")
                }
            }
        }
        .task {
            if health.isAuthorized { await refresh() }
        }
    }

    private func metric(value: Double, label: String, format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: format, value))
                .font(Theme.Typography.title)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.ColorToken.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func refresh() async {
        async let stepsValue = health.todayTotal(for: .steps)
        async let sleepValue = health.todayTotal(for: .sleepHours)
        async let hrvValue = health.todayTotal(for: .heartRateVariability)
        async let restingValue = health.todayTotal(for: .restingHeartRate)
        steps = await stepsValue
        sleepHours = await sleepValue
        hrv = await hrvValue
        restingHeartRate = await restingValue
    }
}
