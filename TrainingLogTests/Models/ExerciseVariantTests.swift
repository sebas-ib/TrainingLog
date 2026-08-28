//
//  ExerciseVariantTests.swift
//  TrainingLogTests
//

import XCTest
@testable import TrainingLog

final class ExerciseVariantTests: XCTestCase {

    private func legPress() -> Exercise {
        Exercise(
            name: "Leg Press",
            primaryMuscleTargets: [.quads],
            secondaryMuscleTargets: [.glutes, .hamstrings],
            loggingType: .weightReps
        )
    }

    // MARK: - No variant

    func testNilVariantResolvesToTheParent() {
        let exercise = legPress()

        XCTAssertEqual(exercise.primaryTargets(for: nil), [.quads])
        XCTAssertEqual(exercise.secondaryTargets(for: nil), [.glutes, .hamstrings])
        XCTAssertEqual(exercise.loggingType(for: nil), .weightReps)
        XCTAssertEqual(exercise.displayName(for: nil), "Leg Press")
    }

    // MARK: - Inheriting variant

    func testVariantWithNoOverridesInheritsEverything() {
        let exercise = legPress()
        let midFoot = ExerciseVariant(name: "Mid Foot")

        XCTAssertEqual(exercise.primaryTargets(for: midFoot), [.quads])
        XCTAssertEqual(exercise.secondaryTargets(for: midFoot), [.glutes, .hamstrings])
        XCTAssertEqual(exercise.loggingType(for: midFoot), .weightReps)
    }

    // MARK: - Target override

    func testVariantTargetsReplaceRatherThanLayerOnTheParent() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(
            name: "High Foot",
            primaryMuscleTargets: [.hamstrings, .glutes],
            secondaryMuscleTargets: [.quads]
        )

        // Replacement, not union: a high-foot press trains hamstrings
        // *instead of* quads, so quads must not survive as a primary.
        XCTAssertEqual(exercise.primaryTargets(for: highFoot), [.hamstrings, .glutes])
        XCTAssertFalse(exercise.primaryTargets(for: highFoot).contains(.quads))
    }

    func testOverridingPrimaryAlsoReplacesSecondary() {
        let exercise = legPress()
        // Overrides primary but leaves secondary empty — the parent's
        // secondaries must not leak back in, or the muscles the override
        // just removed would reappear.
        let highFoot = ExerciseVariant(
            name: "High Foot",
            primaryMuscleTargets: [.hamstrings]
        )

        XCTAssertEqual(exercise.secondaryTargets(for: highFoot), [])
    }

    func testSecondaryIsInheritedWhenPrimaryIsNotOverridden() {
        let exercise = legPress()
        let cosmetic = ExerciseVariant(name: "Paused")

        XCTAssertEqual(exercise.secondaryTargets(for: cosmetic), [.glutes, .hamstrings])
    }

    // MARK: - Logging type override

    func testVariantCanChangeLoggingType() {
        let plank = Exercise(
            name: "Plank",
            primaryMuscleTargets: [.abs],
            secondaryMuscleTargets: [.obliques],
            loggingType: .time
        )
        let weighted = ExerciseVariant(name: "Weighted", loggingType: .timeWeight)

        XCTAssertEqual(plank.loggingType(for: weighted), .timeWeight)
        // Targets are untouched by a format-only override.
        XCTAssertEqual(plank.primaryTargets(for: weighted), [.abs])
    }

    func testNilLoggingTypeInheritsTheParents() {
        let plank = Exercise(
            name: "Plank",
            primaryMuscleTargets: [.abs],
            loggingType: .time
        )
        let side = ExerciseVariant(name: "Side", primaryMuscleTargets: [.obliques])

        XCTAssertEqual(plank.loggingType(for: side), .time)
    }

    // MARK: - Display name

    func testDisplayNameAppendsRatherThanReplaces() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot")

        XCTAssertEqual(exercise.displayName(for: highFoot), "Leg Press · High Foot")
    }

    // MARK: - WorkoutExercise passthroughs

    func testWorkoutExerciseResolvesThroughItsOwnVariant() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(
            name: "High Foot",
            primaryMuscleTargets: [.hamstrings, .glutes],
            secondaryMuscleTargets: [.quads]
        )
        let logged = WorkoutExercise(exercise: exercise, variant: highFoot)

        XCTAssertEqual(logged.resolvedPrimaryTargets, [.hamstrings, .glutes])
        XCTAssertEqual(logged.resolvedSecondaryTargets, [.quads])
        XCTAssertEqual(logged.resolvedLoggingType, .weightReps)
        XCTAssertEqual(logged.resolvedDisplayName, "Leg Press · High Foot")
    }

    func testWorkoutExerciseWithoutVariantResolvesToTheParent() {
        let exercise = legPress()
        let logged = WorkoutExercise(exercise: exercise)

        XCTAssertEqual(logged.resolvedPrimaryTargets, [.quads])
        XCTAssertEqual(logged.resolvedDisplayName, "Leg Press")
    }

    // MARK: - Previous instance

    private func instance(
        _ exercise: Exercise,
        _ variant: ExerciseVariant?,
        daysAgo: Int
    ) -> WorkoutExercise {
        WorkoutExercise(
            exercise: exercise,
            variant: variant,
            loggedAt: Date().addingTimeInterval(TimeInterval(-86_400 * daysAgo))
        )
    }

    func testPreviousInstanceMatchesTheSameVariant() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot")

        let older = instance(exercise, highFoot, daysAgo: 7)
        let newer = instance(exercise, highFoot, daysAgo: 2)
        let current = instance(exercise, highFoot, daysAgo: 0)

        let found = WorkoutCalculations.previousInstance(
            of: current,
            in: [older, newer, current]
        )

        XCTAssertIdentical(found, newer)
    }

    func testPreviousInstanceIgnoresOtherVariantsOfTheSameExercise() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot")
        let lowFoot = ExerciseVariant(name: "Low Foot")

        let otherVariant = instance(exercise, lowFoot, daysAgo: 2)
        let current = instance(exercise, highFoot, daysAgo: 0)

        // A first-ever high-foot session must not inherit low-foot loads,
        // because the caller copies these values into the new set.
        XCTAssertNil(
            WorkoutCalculations.previousInstance(of: current, in: [otherVariant, current])
        )
    }

    func testPreviousInstanceDoesNotFallBackToUnspecified() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot")

        let untagged = instance(exercise, nil, daysAgo: 3)
        let current = instance(exercise, highFoot, daysAgo: 0)

        XCTAssertNil(
            WorkoutCalculations.previousInstance(of: current, in: [untagged, current])
        )
    }

    func testUnspecifiedInstanceMatchesOtherUnspecifiedOnes() {
        let exercise = legPress()
        let variantTagged = instance(exercise, ExerciseVariant(name: "High Foot"), daysAgo: 1)
        let untagged = instance(exercise, nil, daysAgo: 3)
        let current = instance(exercise, nil, daysAgo: 0)

        let found = WorkoutCalculations.previousInstance(
            of: current,
            in: [variantTagged, untagged, current]
        )

        XCTAssertIdentical(found, untagged)
    }

    // MARK: - Volume

    func testVolumeCountsAVariantThatAddsWeightToATimedExercise() {
        let plank = Exercise(
            name: "Plank",
            primaryMuscleTargets: [.abs],
            loggingType: .time
        )
        let weighted = ExerciseVariant(name: "Weighted", loggingType: .timeWeight)
        let logged = WorkoutExercise(exercise: plank, variant: weighted)
        logged.sets = [ExerciseSet(reps: 3, weight: 45, order: 1)]

        // The parent's .time type doesn't use weight; the variant's
        // .timeWeight does. Reading the parent here would score this 0.
        XCTAssertEqual(WorkoutCalculations.volume(for: logged), 135)
    }
}
