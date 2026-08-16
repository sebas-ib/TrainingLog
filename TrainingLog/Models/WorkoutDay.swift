//
//  WorkoutDay.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftData

// A calendar day can have multiple workouts (AM/PM/etc.)
@Model
class WorkoutDay {
    var date: Date
    @Relationship(deleteRule: .cascade) var sessions: [WorkoutSession]
    
    init(date: Date) {
        self.date = date
        self.sessions = []
    }
}
