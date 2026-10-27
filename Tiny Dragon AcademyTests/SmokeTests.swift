//
//  SmokeTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class SmokeTests: XCTestCase {
    func test_initialStateHasSparkle() {
        XCTAssertTrue(AppProgressState.initial().dragons.contains { $0.id == "sparkle" })
    }
}
