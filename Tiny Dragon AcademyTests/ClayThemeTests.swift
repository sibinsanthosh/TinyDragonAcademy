//
//  ClayThemeTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
import UIKit
@testable import Tiny_Dragon_Academy

@MainActor
final class ClayThemeTests: XCTestCase {
    func test_baloo2_isBundledAndRegistered() {
        XCTAssertTrue(FontRegistry.registerBundledFonts(), "Baloo 2 should register from the app bundle")
        XCTAssertNotNil(UIFont(name: FontRegistry.displayFamilyPostScript, size: 20))
        XCTAssertTrue(UIFont.familyNames.contains(FontRegistry.displayFamily))
    }

    func test_registration_isIdempotent() {
        XCTAssertTrue(FontRegistry.registerBundledFonts())
        XCTAssertTrue(FontRegistry.registerBundledFonts())
    }
}
