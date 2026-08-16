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
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]
    
    init(exercise: Exercise, loggedAt: Date = Date()) {
        self.loggedAt = loggedAt
        self.exercise = exercise
        self.sets = []
    }
}
