//
//  ExerciseSetsView.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import SwiftUI
import SwiftData

struct ExerciseSetsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var setTimers: SetTimerStore
    @Bindable var workoutExercise: WorkoutExercise
    var focusedField: FocusState<SetField?>.Binding
    @Binding var saveError: Error?

    @Query(sort: \WorkoutExercise.loggedAt, order: .reverse) private var allWorkoutExercises: [WorkoutExercise]
    
    private var previousWorkoutExercise: WorkoutExercise? {
        allWorkoutExercises.first {
            $0.exercise.persistentModelID == workoutExercise.exercise.persistentModelID &&
            $0.persistentModelID != workoutExercise.persistentModelID &&
            $0.loggedAt < workoutExercise.loggedAt
        }
    }
    
    private func previousSet(forOrder order: Int) -> ExerciseSet? {
        previousWorkoutExercise?.sets.sortedByOrder().first { $0.order == order }
    }

    var body: some View {
        let sortedSets = workoutExercise.sets.sortedByOrder()

        ForEach(sortedSets, id: \.id) { set in
            let previous = previousSet(forOrder: set.order)

            SetRowView(
                set: set,
                loggingType: workoutExercise.exercise.loggingType,
                exerciseName: workoutExercise.exercise.name,
                focusedField: focusedField,
                previousSet: previous,
                // Target defaults to what was done last time for this
                // exercise — only for a timer the store hasn't already
                // created, so the user's own +/- adjustments stick.
                timer: setTimers.timer(
                    for: set,
                    defaultTargetSeconds: previous?.durationSeconds ?? 0
                ),
                saveError: $saveError
            )
        }
        .onDelete(perform: deleteSets)

        Button {
            addSet()
        } label: {
            Label("Add Set", systemImage: "plus.circle")
        }
        .font(.subheadline)
    }

    private func addSet() {
        let nextOrder = (workoutExercise.sets.map(\.order).max() ?? 0) + 1
        let newSet = ExerciseSet(order: nextOrder)

        // Auto-fill from the previous session's matching set, same as
        // the row's own "Fill with previous" — the common case is
        // repeating a set with the same numbers, so the row should start
        // pre-filled (and offering "Clear") rather than empty.
        if let template = previousSet(forOrder: nextOrder) {
            newSet.copyValues(from: template, loggingType: workoutExercise.exercise.loggingType)
        }

        workoutExercise.sets.append(newSet)
        modelContext.save(reportingTo: $saveError)
    }

    private func deleteSets(at offsets: IndexSet) {
        let sorted = workoutExercise.sets.sortedByOrder()
        for index in offsets {
            setTimers.discard(sorted[index])
            modelContext.delete(sorted[index])
        }
        workoutExercise.sets.removeAll { deletedSet in
            offsets.contains { sorted[$0].persistentModelID == deletedSet.persistentModelID }
        }
        renumberSets()
        modelContext.save(reportingTo: $saveError)
    }

    private func renumberSets() {
        let sorted = workoutExercise.sets.sortedByOrder()
        for (index, set) in sorted.enumerated() {
            set.order = index + 1
        }
    }
}
