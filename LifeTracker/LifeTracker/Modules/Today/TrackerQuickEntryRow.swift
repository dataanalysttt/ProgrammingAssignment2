import SwiftUI
import SwiftData

/// One row on the Today screen for a single tracker, sized for a single tap
/// (yes/no, scale) or a quick keyboard entry (number, duration, text).
/// Writes are auto-saved immediately — there is no separate "Save" step for
/// quick trackers, per the "as few taps as possible" requirement.
struct TrackerQuickEntryRow: View {
    let tracker: CustomTracker

    @Environment(\.modelContext) private var context
    @Query private var entries: [TrackerEntry]

    @State private var numberText: String = ""
    @State private var durationMinutesText: String = ""
    @State private var textNote: String = ""

    init(tracker: CustomTracker) {
        self.tracker = tracker
        let id = tracker.id
        _entries = Query(filter: #Predicate<TrackerEntry> { $0.trackerID == id }, sort: \TrackerEntry.date, order: .reverse)
    }

    private var todayEntry: TrackerEntry? {
        entries.first { DateUtils.isSameDay($0.date, .now) }
    }

    private var streak: Int {
        tracker.cadence == .daily ? Streaks.currentStreak(entryDates: entries.map(\.date)) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(tracker.name)
                    .font(Theme.Typography.body.weight(.medium))
                StreakBadge(days: streak)
                Spacer()
                if let unit = tracker.unit, !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.ColorToken.secondaryText)
                }
            }
            inputControl
        }
        .onAppear(perform: loadDraftFromTodayEntry)
    }

    @ViewBuilder
    private var inputControl: some View {
        switch tracker.valueType {
        case .yesNo:
            HStack(spacing: Theme.Spacing.sm) {
                choiceButton(title: "Yes", isSelected: todayEntry?.boolValue == true) { setBool(true) }
                choiceButton(title: "No", isSelected: todayEntry?.boolValue == false) { setBool(false) }
            }
        case .scale:
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { value in
                    Circle()
                        .fill(todayEntry?.scaleValue == value ? Theme.ColorToken.accent : Theme.ColorToken.secondaryText.opacity(0.15))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Text("\(value)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(todayEntry?.scaleValue == value ? .white : Theme.ColorToken.secondaryText)
                        )
                        .onTapGesture { setScale(value) }
                }
            }
        case .number:
            HStack {
                TextField("Value", text: $numberText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { setNumber() }
                Button("Save") { setNumber() }
                    .buttonStyle(.bordered)
                    .disabled(numberText.isEmpty)
            }
        case .duration:
            HStack {
                TextField("Minutes", text: $durationMinutesText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { setDuration() }
                Button("Save") { setDuration() }
                    .buttonStyle(.bordered)
                    .disabled(durationMinutesText.isEmpty)
            }
        case .text:
            HStack {
                TextField("Note", text: $textNote)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { setText() }
                Button("Save") { setText() }
                    .buttonStyle(.bordered)
                    .disabled(textNote.isEmpty)
            }
        }
    }

    private func choiceButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption.weight(.semibold))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(isSelected ? Theme.ColorToken.accent : Theme.ColorToken.secondaryText.opacity(0.12))
                .foregroundStyle(isSelected ? .white : Theme.ColorToken.primaryText)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func loadDraftFromTodayEntry() {
        guard let entry = todayEntry else { return }
        if let numberValue = entry.numberValue { numberText = String(numberValue) }
        if let durationSeconds = entry.durationSeconds { durationMinutesText = String(Int(durationSeconds / 60)) }
        if let textValue = entry.textValue { textNote = textValue }
    }

    private func setBool(_ value: Bool) {
        upsertTodayEntry { $0.boolValue = value }
    }

    private func setScale(_ value: Int) {
        upsertTodayEntry { $0.scaleValue = value }
    }

    private func setNumber() {
        guard let value = Double(numberText) else { return }
        upsertTodayEntry { $0.numberValue = value }
    }

    private func setDuration() {
        guard let minutes = Double(durationMinutesText) else { return }
        upsertTodayEntry { $0.durationSeconds = minutes * 60 }
    }

    private func setText() {
        upsertTodayEntry { $0.textValue = textNote }
    }

    private func upsertTodayEntry(_ update: (TrackerEntry) -> Void) {
        let entry: TrackerEntry
        if let existing = todayEntry {
            entry = existing
        } else {
            entry = TrackerEntry(trackerID: tracker.id, date: DateUtils.startOfDay(.now))
            context.insert(entry)
        }
        update(entry)
        try? context.save()
    }
}
