//
//  EggHatcher.swift
//  Tiny Dragon Academy
//
//  Warming eggs and rolling which species hatches from a mystery egg.
//

import Foundation

enum HatchOutcome: Equatable {
    case dragon(id: String)
    case stars(Int)
}

enum EggHatcher {
    static let warmthPerTap = 10.0
    static let shinyChance = 0.05

    /// One in twenty hatches is shiny.
    static func rollShiny(rng: inout some RandomNumberGenerator) -> Bool {
        Double.random(in: 0..<1, using: &rng) < shinyChance
    }

    static func warm(_ slot: inout IncubatorSlot) {
        guard slot.egg != nil else { return }
        slot.warmth = min(100, slot.warmth + warmthPerTap)
    }

    /// Picks a species that isn't currently alive (undiscovered or memorialized).
    static func roll(_ egg: Egg, dragons: [DragonModel], rng: inout some RandomNumberGenerator) -> HatchOutcome {
        let available = Set(dragons.filter { $0.residence == .undiscovered || $0.residence == .legend }.map(\.id))
        if let lineage = egg.lineage {
            return rollHybrid(lineage, available: available, rng: &rng)
        }
        if let fixed = egg.fixedSpeciesId, available.contains(fixed) {
            return .dragon(id: fixed)
        }
        let candidates = egg.tier.speciesIds.filter { available.contains($0) }
        guard let pick = candidates.randomElement(using: &rng) else {
            return .stars(egg.tier.duplicateStars)
        }
        return .dragon(id: pick)
    }

    /// A species not alive yet from the parents' egg families, else one family up, else stars.
    private static func rollHybrid(_ lineage: HybridLineage, available: Set<String>, rng: inout some RandomNumberGenerator) -> HatchOutcome {
        let tiers = [lineage.parentA, lineage.parentB].map { EggTier.tier(forSpecies: $0) ?? .common }
        let family = tiers.flatMap(\.speciesIds).filter { available.contains($0) }
        if let pick = family.randomElement(using: &rng) { return .dragon(id: pick) }
        let all = EggTier.allCases
        let highest = tiers.compactMap { all.firstIndex(of: $0) }.max() ?? 0
        if highest + 1 < all.count,
           let pick = all[highest + 1].speciesIds.filter({ available.contains($0) }).randomElement(using: &rng) {
            return .dragon(id: pick)
        }
        return .stars(BreedingRules.price)
    }
}
