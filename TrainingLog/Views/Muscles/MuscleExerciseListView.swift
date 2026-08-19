//
//  MuscleExerciseListView.swift
//  TrainingLog
//

import SwiftUI

/// A simple list of exercises — and how many sets each contributed this
/// week — for one specific muscle or the "Untagged" catch-all. Reached
/// by tapping a muscle inside `MuscleGroupDetailView`. Tapping an
/// exercise pushes into its normal progress screen, same as everywhere
/// else in the app.
struct MuscleExerciseListView: View {
    let title: String
    let exercises: [WorkoutCalculations.MuscleExerciseContribution]

    var body: some View {
        List {
            if exercises.isEmpty {
                Text("Nothing logged for \(title.lowercased()) this week.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(exercises) { contribution in
                    NavigationLink {
                        ExerciseProgressView(exercise: contribution.exercise)
                    } label: {
                        HStack {
                            Text(contribution.exercise.name)
                            Spacer()
                            Text("\(contribution.sets) set\(contribution.sets == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
