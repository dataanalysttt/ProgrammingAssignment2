import SwiftUI
import SwiftData
import Charts

struct GoalDetailView: View {
    @Bindable var goal: Goal

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double?
    @State private var series: [(date: Date, value: Double)] = []
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Card {
                    HStack {
                        Image(systemName: goal.category.systemImage)
                            .foregroundStyle(Theme.ColorToken.accent)
                        Text(goal.category.displayName)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.ColorToken.secondaryText)
                        Spacer()
                        if let targetDate = goal.targetDate {
                            Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.ColorToken.secondaryText)
                        }
                    }
                    Text(goal.title)
                        .font(Theme.Typography.largeTitle)
                    if let description = goal.goalDescription, !description.isEmpty {
                        Text(description)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.ColorToken.secondaryText)
                    }
                }

                if let progress {
                    Card {
                        SectionHeader(title: "Progress")
                        ProgressBar(fraction: progress)
                        Text("\(Int(progress * 100))% complete")
                            .font(Theme.Typography.body.weight(.medium))
                    }
                }

                if !series.isEmpty {
                    Card {
                        SectionHeader(title: "Over Time")
                        Chart(series, id: \.date) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                                .foregroundStyle(Theme.ColorToken.accent)
                            AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                                .foregroundStyle(Theme.ColorToken.accent.opacity(0.1))
                        }
                        .frame(height: 180)
                    }
                }

                Card {
                    if goal.status == .active {
                        Button("Mark as Complete") { markComplete() }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.ColorToken.accent)
                        Button("Archive") { goal.status = .archived; try? context.save() }
                            .buttonStyle(.bordered)
                    } else if goal.status == .completed, let completedAt = goal.completedAt {
                        Label("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Theme.ColorToken.positive)
                    }
                    Button("Delete Goal", role: .destructive) { showingDeleteConfirmation = true }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) { GoalEditView(goal: goal) }
        .confirmationDialog("Delete this goal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteGoal() }
        }
        .task(id: goal.id) { await refresh() }
    }

    private func refresh() async {
        progress = await GoalProgressCalculator.progress(for: goal, context: context)
        series = await GoalProgressCalculator.progressSeries(for: goal, context: context)
    }

    private func markComplete() {
        goal.status = .completed
        goal.completedAt = .now
        try? context.save()
    }

    private func deleteGoal() {
        context.delete(goal)
        try? context.save()
        dismiss()
    }
}
