//
//  LifeModelTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class LifeModelTests: XCTestCase {

    func test_dragonStats_decodesLegacyJSONWithoutNewFields() throws {
        let legacy = #"{"hunger":50,"happiness":60,"energy":70,"health":100,"experience":0,"level":1,"growthStage":"Baby Dragon","ageInDays":1,"totalFeedings":0,"favoriteFoodDiscovered":false,"lastCareTimestamp":0,"lastFeedingTimestamp":0,"unlockedPowerIds":["fire_1"]}"#
        let stats = try JSONDecoder().decode(DragonStats.self, from: Data(legacy.utf8))
        XCTAssertEqual(stats.hunger, 50)
        XCTAssertEqual(stats.condition, .healthy)
        XCTAssertEqual(stats.fitness, 100)
        XCTAssertEqual(stats.stagesRewarded, [.baby])
    }

    func test_dragonCondition_roundTripsSpirit() throws {
        let condition = DragonCondition.spirit(diedAt: TestTime.date(day: 5, hour: 10))
        let decoded = try JSONDecoder().decode(DragonCondition.self, from: JSONEncoder().encode(condition))
        XCTAssertEqual(decoded, condition)
        let ill = DragonCondition.ill(.sluggishScales)
        XCTAssertEqual(try JSONDecoder().decode(DragonCondition.self, from: JSONEncoder().encode(ill)), ill)
    }

    func test_legacySave_migratesOwnedDragonsIntoDen_selectedFirst_capThree() throws {
        let data = try legacySaveJSON(owned: ["sparkle", "ember", "frosty", "volt"], selected: "volt")
        let state = try JSONDecoder().decode(AppProgressState.self, from: data)

        // Selected dragon is guaranteed a den slot; the remaining owned dragons fill in array order
        XCTAssertEqual(Set(state.denDragons.map(\.id)), ["volt", "sparkle", "ember"])
        XCTAssertEqual(state.selectedDragonId, "volt")
        XCTAssertEqual(state.dragons.first { $0.id == "frosty" }?.residence, .sanctuary)
        XCTAssertEqual(state.dragons.first { $0.id == "nova" }?.residence, .undiscovered)
        XCTAssertEqual(state.eggBasket.count, 1)
        XCTAssertEqual(state.eggBasket.first?.tier, .common)
        for id in ["sparkle", "ember", "frosty", "volt"] {
            let stats = try XCTUnwrap(state.dragons.first { $0.id == id }?.stats)
            XCTAssertEqual(stats.fitness, 70, id)
            XCTAssertEqual(stats.health, 100, id)
            XCTAssertEqual(stats.condition, .healthy, id)
        }
    }

    func test_newState_roundTripsAllNewFields() throws {
        // Normalize once: decoding adds each element's starting power to legacy stats
        var state = try JSONDecoder().decode(AppProgressState.self, from: JSONEncoder().encode(AppProgressState.initial()))
        state.eggBasket = [Egg(tier: .rare), Egg(tier: .common, fixedSpeciesId: "ember")]
        state.itemInventory[CareItem.phoenixEmber.rawValue] = 2
        state.trainingBests["Dragon Dash"] = 500
        state.trainingSessionsCompleted = 7
        state.denCapacity = 4
        state.hallOfLegends = [Memorial(id: UUID(), dragonId: "ember", name: "Blaze", speciesTitle: "Little Flame",
                                        stage: .young, level: 6, bornAt: TestTime.date(day: 1, hour: 8),
                                        diedAt: TestTime.date(day: 4, hour: 9))]
        state.hasSeenReminderPrimer = true
        let decoded = try JSONDecoder().decode(AppProgressState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded, state)
    }

    func test_eggTier_speciesTable() {
        XCTAssertEqual(EggTier.common.speciesIds, ["ember", "splash", "sprout", "terra"])
        XCTAssertEqual(EggTier.uncommon.speciesIds, ["frosty", "volt", "zephyr", "flora"])
        XCTAssertEqual(EggTier.rare.speciesIds, ["nova", "sunny", "bubble", "berry"])
        XCTAssertEqual(EggTier.legendary.speciesIds, ["twinkle", "rainbow"])
        XCTAssertNil(EggTier.legendary.shopPrice)
        XCTAssertEqual(EggTier.common.shopPrice, 25)
        XCTAssertEqual(EggTier.rare.hatchDuration, 8 * 3600)
        XCTAssertEqual(EggTier.tier(forSpecies: "nova"), .rare)
        XCTAssertNil(EggTier.tier(forSpecies: "sparkle"))
    }

    func test_newGame_onlySparkleInDen() {
        let state = AppProgressState.initial()
        XCTAssertEqual(state.denDragons.map(\.id), ["sparkle"])
        XCTAssertTrue(state.eggBasket.isEmpty)
        XCTAssertEqual(state.incubatorCapacity, 1)
    }

    // MARK: - Helpers

    /// Encodes a fresh state, then rewrites it into the pre-update save format.
    private func legacySaveJSON(owned: Set<String>, selected: String) throws -> Data {
        let fresh = try JSONEncoder().encode(AppProgressState.initial())
        var root = try XCTUnwrap(try JSONSerialization.jsonObject(with: fresh) as? [String: Any])
        for key in ["eggBasket", "incubatorSlots", "denCapacity", "itemInventory", "trainingBests",
                    "trainingSessionsCompleted", "hallOfLegends", "remindersEnabled", "hasSeenReminderPrimer"] {
            root.removeValue(forKey: key)
        }
        root["selectedDragonId"] = selected
        let dragons = try XCTUnwrap(root["dragons"] as? [[String: Any]])
        root["dragons"] = dragons.map { dragon -> [String: Any] in
            var d = dragon
            d.removeValue(forKey: "residence")
            d["isUnlocked"] = owned.contains(d["id"] as? String ?? "")
            var stats = d["stats"] as? [String: Any] ?? [:]
            for key in ["fitness", "condition", "fullnessZeroMinutes", "lowFitnessMinutes", "cureSessionsRemaining",
                        "tummyAcheUntil", "isSleepingEarly", "lastSimulatedAt", "stagesRewarded", "bornAt"] {
                stats.removeValue(forKey: key)
            }
            stats["health"] = 40
            d["stats"] = stats
            return d
        }
        return try JSONSerialization.data(withJSONObject: root)
    }
}
