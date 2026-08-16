import SwiftUI
import HealthKit

/// Today's glance at what Whoop itself has written into Health — deliberately
/// scoped to Whoop's own source rather than any device writing to Health, so
/// these numbers can't quietly end up being an Apple Watch's or the iPhone's
/// own sensor instead. Whoop doesn't track steps, so this shows the things it
/// actually measures: sleep, HRV, resting heart rate, respiratory rate.
struct TodayHealthSection: View {
    @ObservedObject private var health = HealthKitManager.shared
    @State private var whoopSource: HKSource?
    @State private var lookedUpSource = false
    @State private var sleepHours: Double = 0
    @State private var hrv: Double = 0
    @State private var restingHeartRate: Double = 0
    @State private var respiratoryRate: Double = 0

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Card {
            SectionHeader(title: "Health Today (Whoop)")
            if !health.isAuthorized {
                Button("Allow Health Access") {
                    Task {
                        try? await health.requestAuthorization()
                        await refresh()
                    }
                }
                .buttonStyle(.bordered)
            } else if lookedUpSource && whoopSource == nil {
                Text("No Whoop data found in Health yet. Open the Whoop app and turn on Apple Health sync, then check back once it's synced.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.md) {
                    metric(value: sleepHours, label: "hr Sleep", format: "%.1f")
                    metric(value: hrv, label: "ms HRV", format: "%.0f")
                    metric(value: restingHeartRate, label: "bpm Resting HR", format: "%.0f")
                    metric(value: respiratoryRate, label: "br/min Respiratory", format: "%.1f")
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
        let source = await health.resolveWhoopSource()
        whoopSource = source
        lookedUpSource = true
        guard source != nil else { return }

        async let sleepValue = health.todayTotal(for: .sleepHours, source: source)
        async let hrvValue = health.todayTotal(for: .heartRateVariability, source: source)
        async let restingValue = health.todayTotal(for: .restingHeartRate, source: source)
        async let respiratoryValue = health.todayTotal(for: .respiratoryRate, source: source)
        sleepHours = await sleepValue
        hrv = await hrvValue
        restingHeartRate = await restingValue
        respiratoryRate = await respiratoryValue
    }
}
