//
//  VariantAttributionTests.swift
//  TrainingLogTests
//

import XCTest
@testable import TrainingLog

/// Phase 3 behavior: the Balance tab attributes sets through the
/// variation's muscles rather than the parent exercise's.
final class VariantAttributionTests: XCTestCase {

    private let week = Date(timeIntervalSince1970: 1_700_000_000)

    private var range: Range<Date> {
        week.addingTimeInterval(-86_400)..<week.addingTimeInterval(86_400)
    }

    private func legPress() -> Exercise {
        Exercise(
            name: "Leg Press",
            primaryMuscleTargets: [.quads],
            secondaryMuscleTargets: [.glutes],
            loggingType: .weightReps
        )
    }

    private func logged(
        _ exercise: Exercise,
        _ variant: ExerciseVariant?,
        sets: Int
    ) -> WorkoutExercise {
        let instance = WorkoutExercise(exercise: exercise, variant: variant, loggedAt: week)
        instance.sets = (1...sets).map { ExerciseSet(reps: 8, weight: 100, order: $0) }
        return instance
    }

    // MARK: - Attribution

    func testRetargetingVariantMovesSetsOffTheParentsMuscle() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(
            name: "High Foot",
            primaryMuscleTargets: [.hamstrings, .glutes]
        )

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [logged(exercise, highFoot, sets: 3)],
            in: range
        )

        let legs = breakdown[.legs]
        XCTAssertEqual(legs?.setCount(for: .hamstrings), 3)
        XCTAssertEqual(legs?.setCount(for: .glutes), 3)
        // The parent's quads must not receive these sets.
        XCTAssertEqual(legs?.setCount(for: .quads), 0)
    }

    func testInheritingVariantStillCountsTowardTheParentsMuscle() {
        let exercise = legPress()
        let midFoot = ExerciseVariant(name: "Mid Foot")

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [logged(exercise, midFoot, sets: 4)],
            in: range
        )

        XCTAssertEqual(breakdown[.legs]?.setCount(for: .quads), 4)
    }

    func testTwoVariantsOfOneMovementSplitAcrossTheirOwnMuscles() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot", primaryMuscleTargets: [.hamstrings])
        let lowFoot = ExerciseVariant(name: "Low Foot")

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [
                logged(exercise, highFoot, sets: 3),
                logged(exercise, lowFoot, sets: 2)
            ],
            in: range
        )

        let legs = breakdown[.legs]
        XCTAssertEqual(legs?.setCount(for: .hamstrings), 3)
        XCTAssertEqual(legs?.setCount(for: .quads), 2)
        XCTAssertEqual(legs?.totalSets, 5)
    }

    func testVariantCanMoveSetsIntoADifferentMuscleGroupEntirely() {
        let dip = Exercise(
            name: "Dip",
            primaryMuscleTargets: [.lowerChest],
            loggingType: .bodyweightReps
        )
        let triceps = ExerciseVariant(
            name: "Triceps",
            primaryMuscleTargets: [.tricepsLateralHead, .tricepsMedialHead]
        )

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [logged(dip, triceps, sets: 3)],
            in: range
        )

        XCTAssertEqual(breakdown[.triceps]?.totalSets, 3)
        XCTAssertNil(breakdown[.chest])
    }

    // MARK: - Contributions

    func testContributionsAreSplitAndLabelledPerVariation() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot", primaryMuscleTargets: [.hamstrings])
        let lowFoot = ExerciseVariant(name: "Low Foot")

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [
                logged(exercise, highFoot, sets: 3),
                logged(exercise, lowFoot, sets: 2)
            ],
            in: range
        )

        let all = breakdown[.legs]?.allExercises ?? []

        // One row per variation, not one merged "Leg Press — 5 sets".
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.map(\.displayName), ["Leg Press · High Foot", "Leg Press · Low Foot"])
        XCTAssertEqual(all.map(\.sets), [3, 2])
    }

    func testContributionsForASpecificMuscleOnlyIncludeVariationsThatTrainIt() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot", primaryMuscleTargets: [.hamstrings])
        let lowFoot = ExerciseVariant(name: "Low Foot")

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [
                logged(exercise, highFoot, sets: 3),
                logged(exercise, lowFoot, sets: 2)
            ],
            in: range
        )

        let hamstringRows = breakdown[.legs]?.exercises(for: .hamstrings) ?? []
        XCTAssertEqual(hamstringRows.map(\.displayName), ["Leg Press · High Foot"])

        let quadRows = breakdown[.legs]?.exercises(for: .quads) ?? []
        XCTAssertEqual(quadRows.map(\.displayName), ["Leg Press · Low Foot"])
    }

    func testUnspecifiedAndVariantInstancesAreSeparateContributions() {
        let exercise = legPress()
        let lowFoot = ExerciseVariant(name: "Low Foot")

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [
                logged(exercise, nil, sets: 2),
                logged(exercise, lowFoot, sets: 3)
            ],
            in: range
        )

        let all = breakdown[.legs]?.allExercises ?? []
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(Set(all.map(\.displayName)), ["Leg Press", "Leg Press · Low Foot"])
        XCTAssertEqual(breakdown[.legs]?.setCount(for: .quads), 5)
    }

    // MARK: - Untagged bucket

    func testUntaggedExerciseWithoutTargetsStillLandsInItsGroup() {
        let exercise = Exercise(name: "Mystery Machine", muscleGroup: .back)

        let breakdown = WorkoutCalculations.muscleBreakdown(
            from: [logged(exercise, nil, sets: 2)],
            in: range
        )

        XCTAssertEqual(breakdown[.back]?.untaggedSets, 2)
        XCTAssertEqual(breakdown[.back]?.totalSets, 2)
    }

    // MARK: - Volume

    func testVolumeByMuscleGroupFollowsTheResolvedGroup() {
        let dip = Exercise(
            name: "Dip",
            primaryMuscleTargets: [.lowerChest],
            loggingType: .weightReps
        )
        let triceps = ExerciseVariant(
            name: "Triceps",
            primaryMuscleTargets: [.tricepsLateralHead]
        )

        let session = WorkoutSession(startTime: week)
        session.exercises = [logged(dip, triceps, sets: 2)]

        let volumes = WorkoutCalculations.volumeByMuscleGroup(for: session)

        // 2 sets × 8 reps × 100 lbs, attributed to the variation's group.
        XCTAssertEqual(volumes[.triceps], 1600)
        XCTAssertNil(volumes[.chest])
    }
}
