import XCTest
import SwiftData
@testable import LifeTracker

@MainActor
final class ExportImportTests: XCTestCase {
    func testExportThenImportIntoFreshStoreRoundTripsData() throws {
        let sourceContext = TestSupport.makeInMemoryContext()
        let tracker = CustomTracker(name: "Mood", valueType: .scale)
        sourceContext.insert(tracker)
        sourceContext.insert(TrackerEntry(trackerID: tracker.id, date: .now, scaleValue: 7))
        sourceContext.insert(Goal(title: "Meditate daily", manualProgressPercent: 60))
        try sourceContext.save()

        let exportURL = try DataExportImportService.exportJSON(context: sourceContext)
        defer { try? FileManager.default.removeItem(at: exportURL) }

        let destinationContext = TestSupport.makeInMemoryContext()
        try DataExportImportService.importJSON(from: exportURL, context: destinationContext)

        let importedTrackers = try destinationContext.fetch(FetchDescriptor<CustomTracker>())
        let importedEntries = try destinationContext.fetch(FetchDescriptor<TrackerEntry>())
        let importedGoals = try destinationContext.fetch(FetchDescriptor<Goal>())

        XCTAssertEqual(importedTrackers.count, 1)
        XCTAssertEqual(importedTrackers.first?.name, "Mood")
        XCTAssertEqual(importedEntries.count, 1)
        XCTAssertEqual(importedEntries.first?.scaleValue, 7)
        XCTAssertEqual(importedGoals.count, 1)
        XCTAssertEqual(importedGoals.first?.manualProgressPercent, 60)
    }

    func testImportingTheSameFileTwiceDoesNotDuplicate() throws {
        let sourceContext = TestSupport.makeInMemoryContext()
        sourceContext.insert(CustomTracker(name: "Water", valueType: .number))
        try sourceContext.save()

        let exportURL = try DataExportImportService.exportJSON(context: sourceContext)
        defer { try? FileManager.default.removeItem(at: exportURL) }

        let destinationContext = TestSupport.makeInMemoryContext()
        try DataExportImportService.importJSON(from: exportURL, context: destinationContext)
        try DataExportImportService.importJSON(from: exportURL, context: destinationContext)

        let trackers = try destinationContext.fetch(FetchDescriptor<CustomTracker>())
        XCTAssertEqual(trackers.count, 1)
    }
}
