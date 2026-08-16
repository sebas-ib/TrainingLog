//
//  ExerciseSeedDataTests.swift
//  TrainingLogTests
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//

import XCTest
import SwiftData
@testable import TrainingLog

@MainActor
final class ExerciseSeedDataTests: XCTestCase {

    // MARK: - Starter Data

    func testStarterExerciseCount() {
        XCTAssertEqual(
            ExerciseSeedData.starterExercises.count,
            29
        )
    }

    func testStarterExercisesContainExpectedExercises() {
        let names = ExerciseSeedData.starterExercises.map(\.name)

        XCTAssertTrue(names.contains("Bench Press"))
        XCTAssertTrue(names.contains("Squat"))
        XCTAssertTrue(names.contains("Pull-Up"))
        XCTAssertTrue(names.contains("Bicep Curl"))
        XCTAssertTrue(names.contains("Plank"))
    }

    func testStarterExerciseConfigurations() {
        let benchPress = starterExercise(named: "Bench Press")

        XCTAssertEqual(benchPress?.primary, .chest)
        XCTAssertEqual(benchPress?.secondary, .arms)
        XCTAssertEqual(
            benchPress?.type,
            ExerciseLoggingType.weightReps
        )

        let pullUp = starterExercise(named: "Pull-Up")

        XCTAssertEqual(pullUp?.primary, .back)
        XCTAssertEqual(pullUp?.secondary, .arms)
        XCTAssertEqual(
            pullUp?.type,
            ExerciseLoggingType.bodyweightReps
        )

        let plank = starterExercise(named: "Plank")

        XCTAssertEqual(plank?.primary, .core)
        XCTAssertNil(plank?.secondary)
        XCTAssertEqual(
            plank?.type,
            ExerciseLoggingType.time
        )
    }

    // MARK: - Seeding

    func testSeedIfNeededCreatesStarterExercises() throws {
        let context = try makeModelContext()

        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)

        XCTAssertEqual(
            exercises.count,
            ExerciseSeedData.starterExercises.count
        )

        for entry in ExerciseSeedData.starterExercises {
            let exercise = try XCTUnwrap(
                exercises.first { $0.name == entry.name }
            )

            XCTAssertFalse(exercise.isCustom)

            XCTAssertEqual(
                exercise.muscleGroup,
                entry.primary
            )

            XCTAssertEqual(
                exercise.secondaryMuscleGroup,
                entry.secondary
            )

            XCTAssertEqual(
                exercise.loggingType,
                entry.type
            )
        }
    }

    func testSeedIfNeededDoesNotDuplicateExercises() throws {
        let context = try makeModelContext()

        ExerciseSeedData.seedIfNeeded(context: context)
        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)

        XCTAssertEqual(
            exercises.count,
            ExerciseSeedData.starterExercises.count
        )
    }

    func testSeedIfNeededDoesNotSeedWhenExercisesAlreadyExist() throws {
        let context = try makeModelContext()

        let customExercise = Exercise(
            name: "My Custom Exercise",
            isCustom: true,
            muscleGroup: .chest,
            secondaryMuscleGroup: nil,
            loggingType: ExerciseLoggingType.weightReps
        )

        context.insert(customExercise)
        try context.save()

        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)

        XCTAssertEqual(exercises.count, 1)

        XCTAssertEqual(
            exercises.first?.name,
            "My Custom Exercise"
        )

        XCTAssertTrue(
            exercises.first?.isCustom == true
        )
    }

    // MARK: - Helpers

    private func makeModelContext() throws -> ModelContext {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )

        let container = try ModelContainer(
            for: Exercise.self,
            configurations: configuration
        )

        return ModelContext(container)
    }

    private func fetchExercises(
        context: ModelContext
    ) throws -> [Exercise] {
        try context.fetch(
            FetchDescriptor<Exercise>()
        )
    }

    private func starterExercise(
        named name: String
    ) -> (
        name: String,
        primary: MuscleGroup,
        secondary: MuscleGroup?,
        type: ExerciseLoggingType
    )? {
        ExerciseSeedData.starterExercises.first {
            $0.name == name
        }
    }
}
