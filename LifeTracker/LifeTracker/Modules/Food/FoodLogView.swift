import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Query(sort: \FoodEntry.date, order: .reverse) private var entries: [FoodEntry]
    @Environment(\.modelContext) private var context
    @ObservedObject private var health = HealthKitManager.shared

    @State private var showingAdd = false
    @State private var editingEntry: FoodEntry?
    @State private var healthCalories: Double = 0
    @State private var healthWater: Double = 0

    var body: some View {
        List {
            if health.isAuthorized {
                Section("From Health Today") {
                    HStack {
                        Text("Dietary Energy")
                        Spacer()
                        Text("\(Int(healthCalories)) kcal").foregroundStyle(Theme.ColorToken.secondaryText)
                    }
                    HStack {
                        Text("Water")
                        Spacer()
                        Text(String(format: "%.1f L", healthWater)).foregroundStyle(Theme.ColorToken.secondaryText)
                    }
                }
            }

            Section("Logged Meals") {
                if entries.isEmpty {
                    Text("No meals logged yet.")
                        .foregroundStyle(Theme.ColorToken.secondaryText)
                } else {
                    ForEach(entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(entry.mealName)
                                        .foregroundStyle(Theme.ColorToken.primaryText)
                                    Spacer()
                                    if let calories = entry.calories {
                                        Text("\(Int(calories)) kcal")
                                            .font(Theme.Typography.caption)
                                            .foregroundStyle(Theme.ColorToken.secondaryText)
                                    }
                                }
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.ColorToken.secondaryText)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("Food")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { FoodEntryEditView() }
        .sheet(item: $editingEntry) { entry in FoodEntryEditView(entry: entry) }
        .task {
            if health.isAuthorized {
                async let calories = health.todayDietaryEnergy()
                async let water = health.todayDietaryWaterLiters()
                healthCalories = await calories
                healthWater = await water
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(entries[index]) }
        try? context.save()
    }
}
