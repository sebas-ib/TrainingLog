//
//  UnitPreferenceTests.swift
//  TrainingLogTests
//

import XCTest
@testable import TrainingLog

final class UnitPreferenceTests: XCTestCase {

    // MARK: - DistanceUnit

    func testMilesConversionIsIdentity() {
        XCTAssertEqual(DistanceUnit.miles.convert(fromMiles: 5), 5)
        XCTAssertEqual(DistanceUnit.miles.convertToMiles(5), 5)
    }

    func testKilometersConversion() {
        let km = DistanceUnit.kilometers.convert(fromMiles: 1)
        XCTAssertEqual(km, 1.609344, accuracy: 0.0001)
    }

    func testKilometersRoundTrip() {
        let originalMiles = 3.5
        let km = DistanceUnit.kilometers.convert(fromMiles: originalMiles)
        let backToMiles = DistanceUnit.kilometers.convertToMiles(km)

        XCTAssertEqual(backToMiles, originalMiles, accuracy: 0.0001)
    }

    // MARK: - UnitSettings.distanceUnit follows the weight unit

    func testDistanceUnitFollowsLbs() {
        let settings = UnitSettings()
        settings.unit = .lbs

        XCTAssertEqual(settings.distanceUnit, .miles)
    }

    func testDistanceUnitFollowsKg() {
        let settings = UnitSettings()
        settings.unit = .kg

        XCTAssertEqual(settings.distanceUnit, .kilometers)
    }
}
