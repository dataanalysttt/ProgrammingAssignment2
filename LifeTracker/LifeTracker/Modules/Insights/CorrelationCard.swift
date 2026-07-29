import SwiftUI
import SwiftData

/// A simple Pearson correlation between any two of your metrics over the last
/// 30 days (e.g. Sleep vs Mood). Not a claim of causation — just a quick
/// "these seem to move together" signal, which is what actually stays
/// skimmable for a single person's own data.
struct CorrelationCard: View {
    @Query(filter: #Predicate<CustomTracker> { $0.isArchived == false }, sort: \CustomTracker.sortOrder)
    private var trackers: [CustomTracker]
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore
    @Environment(\.modelContext) private var context

    @State private var sourceA: TrendSource?
    @State private var sourceB: TrendSource?
    @State private var coefficient: Double?

    private var availableSources: [TrendSource] {
        var sources = trackers.map(TrendSource.tracker)
        if moduleSettings.isEnabled(.health) {
            sources += HealthMetricKind.allCases.map(TrendSource.health)
        }
        return sources
    }

    var body: some View {
        Card {
            SectionHeader(title: "Correlation")
            if availableSources.count < 2 {
                Text("Add a couple more trackers to see correlations.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            } else {
                HStack {
                    sourcePicker("A", selection: $sourceA)
                    Text("vs").foregroundStyle(Theme.ColorToken.secondaryText)
                    sourcePicker("B", selection: $sourceB)
                }
                if let coefficient {
                    Text(description(for: coefficient))
                        .font(Theme.Typography.body.weight(.medium))
                        .padding(.top, Theme.Spacing.xs)
                } else {
                    Text("Not enough overlapping data yet.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.ColorToken.secondaryText)
                }
            }
        }
        .onAppear {
            if sourceA == nil { sourceA = availableSources.first }
            if sourceB == nil { sourceB = availableSources.dropFirst().first }
        }
        .task(id: TaskKey(a: sourceA, b: sourceB)) {
            await computeCorrelation()
        }
    }

    private struct TaskKey: Equatable {
        let a: TrendSource?
        let b: TrendSource?
    }

    private func sourcePicker(_ label: String, selection: Binding<TrendSource?>) -> some View {
        Picker(label, selection: selection) {
            ForEach(availableSources, id: \.self) { source in
                Text(source.title).tag(Optional(source))
            }
        }
        .pickerStyle(.menu)
        .font(Theme.Typography.caption)
    }

    private func description(for r: Double) -> String {
        let strength: String
        switch abs(r) {
        case 0.7...: strength = "Strong"
        case 0.4..<0.7: strength = "Moderate"
        case 0.2..<0.4: strength = "Weak"
        default: strength = "Little to no"
        }
        let direction = r >= 0 ? "positive" : "negative"
        return "\(strength) \(direction) relationship (r = \(String(format: "%.2f", r)))"
    }

    private func computeCorrelation() async {
        guard let sourceA, let sourceB else { coefficient = nil; return }
        let seriesA = await dailyValues(for: sourceA)
        let seriesB = await dailyValues(for: sourceB)

        let commonDates = Set(seriesA.keys).intersection(seriesB.keys)
        guard commonDates.count >= 4 else { coefficient = nil; return }

        let pairs = commonDates.map { (seriesA[$0]!, seriesB[$0]!) }
        coefficient = pearson(pairs)
    }

    private func dailyValues(for source: TrendSource) async -> [Date: Double] {
        let start = DateUtils.daysAgo(30)
        switch source {
        case .tracker(let tracker):
            let trackerID = tracker.id
            let entries = (try? context.fetch(
                FetchDescriptor<TrackerEntry>(predicate: #Predicate<TrackerEntry> { $0.trackerID == trackerID })
            )) ?? []
            var result: [Date: Double] = [:]
            for entry in entries where entry.date >= start {
                if let value = entry.numericRepresentation {
                    result[DateUtils.startOfDay(entry.date)] = value
                }
            }
            return result
        case .health(let kind):
            let series = (try? await HealthKitManager.shared.dailySeries(for: kind, from: start, to: .now)) ?? []
            return Dictionary(uniqueKeysWithValues: series.map { (DateUtils.startOfDay($0.date), $0.value) })
        }
    }

    private func pearson(_ pairs: [(Double, Double)]) -> Double? {
        let n = Double(pairs.count)
        let xs = pairs.map(\.0)
        let ys = pairs.map(\.1)
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var covariance = 0.0, varianceX = 0.0, varianceY = 0.0
        for (x, y) in pairs {
            covariance += (x - meanX) * (y - meanY)
            varianceX += (x - meanX) * (x - meanX)
            varianceY += (y - meanY) * (y - meanY)
        }
        guard varianceX > 0, varianceY > 0 else { return nil }
        return covariance / (varianceX.squareRoot() * varianceY.squareRoot())
    }
}
