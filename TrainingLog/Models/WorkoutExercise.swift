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
    // SwiftData to-many relationships don't guarantee their array
    // preserves insertion order across fetches — this is what actually
    // pins display order in place, the same way ExerciseSet.order does
    // for sets within an exercise.
    var order: Int = 0
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]

    init(exercise: Exercise, loggedAt: Date = Date(), order: Int = 0) {
        self.loggedAt = loggedAt
        self.exercise = exercise
        self.order = order
        self.sets = []
    }
}
