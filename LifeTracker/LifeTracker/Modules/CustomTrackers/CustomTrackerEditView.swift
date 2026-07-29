import SwiftUI
import SwiftData

/// The "build your own metric" screen described in the brief: name, type,
/// unit, cadence, and an optional per-entry target — no code required.
struct CustomTrackerEditView: View {
    let tracker: CustomTracker?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var existingTrackers: [CustomTracker]

    @State private var name: String
    @State private var unit: String
    @State private var valueType: TrackerValueType
    @State private var cadence: TrackerCadence
    @State private var hasGoalTarget: Bool
    @State private var goalTargetText: String

    init(tracker: CustomTracker?) {
        self.tracker = tracker
        _name = State(initialValue: tracker?.name ?? "")
        _unit = State(initialValue: tracker?.unit ?? "")
        _valueType = State(initialValue: tracker?.valueType ?? .number)
        _cadence = State(initialValue: tracker?.cadence ?? .daily)
        _hasGoalTarget = State(initialValue: tracker?.goalTarget != nil)
        _goalTargetText = State(initialValue: tracker?.goalTarget.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tracker") {
                    TextField("Name", text: $name)
                    TextField("Unit (optional, e.g. glasses, km)", text: $unit)
                }
                Section("Type") {
                    Picker("Type", selection: $valueType) {
                        ForEach(TrackerValueType.allCases) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Cadence") {
                    Picker("Cadence", selection: $cadence) {
                        ForEach(TrackerCadence.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                if valueType == .number || valueType == .duration {
                    Section("Per-entry Target (optional)") {
                        Toggle("Set a target", isOn: $hasGoalTarget)
                        if hasGoalTarget {
                            TextField("Target", text: $goalTargetText)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                if let tracker, !tracker.isSystemSeeded {
                    Section {
                        Button("Delete Tracker", role: .destructive) { delete(tracker) }
                    }
                }
            }
            .navigationTitle(tracker == nil ? "New Tracker" : "Edit Tracker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let resolved = tracker ?? CustomTracker(
            name: name,
            valueType: valueType,
            sortOrder: (existingTrackers.map(\.sortOrder).max() ?? -1) + 1
        )
        resolved.name = name
        resolved.unit = unit.isEmpty ? nil : unit
        resolved.valueType = valueType
        resolved.cadence = cadence
        resolved.goalTarget = hasGoalTarget ? Double(goalTargetText) : nil
        if tracker == nil { context.insert(resolved) }
        try? context.save()
        dismiss()
    }

    private func delete(_ tracker: CustomTracker) {
        context.delete(tracker)
        try? context.save()
        dismiss()
    }
}
