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
            69
        )
    }

    func testStarterExercisesContainExpectedExercises() {
        let names = ExerciseSeedData.starterExercises.map(\.name)

        XCTAssertTrue(names.contains("Bench Press"))
        XCTAssertTrue(names.contains("Squat"))
        XCTAssertTrue(names.contains("Pull-Up"))
        XCTAssertTrue(names.contains("Bicep Curl"))
        XCTAssertTrue(names.contains("Plank"))
        XCTAssertTrue(names.contains("Running"))
    }

    func testStarterExerciseConfigurations() {
        let benchPress = starterExercise(named: "Bench Press")

        XCTAssertEqual(benchPress?.primary, [.middleChest])
        XCTAssertEqual(benchPress?.secondary, [.frontDelts, .tricepsLateralHead, .tricepsMedialHead])
        XCTAssertEqual(
            benchPress?.type,
            ExerciseLoggingType.weightReps
        )

        let pullUp = starterExercise(named: "Pull-Up")

        XCTAssertEqual(pullUp?.primary, [.lats])
        XCTAssertEqual(pullUp?.secondary, [.bicepsLongHead, .bicepsShortHead])
        XCTAssertEqual(
            pullUp?.type,
            ExerciseLoggingType.bodyweightReps
        )

        let plank = starterExercise(named: "Plank")

        XCTAssertEqual(plank?.primary, [.abs])
        XCTAssertEqual(plank?.secondary, [.obliques])
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
                exercise.primaryMuscleTargets,
                entry.primary
            )

            XCTAssertEqual(
                exercise.secondaryMuscleTargets,
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

    func testSeedIfNeededAddsStarterExercisesAlongsideExistingCustomExercise() throws {
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

        XCTAssertEqual(
            exercises.count,
            ExerciseSeedData.starterExercises.count + 1
        )

        let custom = try XCTUnwrap(
            exercises.first { $0.name == "My Custom Exercise" }
        )
        XCTAssertTrue(custom.isCustom)
        XCTAssertEqual(custom.muscleGroup, .chest)
    }

    func testSeedIfNeededBackfillsUntaggedNonCustomExercise() throws {
        let context = try makeModelContext()

        // Simulates a device seeded before target-level detail existed:
        // a non-custom exercise sharing a starter name, but with no
        // muscle targets yet.
        let staleExercise = Exercise(
            name: "Bench Press",
            isCustom: false,
            muscleGroup: .chest,
            secondaryMuscleGroup: nil,
            loggingType: .weightReps
        )
        context.insert(staleExercise)
        try context.save()

        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)

        XCTAssertEqual(
            exercises.count,
            ExerciseSeedData.starterExercises.count
        )

        let benchPress = try XCTUnwrap(
            exercises.first { $0.name == "Bench Press" }
        )
        XCTAssertEqual(benchPress.primaryMuscleTargets, [.middleChest])
        XCTAssertEqual(benchPress.secondaryMuscleTargets, [.frontDelts, .tricepsLateralHead, .tricepsMedialHead])
    }

    func testSeedIfNeededDoesNotOverwriteCustomExerciseWithMatchingName() throws {
        let context = try makeModelContext()

        let customExercise = Exercise(
            name: "Bench Press",
            isCustom: true,
            muscleGroup: .biceps,
            secondaryMuscleGroup: nil,
            loggingType: .weightReps
        )
        context.insert(customExercise)
        try context.save()

        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)
        let benchPress = try XCTUnwrap(
            exercises.first { $0.name == "Bench Press" }
        )

        XCTAssertTrue(benchPress.isCustom)
        XCTAssertTrue(benchPress.primaryMuscleTargets.isEmpty)
        XCTAssertEqual(benchPress.muscleGroup, .biceps)
    }

    // MARK: - Renaming a seeded exercise

    func testSeedIfNeededStampsSeedNameOnStarterExercises() throws {
        let context = try makeModelContext()

        ExerciseSeedData.seedIfNeeded(context: context)

        let benchPress = try XCTUnwrap(
            try fetchExercises(context: context).first { $0.name == "Bench Press" }
        )

        XCTAssertEqual(benchPress.seedName, "Bench Press")
    }

    func testRenamedStarterExerciseIsNotReseededAsADuplicate() throws {
        let context = try makeModelContext()

        ExerciseSeedData.seedIfNeeded(context: context)

        let benchPress = try XCTUnwrap(
            try fetchExercises(context: context).first { $0.name == "Bench Press" }
        )
        benchPress.name = "BP"
        try context.save()

        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)

        // The rename must not resurrect a second "Bench Press".
        XCTAssertEqual(exercises.count, ExerciseSeedData.starterExercises.count)
        XCTAssertNil(exercises.first { $0.name == "Bench Press" })
        XCTAssertEqual(exercises.filter { $0.seedName == "Bench Press" }.count, 1)
    }

    func testSeedIfNeededBackfillsSeedNameOnPreExistingRowsBeforeRename() throws {
        let context = try makeModelContext()

        // A row seeded before `seedName` existed: non-custom, matching a
        // starter name, but with no seed identity recorded yet.
        let legacy = Exercise(
            name: "Squat",
            isCustom: false,
            muscleGroup: .legs,
            secondaryMuscleGroup: nil,
            loggingType: .weightReps
        )
        context.insert(legacy)
        try context.save()
        XCTAssertNil(legacy.seedName)

        // First launch after the update stamps the identity...
        ExerciseSeedData.seedIfNeeded(context: context)
        XCTAssertEqual(legacy.seedName, "Squat")

        // ...so a later rename is safe from then on.
        legacy.name = "Back Squat"
        try context.save()
        ExerciseSeedData.seedIfNeeded(context: context)

        let exercises = try fetchExercises(context: context)
        XCTAssertEqual(exercises.count, ExerciseSeedData.starterExercises.count)
        XCTAssertNil(exercises.first { $0.name == "Squat" })
    }

    func testSeedIfNeededDoesNotStampSeedNameOnCustomExercise() throws {
        let context = try makeModelContext()

        let custom = Exercise(
            name: "Bench Press",
            isCustom: true,
            muscleGroup: .biceps,
            secondaryMuscleGroup: nil,
            loggingType: .weightReps
        )
        context.insert(custom)
        try context.save()

        ExerciseSeedData.seedIfNeeded(context: context)

        // A user's own exercise never inherits a starter's identity —
        // otherwise it would permanently shadow the real starter.
        XCTAssertNil(custom.seedName)
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
        primary: [MuscleTarget],
        secondary: [MuscleTarget],
        type: ExerciseLoggingType
    )? {
        ExerciseSeedData.starterExercises.first {
            $0.name == name
        }
    }
}
