//
//  WorkoutCalculations.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation

enum WorkoutCalculations {
    
    /// Total volume for a single exercise = sum of (reps × weight) across all its sets
    static func volume(for workoutExercise: WorkoutExercise) -> Double {
        guard workoutExercise.exercise.loggingType.usesWeight else { return 0 }
        return workoutExercise.sets.reduce(0) { total, set in
            total + (Double(set.reps) * set.weight)
        }
    }
    
    /// Total volume across all exercises in a session
    static func totalVolume(for session: WorkoutSession) -> Double {
        session.exercises.reduce(0) { total, exercise in
            total + volume(for: exercise)
        }
    }
    
    /// Total number of sets logged in a session
    static func totalSets(for session: WorkoutSession) -> Int {
        session.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
    
    /// Total reps across all sets in a session
    static func totalReps(for session: WorkoutSession) -> Int {
        session.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + $1.reps }
        }
    }
    
    /// Aggregated totals across every session in a day
    static func totalVolume(for day: WorkoutDay) -> Double {
        day.sessions.reduce(0) { $0 + totalVolume(for: $1) }
    }
    
    static func totalSets(for day: WorkoutDay) -> Int {
        day.sessions.reduce(0) { $0 + totalSets(for: $1) }
    }
    
    static func totalReps(for day: WorkoutDay) -> Int {
        day.sessions.reduce(0) { $0 + totalReps(for: $1) }
    }
    
    /// Heaviest single set weight in a session (a simple "top set" indicator)
    static func maxWeight(for session: WorkoutSession) -> Double {
        session.exercises
            .flatMap { $0.sets }
            .map { $0.weight }
            .max() ?? 0
    }

    /// Returns a dictionary mapping each calendar day (start-of-day) to a simple
    /// "intensity" score (based on total sets logged that day) for consistency tracking.
    static func activityByDay(from workoutDays: [WorkoutDay]) -> [Date: Int] {
        var result: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for day in workoutDays {
            let key = calendar.startOfDay(for: day.date)
            let sets = totalSets(for: day)
            result[key, default: 0] += sets
        }
        
        return result
    }
    
    /// Total volume broken down by muscle group for a session.
    /// Exercises that don't use weight (bodyweight, time, distance, reps-only
    /// types) contribute 0 and are skipped entirely, rather than showing up
    /// as a misleading "0 lbs" entry for a muscle group that was still
    /// actually trained.
    static func volumeByMuscleGroup(for session: WorkoutSession) -> [MuscleGroup: Double] {
        var result: [MuscleGroup: Double] = [:]

        for workoutExercise in session.exercises {
            let exerciseVolume = volume(for: workoutExercise)
            guard exerciseVolume > 0 else { continue }
            let group = workoutExercise.exercise.muscleGroup
            result[group, default: 0] += exerciseVolume
        }

        return result
    }
    
    /// Same, aggregated across every session in a day
    static func volumeByMuscleGroup(for day: WorkoutDay) -> [MuscleGroup: Double] {
        var result: [MuscleGroup: Double] = [:]
        
        for session in day.sessions {
            let sessionBreakdown = volumeByMuscleGroup(for: session)
            for (group, volume) in sessionBreakdown {
                result[group, default: 0] += volume
            }
        }
        
        return result
    }
}
