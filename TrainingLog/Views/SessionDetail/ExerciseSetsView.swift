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
    @Bindable var workoutExercise: WorkoutExercise
    var focusedField: FocusState<SetField?>.Binding
    
    @Query(sort: \WorkoutExercise.loggedAt, order: .reverse) private var allWorkoutExercises: [WorkoutExercise]
    
    private var previousWorkoutExercise: WorkoutExercise? {
        allWorkoutExercises.first {
            $0.exercise.persistentModelID == workoutExercise.exercise.persistentModelID &&
            $0.persistentModelID != workoutExercise.persistentModelID &&
            $0.loggedAt < workoutExercise.loggedAt
        }
    }
    
    private func previousSet(forOrder order: Int) -> ExerciseSet? {
        previousWorkoutExercise?.sets.sorted(by: { $0.order < $1.order }).first { $0.order == order }
    }
    
    var body: some View {
        let sortedSets = workoutExercise.sets.sorted(by: { $0.order < $1.order })

        ForEach(sortedSets, id: \.id) { set in
            SetRowView(
                set: set,
                loggingType: workoutExercise.exercise.loggingType,
                focusedField: focusedField,
                previousSet: previousSet(forOrder: set.order)
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
        try? modelContext.save()
    }
    
    private func deleteSets(at offsets: IndexSet) {
        let sorted = workoutExercise.sets.sorted(by: { $0.order < $1.order })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        workoutExercise.sets.removeAll { deletedSet in
            offsets.contains { sorted[$0].persistentModelID == deletedSet.persistentModelID }
        }
        renumberSets()
        try? modelContext.save()
    }
    
    private func renumberSets() {
        let sorted = workoutExercise.sets.sorted(by: { $0.order < $1.order })
        for (index, set) in sorted.enumerated() {
            set.order = index + 1
        }
    }
}
