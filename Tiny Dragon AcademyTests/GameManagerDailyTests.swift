//
//  GameManagerDailyTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class GameManagerDailyTests: XCTestCase {
    private let t0 = TestTime.date(day: 5, hour: 12)
    private var fileURL: URL!
    private var spy: SpyScheduler!

    override func setUp() {
        super.setUp()
        spy = SpyScheduler()
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("daily-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    private func manager(_ configure: (inout AppProgressState) -> Void = { _ in }) -> GameManager {
        makeTestManager(fileURL: fileURL, notifications: spy, now: t0, configure: configure)
    }

    private func idx(_ id: String, _ gm: GameManager) -> Int { gm.state.dragons.firstIndex { $0.id == id }! }

    // MARK: - Shiny

    func test_crackEgg_forcedShiny_setsFlagAndPalette() throws {
        let gm = manager { s in
            s.incubatorSlots = [IncubatorSlot(egg: Egg(tier: .common), warmth: 100, progress: 1, lastSimulatedAt: self.t0)]
        }
        var lucky = FixedRNG(value: 0)
        let outcome = try XCTUnwrap(gm.crackEgg(slot: 0, rng: &lucky))
        guard case .dragon(let id) = outcome else { return XCTFail("expected a dragon") }
        let dragon = gm.state.dragons[idx(id, gm)]
        XCTAssertTrue(dragon.isShiny)
        XCTAssertEqual(dragon.primaryColorHex, ShinyPalette.colors(for: dragon.element).primary)
    }

    func test_crackEgg_unlucky_notShiny() throws {
        let gm = manager { s in
            s.incubatorSlots = [IncubatorSlot(egg: Egg(tier: .common), warmth: 100, progress: 1, lastSimulatedAt: self.t0)]
        }
        var unlucky = FixedRNG(value: .max)
        guard case .dragon(let id) = try XCTUnwrap(gm.crackEgg(slot: 0, rng: &unlucky)) else { return XCTFail("expected a dragon") }
        XCTAssertFalse(gm.state.dragons[idx(id, gm)].isShiny)
    }

    func test_shinyDragon_earnsTenPercentMoreXP() {
        let gm = manager { s in
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].isShiny = true
            s.dragons[i].stats.hunger = 40
            s.foodInventory[FoodType.dragonRoast.rawValue] = 1
        }
        XCTAssertEqual(gm.feedActiveDragon(food: .dragonRoast).gainedXP, 28) // 25 × 1.1 = 27.5 → 28
    }

    // MARK: - Day rollover & recording

    func test_newDay_givesFreshQuestsAndWishes_andRollsStreak() {
        let gm = manager { s in
            s.daily = DailyState(dayId: "2026-01-04", caredToday: true)
        }
        XCTAssertEqual(gm.state.daily.dayId, "2026-01-05")
        XCTAssertEqual(gm.state.daily.quests.count, 3)
        XCTAssertNotNil(gm.state.daily.wishes["sparkle"])
        XCTAssertEqual(gm.state.streak.current, 1)
    }

    func test_feeding_completesQuest_paysStars_marksCare() {
        let gm = manager { s in
            s.daily = DailyState(dayId: "2026-01-05", quests: [DailyQuest(kind: .feed, target: 1)])
            s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.hunger = 40
            s.foodInventory[FoodType.frostApples.rawValue] = 1
        }
        let stars = gm.state.totalStars
        _ = gm.feedActiveDragon(food: .frostApples)
        XCTAssertTrue(gm.state.daily.caredToday)
        XCTAssertTrue(gm.state.daily.quests[0].isComplete)
        XCTAssertEqual(gm.state.totalStars, stars + DailyRules.questReward + DailyRules.allClearStars)
        XCTAssertEqual(gm.state.itemCount(.healingHerb), 1, "all-clear pays a Healing Herb")
        XCTAssertNotNil(gm.toast)
    }

    func test_wishGranted_appliesRewards() {
        let gm = manager { s in
            s.daily = DailyState(dayId: "2026-01-05", quests: [DailyQuest(kind: .pet, target: 99)],
                                 wishes: ["sparkle": DragonWish(kind: .pet)])
        }
        let stars = gm.state.totalStars
        let xp = gm.activeDragon.stats.experience
        gm.petActiveDragon(); gm.petActiveDragon(); gm.petActiveDragon()
        XCTAssertTrue(gm.state.daily.wishes["sparkle"]!.granted)
        XCTAssertEqual(gm.state.totalStars, stars + DailyRules.wishStars)
        XCTAssertEqual(gm.activeDragon.stats.experience, xp + DailyRules.wishXP)
    }

    func test_streakMilestone_rewardApplied() {
        let gm = manager { s in
            s.totalStars = 0
            s.streak = StreakState(current: 2, best: 2)
            s.daily = DailyState(dayId: "2026-01-04", caredToday: true)
        }
        XCTAssertEqual(gm.state.streak.current, 3)
        XCTAssertEqual(gm.state.totalStars, 15)
    }

    func test_streakEggMilestone_addsEgg() {
        let gm = manager { s in
            s.streak = StreakState(current: 13, best: 13)
            s.daily = DailyState(dayId: "2026-01-04", caredToday: true)
        }
        XCTAssertEqual(gm.state.eggBasket.last?.tier, .uncommon)
    }

    func test_illnessDuringAbsence_creditedToItsDay() {
        let gm = manager { s in
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].stats.hunger = 0
            s.daily = DailyState(dayId: "2026-01-05", caredToday: true)
        }
        gm.clock.offset = 86_400 // next day at noon; Hunger Fever struck at 14:00 on the 5th
        gm.catchUp()
        XCTAssertEqual(gm.state.streak.recent.last, StreakDay(dayId: "2026-01-05", result: .missed))
        XCTAssertEqual(gm.state.daily.dayId, "2026-01-06")
        XCTAssertFalse(gm.state.daily.illnessToday)
    }

    func test_gentleMode_reachesSimulator() {
        let gm = manager { s in
            s.careMode = .gentle
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].stats.hunger = 0
            s.dragons[i].stats.health = 12
            s.dragons[i].stats.condition = .ill(.hungerFever)
        }
        gm.clock.offset = 2 * 86_400
        gm.tick()
        XCTAssertFalse(gm.activeDragon.stats.condition.isSpirit)
        XCTAssertEqual(gm.activeDragon.stats.health, LifeRules.gentleHealthFloor, accuracy: 0.001)
    }

    func test_learningGame_countsForQuest() {
        let gm = manager { s in
            s.daily = DailyState(dayId: "2026-01-05", quests: [DailyQuest(kind: .learningGame, target: 1), DailyQuest(kind: .pet, target: 9)])
        }
        gm.awardStars(3, forGame: .colorGarden)
        XCTAssertTrue(gm.state.daily.quests[0].isComplete)
    }

    func test_shortTrainingSession_isNotCare() {
        let gm = manager { s in s.daily = DailyState(dayId: "2026-01-05") }
        var rng = FixedRNG(value: .max)
        _ = gm.finishTraining(.dragonDash, score: 10, duration: 3, completedRound: false, rng: &rng)
        XCTAssertFalse(gm.state.daily.caredToday)
        _ = gm.finishTraining(.dragonDash, score: 300, duration: 30, completedRound: false, rng: &rng)
        XCTAssertTrue(gm.state.daily.caredToday)
    }

    func test_questContext_readyEggIsNotIncubating() {
        let gm = manager { s in
            s.incubatorSlots = [IncubatorSlot(egg: Egg(tier: .common), warmth: 100, progress: 1, lastSimulatedAt: self.t0)]
        }
        XCTAssertFalse(gm.questContext.hasIncubatingEgg)
        gm.state.incubatorSlots[0].progress = 0.5
        XCTAssertTrue(gm.questContext.hasIncubatingEgg)
    }

    func test_onboarding_setsCareMode() {
        let gm = manager { s in s.hasCompletedOnboarding = false }
        gm.completeOnboarding(starterDragonName: "Pip", careMode: .gentle)
        XCTAssertEqual(gm.state.careMode, .gentle)
        XCTAssertEqual(gm.state.daily.quests.count, 3)
        gm.setCareMode(.classic)
        XCTAssertEqual(gm.state.careMode, .classic)
    }
}
