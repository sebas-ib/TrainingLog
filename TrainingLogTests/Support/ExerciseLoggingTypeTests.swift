//
//  ExerciseLoggingTypeTests.swift
//  TrainingLog
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//
import XCTest
@testable import TrainingLog

final class ExerciseLoggingTypeTests: XCTestCase {

    func testUsesReps() {
        XCTAssertTrue(ExerciseLoggingType.weightReps.usesReps)
        XCTAssertTrue(ExerciseLoggingType.bodyweightReps.usesReps)
        XCTAssertTrue(ExerciseLoggingType.repsOnly.usesReps)

        XCTAssertFalse(ExerciseLoggingType.time.usesReps)
        XCTAssertFalse(ExerciseLoggingType.timeWeight.usesReps)
        XCTAssertFalse(ExerciseLoggingType.distanceTime.usesReps)
    }

    func testUsesWeight() {
        XCTAssertTrue(ExerciseLoggingType.weightReps.usesWeight)
        XCTAssertTrue(ExerciseLoggingType.timeWeight.usesWeight)

        XCTAssertFalse(ExerciseLoggingType.bodyweightReps.usesWeight)
        XCTAssertFalse(ExerciseLoggingType.time.usesWeight)
        XCTAssertFalse(ExerciseLoggingType.distanceTime.usesWeight)
        XCTAssertFalse(ExerciseLoggingType.repsOnly.usesWeight)
    }

    func testUsesBodyWeightModifier() {
        XCTAssertTrue(ExerciseLoggingType.bodyweightReps.usesBodyWeightModifier)

        XCTAssertFalse(ExerciseLoggingType.weightReps.usesBodyWeightModifier)
        XCTAssertFalse(ExerciseLoggingType.time.usesBodyWeightModifier)
        XCTAssertFalse(ExerciseLoggingType.timeWeight.usesBodyWeightModifier)
        XCTAssertFalse(ExerciseLoggingType.distanceTime.usesBodyWeightModifier)
        XCTAssertFalse(ExerciseLoggingType.repsOnly.usesBodyWeightModifier)
    }

    func testUsesDuration() {
        XCTAssertTrue(ExerciseLoggingType.time.usesDuration)
        XCTAssertTrue(ExerciseLoggingType.timeWeight.usesDuration)
        XCTAssertTrue(ExerciseLoggingType.distanceTime.usesDuration)

        XCTAssertFalse(ExerciseLoggingType.weightReps.usesDuration)
        XCTAssertFalse(ExerciseLoggingType.bodyweightReps.usesDuration)
        XCTAssertFalse(ExerciseLoggingType.repsOnly.usesDuration)
    }

    func testUsesDistance() {
        XCTAssertTrue(ExerciseLoggingType.distanceTime.usesDistance)

        XCTAssertFalse(ExerciseLoggingType.weightReps.usesDistance)
        XCTAssertFalse(ExerciseLoggingType.bodyweightReps.usesDistance)
        XCTAssertFalse(ExerciseLoggingType.time.usesDistance)
        XCTAssertFalse(ExerciseLoggingType.timeWeight.usesDistance)
        XCTAssertFalse(ExerciseLoggingType.repsOnly.usesDistance)
    }
}
