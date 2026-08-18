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

// MARK: - Input Editing

extension ExerciseSet {

    /// Copies whichever input values `loggingType` actually uses from
    /// `source` — order, takenToFailure, and anything else stay
    /// untouched. Single source of truth for "what counts as this set's
    /// input data" by logging type, shared by the row's "Fill with
    /// previous" action and by auto-filling a freshly-added set from the
    /// prior session's matching set.
    func copyValues(from source: ExerciseSet, loggingType: ExerciseLoggingType) {
        switch loggingType {
        case .weightReps:
            reps = source.reps
            weight = source.weight

        case .bodyweightReps:
            reps = source.reps
            bodyWeightModifier = source.bodyWeightModifier

        case .time:
            durationSeconds = source.durationSeconds

        case .timeWeight:
            durationSeconds = source.durationSeconds
            weight = source.weight

        case .distanceTime:
            distance = source.distance
            durationSeconds = source.durationSeconds

        case .repsOnly:
            reps = source.reps
        }
    }

    /// Zeroes out whichever input values `loggingType` uses — the
    /// counterpart to copyValues(from:), used by the row's "Clear"
    /// action.
    func clearValues(loggingType: ExerciseLoggingType) {
        switch loggingType {
        case .weightReps:
            reps = 0
            weight = 0

        case .bodyweightReps:
            reps = 0
            bodyWeightModifier = 0

        case .time:
            durationSeconds = 0

        case .timeWeight:
            durationSeconds = 0
            weight = 0

        case .distanceTime:
            distance = 0
            durationSeconds = 0

        case .repsOnly:
            reps = 0
        }
    }

    /// Whether every input value `loggingType` uses is still at its
    /// zero/empty default. Drives whether a set row offers "Fill with
    /// previous" (nothing entered yet) or "Clear" (something has).
    func hasEmptyValues(loggingType: ExerciseLoggingType) -> Bool {
        switch loggingType {
        case .weightReps:
            return reps == 0 && weight == 0

        case .bodyweightReps:
            return reps == 0 && bodyWeightModifier == 0

        case .time:
            return durationSeconds == 0

        case .timeWeight:
            return durationSeconds == 0 && weight == 0

        case .distanceTime:
            return distance == 0 && durationSeconds == 0

        case .repsOnly:
            return reps == 0
        }
    }
}
