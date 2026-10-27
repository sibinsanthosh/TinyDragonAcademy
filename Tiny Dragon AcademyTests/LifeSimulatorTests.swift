//
//  LifeSimulatorTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class LifeSimulatorTests: XCTestCase {
    private let cal = TestTime.utc

    private func fullStats() -> DragonStats {
        var s = DragonStats()
        s.hunger = 100; s.happiness = 100; s.energy = 100; s.fitness = 100; s.health = 100
        s.condition = .healthy
        return s
    }

    private func run(_ s: DragonStats, _ from: Date, _ to: Date) -> (DragonStats, [LifeEvent]) {
        LifeSimulator.advance(s, from: from, to: to, calendar: cal)
    }

    // MARK: - Decay

    func test_sixAwakeHours_fullnessDropsTo28_andEmitsHungry() {
        let (s, events) = run(fullStats(), TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 14))
        XCTAssertEqual(s.hunger, 28, accuracy: 0.01)
        XCTAssertTrue(events.contains(.becameHungry))
        XCTAssertEqual(s.lastSimulatedAt, TestTime.date(day: 5, hour: 14))
    }

    func test_awakeRates_energyHappinessFitness() {
        let (s, _) = run(fullStats(), TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 10))
        XCTAssertEqual(s.energy, 92, accuracy: 0.01)
        XCTAssertEqual(s.happiness, 90, accuracy: 0.01)
        XCTAssertEqual(s.fitness, 92, accuracy: 0.01)
    }

    func test_quietHours_freezeAllButEnergy() {
        var start = fullStats()
        start.energy = 40; start.hunger = 50
        let (s, _) = run(start, TestTime.date(day: 5, hour: 22), TestTime.date(day: 6, hour: 7))
        XCTAssertEqual(s.hunger, 50, accuracy: 0.001)
        XCTAssertEqual(s.happiness, 100, accuracy: 0.001)
        XCTAssertEqual(s.fitness, 100, accuracy: 0.001)
        XCTAssertEqual(s.energy, 100, accuracy: 0.001)
    }

    // MARK: - Illness

    func test_hungerFever_afterTwoHoursAtZero() {
        var start = fullStats()
        start.hunger = 24
        let (before, _) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 11, minute: 59))
        XCTAssertEqual(before.condition, .healthy)
        let (after, events) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 12))
        XCTAssertEqual(after.condition, .ill(.hungerFever))
        XCTAssertTrue(events.contains(.starving))
        XCTAssertTrue(events.contains(.becameIll(.hungerFever)))
    }

    func test_sluggishScales_afterSixHoursBelowTwenty() {
        var start = fullStats()
        start.fitness = 19
        let (before, _) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 13, minute: 59))
        XCTAssertEqual(before.condition, .healthy)
        let (after, _) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 14))
        XCTAssertEqual(after.condition, .ill(.sluggishScales))
    }

    func test_onlyOneIllnessAtATime() {
        var start = fullStats()
        start.hunger = 0; start.fitness = 0
        let (s, events) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 16))
        XCTAssertEqual(s.condition, .ill(.hungerFever))
        XCTAssertEqual(events.filter { if case .becameIll = $0 { return true } else { return false } }.count, 1)
    }

    // MARK: - Health

    func test_healthDrain_stacks() {
        var start = fullStats()
        start.hunger = 0; start.fitness = 10; start.condition = .ill(.hungerFever)
        let (s, _) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 10))
        XCTAssertEqual(s.health, 93, accuracy: 0.01)
    }

    func test_healthRegen_onlyWhenFedAndWell() {
        var start = fullStats()
        start.health = 80
        let (well, _) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 9))
        XCTAssertEqual(well.health, 82, accuracy: 0.01)
        start.condition = .ill(.sluggishScales)
        let (ill, _) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 9))
        XCTAssertEqual(ill.health, 79, accuracy: 0.01)
    }

    // MARK: - Death & spirit

    func test_neglectedFromFull_diesBetween48And72Hours() throws {
        let start = TestTime.date(day: 5, hour: 7)
        let (s, events) = run(fullStats(), start, TestTime.date(day: 9, hour: 7))
        let diedAt = try XCTUnwrap(s.condition.spiritDiedAt)
        let hours = diedAt.timeIntervalSince(start) / 3600
        XCTAssertGreaterThanOrEqual(hours, 48)
        XCTAssertLessThanOrEqual(hours, 72)
        XCTAssertEqual(events.filter { $0 == .died }.count, 1)
        let critical = try XCTUnwrap(events.firstIndex(of: .healthCritical))
        let died = try XCTUnwrap(events.firstIndex(of: .died))
        XCTAssertLessThan(critical, died)
    }

    func test_gentle_neverDies() {
        let (s, events) = LifeSimulator.advance(fullStats(), from: TestTime.date(day: 5, hour: 7),
                                                to: TestTime.date(day: 12, hour: 7), calendar: cal, mode: .gentle)
        XCTAssertFalse(s.condition.isSpirit)
        XCTAssertEqual(s.health, LifeRules.gentleHealthFloor, accuracy: 0.001)
        XCTAssertFalse(events.contains(.died))
        XCTAssertTrue(events.contains { if case .becameIll = $0 { return true } else { return false } }, "illness still happens")
    }

    func test_gentle_predictsNoDeath() {
        let predicted = LifeSimulator.predict(fullStats(), from: TestTime.date(day: 5, hour: 7), horizon: 6 * 86_400,
                                              calendar: cal, mode: .gentle)
        XCTAssertFalse(predicted.contains { $0.event == .died })
    }

    func test_spirit_doesNotDecay_andExpiresAfter48h() {
        var start = fullStats()
        start.hunger = 50
        start.condition = .spirit(diedAt: TestTime.date(day: 5, hour: 10))
        let (early, earlyEvents) = run(start, TestTime.date(day: 5, hour: 10), TestTime.date(day: 7, hour: 9, minute: 59))
        XCTAssertFalse(earlyEvents.contains(.spiritExpired))
        XCTAssertEqual(early.hunger, 50)
        let (_, events) = run(start, TestTime.date(day: 5, hour: 10), TestTime.date(day: 7, hour: 10))
        XCTAssertTrue(events.contains(.spiritExpired))
    }

    func test_spiritAlreadyPastWindow_emitsExpiredOnNextAdvance() {
        var start = fullStats()
        start.condition = .spirit(diedAt: TestTime.date(day: 3, hour: 7))
        let (_, events) = run(start, TestTime.date(day: 5, hour: 8), TestTime.date(day: 5, hour: 9))
        XCTAssertEqual(events.filter { $0 == .spiritExpired }.count, 1)
    }

    func test_spiritLastChance_at6hLeft() {
        var start = fullStats()
        start.condition = .spirit(diedAt: TestTime.date(day: 5, hour: 10))
        let (_, before) = run(start, TestTime.date(day: 5, hour: 10), TestTime.date(day: 7, hour: 3, minute: 59))
        XCTAssertFalse(before.contains(.spiritLastChance))
        let (_, events) = run(start, TestTime.date(day: 5, hour: 10), TestTime.date(day: 7, hour: 4))
        XCTAssertTrue(events.contains(.spiritLastChance))
    }

    // MARK: - Sleep & statuses

    func test_tummyAche_wearsOffEvenAsleep() {
        var start = fullStats()
        start.tummyAcheUntil = TestTime.date(day: 5, hour: 22, minute: 30)
        let (s, _) = run(start, TestTime.date(day: 5, hour: 22), TestTime.date(day: 5, hour: 23))
        XCTAssertNil(s.tummyAcheUntil)
    }

    func test_lightsOut_autoWakesAt7() {
        var start = fullStats()
        start.isSleepingEarly = true
        let (s, events) = run(start, TestTime.date(day: 5, hour: 20), TestTime.date(day: 6, hour: 8))
        XCTAssertFalse(s.isSleepingEarly)
        XCTAssertTrue(events.contains(.wokeUp))
        XCTAssertEqual(s.hunger, 88, accuracy: 0.01)
    }

    func test_isAsleep_quietHoursOrLightsOut() {
        var s = fullStats()
        XCTAssertTrue(LifeSimulator.isAsleep(s, at: TestTime.date(day: 5, hour: 23), calendar: cal))
        XCTAssertFalse(LifeSimulator.isAsleep(s, at: TestTime.date(day: 5, hour: 12), calendar: cal))
        s.isSleepingEarly = true
        XCTAssertTrue(LifeSimulator.isAsleep(s, at: TestTime.date(day: 5, hour: 12), calendar: cal))
    }

    // MARK: - Catch-up & clock

    func test_catchUp_cappedAtSevenDays() {
        let t = TestTime.date(day: 1, hour: 8)
        let tenDays = t.addingTimeInterval(10 * 86_400)
        XCTAssertEqual(LifeSimulator.effectiveStart(from: t, to: tenDays), t.addingTimeInterval(3 * 86_400))
        let start = fullStats()
        let full = run(start, t, tenDays)
        let capped = run(start, t.addingTimeInterval(3 * 86_400), tenDays)
        XCTAssertEqual(full.0, capped.0)
        XCTAssertEqual(full.1, capped.1)
    }

    func test_backwardsClock_noChange() {
        let start = fullStats()
        let (s, events) = run(start, TestTime.date(day: 5, hour: 12), TestTime.date(day: 5, hour: 9))
        var expected = start
        expected.lastSimulatedAt = TestTime.date(day: 5, hour: 9)
        XCTAssertEqual(s, expected)
        XCTAssertTrue(events.isEmpty)
    }

    func test_catchUp_spanningDeathAndExpiry_emitsBothEvents() throws {
        let (_, events) = run(fullStats(), TestTime.date(day: 5, hour: 7), TestTime.date(day: 12, hour: 7))
        let died = try XCTUnwrap(events.firstIndex(of: .died))
        let expired = try XCTUnwrap(events.firstIndex(of: .spiritExpired))
        XCTAssertLessThan(died, expired)
    }

    func test_dstSpringForwardNight_quietHoursFollowWallClock() {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        // DST starts 2026-03-08 02:00 local: the 22:00–07:00 night is 8 real hours long.
        var t = ny.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 12))!
        let end = ny.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12))!
        var quietMinutes = 0
        while t < end {
            if LifeSimulator.isQuietHours(t, calendar: ny) { quietMinutes += 1 }
            t = t.addingTimeInterval(60)
        }
        XCTAssertEqual(quietMinutes, 8 * 60)
    }
}
