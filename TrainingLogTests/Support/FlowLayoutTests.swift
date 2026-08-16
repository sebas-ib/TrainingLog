//
//  FlowLayoutTests.swift
//  TrainingLogTests
//
//  Created by Sebastian Ibarra-Perez on 8/15/26.
//

import XCTest
import SwiftUI
@testable import TrainingLog

final class FlowLayoutTests: XCTestCase {

    func testDefaultSpacing() {
        let layout = FlowLayout()

        XCTAssertEqual(layout.spacing, 8)
    }

    func testCustomSpacing() {
        let layout = FlowLayout(spacing: 12)

        XCTAssertEqual(layout.spacing, 12)
    }

    func testZeroSpacing() {
        let layout = FlowLayout(spacing: 0)

        XCTAssertEqual(layout.spacing, 0)
    }

    func testSpacingCanBeFractional() {
        let layout = FlowLayout(spacing: 5.5)

        XCTAssertEqual(layout.spacing, 5.5)
    }
}
