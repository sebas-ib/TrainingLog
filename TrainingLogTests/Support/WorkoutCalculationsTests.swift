//
//  WorkoutCalculationsTests.swift
//  TrainingLogTests
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//

import XCTest
import SwiftData
@testable import TrainingLog

@MainActor
final class WorkoutCalculationsTests: XCTestCase {

    // MARK: - Volume

    func testVolumeCalculatesRepsTimesWeight() {
        let exercise = makeWorkoutExercise(
            loggingType: .weightReps,
            sets: [
                makeSet(reps: 10, weight: 100)
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.volume(for: exercise),
            1000
        )
    }

    func testVolumeSumsMultipleSets() {
        let exercise = makeWorkoutExercise(
            loggingType: .weightReps,
            sets: [
                makeSet(reps: 10, weight: 100),
                makeSet(reps: 8, weight: 110),
                makeSet(reps: 6, weight: 120)
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.volume(for: exercise),
            2600
        )
    }

    func testVolumeReturnsZeroForExerciseWithoutWeight() {
        let exercise = makeWorkoutExercise(
            loggingType: .bodyweightReps,
            sets: [
                makeSet(reps: 10, weight: 0),
                makeSet(reps: 8, weight: 0)
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.volume(for: exercise),
            0
        )
    }

    func testVolumeReturnsZeroForEmptyExercise() {
        let exercise = makeWorkoutExercise(
            loggingType: .weightReps,
            sets: []
        )

        XCTAssertEqual(
            WorkoutCalculations.volume(for: exercise),
            0
        )
    }

    // MARK: - Session Totals

    func testTotalVolumeForSession() {
        let firstExercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 10, weight: 100),
                makeSet(reps: 10, weight: 100)
            ]
        )

        let secondExercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 8, weight: 50)
            ]
        )

        let session = makeSession(
            exercises: [
                firstExercise,
                secondExercise
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalVolume(for: session),
            2400
        )
    }

    func testTotalVolumeIgnoresExercisesWithoutWeight() {
        let weightedExercise = makeWorkoutExercise(
            loggingType: .weightReps,
            sets: [
                makeSet(reps: 10, weight: 100)
            ]
        )

        let bodyweightExercise = makeWorkoutExercise(
            loggingType: .bodyweightReps,
            sets: [
                makeSet(reps: 20)
            ]
        )

        let session = makeSession(
            exercises: [
                weightedExercise,
                bodyweightExercise
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalVolume(for: session),
            1000
        )
    }

    func testTotalSetsForSession() {
        let firstExercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 10, weight: 100),
                makeSet(reps: 8, weight: 100)
            ]
        )

        let secondExercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 12, weight: 50)
            ]
        )

        let session = makeSession(
            exercises: [
                firstExercise,
                secondExercise
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalSets(for: session),
            3
        )
    }

    func testTotalRepsForSession() {
        let firstExercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 10, weight: 100),
                makeSet(reps: 8, weight: 100)
            ]
        )

        let secondExercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 12, weight: 50)
            ]
        )

        let session = makeSession(
            exercises: [
                firstExercise,
                secondExercise
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalReps(for: session),
            30
        )
    }

    // MARK: - Maximum Weight

    func testMaxWeightReturnsHeaviestSet() {
        let exercise = makeWorkoutExercise(
            sets: [
                makeSet(reps: 10, weight: 100),
                makeSet(reps: 8, weight: 135),
                makeSet(reps: 5, weight: 125)
            ]
        )

        let session = makeSession(
            exercises: [exercise]
        )

        XCTAssertEqual(
            WorkoutCalculations.maxWeight(for: session),
            135
        )
    }

    func testMaxWeightReturnsZeroForEmptySession() {
        let session = makeSession(
            exercises: []
        )

        XCTAssertEqual(
            WorkoutCalculations.maxWeight(for: session),
            0
        )
    }

    // MARK: - Day Totals

    func testTotalVolumeForDay() {
        let firstSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    sets: [
                        makeSet(reps: 10, weight: 100)
                    ]
                )
            ]
        )

        let secondSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    sets: [
                        makeSet(reps: 5, weight: 100)
                    ]
                )
            ]
        )

        let day = makeDay(
            sessions: [
                firstSession,
                secondSession
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalVolume(for: day),
            1500
        )
    }

    func testTotalSetsForDay() {
        let firstSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    sets: [
                        makeSet(reps: 10, weight: 100),
                        makeSet(reps: 8, weight: 100)
                    ]
                )
            ]
        )

        let secondSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    sets: [
                        makeSet(reps: 12, weight: 50)
                    ]
                )
            ]
        )

        let day = makeDay(
            sessions: [
                firstSession,
                secondSession
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalSets(for: day),
            3
        )
    }

    func testTotalRepsForDay() {
        let firstSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    sets: [
                        makeSet(reps: 10, weight: 100),
                        makeSet(reps: 8, weight: 100)
                    ]
                )
            ]
        )

        let secondSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    sets: [
                        makeSet(reps: 12, weight: 50)
                    ]
                )
            ]
        )

        let day = makeDay(
            sessions: [
                firstSession,
                secondSession
            ]
        )

        XCTAssertEqual(
            WorkoutCalculations.totalReps(for: day),
            30
        )
    }

    // MARK: - Activity By Day

    func testActivityByDayGroupsSetsByDate() {
        let calendar = Calendar.current

        let firstDate = calendar.startOfDay(
            for: Date(timeIntervalSince1970: 1_000_000)
        )

        let secondDate = calendar.date(
            byAdding: .day,
            value: 1,
            to: firstDate
        )!

        let firstDay = makeDay(
            date: firstDate,
            sessions: [
                makeSession(
                    exercises: [
                        makeWorkoutExercise(
                            sets: [
                                makeSet(reps: 10),
                                makeSet(reps: 8)
                            ]
                        )
                    ]
                )
            ]
        )

        let secondDay = makeDay(
            date: secondDate,
            sessions: [
                makeSession(
                    exercises: [
                        makeWorkoutExercise(
                            sets: [
                                makeSet(reps: 10)
                            ]
                        )
                    ]
                )
            ]
        )

        let result = WorkoutCalculations.activityByDay(
            from: [firstDay, secondDay]
        )

        XCTAssertEqual(result[firstDate], 2)
        XCTAssertEqual(result[secondDate], 1)
    }

    func testActivityByDayCombinesMultipleDaysWithSameStartOfDay() {
        let calendar = Calendar.current

        let firstDate = calendar.date(
            bySettingHour: 8,
            minute: 0,
            second: 0,
            of: Date()
        )!

        let secondDate = calendar.date(
            bySettingHour: 18,
            minute: 0,
            second: 0,
            of: firstDate
        )!

        let firstDay = makeDay(
            date: firstDate,
            sessions: [
                makeSession(
                    exercises: [
                        makeWorkoutExercise(
                            sets: [
                                makeSet(reps: 10),
                                makeSet(reps: 8)
                            ]
                        )
                    ]
                )
            ]
        )

        let secondDay = makeDay(
            date: secondDate,
            sessions: [
                makeSession(
                    exercises: [
                        makeWorkoutExercise(
                            sets: [
                                makeSet(reps: 12)
                            ]
                        )
                    ]
                )
            ]
        )

        let result = WorkoutCalculations.activityByDay(
            from: [firstDay, secondDay]
        )

        let expectedKey = calendar.startOfDay(for: firstDate)

        XCTAssertEqual(result[expectedKey], 3)
    }

    // MARK: - Muscle Group Volume

    func testVolumeByMuscleGroupForSession() {
        let chestExercise = makeWorkoutExercise(
            muscleGroup: .chest,
            sets: [
                makeSet(reps: 10, weight: 100)
            ]
        )

        let backExercise = makeWorkoutExercise(
            muscleGroup: .back,
            sets: [
                makeSet(reps: 10, weight: 80)
            ]
        )

        let session = makeSession(
            exercises: [
                chestExercise,
                backExercise
            ]
        )

        let result = WorkoutCalculations.volumeByMuscleGroup(
            for: session
        )

        XCTAssertEqual(result[.chest], 1000)
        XCTAssertEqual(result[.back], 800)
    }

    func testVolumeByMuscleGroupCombinesSameMuscleGroup() {
        let firstChestExercise = makeWorkoutExercise(
            muscleGroup: .chest,
            sets: [
                makeSet(reps: 10, weight: 100)
            ]
        )

        let secondChestExercise = makeWorkoutExercise(
            muscleGroup: .chest,
            sets: [
                makeSet(reps: 8, weight: 100)
            ]
        )

        let session = makeSession(
            exercises: [
                firstChestExercise,
                secondChestExercise
            ]
        )

        let result = WorkoutCalculations.volumeByMuscleGroup(
            for: session
        )

        XCTAssertEqual(result[.chest], 1800)
    }

    func testVolumeByMuscleGroupForDayCombinesSessions() {
        let firstSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    muscleGroup: .chest,
                    sets: [
                        makeSet(reps: 10, weight: 100)
                    ]
                )
            ]
        )

        let secondSession = makeSession(
            exercises: [
                makeWorkoutExercise(
                    muscleGroup: .chest,
                    sets: [
                        makeSet(reps: 5, weight: 100)
                    ]
                )
            ]
        )

        let day = makeDay(
            sessions: [
                firstSession,
                secondSession
            ]
        )

        let result = WorkoutCalculations.volumeByMuscleGroup(
            for: day
        )

        XCTAssertEqual(result[.chest], 1500)
    }

    // MARK: - Helpers

    private func makeSet(
        reps: Int = 0,
        weight: Double = 0,
        order: Int = 1
    ) -> ExerciseSet {
        ExerciseSet(
            reps: reps,
            weight: weight,
            order: order
        )
    }

    private func makeWorkoutExercise(
        muscleGroup: MuscleGroup = .chest,
        loggingType: ExerciseLoggingType = .weightReps,
        sets: [ExerciseSet]
    ) -> WorkoutExercise {
        let exercise = Exercise(
            name: "Test Exercise",
            isCustom: false,
            muscleGroup: muscleGroup,
            loggingType: loggingType
        )

        let workoutExercise = WorkoutExercise(
            exercise: exercise
        )

        workoutExercise.sets = sets

        return workoutExercise
    }

    private func makeSession(
        exercises: [WorkoutExercise]
    ) -> WorkoutSession {
        let session = WorkoutSession(
            startTime: Date(),
            name: "Test Workout"
        )

        session.exercises = exercises

        return session
    }

    private func makeDay(
        date: Date = Date(),
        sessions: [WorkoutSession]
    ) -> WorkoutDay {
        let day = WorkoutDay(
            date: date
        )

        day.sessions = sessions

        return day
    }
}
