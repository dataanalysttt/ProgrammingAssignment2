import SwiftUI
import SwiftData

struct CustomTrackerListView: View {
    @Query(sort: \CustomTracker.sortOrder) private var trackers: [CustomTracker]
    @Environment(\.modelContext) private var context
    @State private var editingTracker: CustomTracker?
    @State private var showingAdd = false

    var body: some View {
        List {
            Section("Active") {
                ForEach(trackers.filter { !$0.isArchived }) { tracker in
                    row(for: tracker)
                }
            }
            let archived = trackers.filter(\.isArchived)
            if !archived.isEmpty {
                Section("Archived") {
                    ForEach(archived) { tracker in
                        row(for: tracker)
                    }
                }
            }
        }
        .navigationTitle("Custom Trackers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { CustomTrackerEditView(tracker: nil) }
        .sheet(item: $editingTracker) { tracker in CustomTrackerEditView(tracker: tracker) }
    }

    private func row(for tracker: CustomTracker) -> some View {
        Button {
            editingTracker = tracker
        } label: {
            HStack {
                Image(systemName: tracker.valueType.systemImage)
                    .foregroundStyle(Theme.ColorToken.accent)
                VStack(alignment: .leading) {
                    Text(tracker.name).foregroundStyle(Theme.ColorToken.primaryText)
                    Text("\(tracker.valueType.displayName) · \(tracker.cadence.displayName)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.ColorToken.secondaryText)
                }
                Spacer()
            }
        }
        .swipeActions {
            Button(tracker.isArchived ? "Unarchive" : "Archive") {
                tracker.isArchived.toggle()
                try? context.save()
            }
            .tint(.orange)
        }
    }
}
