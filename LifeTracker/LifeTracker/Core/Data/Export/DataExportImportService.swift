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
            csv += csvRow(for: entry, trackersByID: trackersByID)
        }
        for food in payload.foodEntries {
            csv += csvRow(for: food)
        }
        for goal in payload.goals {
            csv += csvRow(for: goal)
        }
        for snapshot in payload.investmentSnapshots {
            csv += csvRow(for: snapshot)
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
        let trackers = try context.fetch(FetchDescriptor<CustomTracker>()).map(trackerDTO)
        let entries = try context.fetch(FetchDescriptor<TrackerEntry>()).map(entryDTO)
        let goals = try context.fetch(FetchDescriptor<Goal>()).map(goalDTO)
        let foodEntries = try context.fetch(FetchDescriptor<FoodEntry>()).map(foodEntryDTO)
        let snapshots = try context.fetch(FetchDescriptor<InvestmentSnapshot>()).map(snapshotDTO)

        return ExportPayload(
            exportedAt: .now,
            appVersion: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0",
            trackers: trackers, entries: entries, goals: goals,
            foodEntries: foodEntries, investmentSnapshots: snapshots
        )
    }

    private static func trackerDTO(_ tracker: CustomTracker) -> ExportPayload.TrackerDTO {
        ExportPayload.TrackerDTO(
            id: tracker.id, name: tracker.name, unit: tracker.unit, valueType: tracker.valueTypeRaw,
            cadence: tracker.cadenceRaw, goalTarget: tracker.goalTarget, sortOrder: tracker.sortOrder,
            isArchived: tracker.isArchived, isSystemSeeded: tracker.isSystemSeeded, createdAt: tracker.createdAt
        )
    }

    private static func entryDTO(_ entry: TrackerEntry) -> ExportPayload.TrackerEntryDTO {
        ExportPayload.TrackerEntryDTO(
            id: entry.id, trackerID: entry.trackerID, date: entry.date, numberValue: entry.numberValue,
            boolValue: entry.boolValue, scaleValue: entry.scaleValue, durationSeconds: entry.durationSeconds,
            textValue: entry.textValue, note: entry.note, createdAt: entry.createdAt
        )
    }

    private static func goalDTO(_ goal: Goal) -> ExportPayload.GoalDTO {
        ExportPayload.GoalDTO(
            id: goal.id, title: goal.title, goalDescription: goal.goalDescription, category: goal.categoryRaw,
            targetDate: goal.targetDate, status: goal.statusRaw, createdAt: goal.createdAt,
            completedAt: goal.completedAt, metricReference: goal.metricReference, targetValue: goal.targetValue,
            aggregation: goal.aggregationRaw, manualProgressPercent: goal.manualProgressPercent,
            linkedCalendarEventIdentifier: goal.linkedCalendarEventIdentifier
        )
    }

    private static func foodEntryDTO(_ entry: FoodEntry) -> ExportPayload.FoodEntryDTO {
        ExportPayload.FoodEntryDTO(
            id: entry.id, date: entry.date, mealName: entry.mealName, calories: entry.calories,
            proteinGrams: entry.proteinGrams, carbsGrams: entry.carbsGrams, fatGrams: entry.fatGrams,
            note: entry.note, createdAt: entry.createdAt
        )
    }

    private static func snapshotDTO(_ snapshot: InvestmentSnapshot) -> ExportPayload.InvestmentSnapshotDTO {
        ExportPayload.InvestmentSnapshotDTO(
            id: snapshot.id, capturedAt: snapshot.capturedAt, totalValue: snapshot.totalValue,
            totalInvested: snapshot.totalInvested, totalPnL: snapshot.totalPnL,
            holdings: snapshot.holdings.map(holdingDTO)
        )
    }

    private static func holdingDTO(_ holding: InvestmentHolding) -> ExportPayload.HoldingDTO {
        ExportPayload.HoldingDTO(
            id: holding.id, symbol: holding.symbol, quantity: holding.quantity, averagePrice: holding.averagePrice,
            lastPrice: holding.lastPrice, currentValue: holding.currentValue, pnl: holding.pnl
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
            snapshot.holdings = dto.holdings.map(holdingModel)
            context.insert(snapshot)
        }
    }

    private static func holdingModel(_ dto: ExportPayload.HoldingDTO) -> InvestmentHolding {
        InvestmentHolding(
            id: dto.id, symbol: dto.symbol, quantity: dto.quantity, averagePrice: dto.averagePrice,
            lastPrice: dto.lastPrice, currentValue: dto.currentValue, pnl: dto.pnl
        )
    }

    // MARK: - CSV rows

    private static func csvLine(_ type: String, _ date: Date, _ name: String, _ value: String, _ unit: String, _ note: String) -> String {
        let dateString = iso8601.string(from: date)
        let nameField = csvEscape(name)
        let noteField = csvEscape(note)
        return "\(type),\(dateString),\(nameField),\(value),\(unit),\(noteField)\n"
    }

    private static func entryValue(_ entry: ExportPayload.TrackerEntryDTO) -> String {
        if let numberValue = entry.numberValue { return String(numberValue) }
        if let boolValue = entry.boolValue { return boolValue ? "yes" : "no" }
        if let scaleValue = entry.scaleValue { return String(scaleValue) }
        if let durationSeconds = entry.durationSeconds { return String(durationSeconds / 60) }
        if let textValue = entry.textValue { return csvEscape(textValue) }
        return ""
    }

    private static func csvRow(for entry: ExportPayload.TrackerEntryDTO, trackersByID: [UUID: ExportPayload.TrackerDTO]) -> String {
        let tracker = trackersByID[entry.trackerID]
        let name = tracker?.name ?? "Unknown"
        let unit = tracker?.unit ?? ""
        let value = entryValue(entry)
        return csvLine("tracker", entry.date, name, value, unit, entry.note ?? "")
    }

    private static func csvRow(for food: ExportPayload.FoodEntryDTO) -> String {
        let value = food.calories.map(String.init) ?? ""
        return csvLine("food", food.date, food.mealName, value, "kcal", food.note ?? "")
    }

    private static func csvRow(for goal: ExportPayload.GoalDTO) -> String {
        let value = goal.manualProgressPercent.map(String.init) ?? ""
        return csvLine("goal", goal.createdAt, goal.title, value, "%", goal.status)
    }

    private static func csvRow(for snapshot: ExportPayload.InvestmentSnapshotDTO) -> String {
        let value = String(snapshot.totalValue)
        let note = "pnl \(snapshot.totalPnL)"
        return csvLine("investment", snapshot.capturedAt, "Portfolio", value, "INR", note)
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
