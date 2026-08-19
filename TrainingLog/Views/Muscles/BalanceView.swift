//
//  BalanceView.swift
//  TrainingLog
//

import SwiftUI
import SwiftData

/// The "Balance" tab — sets logged this calendar week, one row per
/// muscle group with a progress bar against that group's (editable)
/// weekly target. Tap a group to see the breakdown by specific muscle,
/// adjust its target, or see which exercises trained it.
struct BalanceView: View {
    @StateObject private var goalStore = WeeklyGoalStore()
    @Query private var allWorkoutExercises: [WorkoutExercise]

    /// 0 = the current calendar week, -1 = last week, and so on. Capped
    /// at 0 going forward — there's nothing useful to show beyond the
    /// week in progress.
    @State private var weekOffset = 0

    private var isCurrentWeek: Bool { weekOffset == 0 }

    private var weekAnchorDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
    }

    private var weekInterval: DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: weekAnchorDate)
            ?? DateInterval(start: Date(), duration: 0)
    }

    private var weekRange: Range<Date> {
        weekInterval.start..<weekInterval.end
    }

    private var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let lastDay = Calendar.current.date(byAdding: .second, value: -1, to: weekInterval.end) ?? weekInterval.end
        return "\(formatter.string(from: weekInterval.start)) – \(formatter.string(from: lastDay))"
    }

    private var breakdownByGroup: [MuscleGroup: WorkoutCalculations.MuscleGroupBreakdown] {
        WorkoutCalculations.muscleBreakdown(from: allWorkoutExercises, in: weekRange)
    }

    private var displayedGroups: [MuscleGroup] {
        MuscleGroup.allCases.filter {
            $0 != .other || (breakdownByGroup[$0]?.totalSets ?? 0) > 0
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(displayedGroups, id: \.self) { group in
                        NavigationLink {
                            MuscleGroupDetailView(
                                group: group,
                                breakdown: breakdownByGroup[group] ?? .init(),
                                weekLabel: weekLabel,
                                goalStore: goalStore
                            )
                        } label: {
                            groupRow(group: group, breakdown: breakdownByGroup[group] ?? .init())
                        }
                    }
                } header: {
                    weekNavigationHeader
                } footer: {
                    Text("A set counts toward every muscle its exercise targets. Tap a muscle group to see the breakdown, adjust its weekly target, or see which exercises trained it.")
                }
            }
            .navigationTitle("Balance")
            .scrollContentBackground(.hidden)
            .background(SpinningGradientBackground())
        }
    }

    // MARK: - Week Navigation

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation { weekOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Previous week")

            Spacer()

            VStack(spacing: 1) {
                Text(isCurrentWeek ? "This Week" : weekLabel)
                    .font(.subheadline.weight(.semibold))
                if isCurrentWeek {
                    Text(weekLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Spacer()

            Button {
                withAnimation { weekOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(isCurrentWeek)
            .accessibilityLabel("Next week")
        }
        .buttonStyle(.plain)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Theme.accent)
        .textCase(nil)
        .padding(.vertical, 4)
    }

    // MARK: - Group Row

    private func groupRow(group: MuscleGroup, breakdown: WorkoutCalculations.MuscleGroupBreakdown) -> some View {
        let goal = goalStore.goal(for: group)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: group.icon)
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)

                Text(group.rawValue)

                Spacer()

                Text("\(breakdown.totalSets) / \(goal) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GoalProgressBar(current: breakdown.totalSets, goal: goal)
                .frame(height: 6)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    let schema = Schema([
        WorkoutDay.self,
        WorkoutSession.self,
        WorkoutExercise.self,
        ExerciseSet.self,
        Exercise.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    return BalanceView()
        .modelContainer(container)
}
