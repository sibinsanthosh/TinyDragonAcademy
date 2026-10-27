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
}
