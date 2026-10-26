//
//  GameManagerLifeTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class SpyScheduler: NotificationScheduling {
    var plans: [[PlannedNotification]] = []
    func schedule(_ plan: [PlannedNotification]) { plans.append(plan) }
    func requestAuthorization() async -> Bool { true }
    func authorizationDenied() async -> Bool { false }
}

@MainActor
final class GameManagerLifeTests: XCTestCase {
    private let t0 = TestTime.date(day: 5, hour: 8)
    private var spy: SpyScheduler!
    private var fileURL: URL!

    override func setUp() {
        super.setUp()
        spy = SpyScheduler()
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("gm-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    /// A manager whose clock is frozen at `t0` (advance with `gm.clock.offset`), with a seeded save.
    private func manager(_ configure: (inout AppProgressState) -> Void = { _ in }) -> GameManager {
        var state = AppProgressState.initial()
        state.hasCompletedOnboarding = true
        state.lastDailyBonusClaimDate = t0
        for idx in state.dragons.indices {
            state.dragons[idx].stats.lastSimulatedAt = t0
            state.dragons[idx].stats.bornAt = t0
        }
        state.incubatorSlots = [IncubatorSlot(lastSimulatedAt: t0)]
        configure(&state)
        PersistenceService(fileURL: fileURL).saveState(state)
        return GameManager(
            persistence: PersistenceService(fileURL: fileURL),
            clock: GameClock(timeScale: 0, origin: t0),
            notifications: spy,
            calendar: TestTime.utc
        )
    }

    private func idx(_ id: String, _ gm: GameManager) -> Int {
        gm.state.dragons.firstIndex { $0.id == id }!
    }

    func test_tick_advancesDenOnly_notSanctuary() {
        let gm = manager { s in
            s.dragons[s.dragons.firstIndex { $0.id == "ember" }!].residence = .sanctuary
        }
        let emberHunger = gm.state.dragons[idx("ember", gm)].stats.hunger
        let sparkleHunger = gm.state.dragons[idx("sparkle", gm)].stats.hunger
        gm.clock.offset = 3600
        gm.tick()
        XCTAssertEqual(gm.state.dragons[idx("sparkle", gm)].stats.hunger, sparkleHunger - 12, accuracy: 0.01)
        XCTAssertEqual(gm.state.dragons[idx("ember", gm)].stats.hunger, emberHunger)
    }

    func test_tick_expiredSpirit_movesToLegendAndAddsEgg() {
        let gm = manager { s in
            s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.condition = .spirit(diedAt: TestTime.date(day: 3, hour: 7))
        }
        gm.clock.offset = 3600
        gm.tick()
        XCTAssertEqual(gm.state.dragons[idx("sparkle", gm)].residence, .legend)
        XCTAssertEqual(gm.state.hallOfLegends.count, 1)
        XCTAssertEqual(gm.state.eggBasket.last?.fixedSpeciesId, "sparkle")
    }

    func test_feed_illHalvesXP_andRefusalSpendsNoFood() {
        let gm = manager { s in
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].stats.hunger = 40
            s.dragons[i].stats.condition = .ill(.sluggishScales)
            s.foodInventory[FoodType.dragonRoast.rawValue] = 3
        }
        let result = gm.feedActiveDragon(food: .dragonRoast)
        XCTAssertEqual(result.outcome, .fed)
        XCTAssertEqual(result.gainedXP, FoodType.dragonRoast.baseXP / 2)
        XCTAssertEqual(gm.state.foodInventory[FoodType.dragonRoast.rawValue], 2)

        gm.lightsOut()
        let refused = gm.feedActiveDragon(food: .dragonRoast)
        XCTAssertEqual(refused.outcome, .refusedAsleep)
        XCTAssertEqual(gm.state.foodInventory[FoodType.dragonRoast.rawValue], 2)
    }

    func test_reachingYoung_grantsCommonEggOnce() {
        let gm = manager { s in
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].stats.level = 6
            s.itemInventory[CareItem.phoenixEmber.rawValue] = 1
        }
        XCTAssertTrue(gm.evolveActiveDragon())
        XCTAssertEqual(gm.state.eggBasket.map(\.tier), [.common])

        gm.state.dragons[idx("sparkle", gm)].stats.condition = .spirit(diedAt: t0)
        XCTAssertTrue(gm.reviveActiveDragon())
        XCTAssertEqual(gm.activeDragon.stats.growthStage, .baby)
        XCTAssertTrue(gm.evolveActiveDragon())
        XCTAssertEqual(gm.state.eggBasket.count, 1)
    }

    func test_evolve_refusedWhileIll() {
        let gm = manager { s in
            let i = s.dragons.firstIndex { $0.id == "sparkle" }!
            s.dragons[i].stats.level = 6
            s.dragons[i].stats.condition = .ill(.hungerFever)
        }
        XCTAssertFalse(gm.evolveActiveDragon())
    }

    func test_revive_consumesEmber_failsWithoutEmber() {
        let gm = manager { s in
            s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.condition = .spirit(diedAt: TestTime.date(day: 5, hour: 7))
        }
        XCTAssertFalse(gm.reviveActiveDragon())
        gm.state.itemInventory[CareItem.phoenixEmber.rawValue] = 1
        XCTAssertTrue(gm.reviveActiveDragon())
        XCTAssertEqual(gm.state.itemCount(.phoenixEmber), 0)
        XCTAssertEqual(gm.activeDragon.stats.condition, .healthy)
    }

    func test_healingHerb_consumedOnlyWhenIll() {
        let gm = manager { s in s.itemInventory[CareItem.healingHerb.rawValue] = 1 }
        XCTAssertFalse(gm.useHealingHerb())
        XCTAssertEqual(gm.state.itemCount(.healingHerb), 1)
        gm.state.dragons[idx("sparkle", gm)].stats.condition = .ill(.hungerFever)
        XCTAssertTrue(gm.useHealingHerb())
        XCTAssertEqual(gm.state.itemCount(.healingHerb), 0)
    }

    func test_tick_reschedulesNotifications() {
        let gm = manager { s in s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.hunger = 40 }
        spy.plans.removeAll()
        gm.tick()
        XCTAssertFalse(spy.plans.last?.isEmpty ?? true)
    }

    func test_purchaseDenSlot_pricesAndCap() {
        let gm = manager { s in s.totalStars = 1000 }
        XCTAssertTrue(gm.purchaseDenSlot())
        XCTAssertEqual(gm.state.totalStars, 800)
        XCTAssertTrue(gm.purchaseDenSlot())
        XCTAssertEqual(gm.state.totalStars, 400)
        XCTAssertEqual(gm.state.denCapacity, 5)
        XCTAssertFalse(gm.purchaseDenSlot())
    }

    func test_purchases_eggsItemsIncubator() {
        let gm = manager { s in s.totalStars = 300 }
        XCTAssertTrue(gm.purchaseEgg(.rare))
        XCTAssertFalse(gm.purchaseEgg(.legendary))
        XCTAssertTrue(gm.purchaseCareItem(.healingHerb))
        XCTAssertTrue(gm.purchaseIncubatorSlot())
        XCTAssertFalse(gm.purchaseIncubatorSlot())
        XCTAssertEqual(gm.state.totalStars, 300 - 100 - 15 - 150)
        XCTAssertEqual(gm.state.incubatorCapacity, 2)
    }

    func test_eggFlow_placeWarmCrackAndName() throws {
        let egg = Egg(tier: .common)
        let gm = manager { s in s.eggBasket = [egg] }
        XCTAssertTrue(gm.placeEgg(egg.id, slot: 0))
        XCTAssertTrue(gm.state.eggBasket.isEmpty)
        XCTAssertNil(gm.crackEgg(slot: 0))
        gm.clock.offset = 2 * 3600
        gm.tick()
        let outcome = try XCTUnwrap(gm.crackEgg(slot: 0))
        guard case .dragon(let id) = outcome else { return XCTFail("expected dragon") }
        XCTAssertEqual(gm.state.dragons[idx(id, gm)].residence, .den)
        gm.nameHatched(id: id, name: "Pip")
        XCTAssertEqual(gm.state.dragons[idx(id, gm)].name, "Pip")
        XCTAssertNil(gm.state.incubatorSlots[0].egg)
    }

    func test_catchUp_fillsAwayReport() {
        let gm = manager { s in s.dragons[s.dragons.firstIndex { $0.id == "sparkle" }!].stats.hunger = 35 }
        gm.awayReport = [:]
        gm.clock.offset = 3600
        gm.catchUp()
        XCTAssertEqual(gm.awayReport["sparkle"], [.becameHungry])
    }

    func test_handleNotificationTap_selectsDenDragon() {
        let gm = manager { s in s.dragons[s.dragons.firstIndex { $0.id == "ember" }!].residence = .den }
        gm.handleNotificationTap(dragonId: "ember")
        XCTAssertEqual(gm.state.selectedDragonId, "ember")
        XCTAssertEqual(gm.currentRoute, .dragonPlayground)
    }

    func test_gameClock_scalesAndConvertsBack() {
        let clock = GameClock(timeScale: 60, origin: t0)
        let game = clock.now(real: t0.addingTimeInterval(60))
        XCTAssertEqual(game, t0.addingTimeInterval(3600))
        XCTAssertEqual(clock.realDate(forGame: game), t0.addingTimeInterval(60))
        XCTAssertEqual(GameClock.fromLaunchArguments(["app", "-timeScale", "120"]).timeScale, 120)
        XCTAssertEqual(GameClock.fromLaunchArguments(["app"]).timeScale, 1)
    }
}
