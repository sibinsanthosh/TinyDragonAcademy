//
//  DragonSkills.swift
//  Tiny Dragon Academy
//
//  What makes each dragon play differently: four skills that grow with
//  training (each tied to one training game) and one signature talent per
//  species that only works in its own game.
//

import Foundation

enum DragonSkill: String, Codable, CaseIterable, Identifiable {
    case stamina, aim, agility, reflexes

    var id: String { rawValue }

    var game: TrainingGameType {
        switch self {
        case .stamina: return .dragonDash
        case .aim: return .fireTarget
        case .agility: return .skyFlight
        case .reflexes: return .snackCatch
        }
    }

    var title: String { game.trainsLabel }

    var iconName: String {
        switch self {
        case .stamina: return "figure.run"
        case .aim: return "scope"
        case .agility: return "wind"
        case .reflexes: return "bolt.fill"
        }
    }

    static func forGame(_ game: TrainingGameType) -> DragonSkill {
        allCases.first { $0.game == game } ?? .stamina
    }
}

enum DragonTalent: String, Codable, CaseIterable {
    case splashBlast, chainBolt, frozenField, laserShot
    case rockHide, leafGlide, sunriseSprint
    case tailwind, bubbleShield, moonFloat, starMagnet
    case waveGuard, sweetTooth, blossomDrift, rainbowLuck

    var title: String {
        switch self {
        case .splashBlast: return "Splash Blast"
        case .chainBolt: return "Chain Bolt"
        case .frozenField: return "Frozen Field"
        case .laserShot: return "Laser Shot"
        case .rockHide: return "Rock Hide"
        case .leafGlide: return "Leaf Glide"
        case .sunriseSprint: return "Sunrise Sprint"
        case .tailwind: return "Tailwind"
        case .bubbleShield: return "Bubble Shield"
        case .moonFloat: return "Moon Float"
        case .starMagnet: return "Star Magnet"
        case .waveGuard: return "Wave Guard"
        case .sweetTooth: return "Sweet Tooth"
        case .blossomDrift: return "Blossom Drift"
        case .rainbowLuck: return "Rainbow Luck"
        }
    }

    var summary: String {
        switch self {
        case .splashBlast: return "Fireballs burst and hit nearby targets too."
        case .chainBolt: return "Every hit zaps the nearest other target."
        case .frozenField: return "Targets move at half speed."
        case .laserShot: return "Shots fly straight and pierce through targets."
        case .rockHide: return "Shrugs off the first crash in each run."
        case .leafGlide: return "Holding jump floats much longer."
        case .sunriseSprint: return "Distance scores 25% faster."
        case .tailwind: return "Falls 20% slower between flaps."
        case .bubbleShield: return "Bounces off the first cloud it bumps."
        case .moonFloat: return "Clouds drift by 15% slower."
        case .starMagnet: return "Pulls in gems from twice as far."
        case .waveGuard: return "The first storm doesn't cost a life."
        case .sweetTooth: return "Every snack is worth double points."
        case .blossomDrift: return "Snacks float down 20% slower."
        case .rainbowLuck: return "Storms come half as often."
        }
    }

    var game: TrainingGameType {
        switch self {
        case .splashBlast, .chainBolt, .frozenField, .laserShot: return .fireTarget
        case .rockHide, .leafGlide, .sunriseSprint: return .dragonDash
        case .tailwind, .bubbleShield, .moonFloat, .starMagnet: return .skyFlight
        case .waveGuard, .sweetTooth, .blossomDrift, .rainbowLuck: return .snackCatch
        }
    }
}

/// Per-species starting skills and talent. Totals rise with egg rarity
/// (common 8, uncommon 9, rare 10, legendary 11); the talent's skill is the highest.
enum SpeciesTraits {
    private struct Traits {
        let stamina: Int, aim: Int, agility: Int, reflexes: Int
        let talent: DragonTalent
    }

    private static let table: [String: Traits] = [
        "sparkle": Traits(stamina: 2, aim: 2, agility: 3, reflexes: 1, talent: .starMagnet),
        "ember": Traits(stamina: 2, aim: 3, agility: 1, reflexes: 2, talent: .splashBlast),
        "splash": Traits(stamina: 1, aim: 2, agility: 3, reflexes: 2, talent: .bubbleShield),
        "sprout": Traits(stamina: 3, aim: 1, agility: 2, reflexes: 2, talent: .leafGlide),
        "terra": Traits(stamina: 3, aim: 2, agility: 1, reflexes: 2, talent: .rockHide),
        "frosty": Traits(stamina: 1, aim: 3, agility: 2, reflexes: 3, talent: .frozenField),
        "volt": Traits(stamina: 2, aim: 3, agility: 1, reflexes: 3, talent: .chainBolt),
        "zephyr": Traits(stamina: 1, aim: 2, agility: 3, reflexes: 3, talent: .tailwind),
        "flora": Traits(stamina: 3, aim: 1, agility: 2, reflexes: 3, talent: .blossomDrift),
        "nova": Traits(stamina: 2, aim: 4, agility: 3, reflexes: 1, talent: .laserShot),
        "sunny": Traits(stamina: 4, aim: 1, agility: 3, reflexes: 2, talent: .sunriseSprint),
        "bubble": Traits(stamina: 3, aim: 1, agility: 2, reflexes: 4, talent: .waveGuard),
        "berry": Traits(stamina: 2, aim: 1, agility: 3, reflexes: 4, talent: .sweetTooth),
        "twinkle": Traits(stamina: 3, aim: 1, agility: 4, reflexes: 3, talent: .moonFloat),
        "rainbow": Traits(stamina: 3, aim: 3, agility: 1, reflexes: 4, talent: .rainbowLuck),
    ]

    static func baseStars(_ speciesId: String) -> [DragonSkill: Int] {
        guard let t = table[speciesId] else {
            return Dictionary(uniqueKeysWithValues: DragonSkill.allCases.map { ($0, 2) })
        }
        return [.stamina: t.stamina, .aim: t.aim, .agility: t.agility, .reflexes: t.reflexes]
    }

    static func talent(_ speciesId: String) -> DragonTalent? {
        table[speciesId]?.talent
    }
}

enum SkillRules {
    static let maxStars = 5
    /// Cumulative points for each star earned above the species base (10, 20, 35, 50 apart).
    static let thresholds = [10, 30, 65, 115]

    /// 1–3 points per counted session, more for a better score.
    static func points(forNormalizedScore score: Double) -> Int {
        1 + Int((2 * min(1, max(0, score))).rounded())
    }

    static func stars(base: Int, points: Int) -> Int {
        min(maxStars, base + thresholds.filter { points >= $0 }.count)
    }

    /// Stars now, points earned toward the next star, and that star's cost (nil at 5★).
    static func progress(base: Int, points: Int) -> (stars: Int, into: Int, needed: Int?) {
        let current = stars(base: base, points: points)
        let earned = current - base
        guard current < maxStars, earned < thresholds.count else { return (current, 0, nil) }
        let floor = earned == 0 ? 0 : thresholds[earned - 1]
        return (current, points - floor, thresholds[earned] - floor)
    }
}

extension DragonModel {
    func skillPoints(_ skill: DragonSkill) -> Int {
        stats.skillPoints[skill.rawValue] ?? 0
    }

    func skillStars(_ skill: DragonSkill) -> Int {
        SkillRules.stars(base: SpeciesTraits.baseStars(id)[skill] ?? 1, points: skillPoints(skill))
    }

    func skillProgress(_ skill: DragonSkill) -> (stars: Int, into: Int, needed: Int?) {
        SkillRules.progress(base: SpeciesTraits.baseStars(id)[skill] ?? 1, points: skillPoints(skill))
    }

    var talent: DragonTalent? { SpeciesTraits.talent(id) }
}
