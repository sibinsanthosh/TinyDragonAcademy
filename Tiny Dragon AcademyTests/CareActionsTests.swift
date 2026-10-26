//
//  CareActionsTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class CareActionsTests: XCTestCase {
    private let cal = TestTime.utc
    private let noon = TestTime.date(day: 5, hour: 12)

    private func stats(hunger: Double = 50) -> DragonStats {
        var s = DragonStats()
        s.hunger = hunger; s.happiness = 50; s.energy = 50; s.fitness = 50; s.health = 100
        return s
    }

    func test_feed_restoresFoodValues() {
        var s = stats()
        let outcome = CareActions.feed(&s, food: .frostApples, isFavorite: false, now: noon, calendar: cal)
        XCTAssertEqual(outcome, .fed)
        XCTAssertEqual(s.hunger, 72)
        XCTAssertEqual(s.happiness, 65)
        XCTAssertEqual(s.energy, 62)
    }

    func test_feed_favoriteDoublesHappiness() {
        var s = stats()
        _ = CareActions.feed(&s, food: .frostApples, isFavorite: true, now: noon, calendar: cal)
        XCTAssertEqual(s.happiness, 80)
    }

    func test_feed_overfull_givesTummyAche() {
        var s = stats(hunger: 96)
        let outcome = CareActions.feed(&s, food: .frostApples, isFavorite: false, now: noon, calendar: cal)
        XCTAssertEqual(outcome, .tummyAche)
        XCTAssertEqual(s.happiness, 40)
        XCTAssertEqual(s.hunger, 96)
        XCTAssertEqual(s.tummyAcheUntil, noon.addingTimeInterval(3600))
    }

    func test_feedWhileAsleep_refusedAndNoFoodSpent() {
        var s = stats()
        let before = s
        let outcome = CareActions.feed(&s, food: .frostApples, isFavorite: false, now: TestTime.date(day: 5, hour: 23), calendar: cal)
        XCTAssertEqual(outcome, .refusedAsleep)
        XCTAssertEqual(s, before)
    }

    func test_feedSpirit_refused() {
        var s = stats()
        s.condition = .spirit(diedAt: noon)
        XCTAssertEqual(CareActions.feed(&s, food: .frostApples, isFavorite: false, now: noon, calendar: cal), .refusedSpirit)
        XCTAssertEqual(s.hunger, 50)
    }

    func test_herb_curesIllness_onlyWhenIll() {
        var s = stats()
        XCTAssertFalse(CareActions.useHealingHerb(&s))
        s.condition = .ill(.hungerFever)
        s.fullnessZeroMinutes = 200
        XCTAssertTrue(CareActions.useHealingHerb(&s))
        XCTAssertEqual(s.condition, .healthy)
        XCTAssertEqual(s.fullnessZeroMinutes, 0)
    }

    func test_revive_dropsOneStage_keepsLevel() {
        var s = stats(hunger: 0)
        s.health = 0
        s.growthStage = .adolescent
        s.level = 12
        s.condition = .spirit(diedAt: noon)
        XCTAssertTrue(CareActions.revive(&s))
        XCTAssertEqual(s.growthStage, .young)
        XCTAssertEqual(s.level, 12)
        XCTAssertEqual(s.health, 50)
        XCTAssertEqual(s.hunger, 50)
        XCTAssertEqual(s.condition, .healthy)
    }

    func test_revive_babyStaysBaby() {
        var s = stats()
        s.condition = .spirit(diedAt: noon)
        XCTAssertTrue(CareActions.revive(&s))
        XCTAssertEqual(s.growthStage, .baby)
    }

    func test_revive_notSpirit_returnsFalse() {
        var s = stats()
        XCTAssertFalse(CareActions.revive(&s))
    }

    func test_lightsOut_onlyInTheEvening() {
        var s = stats()
        XCTAssertFalse(CareActions.lightsOut(&s, now: TestTime.date(day: 5, hour: 8), calendar: cal))
        XCTAssertFalse(s.isSleepingEarly)
        XCTAssertFalse(CareActions.lightsOut(&s, now: TestTime.date(day: 5, hour: 18, minute: 59), calendar: cal))
        XCTAssertTrue(CareActions.lightsOut(&s, now: TestTime.date(day: 5, hour: 20), calendar: cal))
        XCTAssertTrue(s.isSleepingEarly)
    }

    func test_lightsOut_and_wakeUp() {
        var s = stats()
        XCTAssertTrue(CareActions.lightsOut(&s, now: TestTime.date(day: 5, hour: 21), calendar: cal))
        XCTAssertTrue(s.isSleepingEarly)
        CareActions.wakeUp(&s)
        XCTAssertFalse(s.isSleepingEarly)
    }

    func test_trainingReward_scaling() {
        XCTAssertEqual(CareActions.trainingReward(normalizedScore: 0, isIll: false), TrainingReward(fitness: 25, xp: 10, stars: 1))
        XCTAssertEqual(CareActions.trainingReward(normalizedScore: 1, isIll: false), TrainingReward(fitness: 40, xp: 40, stars: 5))
        XCTAssertEqual(CareActions.trainingReward(normalizedScore: 0.5, isIll: true), TrainingReward(fitness: 32.5, xp: 12, stars: 3))
        XCTAssertEqual(CareActions.trainingReward(normalizedScore: 7, isIll: false), TrainingReward(fitness: 40, xp: 40, stars: 5))
    }

    func test_sluggishScales_curedAfterTwoCountedSessions() {
        var s = stats()
        s.condition = .ill(.sluggishScales)
        let reward = TrainingReward(fitness: 30, xp: 10, stars: 1)
        XCTAssertFalse(CareActions.applyCountedSession(&s, reward: reward))
        XCTAssertEqual(s.condition, .ill(.sluggishScales))
        XCTAssertEqual(s.fitness, 80)
        XCTAssertTrue(CareActions.applyCountedSession(&s, reward: reward))
        XCTAssertEqual(s.condition, .healthy)
        XCTAssertEqual(s.fitness, 100)
    }

    func test_countedSession_doesNotCureHungerFever() {
        var s = stats()
        s.condition = .ill(.hungerFever)
        XCTAssertFalse(CareActions.applyCountedSession(&s, reward: TrainingReward(fitness: 30, xp: 10, stars: 1)))
        XCTAssertFalse(CareActions.applyCountedSession(&s, reward: TrainingReward(fitness: 30, xp: 10, stars: 1)))
        XCTAssertEqual(s.condition, .ill(.hungerFever))
    }

    func test_canTrain_rules() {
        var s = stats()
        s.energy = 14
        XCTAssertFalse(CareActions.canTrain(s, now: noon, calendar: cal))
        s.energy = 50
        XCTAssertFalse(CareActions.canTrain(s, now: TestTime.date(day: 5, hour: 23), calendar: cal))
        s.condition = .ill(.sluggishScales)
        XCTAssertTrue(CareActions.canTrain(s, now: noon, calendar: cal))
        s.condition = .spirit(diedAt: noon)
        XCTAssertFalse(CareActions.canTrain(s, now: noon, calendar: cal))
    }
}
