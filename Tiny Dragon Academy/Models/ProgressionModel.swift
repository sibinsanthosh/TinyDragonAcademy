//
//  ProgressionModel.swift
//  Tiny Dragon Academy
//
//  Persistent state for stars, completed milestones, child accessibility options,
//  food inventory, achievements, and onboarding completion.
//

import Foundation

struct UserSettings: Codable, Equatable {
    var isSoundEnabled: Bool = true
    var isMusicEnabled: Bool = true
    var reduceMotion: Bool = false
    var highContrastHints: Bool = false
    var spokenVoiceAssistance: Bool = true
}

struct Milestone: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isCompleted: Bool
}

struct AppProgressState: Codable, Equatable {
    var hasCompletedOnboarding: Bool = false
    var totalStars: Int = 10 // Start with a few celebratory welcome stars!
    var selectedDragonId: String = "sparkle"
    var dragons: [DragonModel] = DragonModel.defaultDragons()
    var island: IslandState = IslandState.defaultIsland()
    var unlockedAccessories: Set<DragonAccessory> = [.none, .flowerCrown]
    var gameStats: [String: GameStats] = [:]
    var settings: UserSettings = UserSettings()
    
    // New Feature State
    var foodInventory: [String: Int] = [
        FoodType.fireBerries.rawValue: 5,
        FoodType.frostApples.rawValue: 5,
        FoodType.crystalShards.rawValue: 3,
        FoodType.starfishTreats.rawValue: 6,
        FoodType.dragonRoast.rawValue: 2,
        FoodType.goldenFruit.rawValue: 1,
        FoodType.moonbeamPudding.rawValue: 4,
        FoodType.sunbeamOrange.rawValue: 4
    ]
    var achievements: [DragonAchievement] = AppProgressState.defaultAchievements()
    var lastDailyBonusClaimDate: Date? = nil
    
    static func initial() -> AppProgressState {
        return AppProgressState()
    }
    
    static func defaultAchievements() -> [DragonAchievement] {
        return [
            DragonAchievement(
                id: "first_munch",
                title: "First Munch",
                subtitle: "Feed your dragon a tasty treat",
                iconName: "fork.knife",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 5
            ),
            DragonAchievement(
                id: "gourmet_dragon",
                title: "Gourmet Dragon",
                subtitle: "Feed your dragon 15 times",
                iconName: "heart.fill",
                targetCount: 15,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 15
            ),
            DragonAchievement(
                id: "growing_young",
                title: "Growing Up",
                subtitle: "Raise a dragon to the Young stage",
                iconName: "leaf.fill",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 10
            ),
            DragonAchievement(
                id: "mighty_wings",
                title: "Mighty Wings",
                subtitle: "Reach the Adolescent Dragon stage",
                iconName: "wind",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 20
            ),
            DragonAchievement(
                id: "dragon_guardian",
                title: "Dragon Guardian",
                subtitle: "Raise a dragon to full Adulthood",
                iconName: "flame.fill",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 30
            ),
            DragonAchievement(
                id: "ancient_legend",
                title: "Ancient Legend",
                subtitle: "Awaken an Ancient Dragon",
                iconName: "crown.fill",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 50
            ),
            DragonAchievement(
                id: "power_spark",
                title: "Power Spark",
                subtitle: "Cast your first elemental power",
                iconName: "sparkles",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 5
            ),
            DragonAchievement(
                id: "elemental_master",
                title: "Elemental Master",
                subtitle: "Unlock 3 elemental abilities",
                iconName: "bolt.fill",
                targetCount: 3,
                currentProgress: 1,
                isUnlocked: false,
                rewardStars: 25
            ),
            DragonAchievement(
                id: "favorite_snack",
                title: "Favorite Flavor",
                subtitle: "Discover your dragon's favorite food",
                iconName: "star.fill",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 15
            ),
            DragonAchievement(
                id: "full_tummy",
                title: "Full & Happy",
                subtitle: "Reach 100% hunger satisfaction",
                iconName: "face.smiling.fill",
                targetCount: 1,
                currentProgress: 0,
                isUnlocked: false,
                rewardStars: 10
            )
        ]
    }
    
    // MARK: - Backward-Compatible Decoding
    
    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding, totalStars, selectedDragonId, dragons
        case island, unlockedAccessories, gameStats, settings
        case foodInventory, achievements, lastDailyBonusClaimDate
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        totalStars = try container.decodeIfPresent(Int.self, forKey: .totalStars) ?? 10
        selectedDragonId = try container.decodeIfPresent(String.self, forKey: .selectedDragonId) ?? "sparkle"
        
        // Merge or decode dragons
        let loadedDragons = try container.decodeIfPresent([DragonModel].self, forKey: .dragons) ?? []
        if loadedDragons.isEmpty {
            dragons = DragonModel.defaultDragons()
        } else {
            // Ensure any new species from default dragons (like Volt, Nova, Terra) are merged in if not present!
            var currentList = loadedDragons
            let defaults = DragonModel.defaultDragons()
            for def in defaults {
                if !currentList.contains(where: { $0.id == def.id }) {
                    currentList.append(def)
                }
            }
            dragons = currentList
        }
        
        island = try container.decodeIfPresent(IslandState.self, forKey: .island) ?? IslandState.defaultIsland()
        unlockedAccessories = try container.decodeIfPresent(Set<DragonAccessory>.self, forKey: .unlockedAccessories) ?? [.none, .flowerCrown]
        gameStats = try container.decodeIfPresent([String: GameStats].self, forKey: .gameStats) ?? [:]
        settings = try container.decodeIfPresent(UserSettings.self, forKey: .settings) ?? UserSettings()
        
        // Safe defaults for newly added raising state
        foodInventory = try container.decodeIfPresent([String: Int].self, forKey: .foodInventory) ?? [
            FoodType.fireBerries.rawValue: 5,
            FoodType.frostApples.rawValue: 5,
            FoodType.crystalShards.rawValue: 3,
            FoodType.starfishTreats.rawValue: 6,
            FoodType.dragonRoast.rawValue: 2,
            FoodType.goldenFruit.rawValue: 1,
            FoodType.moonbeamPudding.rawValue: 4,
            FoodType.sunbeamOrange.rawValue: 4
        ]
        achievements = try container.decodeIfPresent([DragonAchievement].self, forKey: .achievements) ?? AppProgressState.defaultAchievements()
        lastDailyBonusClaimDate = try container.decodeIfPresent(Date.self, forKey: .lastDailyBonusClaimDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(totalStars, forKey: .totalStars)
        try container.encode(selectedDragonId, forKey: .selectedDragonId)
        try container.encode(dragons, forKey: .dragons)
        try container.encode(island, forKey: .island)
        try container.encode(unlockedAccessories, forKey: .unlockedAccessories)
        try container.encode(gameStats, forKey: .gameStats)
        try container.encode(settings, forKey: .settings)
        try container.encode(foodInventory, forKey: .foodInventory)
        try container.encode(achievements, forKey: .achievements)
        try container.encodeIfPresent(lastDailyBonusClaimDate, forKey: .lastDailyBonusClaimDate)
    }
}
