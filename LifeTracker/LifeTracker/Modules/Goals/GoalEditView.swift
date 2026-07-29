import SwiftUI
import SwiftData

struct GoalEditView: View {
    let goal: Goal?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore

    @Query(filter: #Predicate<CustomTracker> { $0.isArchived == false }, sort: \CustomTracker.sortOrder)
    private var trackers: [CustomTracker]

    @State private var title: String
    @State private var description: String
    @State private var category: GoalCategory
    @State private var hasTargetDate: Bool
    @State private var targetDate: Date
    @State private var linkKind: LinkKind
    @State private var linkedTrackerID: UUID?
    @State private var linkedHealthKind: HealthMetricKind
    @State private var targetValueText: String
    @State private var aggregation: GoalAggregation
    @State private var manualProgress: Double
    @State private var createCalendarEvent = false

    private enum LinkKind: String, CaseIterable, Identifiable, Hashable {
        case none = "None"
        case tracker = "Custom Tracker"
        case health = "Health Metric"
        case investment = "Portfolio Value"
        var id: String { rawValue }
    }

    init(goal: Goal?) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "")
        _description = State(initialValue: goal?.goalDescription ?? "")
        _category = State(initialValue: goal?.category ?? .personal)
        _hasTargetDate = State(initialValue: goal?.targetDate != nil)
        _targetDate = State(initialValue: goal?.targetDate ?? .now.addingTimeInterval(7 * 86400))
        _targetValueText = State(initialValue: goal?.targetValue.map { String($0) } ?? "")
        _aggregation = State(initialValue: goal?.aggregation ?? .sum)
        _manualProgress = State(initialValue: goal?.manualProgressPercent ?? 0)

        switch goal?.metricReference ?? .none {
        case .none:
            _linkKind = State(initialValue: .none)
            _linkedTrackerID = State(initialValue: nil)
            _linkedHealthKind = State(initialValue: .steps)
        case .tracker(let id):
            _linkKind = State(initialValue: .tracker)
            _linkedTrackerID = State(initialValue: id)
            _linkedHealthKind = State(initialValue: .steps)
        case .health(let kind):
            _linkKind = State(initialValue: .health)
            _linkedTrackerID = State(initialValue: nil)
            _linkedHealthKind = State(initialValue: kind)
        case .investmentValue:
            _linkKind = State(initialValue: .investment)
            _linkedTrackerID = State(initialValue: nil)
            _linkedHealthKind = State(initialValue: .steps)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                Section("Target Date") {
                    Toggle("Has a target date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Date", selection: $targetDate, displayedComponents: .date)
                        if moduleSettings.isEnabled(.calendar) {
                            Toggle("Add to Calendar", isOn: $createCalendarEvent)
                        }
                    }
                }

                Section("Progress") {
                    Picker("Tracked by", selection: $linkKind) {
                        ForEach(availableLinkKinds) { Text($0.rawValue).tag($0) }
                    }
                    switch linkKind {
                    case .none:
                        VStack(alignment: .leading) {
                            Text("Manual progress: \(Int(manualProgress))%")
                                .font(Theme.Typography.caption)
                            Slider(value: $manualProgress, in: 0...100, step: 5)
                        }
                    case .tracker:
                        Picker("Tracker", selection: $linkedTrackerID) {
                            Text("Choose one").tag(UUID?.none)
                            ForEach(trackers) { tracker in
                                Text(tracker.name).tag(Optional(tracker.id))
                            }
                        }
                        TextField("Target value", text: $targetValueText)
                            .keyboardType(.decimalPad)
                        Picker("Combine as", selection: $aggregation) {
                            ForEach(GoalAggregation.allCases) { Text($0.displayName).tag($0) }
                        }
                    case .health:
                        Picker("Metric", selection: $linkedHealthKind) {
                            ForEach(HealthMetricKind.allCases) { Text($0.displayName).tag($0) }
                        }
                        TextField("Target value (\(linkedHealthKind.unit))", text: $targetValueText)
                            .keyboardType(.decimalPad)
                        Picker("Combine as", selection: $aggregation) {
                            ForEach(GoalAggregation.allCases) { Text($0.displayName).tag($0) }
                        }
                    case .investment:
                        TextField("Target portfolio value (₹)", text: $targetValueText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var availableLinkKinds: [LinkKind] {
        var kinds: [LinkKind] = [.none, .tracker]
        if moduleSettings.isEnabled(.health) { kinds.append(.health) }
        if moduleSettings.isEnabled(.investments) { kinds.append(.investment) }
        return kinds
    }

    private func save() {
        let resolvedGoal = goal ?? Goal(title: title)
        resolvedGoal.title = title
        resolvedGoal.goalDescription = description.isEmpty ? nil : description
        resolvedGoal.category = category
        resolvedGoal.targetDate = hasTargetDate ? targetDate : nil
        resolvedGoal.aggregation = aggregation

        switch linkKind {
        case .none:
            resolvedGoal.metricReference = .none
            resolvedGoal.manualProgressPercent = manualProgress
            resolvedGoal.targetValue = nil
        case .tracker:
            if let linkedTrackerID {
                resolvedGoal.metricReference = .tracker(linkedTrackerID)
            }
            resolvedGoal.targetValue = Double(targetValueText)
        case .health:
            resolvedGoal.metricReference = .health(linkedHealthKind)
            resolvedGoal.targetValue = Double(targetValueText)
        case .investment:
            resolvedGoal.metricReference = .investmentValue
            resolvedGoal.targetValue = Double(targetValueText)
        }

        if goal == nil {
            context.insert(resolvedGoal)
        }

        if hasTargetDate, createCalendarEvent, resolvedGoal.linkedCalendarEventIdentifier == nil {
            resolvedGoal.linkedCalendarEventIdentifier = try? CalendarManager.shared.createEvent(
                title: "Goal due: \(title)",
                on: targetDate
            )
        }

        try? context.save()
        dismiss()
    }
}
