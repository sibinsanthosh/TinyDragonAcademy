//
//  BreedingRules.swift
//  Tiny Dragon Academy
//
//  The Dragon Nest: when two grown dragons may pair, the hybrid egg they
//  lay, and how the hatchling inherits a blend of their look and skills.
//

import Foundation

enum BreedingRefusal: Equatable {
    case sameDragon
    case tooYoung
    case notAvailable
    case notWell
    case resting(until: Date)
    case notEnoughStars

    var message: String {
        switch self {
        case .sameDragon: return "Pick two different dragons."
        case .tooYoung: return "Both dragons need to be Adult or Ancient."
        case .notAvailable: return "Both dragons must live in your den or sanctuary."
        case .notWell: return "Both dragons need to be healthy."
        case .resting: return "One of them is resting after their last nest."
        case .notEnoughStars: return "Pairing costs \(BreedingRules.price)★."
        }
    }
}

enum BreedingRules {
    static let price = 50
    static let restDays = 3.0
    /// Skill points a hatchling starts with in its parents' best skill: one star's worth.
    static let skillHeadStart = SkillRules.thresholds[0]
    /// How far each of the hatchling's colours moves toward its parents' mix.
    static let parentColorShare = 0.4

    static func refusal(_ a: DragonModel, _ b: DragonModel, stars: Int, now: Date) -> BreedingRefusal? {
        if a.id == b.id { return .sameDragon }
        for d in [a, b] where d.residence != .den && d.residence != .sanctuary { return .notAvailable }
        for d in [a, b] where d.stats.growthStage != .adult && d.stats.growthStage != .ancient { return .tooYoung }
        for d in [a, b] where d.stats.condition != .healthy { return .notWell }
        if let until = [a, b].compactMap({ restUntil($0, now: now) }).max() { return .resting(until: until) }
        if stars < price { return .notEnoughStars }
        return nil
    }

    /// When a dragon may pair again, or nil if it already can.
    static func restUntil(_ dragon: DragonModel, now: Date) -> Date? {
        guard let last = dragon.stats.lastBredAt else { return nil }
        let until = last.addingTimeInterval(restDays * 86_400)
        return until > now ? until : nil
    }

    static func makeEgg(_ a: DragonModel, _ b: DragonModel) -> Egg {
        Egg(tier: .rare, lineage: HybridLineage(
            parentA: a.id,
            parentB: b.id,
            colorsA: [a.primaryColorHex, a.secondaryColorHex, a.bellyColorHex],
            colorsB: [b.primaryColorHex, b.secondaryColorHex, b.bellyColorHex],
            bestSkill: bestSkill(a, b)
        ))
    }

    /// The highest-starred skill across both parents; ties go to the earlier skill.
    static func bestSkill(_ a: DragonModel, _ b: DragonModel) -> DragonSkill {
        func stars(_ s: DragonSkill) -> Int { max(a.skillStars(s), b.skillStars(s)) }
        return DragonSkill.allCases.reduce(DragonSkill.allCases[0]) { best, s in stars(s) > stars(best) ? s : best }
    }

    /// Each of the species' colours moved 40% toward the 50/50 mix of both parents.
    static func hybridColors(base: [String], lineage: HybridLineage) -> [String] {
        base.indices.map { i in
            guard i < lineage.colorsA.count, i < lineage.colorsB.count else { return base[i] }
            let parents = ColorHex.blend(lineage.colorsA[i], lineage.colorsB[i], t: 0.5)
            return ColorHex.blend(base[i], parents, t: parentColorShare)
        }
    }
}

enum ColorHex {
    /// Mixes two "#RRGGBB" colours: t = 0 gives `a`, t = 1 gives `b`. Bad input returns `a` unchanged.
    static func blend(_ a: String, _ b: String, t: Double) -> String {
        guard let ca = rgb(a), let cb = rgb(b) else { return a }
        let mixed = zip(ca, cb).map { pair -> Int in
            Int((Double(pair.0) + (Double(pair.1) - Double(pair.0)) * t).rounded())
        }
        return String(format: "#%02X%02X%02X", mixed[0], mixed[1], mixed[2])
    }

    private static func rgb(_ hex: String) -> [Int]? {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let v = Int(s, radix: 16) else { return nil }
        return [(v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF]
    }
}
