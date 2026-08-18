//
//  ExerciseSetEditingTests.swift
//  TrainingLogTests
//

import XCTest
@testable import TrainingLog

final class ExerciseSetEditingTests: XCTestCase {

    // MARK: - copyValues(from:loggingType:)

    func testCopyValuesForWeightReps() {
        let target = ExerciseSet(order: 1)
        let source = ExerciseSet(reps: 10, weight: 135, order: 1)

        target.copyValues(from: source, loggingType: .weightReps)

        XCTAssertEqual(target.reps, 10)
        XCTAssertEqual(target.weight, 135)
    }

    func testCopyValuesForBodyweightRepsDoesNotTouchWeight() {
        let target = ExerciseSet(weight: 999, order: 1)
        let source = ExerciseSet(reps: 8, order: 1, bodyWeightModifier: -25)

        target.copyValues(from: source, loggingType: .bodyweightReps)

        XCTAssertEqual(target.reps, 8)
        XCTAssertEqual(target.bodyWeightModifier, -25)
        XCTAssertEqual(target.weight, 999) // untouched — not part of this logging type
    }

    func testCopyValuesForDistanceTime() {
        let target = ExerciseSet(order: 1)
        let source = ExerciseSet(order: 1, durationSeconds: 600, distance: 1.5)

        target.copyValues(from: source, loggingType: .distanceTime)

        XCTAssertEqual(target.distance, 1.5)
        XCTAssertEqual(target.durationSeconds, 600)
    }

    func testCopyValuesLeavesOrderAndFailureUntouched() {
        let target = ExerciseSet(order: 3, takenToFailure: true)
        let source = ExerciseSet(reps: 5, weight: 45, order: 1, takenToFailure: false)

        target.copyValues(from: source, loggingType: .weightReps)

        XCTAssertEqual(target.order, 3)
        XCTAssertTrue(target.takenToFailure)
    }

    // MARK: - clearValues(loggingType:)

    func testClearValuesForWeightReps() {
        let set = ExerciseSet(reps: 10, weight: 135, order: 1)

        set.clearValues(loggingType: .weightReps)

        XCTAssertEqual(set.reps, 0)
        XCTAssertEqual(set.weight, 0)
    }

    func testClearValuesForTimeWeightClearsBothDurationAndWeight() {
        let set = ExerciseSet(weight: 25, order: 1, durationSeconds: 90)

        set.clearValues(loggingType: .timeWeight)

        XCTAssertEqual(set.durationSeconds, 0)
        XCTAssertEqual(set.weight, 0)
    }

    func testClearValuesLeavesOrderAndFailureUntouched() {
        let set = ExerciseSet(reps: 10, weight: 135, order: 4, takenToFailure: true)

        set.clearValues(loggingType: .weightReps)

        XCTAssertEqual(set.order, 4)
        XCTAssertTrue(set.takenToFailure)
    }

    // MARK: - hasEmptyValues(loggingType:)

    func testHasEmptyValuesTrueForFreshSet() {
        let set = ExerciseSet(order: 1)

        XCTAssertTrue(set.hasEmptyValues(loggingType: .weightReps))
        XCTAssertTrue(set.hasEmptyValues(loggingType: .bodyweightReps))
        XCTAssertTrue(set.hasEmptyValues(loggingType: .time))
        XCTAssertTrue(set.hasEmptyValues(loggingType: .timeWeight))
        XCTAssertTrue(set.hasEmptyValues(loggingType: .distanceTime))
        XCTAssertTrue(set.hasEmptyValues(loggingType: .repsOnly))
    }

    func testHasEmptyValuesFalseOnceAnyRelevantFieldIsSet() {
        let repsOnly = ExerciseSet(reps: 1, order: 1)
        XCTAssertFalse(repsOnly.hasEmptyValues(loggingType: .weightReps))

        let weightOnly = ExerciseSet(weight: 1, order: 1)
        XCTAssertFalse(weightOnly.hasEmptyValues(loggingType: .weightReps))

        let durationOnly = ExerciseSet(order: 1, durationSeconds: 1)
        XCTAssertFalse(durationOnly.hasEmptyValues(loggingType: .time))
    }

    func testHasEmptyValuesIgnoresFieldsOutsideTheLoggingType() {
        // Weight is nonzero, but bodyweightReps doesn't look at weight —
        // only reps and bodyWeightModifier.
        let set = ExerciseSet(weight: 999, order: 1)

        XCTAssertTrue(set.hasEmptyValues(loggingType: .bodyweightReps))
    }

    func testHasEmptyValuesFalseForNegativeBodyWeightModifier() {
        // An assisted-pullup modifier of -25 is meaningfully "filled in,"
        // even though it's negative rather than positive.
        let set = ExerciseSet(order: 1, bodyWeightModifier: -25)

        XCTAssertFalse(set.hasEmptyValues(loggingType: .bodyweightReps))
    }
}
