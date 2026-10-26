//
//  TrainingSessionRulesTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class TrainingSessionRulesTests: XCTestCase {
    private let noon = TestTime.date(day: 5, hour: 12)
    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("tr-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    private func manager(_ configure: (inout AppProgressState) -> Void = { _ in }) -> GameManager {
        makeTestManager(fileURL: fileURL, notifications: SpyScheduler(), now: noon) { s in
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].stats.fitness = 40
            s.dragons[i].stats.energy = 100
            configure(&s)
        }
    }

    private var noDrop: FixedRNG { FixedRNG(value: .max) }

    func test_counts_untimedNeedsTwentySecondsOrMinScore() {
        XCTAssertFalse(TrainingSessionRules.counts(.dragonDash, duration: 10, score: 150, completedRound: false))
        XCTAssertTrue(TrainingSessionRules.counts(.dragonDash, duration: 25, score: 0, completedRound: false))
        XCTAssertTrue(TrainingSessionRules.counts(.dragonDash, duration: 5, score: 200, completedRound: false))
        XCTAssertTrue(TrainingSessionRules.counts(.skyFlight, duration: 5, score: 5, completedRound: false))
    }

    func test_counts_timedCountsWhenRoundCompleted() {
        XCTAssertTrue(TrainingSessionRules.counts(.fireTarget, duration: 45, score: 0, completedRound: true))
        XCTAssertFalse(TrainingSessionRules.counts(.fireTarget, duration: 10, score: 3, completedRound: false))
        XCTAssertTrue(TrainingSessionRules.counts(.snackCatch, duration: 21, score: 0, completedRound: false))
    }

    func test_normalizedScore_clamped() {
        XCTAssertEqual(TrainingSessionRules.normalizedScore(.dragonDash, score: 1000), 0.5)
        XCTAssertEqual(TrainingSessionRules.normalizedScore(.dragonDash, score: 9999), 1)
        XCTAssertEqual(TrainingSessionRules.normalizedScore(.skyFlight, score: 0), 0)
        XCTAssertEqual(TrainingSessionRules.normalizedScore(.fireTarget, score: 15), 0.5)
    }

    func test_gameTypeMetadata() {
        XCTAssertEqual(TrainingGameType.fireTarget.roundDuration, 45)
        XCTAssertEqual(TrainingGameType.snackCatch.roundDuration, 60)
        XCTAssertNil(TrainingGameType.dragonDash.roundDuration)
        XCTAssertEqual(TrainingGameType.dragonDash.minimumCountedScore, 200)
        XCTAssertEqual(TrainingGameType.skyFlight.minimumCountedScore, 5)
    }

    func test_startTraining_spendsEnergy() {
        let gm = manager()
        XCTAssertTrue(gm.startTraining(.dragonDash))
        XCTAssertEqual(gm.activeDragon.stats.energy, 85)
    }

    func test_startTraining_refusedWhenAsleepOrLowEnergy_noEnergySpent() {
        let low = manager { s in s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.energy = 10 }
        XCTAssertFalse(low.startTraining(.dragonDash))
        XCTAssertEqual(low.activeDragon.stats.energy, 10)
        let sleepy = manager()
        sleepy.lightsOut()
        XCTAssertFalse(sleepy.startTraining(.skyFlight))
        XCTAssertEqual(sleepy.activeDragon.stats.energy, 100)
    }

    func test_finishTraining_counted_appliesRewardAndCounter() {
        let gm = manager()
        let stars = gm.state.totalStars
        var rng = noDrop
        let result = gm.finishTraining(.dragonDash, score: 2000, duration: 60, completedRound: false, rng: &rng)
        XCTAssertTrue(result.counted)
        XCTAssertEqual(result.reward, TrainingReward(fitness: 40, xp: 40, stars: 5))
        XCTAssertEqual(gm.activeDragon.stats.fitness, 80)
        XCTAssertEqual(gm.activeDragon.stats.experience, 40)
        XCTAssertEqual(gm.state.totalStars, stars + 5)
        XCTAssertEqual(gm.state.trainingSessionsCompleted, 1)
        XCTAssertTrue(result.isNewBest)
        XCTAssertEqual(gm.state.trainingBests[TrainingGameType.dragonDash.rawValue], 2000)
    }

    func test_finishTraining_notCounted_noRewards() {
        let gm = manager()
        var rng = noDrop
        let result = gm.finishTraining(.dragonDash, score: 10, duration: 3, completedRound: false, rng: &rng)
        XCTAssertFalse(result.counted)
        XCTAssertNil(result.reward)
        XCTAssertEqual(gm.activeDragon.stats.fitness, 40)
        XCTAssertEqual(gm.state.trainingSessionsCompleted, 0)
    }

    func test_tenthSession_grantsCommonEgg() {
        let gm = manager { s in s.trainingSessionsCompleted = 9 }
        var rng = noDrop
        let result = gm.finishTraining(.skyFlight, score: 10, duration: 30, completedRound: false, rng: &rng)
        XCTAssertTrue(result.earnedEgg)
        XCTAssertEqual(gm.state.eggBasket.map(\.tier), [.common])
    }

    func test_newBest_emberDrop_usesRNG() {
        let gm = manager()
        var lucky = FixedRNG(value: 0)
        let result = gm.finishTraining(.skyFlight, score: 12, duration: 30, completedRound: false, rng: &lucky)
        XCTAssertTrue(result.droppedEmber)
        XCTAssertEqual(gm.state.itemCount(.phoenixEmber), 1)

        var unlucky = noDrop
        let second = gm.finishTraining(.skyFlight, score: 20, duration: 30, completedRound: false, rng: &unlucky)
        XCTAssertTrue(second.isNewBest)
        XCTAssertFalse(second.droppedEmber)
    }

    func test_noEmberWithoutNewBest() {
        let gm = manager { s in s.trainingBests[TrainingGameType.skyFlight.rawValue] = 50 }
        var lucky = FixedRNG(value: 0)
        let result = gm.finishTraining(.skyFlight, score: 12, duration: 30, completedRound: false, rng: &lucky)
        XCTAssertFalse(result.isNewBest)
        XCTAssertFalse(result.droppedEmber)
    }

    func test_snacks_cappedAtFive() {
        let gm = manager { s in s.foodInventory[FoodType.fireBerries.rawValue] = 0 }
        var rng = noDrop
        let caught = Array(repeating: FoodType.fireBerries, count: 8)
        let result = gm.finishTraining(.snackCatch, score: 8, duration: 60, completedRound: true, caughtSnacks: caught, rng: &rng)
        XCTAssertEqual(result.snacksAdded.count, 5)
        XCTAssertEqual(gm.state.foodInventory[FoodType.fireBerries.rawValue], 5)
    }

    func test_sluggishScales_curedByTraining() {
        let gm = manager { s in s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.condition = .ill(.sluggishScales) }
        var rng = noDrop
        XCTAssertFalse(gm.finishTraining(.dragonDash, score: 300, duration: 30, completedRound: false, rng: &rng).cured)
        XCTAssertTrue(gm.finishTraining(.dragonDash, score: 300, duration: 30, completedRound: false, rng: &rng).cured)
        XCTAssertEqual(gm.activeDragon.stats.condition, .healthy)
    }
}
