import SwiftUI
import SwiftData

struct GoalsSummaryCard: View {
    @Query private var goals: [Goal]

    private var active: Int { goals.filter { $0.status == .active }.count }
    private var completed: Int { goals.filter { $0.status == .completed }.count }
    private var total: Int { goals.filter { $0.status != .archived }.count }
    private var completionRate: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    var body: some View {
        Card {
            SectionHeader(title: "Goals")
            HStack(spacing: Theme.Spacing.lg) {
                stat(value: "\(active)", label: "Active")
                stat(value: "\(completed)", label: "Completed")
                stat(value: "\(Int(completionRate * 100))%", label: "Completion Rate")
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.Typography.title)
            Text(label).font(Theme.Typography.caption).foregroundStyle(Theme.ColorToken.secondaryText)
        }
    }
}
