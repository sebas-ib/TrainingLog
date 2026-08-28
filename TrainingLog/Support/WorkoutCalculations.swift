//
//  WorkoutCalculations.swift
//  workout-tracker
//
//  Created by Sebastian Ibarra-Perez on 8/9/26.
//
import Foundation
import SwiftData

enum WorkoutCalculations {
    
    /// Total volume for a single exercise = sum of (reps × weight) across all its sets
    static func volume(for workoutExercise: WorkoutExercise) -> Double {
        // Resolved, not the parent's own type: a variant can change how a
        // movement is logged (a weighted plank is timed *with* load), and
        // reading the parent here would score its volume as zero.
        guard workoutExercise.resolvedLoggingType.usesWeight else { return 0 }
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

    // MARK: - Previous Instance

    /// The last time this same exercise *and variant* was logged before
    /// `workoutExercise` — what drives the "fill with previous" hint and
    /// the auto-fill of a freshly-added set.
    ///
    /// Variant-scoped with no fallback to the parent's history on
    /// purpose. An incline and a flat set of the same movement carry very
    /// different loads, and the caller doesn't merely display this — it
    /// *copies* the values into the new set. Falling back would silently
    /// pre-fill a weight the user has never lifted in that position, so a
    /// variant's first session correctly shows nothing.
    static func previousInstance(
        of workoutExercise: WorkoutExercise,
        in history: [WorkoutExercise]
    ) -> WorkoutExercise? {
        history
            .filter {
                $0.exercise.persistentModelID == workoutExercise.exercise.persistentModelID
                    && $0.variant?.persistentModelID == workoutExercise.variant?.persistentModelID
                    && $0.persistentModelID != workoutExercise.persistentModelID
                    && $0.loggedAt < workoutExercise.loggedAt
            }
            .max { $0.loggedAt < $1.loggedAt }
    }

    // MARK: - Personal Records

    /// The single "how much/how far/how long" number a personal record is
    /// tracked against for one exercise instance, in storage units (lbs,
    /// miles, seconds) — unconverted, since only the caller knows which
    /// display unit applies. Mirrors the "primary" metric
    /// ExerciseProgressView already charts per logging type. nil if
    /// every set is still at its empty default (nothing to record).
    static func primaryMetricValue(for instance: WorkoutExercise) -> Double? {
        switch instance.exercise.loggingType {
        case .weightReps:
            let value = instance.sets.map(\.weight).max() ?? 0
            return value > 0 ? value : nil

        case .bodyweightReps, .repsOnly:
            let value = instance.sets.map(\.reps).max() ?? 0
            return value > 0 ? Double(value) : nil

        case .time, .timeWeight:
            let value = instance.sets.map(\.durationSeconds).max() ?? 0
            return value > 0 ? Double(value) : nil

        case .distanceTime:
            let value = instance.sets.map(\.distance).max() ?? 0
            return value > 0 ? value : nil
        }
    }

    /// Every point in an exercise's history where its primary metric beat
    /// every instance before it — i.e. every personal record ever set,
    /// oldest first. The very first logged instance never counts (there's
    /// nothing yet to beat), so a brand-new exercise's first session isn't
    /// noise here.
    static func personalRecordHistory(for exerciseHistory: [WorkoutExercise]) -> [PersonalRecord] {
        guard let exercise = exerciseHistory.first?.exercise else { return [] }

        let sorted = exerciseHistory.sorted { $0.loggedAt < $1.loggedAt }
        var best: Double?
        var records: [PersonalRecord] = []

        for instance in sorted {
            guard let value = primaryMetricValue(for: instance) else { continue }

            if let currentBest = best, value > currentBest {
                records.append(PersonalRecord(exercise: exercise, date: instance.loggedAt, value: value))
            }

            best = max(best ?? value, value)
        }

        return records
    }

    /// Every personal record across every exercise, most recent first —
    /// what a "recent PRs" feed shows.
    static func recentPersonalRecords(from allWorkoutExercises: [WorkoutExercise]) -> [PersonalRecord] {
        let byExercise = Dictionary(grouping: allWorkoutExercises) { $0.exercise.persistentModelID }

        return byExercise.values
            .flatMap { personalRecordHistory(for: $0) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Streaks

    /// Consecutive days up to and including today with at least one
    /// logged session — except a day that hasn't happened yet (it's only
    /// early evening, say) doesn't break a streak still very much in
    /// progress, so the count starts from yesterday instead when today
    /// has nothing logged yet.
    static func currentStreak(
        from workoutDays: [WorkoutDay],
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let activeDays = Set(
            workoutDays
                .filter { !$0.sessions.isEmpty }
                .map { calendar.startOfDay(for: $0.date) }
        )

        var cursor = calendar.startOfDay(for: today)
        if !activeDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    /// The longest run of consecutive logged days ever, not just the one
    /// currently in progress.
    static func longestStreak(from workoutDays: [WorkoutDay], calendar: Calendar = .current) -> Int {
        let activeDays = Set(
            workoutDays
                .filter { !$0.sessions.isEmpty }
                .map { calendar.startOfDay(for: $0.date) }
        )
        .sorted()

        guard !activeDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<activeDays.count {
            let expectedPrevious = calendar.date(byAdding: .day, value: -1, to: activeDays[i])
            if expectedPrevious == activeDays[i - 1] {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
        }

        return longest
    }

    // MARK: - Sets by Muscle

    /// One exercise's contribution — total sets logged over the range in
    /// question — to a muscle or muscle group.
    struct MuscleExerciseContribution: Identifiable {
        let exercise: Exercise
        let sets: Int
        var id: PersistentIdentifier { exercise.persistentModelID }
    }

    fileprivate struct ExerciseAccumulator {
        let exercise: Exercise
        var sets: Int = 0
    }

    /// Set totals for one `MuscleGroup` over a date range, broken down by
    /// which specific `MuscleTarget`s within it those sets came from, and
    /// which exercises contributed at each level. An exercise tagged
    /// with primary targets in multiple *different* groups counts fully
    /// toward each group (the same "counts for every muscle it trains"
    /// convention most set-volume trackers use); targets that land in
    /// the *same* group only count once toward that group's total, so
    /// one set can't inflate a group's number just because it was
    /// tagged with two muscles inside it. `untaggedSets`/
    /// `untaggedExercises` hold sets from exercises that landed in this
    /// group but don't have granular targets yet.
    struct MuscleGroupBreakdown {
        fileprivate(set) var totalSets: Int = 0
        fileprivate(set) var untaggedSets: Int = 0

        fileprivate var targetSetCounts: [MuscleTarget: Int] = [:]
        fileprivate var exerciseAccumulatorsByTarget: [MuscleTarget: [PersistentIdentifier: ExerciseAccumulator]] = [:]
        fileprivate var untaggedExerciseAccumulators: [PersistentIdentifier: ExerciseAccumulator] = [:]
        fileprivate var allExerciseAccumulators: [PersistentIdentifier: ExerciseAccumulator] = [:]

        init() {}

        func setCount(for target: MuscleTarget) -> Int {
            targetSetCounts[target] ?? 0
        }

        func exercises(for target: MuscleTarget) -> [MuscleExerciseContribution] {
            Self.sorted(exerciseAccumulatorsByTarget[target] ?? [:])
        }

        var untaggedExercises: [MuscleExerciseContribution] {
            Self.sorted(untaggedExerciseAccumulators)
        }

        /// Every exercise that contributed to this group this range,
        /// tagged or not — what tapping into the group itself shows.
        var allExercises: [MuscleExerciseContribution] {
            Self.sorted(allExerciseAccumulators)
        }

        private static func sorted(
            _ accumulators: [PersistentIdentifier: ExerciseAccumulator]
        ) -> [MuscleExerciseContribution] {
            accumulators.values
                .map { MuscleExerciseContribution(exercise: $0.exercise, sets: $0.sets) }
                .sorted {
                    $0.sets == $1.sets ? $0.exercise.name < $1.exercise.name : $0.sets > $1.sets
                }
        }
    }

    /// Sets logged within `range`, broken down by muscle group and, in
    /// turn, by the specific muscle(s) each contributing exercise
    /// targets.
    static func muscleBreakdown(
        from workoutExercises: [WorkoutExercise],
        in range: Range<Date>
    ) -> [MuscleGroup: MuscleGroupBreakdown] {
        var result: [MuscleGroup: MuscleGroupBreakdown] = [:]

        for workoutExercise in workoutExercises {
            guard range.contains(workoutExercise.loggedAt) else { continue }
            let setCount = workoutExercise.sets.count
            guard setCount > 0 else { continue }

            let exercise = workoutExercise.exercise
            let exerciseID = exercise.persistentModelID
            let targets = exercise.primaryMuscleTargets

            if targets.isEmpty {
                let group = exercise.muscleGroup
                var breakdown = result[group] ?? MuscleGroupBreakdown()
                breakdown.totalSets += setCount
                breakdown.untaggedSets += setCount
                breakdown.untaggedExerciseAccumulators[exerciseID, default: ExerciseAccumulator(exercise: exercise)].sets += setCount
                breakdown.allExerciseAccumulators[exerciseID, default: ExerciseAccumulator(exercise: exercise)].sets += setCount
                result[group] = breakdown
            } else {
                for (group, groupTargets) in Dictionary(grouping: targets, by: { $0.muscleGroup }) {
                    var breakdown = result[group] ?? MuscleGroupBreakdown()
                    breakdown.totalSets += setCount
                    breakdown.allExerciseAccumulators[exerciseID, default: ExerciseAccumulator(exercise: exercise)].sets += setCount

                    for target in groupTargets {
                        breakdown.targetSetCounts[target, default: 0] += setCount
                        var targetAccumulators = breakdown.exerciseAccumulatorsByTarget[target] ?? [:]
                        targetAccumulators[exerciseID, default: ExerciseAccumulator(exercise: exercise)].sets += setCount
                        breakdown.exerciseAccumulatorsByTarget[target] = targetAccumulators
                    }

                    result[group] = breakdown
                }
            }
        }

        return result
    }

    // MARK: - All-Time Totals

    static func allTimeWorkoutCount(from workoutDays: [WorkoutDay]) -> Int {
        workoutDays.reduce(0) { $0 + $1.sessions.count }
    }

    static func allTimeSetCount(from workoutDays: [WorkoutDay]) -> Int {
        workoutDays.reduce(0) { $0 + totalSets(for: $1) }
    }

    static func allTimeVolume(from workoutDays: [WorkoutDay]) -> Double {
        workoutDays.reduce(0) { $0 + totalVolume(for: $1) }
    }
}

/// A single personal-record moment — this exercise instance's primary
/// metric beat everything logged before it. `value` is in storage units
/// (lbs, miles, seconds); the caller converts for display the same way
/// ExerciseProgressView already does.
struct PersonalRecord: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let date: Date
    let value: Double
}
