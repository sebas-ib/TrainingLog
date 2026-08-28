//
//  VariantProgressTests.swift
//  TrainingLogTests
//

import XCTest
@testable import TrainingLog

/// Phase 2 behavior: personal records and chart series split by variation
/// rather than by exercise.
final class VariantProgressTests: XCTestCase {

    private func legPress() -> Exercise {
        Exercise(
            name: "Leg Press",
            primaryMuscleTargets: [.quads],
            secondaryMuscleTargets: [.glutes],
            loggingType: .weightReps
        )
    }

    private func session(
        _ exercise: Exercise,
        _ variant: ExerciseVariant?,
        weight: Double,
        daysAgo: Int
    ) -> WorkoutExercise {
        let instance = WorkoutExercise(
            exercise: exercise,
            variant: variant,
            loggedAt: Date().addingTimeInterval(TimeInterval(-86_400 * daysAgo))
        )
        instance.sets = [ExerciseSet(reps: 8, weight: weight, order: 1)]
        return instance
    }

    // MARK: - Personal records

    func testAVariantsRecordIsNotMaskedByAHeavierSiblingVariant() {
        let exercise = legPress()
        let lowFoot = ExerciseVariant(name: "Low Foot")
        let highFoot = ExerciseVariant(name: "High Foot")

        let history = [
            session(exercise, lowFoot, weight: 400, daysAgo: 30),
            session(exercise, lowFoot, weight: 420, daysAgo: 20),
            // High foot is lighter by nature — but 300 → 320 is still a
            // record *for high foot*, and grouping by exercise alone
            // would let the 420 low-foot best hide it forever.
            session(exercise, highFoot, weight: 300, daysAgo: 10),
            session(exercise, highFoot, weight: 320, daysAgo: 5)
        ]

        let records = WorkoutCalculations.recentPersonalRecords(from: history)

        XCTAssertEqual(records.count, 2)
        XCTAssertNotNil(records.first { $0.variant === highFoot && $0.value == 320 })
        XCTAssertNotNil(records.first { $0.variant === lowFoot && $0.value == 420 })
    }

    func testRecordsFromDifferentVariantsAreLabelledDistinctly() throws {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot")

        let history = [
            session(exercise, highFoot, weight: 300, daysAgo: 10),
            session(exercise, highFoot, weight: 320, daysAgo: 5)
        ]

        let record = try XCTUnwrap(
            WorkoutCalculations.recentPersonalRecords(from: history).first
        )
        XCTAssertEqual(record.displayName, "Leg Press · High Foot")
    }

    func testUnspecifiedInstancesFormTheirOwnRecordBucket() {
        let exercise = legPress()
        let highFoot = ExerciseVariant(name: "High Foot")

        let history = [
            session(exercise, nil, weight: 500, daysAgo: 30),
            session(exercise, highFoot, weight: 300, daysAgo: 10),
            session(exercise, highFoot, weight: 320, daysAgo: 5)
        ]

        let records = WorkoutCalculations.recentPersonalRecords(from: history)

        // The untagged 500 must not suppress high foot's 320.
        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(records[0].variant === highFoot)
    }

    func testRecordReportsTheVariantsResolvedLoggingType() {
        let plank = Exercise(
            name: "Plank",
            primaryMuscleTargets: [.abs],
            loggingType: .time
        )
        let weighted = ExerciseVariant(name: "Weighted", loggingType: .timeWeight)

        let first = WorkoutExercise(exercise: plank, variant: weighted, loggedAt: Date().addingTimeInterval(-86_400))
        first.sets = [ExerciseSet(order: 1, durationSeconds: 60)]
        let second = WorkoutExercise(exercise: plank, variant: weighted)
        second.sets = [ExerciseSet(order: 1, durationSeconds: 90)]

        let record = WorkoutCalculations.recentPersonalRecords(from: [first, second]).first

        XCTAssertEqual(record?.loggingType, .timeWeight)
    }

    // MARK: - Variation series

    func testSeriesAreSplitPerVariantAndOrderedByVariantOrder() {
        let exercise = legPress()
        let mid = ExerciseVariant(name: "Mid Foot", order: 1)
        let high = ExerciseVariant(name: "High Foot", order: 2)
        exercise.variants = [high, mid]

        let history = [
            session(exercise, high, weight: 300, daysAgo: 5),
            session(exercise, mid, weight: 400, daysAgo: 3)
        ]

        let series = WorkoutCalculations.variationSeries(for: exercise, in: history)

        XCTAssertEqual(series.map(\.label), ["Mid Foot", "High Foot"])
    }

    func testUnspecifiedSeriesComesLast() {
        let exercise = legPress()
        let mid = ExerciseVariant(name: "Mid Foot", order: 1)
        exercise.variants = [mid]

        let history = [
            session(exercise, nil, weight: 350, daysAgo: 6),
            session(exercise, mid, weight: 400, daysAgo: 3)
        ]

        let series = WorkoutCalculations.variationSeries(for: exercise, in: history)

        XCTAssertEqual(series.map(\.label), ["Mid Foot", WorkoutCalculations.unspecifiedVariationLabel])
    }

    func testSeriesOmitsVariantsWithNoLoggedHistory() {
        let exercise = legPress()
        let mid = ExerciseVariant(name: "Mid Foot", order: 1)
        let unused = ExerciseVariant(name: "Wide Stance", order: 2)
        exercise.variants = [mid, unused]

        let series = WorkoutCalculations.variationSeries(
            for: exercise,
            in: [session(exercise, mid, weight: 400, daysAgo: 3)]
        )

        XCTAssertEqual(series.map(\.label), ["Mid Foot"])
    }

    func testSharesLoggingTypeIsFalseWhenAVariantIsMeasuredDifferently() {
        let plank = Exercise(name: "Plank", primaryMuscleTargets: [.abs], loggingType: .time)
        let standard = ExerciseVariant(name: "Standard", order: 1)
        let weighted = ExerciseVariant(name: "Weighted", order: 2, loggingType: .timeWeight)
        plank.variants = [standard, weighted]

        let history = [
            WorkoutExercise(exercise: plank, variant: standard),
            WorkoutExercise(exercise: plank, variant: weighted)
        ]

        let series = WorkoutCalculations.variationSeries(for: plank, in: history)

        XCTAssertEqual(series.count, 2)
        XCTAssertFalse(WorkoutCalculations.sharesLoggingType(series))
    }

    func testSharesLoggingTypeIsTrueForOrdinaryVariants() {
        let exercise = legPress()
        let mid = ExerciseVariant(name: "Mid Foot", order: 1)
        let high = ExerciseVariant(name: "High Foot", order: 2, primaryMuscleTargets: [.hamstrings])
        exercise.variants = [mid, high]

        let series = WorkoutCalculations.variationSeries(
            for: exercise,
            in: [
                session(exercise, mid, weight: 400, daysAgo: 3),
                session(exercise, high, weight: 300, daysAgo: 2)
            ]
        )

        XCTAssertTrue(WorkoutCalculations.sharesLoggingType(series))
    }

    func testSeriesIgnoresOtherExercises() {
        let exercise = legPress()
        let other = Exercise(name: "Squat", primaryMuscleTargets: [.quads])

        let series = WorkoutCalculations.variationSeries(
            for: exercise,
            in: [
                session(exercise, nil, weight: 400, daysAgo: 3),
                session(other, nil, weight: 300, daysAgo: 2)
            ]
        )

        XCTAssertEqual(series.count, 1)
        XCTAssertEqual(series.first?.instances.count, 1)
    }
}
