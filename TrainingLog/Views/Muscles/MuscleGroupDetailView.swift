//
//  MuscleGroupDetailView.swift
//  TrainingLog
//

import SwiftUI

/// Drilldown from `BalanceView` for one muscle group: this week's
/// progress against its editable weekly target, a breakdown by specific
/// muscle (tap one to see which exercises trained it), and a flat list
/// of every exercise that trained the group at all.
struct MuscleGroupDetailView: View {
    let group: MuscleGroup
    let breakdown: WorkoutCalculations.MuscleGroupBreakdown
    let weekLabel: String
    let goalStore: WeeklyGoalStore

    @State private var goal: Int

    init(
        group: MuscleGroup,
        breakdown: WorkoutCalculations.MuscleGroupBreakdown,
        weekLabel: String,
        goalStore: WeeklyGoalStore
    ) {
        self.group = group
        self.breakdown = breakdown
        self.weekLabel = weekLabel
        self.goalStore = goalStore
        _goal = State(initialValue: goalStore.goal(for: group))
    }

    private var targets: [(target: MuscleTarget, count: Int)] {
        MuscleTarget.allCases
            .filter { $0.muscleGroup == group }
            .compactMap { target in
                let count = breakdown.setCount(for: target)
                return count > 0 ? (target, count) : nil
            }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(breakdown.totalSets) of \(goal) sets")
                            .font(Theme.title(.title2))
                        if breakdown.totalSets >= goal {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                        Spacer()
                    }

                    GoalProgressBar(current: breakdown.totalSets, goal: goal)
                        .frame(height: 10)

                    Stepper(
                        "Weekly Target: \(goal) sets",
                        value: $goal,
                        in: 1...50
                    )
                    .onChange(of: goal) { _, newValue in
                        goalStore.setGoal(newValue, for: group)
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Text(weekLabel)
            }

            if !targets.isEmpty || breakdown.untaggedSets > 0 {
                Section("By Muscle") {
                    ForEach(targets, id: \.target) { entry in
                        NavigationLink {
                            MuscleExerciseListView(
                                title: entry.target.rawValue,
                                exercises: breakdown.exercises(for: entry.target)
                            )
                        } label: {
                            muscleRow(name: entry.target.rawValue, count: entry.count)
                        }
                    }

                    if breakdown.untaggedSets > 0 {
                        NavigationLink {
                            MuscleExerciseListView(
                                title: "Untagged",
                                exercises: breakdown.untaggedExercises
                            )
                        } label: {
                            muscleRow(name: "Untagged", count: breakdown.untaggedSets)
                        }
                    }
                }
            }

            Section("Exercises This Week") {
                if breakdown.allExercises.isEmpty {
                    Text("Nothing logged for \(group.rawValue.lowercased()) yet this week.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(breakdown.allExercises) { contribution in
                        NavigationLink {
                            ExerciseProgressView(exercise: contribution.exercise)
                        } label: {
                            muscleRow(name: contribution.exercise.name, count: contribution.sets)
                        }
                    }
                }
            }
        }
        .navigationTitle(group.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func muscleRow(name: String, count: Int) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text("\(count) set\(count == 1 ? "" : "s")")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
