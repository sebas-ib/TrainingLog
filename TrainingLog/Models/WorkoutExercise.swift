//
//  WorkoutExercise.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftData

// A logged exercise instance within a session, linked to the library
@Model
class WorkoutExercise {
    var loggedAt: Date
    var exercise: Exercise
    /// Which way this movement was performed, if the user specified one.
    /// nil is a first-class state — "logged without picking a variant" —
    /// and stays legal even for exercises that have variants.
    var variant: ExerciseVariant? = nil
    // SwiftData to-many relationships don't guarantee their array
    // preserves insertion order across fetches — this is what actually
    // pins display order in place, the same way ExerciseSet.order does
    // for sets within an exercise.
    var order: Int = 0
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]

    init(
        exercise: Exercise,
        variant: ExerciseVariant? = nil,
        loggedAt: Date = Date(),
        order: Int = 0
    ) {
        self.loggedAt = loggedAt
        self.exercise = exercise
        self.variant = variant
        self.order = order
        self.sets = []
    }

    // MARK: - Resolved Values
    //
    // Thin passthroughs over the `Exercise` resolvers, supplying this
    // instance's own variant — so call sites that already hold a
    // WorkoutExercise don't have to thread the pairing themselves.

    var resolvedPrimaryTargets: [MuscleTarget] {
        exercise.primaryTargets(for: variant)
    }

    var resolvedSecondaryTargets: [MuscleTarget] {
        exercise.secondaryTargets(for: variant)
    }

    var resolvedLoggingType: ExerciseLoggingType {
        exercise.loggingType(for: variant)
    }

    var resolvedDisplayName: String {
        exercise.displayName(for: variant)
    }

    /// The broad group this instance actually trained. Derived from the
    /// resolved targets so a variation that retargets the movement is
    /// counted where it belongs, falling back to the exercise's own group
    /// when neither it nor its variation names specific muscles.
    var resolvedMuscleGroup: MuscleGroup {
        resolvedPrimaryTargets.first?.muscleGroup ?? exercise.muscleGroup
    }
}

extension WorkoutExercise: Orderable {}
