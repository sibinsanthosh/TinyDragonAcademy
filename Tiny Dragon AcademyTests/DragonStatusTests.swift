//
//  DragonStatusTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class DragonStatusTests: XCTestCase {
    private let noon = TestTime.date(day: 5, hour: 12)

    private func status(_ configure: (inout DragonStats) -> Void, at time: Date? = nil) -> DragonStatus? {
        var s = DragonStats()
        s.hunger = 80; s.energy = 80; s.fitness = 80; s.health = 100
        configure(&s)
        return DragonStatus.describe(s, now: time ?? noon, calendar: TestTime.utc)
    }

    func test_healthyAwake_hasNoBadge() {
        XCTAssertNil(status { _ in })
    }

    func test_spiritShowsHoursLeft() {
        let badge = status { $0.condition = .spirit(diedAt: TestTime.date(day: 5, hour: 11)) }
        XCTAssertEqual(badge?.text, "Spirit • 47h left")
    }

    func test_spiritUnderAnHourShowsMinutes() {
        let badge = status { $0.condition = .spirit(diedAt: TestTime.date(day: 3, hour: 12, minute: 30)) }
        XCTAssertEqual(badge?.text, "Spirit • 30m left")
    }

    func test_illnessBeatsHunger() {
        let badge = status { $0.condition = .ill(.hungerFever); $0.hunger = 0 }
        XCTAssertEqual(badge?.text, "Sick: Hunger Fever")
    }

    func test_gentleAtHealthFloor_showsDeepSleep() {
        var s = DragonStats()
        s.hunger = 0; s.health = LifeRules.gentleHealthFloor; s.condition = .ill(.hungerFever)
        XCTAssertEqual(DragonStatus.describe(s, now: noon, calendar: TestTime.utc, mode: .gentle)?.text, "Deep sleep — feed me!")
        XCTAssertEqual(DragonStatus.describe(s, now: noon, calendar: TestTime.utc, mode: .classic)?.text, "Sick: Hunger Fever")
    }

    func test_gentleSluggishAtFloor_asksToPlay() {
        var s = DragonStats()
        s.health = LifeRules.gentleHealthFloor; s.hunger = 80; s.condition = .ill(.sluggishScales)
        XCTAssertEqual(DragonStatus.describe(s, now: noon, calendar: TestTime.utc, mode: .gentle)?.text, "Deep sleep — play a game with me!")
    }

    func test_asleep() {
        XCTAssertEqual(status({ _ in }, at: TestTime.date(day: 5, hour: 23))?.text, "Asleep")
    }

    func test_hungryAndTired() {
        XCTAssertEqual(status { $0.hunger = 20 }?.text, "Hungry")
        XCTAssertEqual(status { $0.fitness = 20 }?.text, "Needs training")
    }
}
