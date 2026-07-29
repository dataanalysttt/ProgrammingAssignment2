import Foundation
import EventKit

@MainActor
final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    private let store = EKEventStore()
    @Published private(set) var isAuthorized = false

    func requestAccess() async throws {
        let granted = try await store.requestFullAccessToEvents()
        isAuthorized = granted
    }

    func events(from start: Date, to end: Date) -> [EKEvent] {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func todaysEvents() -> [EKEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        return events(from: start, to: end)
    }

    func thisWeeksEvents() -> [EKEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? .now
        return events(from: start, to: end)
    }

    /// Creates a same-day, all-day event on the goal's target date so it shows
    /// up on your calendar as a deadline reminder. Returns the created event's
    /// identifier, which the caller stores on the Goal for reference.
    @discardableResult
    func createEvent(title: String, on date: Date, notes: String? = nil) throws -> String {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.isAllDay = true
        event.startDate = Calendar.current.startOfDay(for: date)
        event.endDate = event.startDate
        event.calendar = store.defaultCalendarForNewEvents ?? store.calendars(for: .event).first
        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }
}
