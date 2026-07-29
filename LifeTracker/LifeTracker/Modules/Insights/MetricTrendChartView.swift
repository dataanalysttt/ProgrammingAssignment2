import SwiftUI
import SwiftData
import Charts

enum TrendSource: Hashable {
    case tracker(CustomTracker)
    case health(HealthMetricKind)

    var title: String {
        switch self {
        case .tracker(let tracker): return tracker.name
        case .health(let kind): return kind.displayName
        }
    }

    var unit: String? {
        switch self {
        case .tracker(let tracker): return tracker.unit
        case .health(let kind): return kind.unit
        }
    }
}

/// A single metric's trend over the last 30 days, plus a weekly-average and
/// monthly-average rollup line — used throughout Insights so every metric
/// (custom or HealthKit) gets the same look.
struct MetricTrendChartView: View {
    let source: TrendSource
    @Environment(\.modelContext) private var context
    @State private var points: [DailyPoint] = []

    struct DailyPoint: Identifiable {
        var id: Date { date }
        var date: Date
        var value: Double
    }

    private var weeklyAverage: Double {
        let lastWeek = points.filter { $0.date >= DateUtils.daysAgo(7) }
        guard !lastWeek.isEmpty else { return 0 }
        return lastWeek.map(\.value).reduce(0, +) / Double(lastWeek.count)
    }

    private var monthlyAverage: Double {
        guard !points.isEmpty else { return 0 }
        return points.map(\.value).reduce(0, +) / Double(points.count)
    }

    var body: some View {
        Card {
            SectionHeader(title: source.title)
            if points.isEmpty {
                Text("Not enough data yet.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            } else {
                Chart(points) { point in
                    BarMark(x: .value("Day", point.date, unit: .day), y: .value("Value", point.value))
                        .foregroundStyle(Theme.ColorToken.accent.gradient)
                }
                .frame(height: 140)

                HStack {
                    rollupLabel(title: "7-day avg", value: weeklyAverage)
                    Spacer()
                    rollupLabel(title: "30-day avg", value: monthlyAverage)
                }
            }
        }
        .task(id: source) { await load() }
    }

    private func rollupLabel(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.1f", value) + (source.unit.map { " \($0)" } ?? ""))
                .font(Theme.Typography.body.weight(.semibold))
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.ColorToken.secondaryText)
        }
    }

    private func load() async {
        let start = DateUtils.daysAgo(30)
        switch source {
        case .tracker(let tracker):
            let trackerID = tracker.id
            let entries = (try? context.fetch(
                FetchDescriptor<TrackerEntry>(predicate: #Predicate<TrackerEntry> { $0.trackerID == trackerID })
            )) ?? []
            points = entries
                .filter { $0.date >= start }
                .compactMap { entry in entry.numericRepresentation.map { DailyPoint(date: DateUtils.startOfDay(entry.date), value: $0) } }
                .sorted { $0.date < $1.date }
        case .health(let kind):
            let series = (try? await HealthKitManager.shared.dailySeries(for: kind, from: start, to: .now)) ?? []
            points = series.map { DailyPoint(date: $0.date, value: $0.value) }.sorted { $0.date < $1.date }
        }
    }
}
