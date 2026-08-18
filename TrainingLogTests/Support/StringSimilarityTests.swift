//
//  StringSimilarityTests.swift
//  TrainingLogTests
//

import XCTest
@testable import TrainingLog

final class StringSimilarityTests: XCTestCase {

    func testIdenticalStringsHaveZeroDistance() {
        XCTAssertEqual("Bench Press".levenshteinDistance(to: "Bench Press"), 0)
    }

    func testIsCaseInsensitive() {
        XCTAssertEqual("bench press".levenshteinDistance(to: "BENCH PRESS"), 0)
    }

    func testPluralizationIsASmallDistance() {
        // The motivating case: "Bicep Curl" vs "Bicep Curls" should read
        // as a near-duplicate, not a different exercise.
        XCTAssertEqual("Bicep Curl".levenshteinDistance(to: "Bicep Curls"), 1)
    }

    func testSingleTypoIsASmallDistance() {
        XCTAssertEqual("Bench Press".levenshteinDistance(to: "Bench Pres"), 1)
    }

    func testUnrelatedNamesHaveALargeDistance() {
        let distance = "Bench Press".levenshteinDistance(to: "Squat")
        XCTAssertGreaterThan(distance, 5)
    }

    func testEmptyStringDistanceEqualsOtherLength() {
        XCTAssertEqual("".levenshteinDistance(to: "Squat"), 5)
        XCTAssertEqual("Squat".levenshteinDistance(to: ""), 5)
    }
}
