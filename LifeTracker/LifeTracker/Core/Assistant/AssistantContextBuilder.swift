import Foundation
import SwiftData

/// Turns everything currently in the on-device store into a compact plain-text
/// summary handed to the on-device model as its only source of truth. Nothing
/// here ever leaves the phone — this text is passed straight into a local
/// LanguageModelSession (see AssistantService) and nowhere else.
///
/// Kept deliberately short (recent windows, capped list lengths) since the
/// on-device model has a limited context window; the assistant is meant for
/// "how's my week going" style questions, not a full historical export.
@MainActor
enum AssistantContextBuilder {
    static func build(context: ModelContext, moduleSettings: ModuleSettingsStore) async -> String {
        var sections: [String] = []

        if moduleSettings.isEnabled(.customTrackers) {
            if let section = trackersSection(context: context) {
                sections.append(section)
            }
        }

        if moduleSettings.isEnabled(.goals) {
            if let section = await goalsSection(context: context) {
                sections.append(section)
            }
        }

        if moduleSettings.isEnabled(.food) {
            if let section = foodSection(context: context) {
                sections.append(section)
            }
        }

        if moduleSettings.isEnabled(.investments) {
            if let section = investmentsSection(context: context) {
                sections.append(section)
            }
        }

        if moduleSettings.isEnabled(.health) {
            if let section = await healthSection() {
                sections.append(section)
            }
        }

        guard !sections.isEmpty else {
            return "Nothing has been logged in the app yet."
        }
        return sections.joined(separator: "\n\n")
    }

    private static func trackersSection(context: ModelContext) -> String? {
        let trackers = (try? context.fetch(
            FetchDescriptor<CustomTracker>(predicate: #Predicate { $0.isArchived == false })
        )) ?? []
        guard !trackers.isEmpty else { return nil }

        let cutoff = DateUtils.daysAgo(14)
        var lines = ["## Custom trackers (last 14 days)"]
        for tracker in trackers {
            let trackerID = tracker.id
            let entries = (try? context.fetch(FetchDescriptor<TrackerEntry>(
                predicate: #Predicate<TrackerEntry> { $0.trackerID == trackerID }
            ))) ?? []
            let recent = entries.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }.prefix(14)

            let unitSuffix = tracker.unit.map { " (\($0))" } ?? ""
            lines.append("\(tracker.name)\(unitSuffix), \(tracker.cadence.displayName.lowercased()):")
            if recent.isEmpty {
                lines.append("  no entries logged in the last 14 days")
            } else {
                for entry in recent {
                    lines.append("  \(shortDate(entry.date)): \(describeValue(entry))")
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func goalsSection(context: ModelContext) async -> String? {
        let goals = (try? context.fetch(
            FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        )) ?? []
        guard !goals.isEmpty else { return nil }

        var lines = ["## Goals"]
        for goal in goals.prefix(15) {
            let progress = await GoalProgressCalculator.progress(for: goal, context: context)
            let progressText = progress.map { "\(Int($0 * 100))% complete" } ?? "no progress data"
            let dueText = goal.targetDate.map { ", due \(shortDate($0))" } ?? ""
            lines.append("- \(goal.title) [\(goal.status.displayName), \(goal.category.displayName)]\(dueText): \(progressText)")
        }
        return lines.joined(separator: "\n")
    }

    private static func foodSection(context: ModelContext) -> String? {
        let cutoff = DateUtils.daysAgo(7)
        let foods = (try? context.fetch(FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { $0.date >= cutoff }
        ))) ?? []
        guard !foods.isEmpty else { return nil }

        var lines = ["## Food logged in the last 7 days"]
        for food in foods.sorted(by: { $0.date > $1.date }).prefix(30) {
            let caloriesText = food.calories.map { " (\(Int($0)) kcal)" } ?? ""
            lines.append("- \(shortDate(food.date)): \(food.mealName)\(caloriesText)")
        }
        return lines.joined(separator: "\n")
    }

    private static func investmentsSection(context: ModelContext) -> String? {
        var descriptor = FetchDescriptor<InvestmentSnapshot>(sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let latest = (try? context.fetch(descriptor))?.first else { return nil }

        var lines = ["## Investments (snapshot from \(shortDate(latest.capturedAt)))"]
        lines.append("Total value: \(Int(latest.totalValue)), total P/L: \(Int(latest.totalPnL))")
        for holding in latest.holdings.prefix(20) {
            lines.append("- \(holding.symbol): qty \(holding.quantity), value \(Int(holding.currentValue)), P/L \(Int(holding.pnl))")
        }
        return lines.joined(separator: "\n")
    }

    private static func healthSection() async -> String? {
        let health = HealthKitManager.shared
        guard health.isAuthorized else { return nil }

        let start = DateUtils.daysAgo(6)
        let whoopSource = await health.resolveWhoopSource()
        var lines = ["## Health, last 7 days"]

        let whoopMetrics: [HealthMetricKind] = [.sleepHours, .heartRateVariability, .restingHeartRate, .respiratoryRate]
        for kind in whoopMetrics {
            let series = (try? await health.dailySeries(for: kind, from: start, to: .now, source: whoopSource)) ?? []
            appendSeries(series, kind: kind, whoopOnly: true, to: &lines)
        }

        let generalMetrics: [HealthMetricKind] = [.steps, .activeEnergy]
        for kind in generalMetrics {
            let series = (try? await health.dailySeries(for: kind, from: start, to: .now)) ?? []
            appendSeries(series, kind: kind, whoopOnly: false, to: &lines)
        }

        guard lines.count > 1 else { return nil }
        return lines.joined(separator: "\n")
    }

    private static func appendSeries(_ series: [HealthKitManager.DateValue], kind: HealthMetricKind, whoopOnly: Bool, to lines: inout [String]) {
        guard !series.isEmpty else { return }
        let source = whoopOnly ? " (from Whoop)" : ""
        let values = series
            .sorted { $0.date < $1.date }
            .map { "\(shortDate($0.date)): \(String(format: "%.1f", $0.value))" }
            .joined(separator: ", ")
        lines.append("\(kind.displayName)\(source), \(kind.unit): \(values)")
    }

    private static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private static func describeValue(_ entry: TrackerEntry) -> String {
        if let numberValue = entry.numberValue { return String(numberValue) }
        if let boolValue = entry.boolValue { return boolValue ? "yes" : "no" }
        if let scaleValue = entry.scaleValue { return "\(scaleValue)/10" }
        if let durationSeconds = entry.durationSeconds { return "\(Int(durationSeconds / 60)) min" }
        if let textValue = entry.textValue { return textValue }
        return "no value"
    }
}
