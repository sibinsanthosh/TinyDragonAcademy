//
//  DenRulesTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class DenRulesTests: XCTestCase {
    private let now = TestTime.date(day: 5, hour: 12)

    private func state(_ residences: [String: DragonResidence], selected: String = "sparkle") -> AppProgressState {
        var s = AppProgressState.initial()
        for idx in s.dragons.indices {
            s.dragons[idx].residence = residences[s.dragons[idx].id] ?? .undiscovered
        }
        s.selectedDragonId = selected
        return s
    }

    private func index(_ id: String, _ s: AppProgressState) -> Int {
        s.dragons.firstIndex { $0.id == id }!
    }

    func test_moveToSanctuary_onlyWhenHealthy() {
        var s = state(["sparkle": .den, "ember": .den])
        s.dragons[index("ember", s)].stats.condition = .ill(.hungerFever)
        XCTAssertFalse(DenRules.moveToSanctuary("ember", state: &s))
        s.dragons[index("ember", s)].stats.condition = .spirit(diedAt: now)
        XCTAssertFalse(DenRules.moveToSanctuary("ember", state: &s))
        s.dragons[index("ember", s)].stats.condition = .healthy
        XCTAssertTrue(DenRules.moveToSanctuary("ember", state: &s))
        XCTAssertEqual(s.dragons[index("ember", s)].residence, .sanctuary)
    }

    func test_moveToSanctuary_activeDragonHandsOff() {
        var s = state(["sparkle": .den, "ember": .den], selected: "sparkle")
        XCTAssertTrue(DenRules.moveToSanctuary("sparkle", state: &s))
        XCTAssertEqual(s.selectedDragonId, "ember")
    }

    func test_moveToDen_respectsCapacity_resetsClock() {
        var s = state(["sparkle": .den, "ember": .den, "frosty": .den, "volt": .sanctuary])
        XCTAssertFalse(DenRules.moveToDen("volt", state: &s, now: now))
        s.denCapacity = 4
        XCTAssertTrue(DenRules.moveToDen("volt", state: &s, now: now))
        XCTAssertEqual(s.dragons[index("volt", s)].residence, .den)
        XCTAssertEqual(s.dragons[index("volt", s)].stats.lastSimulatedAt, now)
        XCTAssertFalse(DenRules.moveToDen("nova", state: &s, now: now))
    }

    func test_placeHatched_goesToDenWhenFree() {
        var s = state(["sparkle": .den])
        DenRules.placeHatched("ember", name: "Blaze", state: &s, now: now)
        let ember = s.dragons[index("ember", s)]
        XCTAssertEqual(ember.residence, .den)
        XCTAssertEqual(ember.name, "Blaze")
        XCTAssertEqual(ember.stats.bornAt, now)
        XCTAssertEqual(ember.stats.lastSimulatedAt, now)
        XCTAssertEqual(ember.stats.condition, .healthy)
    }

    func test_placeHatched_fullDen_goesToSanctuary() {
        var s = state(["sparkle": .den, "ember": .den, "frosty": .den])
        DenRules.placeHatched("volt", name: "Zap", state: &s, now: now)
        XCTAssertEqual(s.dragons[index("volt", s)].residence, .sanctuary)
    }

    func test_expireSpirit_createsMemorialAndEgg() throws {
        var s = state(["sparkle": .den, "nova": .den])
        let i = index("nova", s)
        s.dragons[i].name = "Prism"
        s.dragons[i].stats.growthStage = .adolescent
        s.dragons[i].stats.level = 11
        s.dragons[i].stats.bornAt = TestTime.date(day: 1, hour: 9)
        s.dragons[i].stats.condition = .spirit(diedAt: TestTime.date(day: 3, hour: 12))
        DenRules.expireSpirit("nova", state: &s, now: now)

        let memorial = try XCTUnwrap(s.hallOfLegends.last)
        XCTAssertEqual(memorial.dragonId, "nova")
        XCTAssertEqual(memorial.name, "Prism")
        XCTAssertEqual(memorial.stage, .adolescent)
        XCTAssertEqual(memorial.level, 11)
        XCTAssertEqual(memorial.bornAt, TestTime.date(day: 1, hour: 9))
        XCTAssertEqual(memorial.diedAt, TestTime.date(day: 3, hour: 12))
        XCTAssertEqual(s.dragons[i].residence, .legend)
        XCTAssertEqual(s.dragons[i].name, "Nova")
        XCTAssertEqual(s.dragons[i].stats.condition, .healthy)
        let egg = try XCTUnwrap(s.eggBasket.last)
        XCTAssertEqual(egg.fixedSpeciesId, "nova")
        XCTAssertEqual(egg.tier, .rare)
    }

    func test_expireSpirit_starterGetsCommonFixedEgg() throws {
        var s = state(["sparkle": .den])
        s.dragons[index("sparkle", s)].stats.condition = .spirit(diedAt: now)
        DenRules.expireSpirit("sparkle", state: &s, now: now)
        let egg = try XCTUnwrap(s.eggBasket.last)
        XCTAssertEqual(egg.tier, .common)
        XCTAssertEqual(egg.fixedSpeciesId, "sparkle")
    }

    func test_allDenDragonsExpire_basketHasEggs_activeFallsBack() {
        var s = state(["sparkle": .den, "ember": .den], selected: "sparkle")
        for id in ["sparkle", "ember"] {
            s.dragons[index(id, s)].stats.condition = .spirit(diedAt: now)
            DenRules.expireSpirit(id, state: &s, now: now)
        }
        DenRules.ensureActiveInDen(&s)
        XCTAssertTrue(s.denDragons.isEmpty)
        XCTAssertEqual(s.eggBasket.count, 2)
        XCTAssertTrue(s.dragons.contains { $0.id == s.selectedDragonId })
    }

    func test_ensureActiveInDen_picksFirstDenDragon() {
        var s = state(["sparkle": .sanctuary, "ember": .den, "frosty": .den], selected: "sparkle")
        DenRules.ensureActiveInDen(&s)
        XCTAssertEqual(s.selectedDragonId, "ember")
    }
}
