//
//  DragonSkillsTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class DragonSkillsTests: XCTestCase {
    private let ids = DragonModel.defaultDragons().map(\.id)

    func test_everySpecies_hasBaseStarsAndATalent() {
        XCTAssertEqual(ids.count, 15)
        for id in ids {
            XCTAssertEqual(SpeciesTraits.baseStars(id).count, 4, id)
            XCTAssertNotNil(SpeciesTraits.talent(id), id)
        }
        XCTAssertEqual(Set(ids.compactMap(SpeciesTraits.talent)).count, 15, "each species has its own talent")
    }

    func test_starTotals_growWithEggRarity() {
        func total(_ id: String) -> Int { SpeciesTraits.baseStars(id).values.reduce(0, +) }
        XCTAssertEqual(total("sparkle"), 8, "the starter counts as common")
        let expected: [EggTier: Int] = [.common: 8, .uncommon: 9, .rare: 10, .legendary: 11]
        for tier in EggTier.allCases {
            for id in tier.speciesIds {
                XCTAssertEqual(total(id), expected[tier], id)
            }
        }
    }

    func test_talentSkill_isTheStrongest() throws {
        for id in ids {
            let stars = SpeciesTraits.baseStars(id)
            let talent = try XCTUnwrap(SpeciesTraits.talent(id))
            let talentSkill = DragonSkill.forGame(talent.game)
            XCTAssertEqual(stars[talentSkill], stars.values.max(), id)
            XCTAssertTrue(stars.values.allSatisfy { (1...5).contains($0) }, id)
        }
    }

    func test_skillsMapOneToOneOntoGames() {
        XCTAssertEqual(Set(DragonSkill.allCases.map(\.game)), Set(TrainingGameType.allCases))
        for skill in DragonSkill.allCases {
            XCTAssertEqual(DragonSkill.forGame(skill.game), skill)
        }
        XCTAssertEqual(DragonSkill.aim.title, TrainingGameType.fireTarget.trainsLabel)
    }

    func test_stars_followCumulativeThresholds() {
        XCTAssertEqual(SkillRules.stars(base: 2, points: 0), 2)
        XCTAssertEqual(SkillRules.stars(base: 2, points: 9), 2)
        XCTAssertEqual(SkillRules.stars(base: 2, points: 10), 3)
        XCTAssertEqual(SkillRules.stars(base: 2, points: 30), 4)
        XCTAssertEqual(SkillRules.stars(base: 2, points: 65), 5)
        XCTAssertEqual(SkillRules.stars(base: 1, points: 115), 5)
        XCTAssertEqual(SkillRules.stars(base: 4, points: 500), 5, "capped at 5")
    }

    func test_progress_reportsPointsTowardNextStar() {
        let p = SkillRules.progress(base: 2, points: 15)
        XCTAssertEqual(p.stars, 3)
        XCTAssertEqual(p.into, 5)
        XCTAssertEqual(p.needed, 20)
        XCTAssertNil(SkillRules.progress(base: 5, points: 0).needed, "nothing left at 5★")
    }

    func test_points_dependOnScore() {
        XCTAssertEqual(SkillRules.points(forNormalizedScore: 0), 1)
        XCTAssertEqual(SkillRules.points(forNormalizedScore: 0.5), 2)
        XCTAssertEqual(SkillRules.points(forNormalizedScore: 1), 3)
        XCTAssertEqual(SkillRules.points(forNormalizedScore: 7), 3)
    }

    func test_dragonSkillStars_useSpeciesBasePlusPoints() {
        var ember = DragonModel.defaultDragons().first { $0.id == "ember" }!
        XCTAssertEqual(ember.skillStars(.aim), 3)
        XCTAssertEqual(ember.skillStars(.agility), 1)
        ember.stats.skillPoints[DragonSkill.agility.rawValue] = 10
        XCTAssertEqual(ember.skillStars(.agility), 2)
        XCTAssertEqual(ember.talent, .splashBlast)
    }

    func test_legacyStats_decodeWithNoSkillPoints() throws {
        var root = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(DragonStats())) as? [String: Any])
        root.removeValue(forKey: "skillPoints")
        let stats = try JSONDecoder().decode(DragonStats.self, from: JSONSerialization.data(withJSONObject: root))
        XCTAssertEqual(stats.skillPoints, [:])
    }

    func test_skillPoints_roundTrip() throws {
        var stats = try JSONDecoder().decode(DragonStats.self, from: JSONEncoder().encode(DragonStats()))
        stats.skillPoints = ["aim": 12, "stamina": 3]
        let decoded = try JSONDecoder().decode(DragonStats.self, from: JSONEncoder().encode(stats))
        XCTAssertEqual(decoded.skillPoints, stats.skillPoints)
    }
}
