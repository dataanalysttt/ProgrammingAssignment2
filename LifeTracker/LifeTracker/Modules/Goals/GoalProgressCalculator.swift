import Foundation
import SwiftData

/// Turns a Goal's linked metric into a 0...1 completion fraction. This is the
/// one place that knows how to read each kind of MetricReference, so adding a
/// new linkable metric source only means adding a case here (and to
/// MetricReference).
enum GoalProgressCalculator {
    static func progress(for goal: Goal, context: ModelContext) async -> Double? {
        switch goal.metricReference {
        case .none:
            return goal.manualProgressPercent.map { min(max($0 / 100, 0), 1) }

        case .tracker(let trackerID):
            guard let target = goal.targetValue, target > 0 else { return nil }
            let entries = (try? context.fetch(
                FetchDescriptor<TrackerEntry>(predicate: #Predicate { $0.trackerID == trackerID })
            )) ?? []
            let start = DateUtils.startOfDay(goal.createdAt)
            let values = entries.filter { $0.date >= start }.compactMap(\.numericRepresentation)
            return min(aggregate(values, using: goal.aggregation) / target, 1)

        case .health(let kind):
            guard let target = goal.targetValue, target > 0 else { return nil }
            let start = DateUtils.startOfDay(goal.createdAt)
            let series = (try? await HealthKitManager.shared.dailySeries(for: kind, from: start, to: .now)) ?? []
            return min(aggregate(series.map(\.value), using: goal.aggregation) / target, 1)

        case .investmentValue:
            guard let target = goal.targetValue, target > 0 else { return nil }
            var descriptor = FetchDescriptor<InvestmentSnapshot>(sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
            descriptor.fetchLimit = 1
            guard let latest = (try? context.fetch(descriptor))?.first else { return nil }
            return min(latest.totalValue / target, 1)
        }
    }

    /// A day-by-day cumulative running total since the goal was created, for
    /// GoalDetailView's progress-over-time chart. Only meaningful for
    /// `.sum`-aggregated tracker/health goals; other combinations return an
    /// empty series and the detail screen falls back to just the progress bar.
    static func progressSeries(for goal: Goal, context: ModelContext) async -> [(date: Date, value: Double)] {
        guard goal.aggregation == .sum else { return [] }
        let start = DateUtils.startOfDay(goal.createdAt)

        let dailyValues: [(Date, Double)]
        switch goal.metricReference {
        case .tracker(let trackerID):
            let entries = (try? context.fetch(
                FetchDescriptor<TrackerEntry>(predicate: #Predicate { $0.trackerID == trackerID })
            )) ?? []
            dailyValues = entries
                .filter { $0.date >= start }
                .compactMap { entry in entry.numericRepresentation.map { (entry.date, $0) } }
        case .health(let kind):
            let series = (try? await HealthKitManager.shared.dailySeries(for: kind, from: start, to: .now)) ?? []
            dailyValues = series.map { ($0.date, $0.value) }
        case .none, .investmentValue:
            return []
        }

        var runningTotal = 0.0
        return dailyValues
            .sorted { $0.0 < $1.0 }
            .map { date, value in
                runningTotal += value
                return (date, runningTotal)
            }
    }

    private static func aggregate(_ values: [Double], using aggregation: GoalAggregation) -> Double {
        guard !values.isEmpty else { return 0 }
        switch aggregation {
        case .sum: return values.reduce(0, +)
        case .average: return values.reduce(0, +) / Double(values.count)
        case .latest: return values.last ?? 0
        }
    }
}
