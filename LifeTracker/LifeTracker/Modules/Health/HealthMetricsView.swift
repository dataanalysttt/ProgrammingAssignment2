import SwiftUI
import HealthKit

struct HealthMetricsView: View {
    @ObservedObject private var health = HealthKitManager.shared
    @State private var workouts: [HKWorkout] = []

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if !health.isAuthorized {
                    Card {
                        Text("Life Tracker needs permission to read Health data.")
                            .font(Theme.Typography.body)
                        Button("Allow Health Access") {
                            Task {
                                try? await health.requestAuthorization()
                                await loadWorkouts()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.ColorToken.accent)
                    }
                } else {
                    ForEach(HealthMetricKind.allCases) { kind in
                        MetricTrendChartView(source: .health(kind))
                    }

                    if !workouts.isEmpty {
                        Card {
                            SectionHeader(title: "Recent Workouts")
                            ForEach(workouts, id: \.uuid) { workout in
                                HStack {
                                    Text(workout.workoutActivityType.name)
                                    Spacer()
                                    Text(workout.startDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.ColorToken.secondaryText)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Health & Fitness")
        .task {
            if health.isAuthorized { await loadWorkouts() }
        }
    }

    private func loadWorkouts() async {
        workouts = (try? await health.recentWorkouts()) ?? []
    }
}

private extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength Training"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
}
