//
//  ExerciseLoggingType.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation

enum ExerciseLoggingType: String, Codable, CaseIterable {
    case weightReps = "Weight & Reps"
    case bodyweightReps = "Bodyweight & Reps"
    case time = "Time"
    case timeWeight = "Time & Weight"
    case distanceTime = "Distance & Time"
    case repsOnly = "Reps Only"
    
    var usesReps: Bool {
        switch self {
        case .weightReps, .bodyweightReps, .repsOnly: return true
        default: return false
        }
    }
    
    var usesWeight: Bool {
        self == .weightReps || self == .timeWeight
    }
    
    var usesBodyWeightModifier: Bool {
        self == .bodyweightReps
    }
    
    var usesDuration: Bool {
        self == .time || self == .timeWeight || self == .distanceTime
    }
    
    var usesDistance: Bool {
        self == .distanceTime
    }
}
