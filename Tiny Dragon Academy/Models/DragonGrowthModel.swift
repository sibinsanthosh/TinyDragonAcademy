//
//  DragonGrowthModel.swift
//  Tiny Dragon Academy
//
//  Comprehensive data models for Dragon Growth, Five Evolution Stages,
//  Interactive Feeding, Elemental Powers, and Achievements.
//

import SwiftUI

// MARK: - Growth Stages

enum GrowthStage: String, Codable, CaseIterable, Comparable {
    case baby = "Baby Dragon"
    case young = "Young Dragon"
    case adolescent = "Adolescent Dragon"
    case adult = "Adult Dragon"
    case ancient = "Ancient Dragon"
    
    var stageIndex: Int {
        switch self {
        case .baby: return 1
        case .young: return 2
        case .adolescent: return 3
        case .adult: return 4
        case .ancient: return 5
        }
    }
    
    static func < (lhs: GrowthStage, rhs: GrowthStage) -> Bool {
        lhs.stageIndex < rhs.stageIndex
    }
    
    var iconName: String {
        switch self {
        case .baby: return "sparkles"
        case .young: return "leaf.fill"
        case .adolescent: return "wind"
        case .adult: return "flame.fill"
        case .ancient: return "crown.fill"
        }
    }
    
    var levelRange: ClosedRange<Int> {
        switch self {
        case .baby: return 1...4
        case .young: return 5...9
        case .adolescent: return 10...14
        case .adult: return 15...19
        case .ancient: return 20...50
        }
    }
    
    var minLevel: Int { levelRange.lowerBound }
    
    var requiredXPToNextStage: Int {
        switch self {
        case .baby: return 100 // Level 5 unlocks Young
        case .young: return 250 // Level 10 unlocks Adolescent
        case .adolescent: return 500 // Level 15 unlocks Adult
        case .adult: return 1000 // Level 20 unlocks Ancient
        case .ancient: return 2500 // Mastery levels
        }
    }
    
    var scaleMultiplier: CGFloat {
        switch self {
        case .baby: return 1.0
        case .young: return 1.18
        case .adolescent: return 1.36
        case .adult: return 1.55
        case .ancient: return 1.75
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .baby: return DragonPalette.softPurple
        case .young: return DragonPalette.mintGreen
        case .adolescent: return DragonPalette.skyBlue
        case .adult: return DragonPalette.coral
        case .ancient: return DragonPalette.buttercup
        }
    }
    
    var description: String {
        switch self {
        case .baby: return "Cute, cuddly, and just discovering its magic."
        case .young: return "Playful and curious, learning its first elemental attack."
        case .adolescent: return "Fast and agile, practicing powerful projectile spells."
        case .adult: return "Majestic and strong, commanding signature elemental forces."
        case .ancient: return "A legendary master of elemental magic with a glowing aura."
        }
    }
    
    var nextStage: GrowthStage? {
        switch self {
        case .baby: return .young
        case .young: return .adolescent
        case .adolescent: return .adult
        case .adult: return .ancient
        case .ancient: return nil
        }
    }

    var previousStage: GrowthStage? {
        switch self {
        case .baby: return nil
        case .young: return .baby
        case .adolescent: return .young
        case .adult: return .adolescent
        case .ancient: return .adult
        }
    }
}

// MARK: - Food Types

enum FoodType: String, Codable, CaseIterable, Identifiable {
    case fireBerries = "Fire Berries"
    case frostApples = "Frost Apples"
    case crystalShards = "Crystal Candies"
    case starfishTreats = "Starfish Cookies"
    case dragonRoast = "Dragon Roast"
    case goldenFruit = "Magical Golden Fruit"
    case moonbeamPudding = "Moonbeam Pudding"
    case sunbeamOrange = "Sunbeam Orange"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .fireBerries: return "flame.fill"
        case .frostApples: return "snowflake"
        case .crystalShards: return "suit.diamond.fill"
        case .starfishTreats: return "star.fill"
        case .dragonRoast: return "fork.knife"
        case .goldenFruit: return "sparkles"
        case .moonbeamPudding: return "moon.stars.fill"
        case .sunbeamOrange: return "sun.max.fill"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .fireBerries: return DragonPalette.coral
        case .frostApples: return DragonPalette.skyBlue
        case .crystalShards: return DragonPalette.lavender
        case .starfishTreats: return DragonPalette.buttercup
        case .dragonRoast: return Color(red: 0.85, green: 0.45, blue: 0.35)
        case .goldenFruit: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .moonbeamPudding: return Color(red: 0.65, green: 0.60, blue: 0.95)
        case .sunbeamOrange: return Color(red: 1.0, green: 0.60, blue: 0.20)
        }
    }
    
    var hungerRestored: Double {
        switch self {
        case .fireBerries: return 20.0
        case .frostApples: return 22.0
        case .crystalShards: return 18.0
        case .starfishTreats: return 15.0
        case .dragonRoast: return 40.0
        case .goldenFruit: return 50.0
        case .moonbeamPudding: return 25.0
        case .sunbeamOrange: return 24.0
        }
    }
    
    var happinessRestored: Double {
        switch self {
        case .fireBerries: return 15.0
        case .frostApples: return 15.0
        case .crystalShards: return 20.0
        case .starfishTreats: return 18.0
        case .dragonRoast: return 10.0
        case .goldenFruit: return 40.0
        case .moonbeamPudding: return 22.0
        case .sunbeamOrange: return 20.0
        }
    }
    
    var energyRestored: Double {
        switch self {
        case .fireBerries: return 10.0
        case .frostApples: return 12.0
        case .crystalShards: return 25.0
        case .starfishTreats: return 10.0
        case .dragonRoast: return 30.0
        case .goldenFruit: return 50.0
        case .moonbeamPudding: return 15.0
        case .sunbeamOrange: return 20.0
        }
    }
    
    var baseXP: Int {
        switch self {
        case .fireBerries: return 15
        case .frostApples: return 15
        case .crystalShards: return 20
        case .starfishTreats: return 12
        case .dragonRoast: return 25
        case .goldenFruit: return 60
        case .moonbeamPudding: return 18
        case .sunbeamOrange: return 18
        }
    }
    
    var purchaseStarCost: Int {
        switch self {
        case .fireBerries: return 2
        case .frostApples: return 2
        case .crystalShards: return 3
        case .starfishTreats: return 2
        case .dragonRoast: return 4
        case .goldenFruit: return 10
        case .moonbeamPudding: return 3
        case .sunbeamOrange: return 3
        }
    }
    
    var description: String {
        switch self {
        case .fireBerries: return "Warm spicy berries that spark with cozy warmth."
        case .frostApples: return "Chilled apples with a frosty, refreshing crunch."
        case .crystalShards: return "Sweet glittering crystals packed with pure magic."
        case .starfishTreats: return "Fun sea-star cookies that crunch delightfully."
        case .dragonRoast: return "Hearty, savory feast for hungry growing dragons."
        case .goldenFruit: return "Legendary orchard fruit that grants massive growth & sparkles!"
        case .moonbeamPudding: return "Creamy glowing pudding that soothes dragon dreams."
        case .sunbeamOrange: return "Zesty golden citrus brimming with daylight energy."
        }
    }
}

// MARK: - Elemental Powers

enum PowerAnimationStyle: String, Codable {
    case flameBreath
    case frostBlast
    case lightningBolt
    case laserBeam
    case earthShockwave
    case starlightBurst
    case bubbleStream
    case petalWhirl
}

struct ElementalPower: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let element: DragonElement
    let stageRequired: GrowthStage
    let levelRequired: Int
    let energyCost: Double
    let cooldownSeconds: Double
    let iconName: String
    let animationStyle: PowerAnimationStyle
    let description: String
    var upgradeLevel: Int = 1
    
    var maxUpgradeLevel: Int { 3 }
    
    var displayPowerRating: Int {
        (stageRequired.stageIndex * 20) + (upgradeLevel * 10)
    }
}

// MARK: - Dragon Stats & Raising State

struct DragonStats: Codable, Equatable {
    var hunger: Double = 85.0       // 0.0 to 100.0 (100 = full)
    var happiness: Double = 90.0    // 0.0 to 100.0 (100 = ecstatic)
    var energy: Double = 100.0      // 0.0 to 100.0 (100 = full stamina)
    var health: Double = 100.0      // 0.0 to 100.0 (100 = perfect)
    
    var experience: Int = 0
    var level: Int = 1
    var growthStage: GrowthStage = .baby
    var ageInDays: Int = 1
    var totalFeedings: Int = 0
    var favoriteFoodDiscovered: Bool = false
    var lastCareTimestamp: Date = Date()
    var lastFeedingTimestamp: Date = Date()
    
    var unlockedPowerIds: Set<String> = []
    var equippedPowerId: String? = nil

    // Life simulation state
    var fitness: Double = 100.0     // 0.0 to 100.0 (training level)
    var condition: DragonCondition = .healthy
    var fullnessZeroMinutes: Double = 0     // consecutive awake minutes at 0 fullness
    var lowFitnessMinutes: Double = 0       // consecutive awake minutes below low-fitness threshold
    var cureSessionsRemaining: Int = 0
    var tummyAcheUntil: Date? = nil
    var isSleepingEarly: Bool = false
    var lastSimulatedAt: Date = Date()
    var stagesRewarded: Set<GrowthStage> = [.baby]
    var bornAt: Date = Date()

    init() {}

    enum CodingKeys: String, CodingKey {
        case hunger, happiness, energy, health
        case experience, level, growthStage, ageInDays, totalFeedings, favoriteFoodDiscovered
        case lastCareTimestamp, lastFeedingTimestamp, unlockedPowerIds, equippedPowerId
        case fitness, condition, fullnessZeroMinutes, lowFitnessMinutes, cureSessionsRemaining
        case tummyAcheUntil, isSleepingEarly, lastSimulatedAt, stagesRewarded, bornAt
    }

    // Every field is optional on decode so saves from older versions keep loading.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hunger = try c.decodeIfPresent(Double.self, forKey: .hunger) ?? 85.0
        happiness = try c.decodeIfPresent(Double.self, forKey: .happiness) ?? 90.0
        energy = try c.decodeIfPresent(Double.self, forKey: .energy) ?? 100.0
        health = try c.decodeIfPresent(Double.self, forKey: .health) ?? 100.0
        experience = try c.decodeIfPresent(Int.self, forKey: .experience) ?? 0
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
        growthStage = try c.decodeIfPresent(GrowthStage.self, forKey: .growthStage) ?? .baby
        ageInDays = try c.decodeIfPresent(Int.self, forKey: .ageInDays) ?? 1
        totalFeedings = try c.decodeIfPresent(Int.self, forKey: .totalFeedings) ?? 0
        favoriteFoodDiscovered = try c.decodeIfPresent(Bool.self, forKey: .favoriteFoodDiscovered) ?? false
        lastCareTimestamp = try c.decodeIfPresent(Date.self, forKey: .lastCareTimestamp) ?? Date()
        lastFeedingTimestamp = try c.decodeIfPresent(Date.self, forKey: .lastFeedingTimestamp) ?? Date()
        unlockedPowerIds = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedPowerIds) ?? []
        equippedPowerId = try c.decodeIfPresent(String.self, forKey: .equippedPowerId)
        fitness = try c.decodeIfPresent(Double.self, forKey: .fitness) ?? 100.0
        condition = try c.decodeIfPresent(DragonCondition.self, forKey: .condition) ?? .healthy
        fullnessZeroMinutes = try c.decodeIfPresent(Double.self, forKey: .fullnessZeroMinutes) ?? 0
        lowFitnessMinutes = try c.decodeIfPresent(Double.self, forKey: .lowFitnessMinutes) ?? 0
        cureSessionsRemaining = try c.decodeIfPresent(Int.self, forKey: .cureSessionsRemaining) ?? 0
        tummyAcheUntil = try c.decodeIfPresent(Date.self, forKey: .tummyAcheUntil)
        isSleepingEarly = try c.decodeIfPresent(Bool.self, forKey: .isSleepingEarly) ?? false
        lastSimulatedAt = try c.decodeIfPresent(Date.self, forKey: .lastSimulatedAt) ?? Date()
        stagesRewarded = try c.decodeIfPresent(Set<GrowthStage>.self, forKey: .stagesRewarded) ?? [.baby]
        bornAt = try c.decodeIfPresent(Date.self, forKey: .bornAt) ?? Date()
    }

    var canEvolve: Bool {
        guard let next = growthStage.nextStage else { return false }
        return level >= next.minLevel
    }
    
    var currentLevelProgress: Double {
        let currentLevelBaseXP = xpRequiredForLevel(level)
        let nextLevelXP = xpRequiredForLevel(level + 1)
        guard nextLevelXP > currentLevelBaseXP else { return 1.0 }
        let progress = Double(experience - currentLevelBaseXP) / Double(nextLevelXP - currentLevelBaseXP)
        return min(max(progress, 0.0), 1.0)
    }
    
    func xpRequiredForLevel(_ lvl: Int) -> Int {
        if lvl <= 1 { return 0 }
        // Smooth progression curve: level 2 = 30, level 5 = 150, level 10 = 500, level 20 = 2000
        return Int(Double(lvl - 1) * 35.0 + pow(Double(lvl - 1), 1.6) * 15.0)
    }
    
    static func defaultStats(for element: DragonElement = .fire) -> DragonStats {
        var stats = DragonStats()
        let startingPower = ElementalPowersCatalog.powers(for: element).first?.id ?? "fire_1"
        stats.unlockedPowerIds = [startingPower]
        return stats
    }
}

// MARK: - Achievements

struct DragonAchievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let targetCount: Int
    var currentProgress: Int
    var isUnlocked: Bool
    var rewardStars: Int
    
    var progressFraction: Double {
        guard targetCount > 0 else { return 0.0 }
        return min(Double(currentProgress) / Double(targetCount), 1.0)
    }
}
