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

    static func warm(_ slot: inout IncubatorSlot) {
        guard slot.egg != nil else { return }
        slot.warmth = min(100, slot.warmth + warmthPerTap)
    }

    /// Picks a species that isn't currently alive (undiscovered or memorialized).
    static func roll(_ egg: Egg, dragons: [DragonModel], rng: inout some RandomNumberGenerator) -> HatchOutcome {
        let available = Set(dragons.filter { $0.residence == .undiscovered || $0.residence == .legend }.map(\.id))
        if let fixed = egg.fixedSpeciesId, available.contains(fixed) {
            return .dragon(id: fixed)
        }
        let candidates = egg.tier.speciesIds.filter { available.contains($0) }
        guard let pick = candidates.randomElement(using: &rng) else {
            return .stars(egg.tier.duplicateStars)
        }
        return .dragon(id: pick)
    }
}
