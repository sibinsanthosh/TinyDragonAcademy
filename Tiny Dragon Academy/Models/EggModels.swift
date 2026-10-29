//
//  EggModels.swift
//  Tiny Dragon Academy
//
//  Mystery egg tiers, eggs, and incubator slots.
//

import SwiftUI

enum EggTier: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case legendary

    var speciesIds: [String] {
        switch self {
        case .common: return ["ember", "splash", "sprout", "terra"]
        case .uncommon: return ["frosty", "volt", "zephyr", "flora"]
        case .rare: return ["nova", "sunny", "bubble", "berry"]
        case .legendary: return ["twinkle", "rainbow"]
        }
    }

    var hatchDuration: TimeInterval {
        switch self {
        case .common: return 2 * 3600
        case .uncommon: return 4 * 3600
        case .rare: return 8 * 3600
        case .legendary: return 12 * 3600
        }
    }

    /// Star price in the shop; legendary eggs cannot be bought.
    var shopPrice: Int? {
        switch self {
        case .common: return 25
        case .uncommon: return 50
        case .rare: return 100
        case .legendary: return nil
        }
    }

    /// Stars granted instead of a dragon when every species in the tier is alive.
    var duplicateStars: Int {
        switch self {
        case .common: return 12
        case .uncommon: return 25
        case .rare: return 50
        case .legendary: return 100
        }
    }

    var displayName: String {
        switch self {
        case .common: return "Common Egg"
        case .uncommon: return "Uncommon Egg"
        case .rare: return "Rare Egg"
        case .legendary: return "Legendary Egg"
        }
    }

    var shellColor: Color {
        switch self {
        case .common: return DragonPalette.mintGreen
        case .uncommon: return DragonPalette.skyBlue
        case .rare: return DragonPalette.softPurple
        case .legendary: return DragonPalette.buttercup
        }
    }

    static func tier(forSpecies id: String) -> EggTier? {
        allCases.first { $0.speciesIds.contains(id) }
    }
}

struct Egg: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var tier: EggTier
    /// Set only for eggs returned when a spirit's revive window expires.
    var fixedSpeciesId: String? = nil
    /// Set only for eggs laid in the Dragon Nest.
    var lineage: HybridLineage? = nil

    static let hybridHatchDuration: TimeInterval = 6 * 3600

    var hatchDuration: TimeInterval { lineage == nil ? tier.hatchDuration : Self.hybridHatchDuration }
    var displayName: String { lineage == nil ? tier.displayName : "Hybrid egg" }
    var shellColor: Color { lineage == nil ? tier.shellColor : Color(red: 0.86, green: 0.55, blue: 0.95) }
}

/// The two parents of a Dragon Nest egg: who they were and what they looked like when they paired.
struct HybridLineage: Codable, Equatable {
    let parentA: String
    let parentB: String
    /// Primary, secondary and belly colour hexes.
    let colorsA: [String]
    let colorsB: [String]
    /// The parents' strongest skill, which the hatchling gets a head start in.
    let bestSkill: DragonSkill
}

struct IncubatorSlot: Codable, Equatable {
    var egg: Egg? = nil
    var warmth: Double = 100
    /// 0…1 hatch progress.
    var progress: Double = 0
    var lastSimulatedAt: Date

    var isReady: Bool { egg != nil && progress >= 1 }
}
