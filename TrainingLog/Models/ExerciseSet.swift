//
//  ExerciseSet.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftData

@Model
class ExerciseSet {
    var reps: Int
    var weight: Double               // used for weightReps AND timeWeight
    var order: Int
    var takenToFailure: Bool
    var durationSeconds: Int         // used for time, timeWeight, distanceTime
    var distance: Double             // used for distanceTime — stored in miles
    var bodyWeightModifier: Double   // used for bodyweightReps — +added / -assisted, stored in lbs
    
    init(
        reps: Int = 0,
        weight: Double = 0,
        order: Int,
        takenToFailure: Bool = false,
        durationSeconds: Int = 0,
        distance: Double = 0,
        bodyWeightModifier: Double = 0
    ) {
        self.reps = reps
        self.weight = weight
        self.order = order
        self.takenToFailure = takenToFailure
        self.durationSeconds = durationSeconds
        self.distance = distance
        self.bodyWeightModifier = bodyWeightModifier
    }
}
