import Foundation
import SwiftData

/// You own your data: this turns everything in the on-device store into a single
/// JSON file you can AirDrop, save to Files, or back up however you like, and
/// reads that same file back in (upserting by id, so importing twice is safe).
/// A CSV export is also offered for opening entries in Numbers/Excel, but CSV
/// is one-way — re-importing structured data like goals from a flat table isn't
/// well-defined, so import only accepts the JSON format this app produces.
enum DataExportImportService {
    private static var iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Export

    static func exportJSON(context: ModelContext) throws -> URL {
        let payload = try buildPayload(context: context)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifeTracker-Export-\(fileTimestamp()).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func exportCSV(context: ModelContext) throws -> URL {
        let payload = try buildPayload(context: context)
        var csv = "type,date,name,value,unit,note\n"

        let trackersByID = Dictionary(uniqueKeysWithValues: payload.trackers.map { ($0.id, $0) })
        for entry in payload.entries {
            let tracker = trackersByID[entry.trackerID]
            let value: String = {
                if let numberValue = entry.numberValue { return String(numberValue) }
                if let boolValue = entry.boolValue { return boolValue ? "yes" : "no" }
                if let scaleValue = entry.scaleValue { return String(scaleValue) }
                if let durationSeconds = entry.durationSeconds { return String(durationSeconds / 60) }
                if let textValue = entry.textValue { return csvEscape(textValue) }
                return ""
            }()
            csv += "tracker,\(iso8601.string(from: entry.date)),\(csvEscape(tracker?.name ?? "Unknown")),\(value),\(csvEscape(tracker?.unit ?? "")),\(csvEscape(entry.note ?? ""))\n"
        }
        for food in payload.foodEntries {
            csv += "food,\(iso8601.string(from: food.date)),\(csvEscape(food.mealName)),\(food.calories.map(String.init) ?? ""),kcal,\(csvEscape(food.note ?? ""))\n"
        }
        for goal in payload.goals {
            csv += "goal,\(iso8601.string(from: goal.createdAt)),\(csvEscape(goal.title)),\(goal.manualProgressPercent.map(String.init) ?? ""),%,\(csvEscape(goal.status))\n"
        }
        for snapshot in payload.investmentSnapshots {
            csv += "investment,\(iso8601.string(from: snapshot.capturedAt)),Portfolio,\(snapshot.totalValue),INR,pnl \(snapshot.totalPnL)\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LifeTracker-Export-\(fileTimestamp()).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Import

    static func importJSON(from url: URL, context: ModelContext) throws {
        let didAccessSecurityScope = url.startAccessingSecurityScopedResource()
        defer { if didAccessSecurityScope { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        try upsertTrackers(payload.trackers, context: context)
        try upsertEntries(payload.entries, context: context)
        try upsertGoals(payload.goals, context: context)
        try upsertFoodEntries(payload.foodEntries, context: context)
        try upsertInvestmentSnapshots(payload.investmentSnapshots, context: context)

        try context.save()
    }

    // MARK: - Building the payload

    private static func buildPayload(context: ModelContext) throws -> ExportPayload {
        let trackers = try context.fetch(FetchDescriptor<CustomTracker>()).map {
            ExportPayload.TrackerDTO(
                id: $0.id, name: $0.name, unit: $0.unit, valueType: $0.valueTypeRaw,
                cadence: $0.cadenceRaw, goalTarget: $0.goalTarget, sortOrder: $0.sortOrder,
                isArchived: $0.isArchived, isSystemSeeded: $0.isSystemSeeded, createdAt: $0.createdAt
            )
        }
        let entries = try context.fetch(FetchDescriptor<TrackerEntry>()).map {
            ExportPayload.TrackerEntryDTO(
                id: $0.id, trackerID: $0.trackerID, date: $0.date, numberValue: $0.numberValue,
                boolValue: $0.boolValue, scaleValue: $0.scaleValue, durationSeconds: $0.durationSeconds,
                textValue: $0.textValue, note: $0.note, createdAt: $0.createdAt
            )
        }
        let goals = try context.fetch(FetchDescriptor<Goal>()).map {
            ExportPayload.GoalDTO(
                id: $0.id, title: $0.title, goalDescription: $0.goalDescription, category: $0.categoryRaw,
                targetDate: $0.targetDate, status: $0.statusRaw, createdAt: $0.createdAt,
                completedAt: $0.completedAt, metricReference: $0.metricReference, targetValue: $0.targetValue,
                aggregation: $0.aggregationRaw, manualProgressPercent: $0.manualProgressPercent,
                linkedCalendarEventIdentifier: $0.linkedCalendarEventIdentifier
            )
        }
        let foodEntries = try context.fetch(FetchDescriptor<FoodEntry>()).map {
            ExportPayload.FoodEntryDTO(
                id: $0.id, date: $0.date, mealName: $0.mealName, calories: $0.calories,
                proteinGrams: $0.proteinGrams, carbsGrams: $0.carbsGrams, fatGrams: $0.fatGrams,
                note: $0.note, createdAt: $0.createdAt
            )
        }
        let snapshots = try context.fetch(FetchDescriptor<InvestmentSnapshot>()).map { snapshot in
            ExportPayload.InvestmentSnapshotDTO(
                id: snapshot.id, capturedAt: snapshot.capturedAt, totalValue: snapshot.totalValue,
                totalInvested: snapshot.totalInvested, totalPnL: snapshot.totalPnL,
                holdings: snapshot.holdings.map {
                    ExportPayload.HoldingDTO(
                        id: $0.id, symbol: $0.symbol, quantity: $0.quantity, averagePrice: $0.averagePrice,
                        lastPrice: $0.lastPrice, currentValue: $0.currentValue, pnl: $0.pnl
                    )
                }
            )
        }

        return ExportPayload(
            exportedAt: .now,
            appVersion: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0",
            trackers: trackers, entries: entries, goals: goals,
            foodEntries: foodEntries, investmentSnapshots: snapshots
        )
    }

    // MARK: - Upserts

    private static func upsertTrackers(_ dtos: [ExportPayload.TrackerDTO], context: ModelContext) throws {
        for dto in dtos {
            let id = dto.id
            let existing = try context.fetch(FetchDescriptor<CustomTracker>(predicate: #Predicate { $0.id == id })).first
            let tracker = existing ?? CustomTracker(id: dto.id, name: dto.name, valueType: .number)
            tracker.name = dto.name
            tracker.unit = dto.unit
            tracker.valueTypeRaw = dto.valueType
            tracker.cadenceRaw = dto.cadence
            tracker.goalTarget = dto.goalTarget
            tracker.sortOrder = dto.sortOrder
            tracker.isArchived = dto.isArchived
            tracker.isSystemSeeded = dto.isSystemSeeded
            tracker.createdAt = dto.createdAt
            if existing == nil { context.insert(tracker) }
        }
    }

    private static func upsertEntries(_ dtos: [ExportPayload.TrackerEntryDTO], context: ModelContext) throws {
        for dto in dtos {
            let id = dto.id
            let existing = try context.fetch(FetchDescriptor<TrackerEntry>(predicate: #Predicate { $0.id == id })).first
            let entry = existing ?? TrackerEntry(id: dto.id, trackerID: dto.trackerID, date: dto.date)
            entry.trackerID = dto.trackerID
            entry.date = dto.date
            entry.numberValue = dto.numberValue
            entry.boolValue = dto.boolValue
            entry.scaleValue = dto.scaleValue
            entry.durationSeconds = dto.durationSeconds
            entry.textValue = dto.textValue
            entry.note = dto.note
            entry.createdAt = dto.createdAt
            if existing == nil { context.insert(entry) }
        }
    }

    private static func upsertGoals(_ dtos: [ExportPayload.GoalDTO], context: ModelContext) throws {
        for dto in dtos {
            let id = dto.id
            let existing = try context.fetch(FetchDescriptor<Goal>(predicate: #Predicate { $0.id == id })).first
            let goal = existing ?? Goal(id: dto.id, title: dto.title)
            goal.title = dto.title
            goal.goalDescription = dto.goalDescription
            goal.categoryRaw = dto.category
            goal.targetDate = dto.targetDate
            goal.statusRaw = dto.status
            goal.createdAt = dto.createdAt
            goal.completedAt = dto.completedAt
            goal.metricReference = dto.metricReference
            goal.targetValue = dto.targetValue
            goal.aggregationRaw = dto.aggregation
            goal.manualProgressPercent = dto.manualProgressPercent
            goal.linkedCalendarEventIdentifier = dto.linkedCalendarEventIdentifier
            if existing == nil { context.insert(goal) }
        }
    }

    private static func upsertFoodEntries(_ dtos: [ExportPayload.FoodEntryDTO], context: ModelContext) throws {
        for dto in dtos {
            let id = dto.id
            let existing = try context.fetch(FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.id == id })).first
            let entry = existing ?? FoodEntry(id: dto.id, mealName: dto.mealName)
            entry.date = dto.date
            entry.mealName = dto.mealName
            entry.calories = dto.calories
            entry.proteinGrams = dto.proteinGrams
            entry.carbsGrams = dto.carbsGrams
            entry.fatGrams = dto.fatGrams
            entry.note = dto.note
            entry.createdAt = dto.createdAt
            if existing == nil { context.insert(entry) }
        }
    }

    private static func upsertInvestmentSnapshots(_ dtos: [ExportPayload.InvestmentSnapshotDTO], context: ModelContext) throws {
        for dto in dtos {
            let id = dto.id
            let existing = try context.fetch(FetchDescriptor<InvestmentSnapshot>(predicate: #Predicate { $0.id == id })).first
            if existing != nil { continue } // snapshots are immutable point-in-time captures
            let snapshot = InvestmentSnapshot(
                id: dto.id, capturedAt: dto.capturedAt, totalValue: dto.totalValue,
                totalInvested: dto.totalInvested, totalPnL: dto.totalPnL
            )
            snapshot.holdings = dto.holdings.map {
                InvestmentHolding(
                    id: $0.id, symbol: $0.symbol, quantity: $0.quantity, averagePrice: $0.averagePrice,
                    lastPrice: $0.lastPrice, currentValue: $0.currentValue, pnl: $0.pnl
                )
            }
            context.insert(snapshot)
        }
    }

    // MARK: - Helpers

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: .now)
    }

    private static func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
