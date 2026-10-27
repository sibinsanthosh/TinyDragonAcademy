//
//  EggHatcherTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class EggHatcherTests: XCTestCase {
    private let t0 = TestTime.date(day: 5, hour: 8)

    private func slot(_ tier: EggTier, warmth: Double = 100) -> IncubatorSlot {
        IncubatorSlot(egg: Egg(tier: tier), warmth: warmth, progress: 0, lastSimulatedAt: t0)
    }

    private func dragons(_ residences: [String: DragonResidence]) -> [DragonModel] {
        DragonModel.defaultDragons().map { d in
            var d = d
            d.residence = residences[d.id] ?? .undiscovered
            return d
        }
    }

    // MARK: - Incubation

    func test_commonEgg_warm_hatchesInTwoHours_emitsReady() {
        let (almost, early) = LifeSimulator.advance(slot(.common), from: t0, to: t0.addingTimeInterval(7_140))
        XCTAssertFalse(almost.isReady)
        XCTAssertFalse(early.contains(.eggReady))
        let (done, events) = LifeSimulator.advance(slot(.common), from: t0, to: t0.addingTimeInterval(7_200))
        XCTAssertTrue(done.isReady)
        XCTAssertEqual(events.filter { $0 == .eggReady }.count, 1)
    }

    func test_coldEgg_hatchesAtHalfSpeed() {
        let (s, _) = LifeSimulator.advance(slot(.common, warmth: 0), from: t0, to: t0.addingTimeInterval(7_200))
        XCTAssertEqual(s.progress, 0.5, accuracy: 0.001)
    }

    func test_warmthDecay_emitsColdOnce() {
        let (s, events) = LifeSimulator.advance(slot(.legendary), from: t0, to: t0.addingTimeInterval(6 * 3600))
        XCTAssertEqual(s.warmth, 40, accuracy: 0.01)
        XCTAssertEqual(events.filter { $0 == .eggCold }.count, 1)
        XCTAssertEqual(s.lastSimulatedAt, t0.addingTimeInterval(6 * 3600))
    }

    func test_emptySlot_onlyUpdatesClock() {
        let empty = IncubatorSlot(lastSimulatedAt: t0)
        let (s, events) = LifeSimulator.advance(empty, from: t0, to: t0.addingTimeInterval(3600))
        XCTAssertEqual(s.warmth, 100)
        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(s.lastSimulatedAt, t0.addingTimeInterval(3600))
    }

    func test_warm_capsAt100() {
        var s = slot(.common, warmth: 95)
        EggHatcher.warm(&s)
        XCTAssertEqual(s.warmth, 100)
        s.warmth = 30
        EggHatcher.warm(&s)
        XCTAssertEqual(s.warmth, 40)
    }

    // MARK: - Rolling

    func test_roll_onlyPicksUndiscoveredOrLegend() {
        let roster = dragons(["ember": .den, "splash": .legend, "sprout": .undiscovered, "terra": .sanctuary])
        var rng = SeededRNG(seed: 1)
        var seen = Set<String>()
        for _ in 0..<50 {
            guard case .dragon(let id) = EggHatcher.roll(Egg(tier: .common), dragons: roster, rng: &rng) else {
                return XCTFail("expected a dragon")
            }
            seen.insert(id)
        }
        XCTAssertEqual(seen, ["splash", "sprout"])
    }

    func test_fixedSpecies_hatchesThatSpecies() {
        var rng = SeededRNG(seed: 2)
        let outcome = EggHatcher.roll(Egg(tier: .common, fixedSpeciesId: "terra"), dragons: dragons(["terra": .legend]), rng: &rng)
        XCTAssertEqual(outcome, .dragon(id: "terra"))
    }

    func test_fixedSpeciesAlive_fallsBackToTierRoll() {
        var rng = SeededRNG(seed: 3)
        let roster = dragons(["ember": .den, "splash": .den, "sprout": .den])
        let outcome = EggHatcher.roll(Egg(tier: .common, fixedSpeciesId: "ember"), dragons: roster, rng: &rng)
        XCTAssertEqual(outcome, .dragon(id: "terra"))
    }

    func test_tierExhausted_givesStars() {
        var rng = SeededRNG(seed: 4)
        let roster = dragons(["ember": .den, "splash": .sanctuary, "sprout": .den, "terra": .den])
        XCTAssertEqual(EggHatcher.roll(Egg(tier: .common), dragons: roster, rng: &rng), .stars(12))
    }

    func test_rollShiny_oneInTwenty() {
        var lucky = FixedRNG(value: 0)
        XCTAssertTrue(EggHatcher.rollShiny(rng: &lucky))
        var unlucky = FixedRNG(value: .max)
        XCTAssertFalse(EggHatcher.rollShiny(rng: &unlucky))
        XCTAssertEqual(EggHatcher.shinyChance, 0.05)
    }

    func test_shinyPalette_coversEveryElement() {
        for element in DragonElement.allCases {
            let colors = ShinyPalette.colors(for: element)
            XCTAssertTrue([colors.primary, colors.secondary, colors.belly].allSatisfy { $0.hasPrefix("#") && $0.count == 7 }, "\(element)")
        }
    }

    func test_seededRNG_isDeterministic() {
        var a = SeededRNG(seed: 42)
        var b = SeededRNG(seed: 42)
        XCTAssertEqual((0..<5).map { _ in a.next() }, (0..<5).map { _ in b.next() })
    }
}
