import SwiftUI
import EventKit

struct CalendarUpcomingView: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @State private var events: [EKEvent] = []

    var body: some View {
        List {
            if events.isEmpty {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "Nothing this week",
                    message: "Events from your iOS calendars will show up here."
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(groupedByDay, id: \.day) { group in
                    Section(group.day.formatted(date: .complete, time: .omitted)) {
                        ForEach(group.events, id: \.eventIdentifier) { event in
                            HStack {
                                Text(event.isAllDay ? "All day" : event.startDate.formatted(date: .omitted, time: .shortened))
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.ColorToken.secondaryText)
                                    .frame(width: 70, alignment: .leading)
                                Text(event.title)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("This Week")
        .task {
            if !calendarManager.isAuthorized { try? await calendarManager.requestAccess() }
            events = calendarManager.thisWeeksEvents()
        }
    }

    private var groupedByDay: [(day: Date, events: [EKEvent])] {
        let grouped = Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.startDate) }
        return grouped.keys.sorted().map { (day: $0, events: grouped[$0]!.sorted { $0.startDate < $1.startDate }) }
    }
}
