//
//  BreedingTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class BreedingTests: XCTestCase {
    private let now = TestTime.date(day: 5, hour: 10)

    private func adult(_ id: String, residence: DragonResidence = .den) -> DragonModel {
        var d = DragonModel.defaultDragons().first { $0.id == id }!
        d.residence = residence
        d.stats.growthStage = .adult
        d.stats.level = 16
        return d
    }

    // MARK: - Rules

    func test_adultPair_canBreed() {
        XCTAssertNil(BreedingRules.refusal(adult("ember"), adult("frosty", residence: .sanctuary), stars: 50, now: now))
    }

    func test_refusals() {
        let ember = adult("ember")
        XCTAssertEqual(BreedingRules.refusal(ember, ember, stars: 99, now: now), .sameDragon)

        var young = adult("frosty")
        young.stats.growthStage = .young
        XCTAssertEqual(BreedingRules.refusal(ember, young, stars: 99, now: now), .tooYoung)

        XCTAssertEqual(BreedingRules.refusal(ember, adult("volt", residence: .legend), stars: 99, now: now), .notAvailable)

        var sick = adult("volt")
        sick.stats.condition = .ill(.hungerFever)
        XCTAssertEqual(BreedingRules.refusal(ember, sick, stars: 99, now: now), .notWell)

        var spirit = adult("volt")
        spirit.stats.condition = .spirit(diedAt: now)
        XCTAssertEqual(BreedingRules.refusal(spirit, ember, stars: 99, now: now), .notWell)

        XCTAssertEqual(BreedingRules.refusal(ember, adult("volt"), stars: 49, now: now), .notEnoughStars)
    }

    func test_parentsRestThreeDays() {
        var ember = adult("ember")
        ember.stats.lastBredAt = now.addingTimeInterval(-2 * 86_400)
        let until = now.addingTimeInterval(86_400)
        XCTAssertEqual(BreedingRules.refusal(ember, adult("volt"), stars: 99, now: now), .resting(until: until))
        XCTAssertEqual(BreedingRules.restUntil(ember, now: now), until)
        ember.stats.lastBredAt = now.addingTimeInterval(-3 * 86_400)
        XCTAssertNil(BreedingRules.refusal(ember, adult("volt"), stars: 99, now: now))
        XCTAssertNil(BreedingRules.restUntil(ember, now: now))
    }

    func test_ancientCanBreed() {
        var old = adult("terra")
        old.stats.growthStage = .ancient
        XCTAssertNil(BreedingRules.refusal(old, adult("ember"), stars: 50, now: now))
    }

    // MARK: - Eggs

    func test_hybridEgg_carriesLineageAndHatchesInSixHours() throws {
        let ember = adult("ember"), frosty = adult("frosty")
        let egg = BreedingRules.makeEgg(ember, frosty)
        let lineage = try XCTUnwrap(egg.lineage)
        XCTAssertEqual(lineage.parentA, "ember")
        XCTAssertEqual(lineage.parentB, "frosty")
        XCTAssertEqual(lineage.colorsA, [ember.primaryColorHex, ember.secondaryColorHex, ember.bellyColorHex])
        XCTAssertEqual(egg.hatchDuration, 6 * 3600)
        XCTAssertEqual(egg.displayName, "Hybrid egg")
        XCTAssertEqual(Egg(tier: .common).hatchDuration, EggTier.common.hatchDuration)
        XCTAssertEqual(Egg(tier: .common).displayName, EggTier.common.displayName)
    }

    func test_eggWithoutLineage_decodes() throws {
        let json = #"{"id":"6809679C-A19C-4004-A60A-B8D22BEF5068","tier":"common"}"#
        let egg = try JSONDecoder().decode(Egg.self, from: Data(json.utf8))
        XCTAssertNil(egg.lineage)
    }

    func test_statsWithoutLastBredAt_decode() throws {
        var root = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(DragonStats())) as? [String: Any])
        root.removeValue(forKey: "lastBredAt")
        let stats = try JSONDecoder().decode(DragonStats.self, from: JSONSerialization.data(withJSONObject: root))
        XCTAssertNil(stats.lastBredAt)
    }

    // MARK: - Hatching

    private func roster(alive: [String]) -> [DragonModel] {
        DragonModel.defaultDragons().map { d in
            var d = d
            d.residence = alive.contains(d.id) ? .den : .undiscovered
            return d
        }
    }

    func test_hybrid_hatchesAnUnownedSpeciesFromTheParentsFamilies() {
        let egg = BreedingRules.makeEgg(adult("ember"), adult("frosty"))
        let family = Set(EggTier.common.speciesIds + EggTier.uncommon.speciesIds).subtracting(["ember", "frosty"])
        var rng = SeededRNG(seed: 3)
        for _ in 0..<30 {
            guard case .dragon(let id) = EggHatcher.roll(egg, dragons: roster(alive: ["ember", "frosty", "sparkle"]), rng: &rng) else {
                return XCTFail("expected a dragon")
            }
            XCTAssertTrue(family.contains(id), id)
        }
    }

    func test_hybrid_movesUpATierWhenTheFamilyIsComplete() {
        let egg = BreedingRules.makeEgg(adult("ember"), adult("splash"))
        let alive = EggTier.common.speciesIds + ["sparkle"]
        var rng = SeededRNG(seed: 4)
        guard case .dragon(let id) = EggHatcher.roll(egg, dragons: roster(alive: alive), rng: &rng) else {
            return XCTFail("expected a dragon")
        }
        XCTAssertTrue(EggTier.uncommon.speciesIds.contains(id))
    }

    func test_hybrid_givesStarsWhenEveryCandidateIsAlive() {
        let egg = BreedingRules.makeEgg(adult("ember"), adult("splash"))
        let alive = EggTier.common.speciesIds + EggTier.uncommon.speciesIds + ["sparkle"]
        var rng = SeededRNG(seed: 5)
        XCTAssertEqual(EggHatcher.roll(egg, dragons: roster(alive: alive), rng: &rng), .stars(EggTier.rare.duplicateStars))
    }

    func test_starterParent_countsAsCommon() {
        let egg = BreedingRules.makeEgg(adult("sparkle"), adult("ember"))
        var rng = SeededRNG(seed: 6)
        guard case .dragon(let id) = EggHatcher.roll(egg, dragons: roster(alive: ["sparkle", "ember"]), rng: &rng) else {
            return XCTFail("expected a dragon")
        }
        XCTAssertTrue(EggTier.common.speciesIds.contains(id))
    }

    // MARK: - Look and skills

    func test_colorBlend() {
        XCTAssertEqual(ColorHex.blend("#000000", "#FFFFFF", t: 0.5), "#808080")
        XCTAssertEqual(ColorHex.blend("#FF0000", "#0000FF", t: 0), "#FF0000")
        XCTAssertEqual(ColorHex.blend("#FF0000", "#0000FF", t: 1), "#0000FF")
        XCTAssertEqual(ColorHex.blend("#abcdef", "#ABCDEF", t: 0.3), "#ABCDEF", "case-insensitive input, upper-case output")
        XCTAssertEqual(ColorHex.blend("nonsense", "#FFFFFF", t: 0.5), "nonsense", "bad input is left alone")
    }

    func test_hybridLook_mixesParentsIntoTheSpeciesColors() {
        let lineage = HybridLineage(parentA: "a", parentB: "b",
                                    colorsA: ["#000000", "#000000", "#000000"],
                                    colorsB: ["#FFFFFF", "#FFFFFF", "#FFFFFF"],
                                    bestSkill: .aim)
        let colors = BreedingRules.hybridColors(base: ["#000000", "#FFFFFF", "#808080"], lineage: lineage)
        // parents mix to #808080; each species colour moves 40% toward it
        XCTAssertEqual(colors, ["#333333", "#CCCCCC", "#808080"])
    }

    func test_bestSkill_isTheStrongestAcrossBothParents() {
        var ember = adult("ember")          // aim 3
        let berry = adult("berry")          // reflexes 4
        XCTAssertEqual(BreedingRules.makeEgg(ember, berry).lineage?.bestSkill, .reflexes)
        ember.stats.skillPoints = ["aim": 30] // aim 5
        XCTAssertEqual(BreedingRules.makeEgg(ember, berry).lineage?.bestSkill, .aim)
    }

    // MARK: - Game flow

    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("breed-\(UUID().uuidString).json")

    private func manager(stars: Int = 100) -> GameManager {
        makeTestManager(fileURL: fileURL, notifications: SpyScheduler(), now: now) { s in
            s.totalStars = stars
            for id in ["ember", "frosty"] {
                let i = s.dragons.firstIndex { $0.id == id }!
                s.dragons[i].residence = .den
                s.dragons[i].stats.growthStage = .adult
                s.dragons[i].stats.level = 16
                s.dragons[i].stats.lastSimulatedAt = self.now
            }
        }
    }

    func test_breed_spendsStarsRestsParentsAndAddsAnEgg() {
        let gm = manager()
        XCTAssertNil(gm.breed("ember", "frosty"))
        XCTAssertEqual(gm.state.totalStars, 50)
        XCTAssertEqual(gm.state.eggBasket.last?.lineage?.parentA, "ember")
        for id in ["ember", "frosty"] {
            XCTAssertEqual(gm.state.dragons.first { $0.id == id }?.stats.lastBredAt, gm.clock.now())
        }
        XCTAssertEqual(gm.breed("ember", "frosty"), .resting(until: gm.clock.now().addingTimeInterval(3 * 86_400)),
                       "a second tap is refused")
        XCTAssertEqual(gm.state.eggBasket.filter { $0.lineage != nil }.count, 1)
    }

    func test_breed_refusedChangesNothing() {
        let gm = manager(stars: 10)
        XCTAssertEqual(gm.breed("ember", "frosty"), .notEnoughStars)
        XCTAssertEqual(gm.state.totalStars, 10)
        XCTAssertTrue(gm.state.eggBasket.allSatisfy { $0.lineage == nil })
    }

    func test_hybridHatch_appliesTheBlendAndSkillBonus() throws {
        let gm = manager()
        XCTAssertNil(gm.breed("ember", "frosty"))
        let egg = try XCTUnwrap(gm.state.eggBasket.last)
        gm.state.incubatorSlots[0] = IncubatorSlot(egg: egg, warmth: 100, progress: 1, lastSimulatedAt: now)
        var rng = FixedRNG(value: .max)  // never shiny
        guard case .dragon(let id) = gm.crackEgg(slot: 0, rng: &rng) else { return XCTFail("expected a dragon") }
        let hatched = try XCTUnwrap(gm.state.dragons.first { $0.id == id })
        let base = DragonModel.defaultDragons().first { $0.id == id }!
        let lineage = try XCTUnwrap(egg.lineage)
        let expected = BreedingRules.hybridColors(base: [base.primaryColorHex, base.secondaryColorHex, base.bellyColorHex], lineage: lineage)
        XCTAssertEqual([hatched.primaryColorHex, hatched.secondaryColorHex, hatched.bellyColorHex], expected)
        XCTAssertEqual(hatched.skillPoints(lineage.bestSkill), 10)
        XCTAssertFalse(hatched.isShiny)
    }
}
