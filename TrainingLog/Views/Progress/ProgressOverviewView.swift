//
//  ProgressOverviewView.swift
//  TrainingLog
//

import SwiftUI
import SwiftData

/// Streak + all-time totals — the first thing the Progress tab shows,
/// self-contained the same way ConsistencyGraphView already is (its own
/// `@Query`, its own card).
struct ProgressOverviewView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    @Query private var workoutDays: [WorkoutDay]

    private var currentStreak: Int {
        WorkoutCalculations.currentStreak(from: workoutDays)
    }

    private var longestStreak: Int {
        WorkoutCalculations.longestStreak(from: workoutDays)
    }

    private var totalWorkouts: Int {
        WorkoutCalculations.allTimeWorkoutCount(from: workoutDays)
    }

    private var totalSets: Int {
        WorkoutCalculations.allTimeSetCount(from: workoutDays)
    }

    /// Compact so a lifetime total (easily 5-6 digits) doesn't force the
    /// tile to shrink its font or wrap.
    private var formattedVolume: String {
        let converted = unitSettings.unit.convert(fromLbs: WorkoutCalculations.allTimeVolume(from: workoutDays))
        switch converted {
        case 1_000_000...:
            return String(format: "%.1fM", converted / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", converted / 1_000)
        default:
            return String(format: "%.0f", converted)
        }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overview")
                .font(Theme.sectionHeader())
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 18) {
                StatTile(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    tint: .orange
                )
                StatTile(
                    icon: "trophy.fill",
                    value: "\(longestStreak)",
                    label: "Best Streak",
                    tint: .yellow
                )
                StatTile(
                    icon: "calendar",
                    value: "\(totalWorkouts)",
                    label: "Workouts"
                )
                StatTile(
                    icon: "list.bullet",
                    value: "\(totalSets)",
                    label: "Sets Logged"
                )
                StatTile(
                    icon: "scalemass.fill",
                    value: formattedVolume,
                    label: "\(unitSettings.unit.rawValue) Lifted"
                )
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
