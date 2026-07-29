import SwiftUI
import EventKit

struct TodayCalendarSection: View {
    @ObservedObject private var calendarManager = CalendarManager.shared
    @State private var events: [EKEvent] = []
    @State private var requestedAccess = false

    var body: some View {
        Card {
            SectionHeader(title: "Today's Events")
            if !calendarManager.isAuthorized {
                Button("Allow Calendar Access") {
                    Task {
                        try? await calendarManager.requestAccess()
                        refresh()
                    }
                }
                .buttonStyle(.bordered)
            } else if events.isEmpty {
                Text("Nothing on your calendar today.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            } else {
                ForEach(events, id: \.eventIdentifier) { event in
                    HStack {
                        Text(event.isAllDay ? "All day" : event.startDate.formatted(date: .omitted, time: .shortened))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.ColorToken.secondaryText)
                            .frame(width: 70, alignment: .leading)
                        Text(event.title)
                            .font(Theme.Typography.body)
                        Spacer()
                    }
                }
            }
        }
        .task {
            if calendarManager.isAuthorized { refresh() }
        }
    }

    private func refresh() {
        events = calendarManager.todaysEvents()
    }
}
