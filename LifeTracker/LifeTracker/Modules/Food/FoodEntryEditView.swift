import SwiftUI
import SwiftData

struct FoodEntryEditView: View {
    var entry: FoodEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var mealName: String
    @State private var date: Date
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @State private var note: String

    init(entry: FoodEntry? = nil) {
        self.entry = entry
        _mealName = State(initialValue: entry?.mealName ?? "")
        _date = State(initialValue: entry?.date ?? .now)
        _caloriesText = State(initialValue: entry?.calories.map { String($0) } ?? "")
        _proteinText = State(initialValue: entry?.proteinGrams.map { String($0) } ?? "")
        _carbsText = State(initialValue: entry?.carbsGrams.map { String($0) } ?? "")
        _fatText = State(initialValue: entry?.fatGrams.map { String($0) } ?? "")
        _note = State(initialValue: entry?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    TextField("Name", text: $mealName)
                    DatePicker("Time", selection: $date)
                }
                Section("Nutrition (optional)") {
                    TextField("Calories", text: $caloriesText).keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $proteinText).keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbsText).keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fatText).keyboardType(.decimalPad)
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(entry == nil ? "Log a Meal" : "Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(mealName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let resolved = entry ?? FoodEntry(mealName: mealName)
        resolved.mealName = mealName
        resolved.date = date
        resolved.calories = Double(caloriesText)
        resolved.proteinGrams = Double(proteinText)
        resolved.carbsGrams = Double(carbsText)
        resolved.fatGrams = Double(fatText)
        resolved.note = note.isEmpty ? nil : note
        if entry == nil { context.insert(resolved) }
        try? context.save()
        dismiss()
    }
}
