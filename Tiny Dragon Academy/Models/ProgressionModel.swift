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
    
    // Life simulation state
    var eggBasket: [Egg] = []
    var incubatorSlots: [IncubatorSlot] = [IncubatorSlot(lastSimulatedAt: Date())]
    var denCapacity: Int = 3
    var itemInventory: [String: Int] = [:]
    var trainingBests: [String: Int] = [:]
    var trainingSessionsCompleted: Int = 0
    var hallOfLegends: [Memorial] = []
    var remindersEnabled: Bool = true
    var hasSeenReminderPrimer: Bool = false
    
    // Daily habit state
    var careMode: CareMode = .classic
    var daily: DailyState = DailyState()
    var streak: StreakState = StreakState()
    
    var denDragons: [DragonModel] { dragons.filter { $0.residence == .den } }
    var incubatorCapacity: Int { incubatorSlots.count }
    
    func itemCount(_ item: CareItem) -> Int { itemInventory[item.rawValue] ?? 0 }
    
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
        case eggBasket, incubatorSlots, denCapacity, itemInventory, trainingBests
        case trainingSessionsCompleted, hallOfLegends, remindersEnabled, hasSeenReminderPrimer
        case careMode, daily, streak
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
        
        let isLegacySave = !container.contains(.eggBasket)
        eggBasket = try container.decodeIfPresent([Egg].self, forKey: .eggBasket) ?? []
        incubatorSlots = try container.decodeIfPresent([IncubatorSlot].self, forKey: .incubatorSlots) ?? [IncubatorSlot(lastSimulatedAt: Date())]
        denCapacity = try container.decodeIfPresent(Int.self, forKey: .denCapacity) ?? 3
        itemInventory = try container.decodeIfPresent([String: Int].self, forKey: .itemInventory) ?? [:]
        trainingBests = try container.decodeIfPresent([String: Int].self, forKey: .trainingBests) ?? [:]
        trainingSessionsCompleted = try container.decodeIfPresent(Int.self, forKey: .trainingSessionsCompleted) ?? 0
        hallOfLegends = try container.decodeIfPresent([Memorial].self, forKey: .hallOfLegends) ?? []
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true
        hasSeenReminderPrimer = try container.decodeIfPresent(Bool.self, forKey: .hasSeenReminderPrimer) ?? false
        careMode = try container.decodeIfPresent(CareMode.self, forKey: .careMode) ?? .classic
        // Daily state is disposable: a field we can no longer read must not cost the whole save
        daily = (try? container.decodeIfPresent(DailyState.self, forKey: .daily)) ?? DailyState()
        streak = (try? container.decodeIfPresent(StreakState.self, forKey: .streak)) ?? StreakState()
        
        if isLegacySave {
            AppProgressState.migrateLegacy(&self, now: Date())
        }
    }
    
    /// One-time upgrade of a pre-life-simulation save: owned dragons fill the den
    /// (selected first), extras go to the sanctuary, and everyone starts healthy.
    static func migrateLegacy(_ state: inout AppProgressState, now: Date) {
        let ownedIds = state.dragons.filter { $0.isUnlocked }.map(\.id)
        let ordered = ownedIds.filter { $0 == state.selectedDragonId } + ownedIds.filter { $0 != state.selectedDragonId }
        for idx in state.dragons.indices {
            guard let rank = ordered.firstIndex(of: state.dragons[idx].id) else {
                state.dragons[idx].residence = .undiscovered
                continue
            }
            state.dragons[idx].residence = rank < state.denCapacity ? .den : .sanctuary
            state.dragons[idx].stats.fitness = LifeRules.migratedFitness
            state.dragons[idx].stats.health = 100
            state.dragons[idx].stats.condition = .healthy
            state.dragons[idx].stats.lastSimulatedAt = now
            state.dragons[idx].stats.bornAt = now
        }
        if let first = ordered.first, !ordered.prefix(state.denCapacity).contains(state.selectedDragonId) {
            state.selectedDragonId = first
        }
        state.eggBasket.append(Egg(tier: .common))
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
        try container.encode(eggBasket, forKey: .eggBasket)
        try container.encode(incubatorSlots, forKey: .incubatorSlots)
        try container.encode(denCapacity, forKey: .denCapacity)
        try container.encode(itemInventory, forKey: .itemInventory)
        try container.encode(trainingBests, forKey: .trainingBests)
        try container.encode(trainingSessionsCompleted, forKey: .trainingSessionsCompleted)
        try container.encode(hallOfLegends, forKey: .hallOfLegends)
        try container.encode(remindersEnabled, forKey: .remindersEnabled)
        try container.encode(hasSeenReminderPrimer, forKey: .hasSeenReminderPrimer)
        try container.encode(careMode, forKey: .careMode)
        try container.encode(daily, forKey: .daily)
        try container.encode(streak, forKey: .streak)
    }
}
