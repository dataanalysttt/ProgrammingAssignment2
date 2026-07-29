import SwiftUI

struct TodayHealthSection: View {
    @ObservedObject private var health = HealthKitManager.shared
    @State private var steps: Double = 0
    @State private var activeEnergy: Double = 0

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
                HStack(spacing: Theme.Spacing.lg) {
                    metric(value: steps, label: "Steps", format: "%.0f")
                    metric(value: activeEnergy, label: "kcal Active", format: "%.0f")
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
    }

    private func refresh() async {
        async let stepsValue = health.todayTotal(for: .steps)
        async let energyValue = health.todayTotal(for: .activeEnergy)
        steps = await stepsValue
        activeEnergy = await energyValue
    }
}
