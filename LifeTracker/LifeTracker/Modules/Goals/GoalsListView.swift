import SwiftUI
import SwiftData

struct GoalsListView: View {
    @Query(sort: \Goal.createdAt, order: .reverse) private var allGoals: [Goal]
    @Environment(\.modelContext) private var context

    @State private var filter: GoalStatus = .active
    @State private var showingAddGoal = false

    private var filteredGoals: [Goal] {
        allGoals.filter { $0.status == filter }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                Picker("Filter", selection: $filter) {
                    ForEach(GoalStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

                if filteredGoals.isEmpty {
                    EmptyStateView(
                        systemImage: "target",
                        title: filter == .active ? "No active goals" : "Nothing here yet",
                        message: filter == .active
                            ? "Set your first goal — with or without a linked metric — and track it over time."
                            : "Goals you complete or archive show up here.",
                        actionTitle: filter == .active ? "Add a Goal" : nil
                    ) {
                        showingAddGoal = true
                    }
                    .padding(.top, Theme.Spacing.xl)
                } else {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(filteredGoals) { goal in
                            NavigationLink(value: goal) {
                                GoalRow(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Goals")
        .navigationDestination(for: Goal.self) { goal in
            GoalDetailView(goal: goal)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            GoalEditView(goal: nil)
        }
    }
}

private struct GoalRow: View {
    let goal: Goal
    @Environment(\.modelContext) private var context
    @State private var progress: Double?

    var body: some View {
        Card {
            HStack {
                Image(systemName: goal.category.systemImage)
                    .foregroundStyle(Theme.ColorToken.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(Theme.Typography.body.weight(.medium))
                    if let targetDate = goal.targetDate {
                        Text("Due \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.ColorToken.secondaryText)
                    }
                }
                Spacer()
                if goal.status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.ColorToken.positive)
                }
            }
            if let progress, goal.status == .active {
                ProgressBar(fraction: progress)
                Text("\(Int(progress * 100))% complete")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.secondaryText)
            }
        }
        .task(id: goal.id) {
            progress = await GoalProgressCalculator.progress(for: goal, context: context)
        }
    }
}
