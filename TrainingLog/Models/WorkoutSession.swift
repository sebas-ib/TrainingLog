//
//  WorkoutSession.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftData

// A single workout within a day (e.g. "Morning Push Day")
@Model
class WorkoutSession {
    var startTime: Date
    var name: String? // optional label, e.g. "Morning", "Leg Day"
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]
    
    init(startTime: Date, name: String? = nil) {
        self.startTime = startTime
        self.name = name
        self.exercises = []
    }
}
