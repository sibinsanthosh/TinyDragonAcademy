//
//  GameManager.swift
//  Tiny Dragon Academy
//
//  Central state coordinator managing dragons, progress, stars, island state,
//  raising, feeding, elemental powers, evolution, and offline persistence.
//

import SwiftUI
import Combine

enum AppRoute: Equatable {
    case onboarding
    case mainMenu
    case miniGamesHub
    case miniGame(MiniGameType)
    case dragonCollection
    case dragonDressUp
    case islandBuilder
    case settings
    case dragonPlayground
    case powerEncyclopedia
    case foodInventoryShop
    case achievementsList
    case den
    case trainingHub
    case incubator
    case hallOfLegends
    case today
    case trainingGame(TrainingGameType)
}

@MainActor
final class GameManager: ObservableObject {
    @Published var currentRoute: AppRoute = .onboarding
    @Published var state: AppProgressState
    /// Events per dragon id (or "incubator") that happened while the player was away.
    @Published var awayReport: [String: [LifeEvent]] = [:]
    @Published var dailyBonus: DailyBonus? = nil
    /// Names at the time of each away event (a memorialized dragon's name resets to its species default).
    @Published var awayNames: [String: String] = [:]
    /// Celebration banners (quests, wishes, streak), shown one after another.
    @Published var toasts: [String] = []
    /// Streak changes that happened at day rollover, for the away report.
    @Published var awayStreakNotes: [String] = []
    
    let persistence: PersistenceService
    var clock: GameClock
    let notifications: NotificationScheduling
    let calendar: Calendar
    
    // Quick getters
    var totalStars: Int {
        state.totalStars
    }
    
    var activeDragon: DragonModel {
        if let found = state.dragons.first(where: { $0.id == state.selectedDragonId }) {
            return found
        }
        return state.dragons.first ?? DragonModel.defaultDragons()[0]
    }
    
    var activeDragonIndex: Int {
        state.dragons.firstIndex(where: { $0.id == state.selectedDragonId }) ?? 0
    }
    
    init(
        persistence: PersistenceService = .shared,
        clock: GameClock = .fromLaunchArguments(ProcessInfo.processInfo.arguments),
        notifications: NotificationScheduling = NotificationService.shared,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.persistence = persistence
        self.clock = clock
        self.notifications = notifications
        self.calendar = calendar
        
        var loaded = persistence.loadState()
        
        // Ensure starting elemental power is unlocked for each dragon
        for idx in loaded.dragons.indices {
            let elem = loaded.dragons[idx].element
            let startingPower = ElementalPowersCatalog.powers(for: elem).first?.id ?? "fire_1"
            if !loaded.dragons[idx].stats.unlockedPowerIds.contains(startingPower) {
                loaded.dragons[idx].stats.unlockedPowerIds.insert(startingPower)
            }
        }
        
        self.state = loaded
        
        if loaded.hasCompletedOnboarding {
            catchUp()
        }
        if let service = notifications as? NotificationService {
            service.onTap = { [weak self] dragonId in self?.handleNotificationTap(dragonId: dragonId) }
        }
        
        // Sync audio settings
        AudioService.shared.isSoundEnabled = loaded.settings.isSoundEnabled
        AudioService.shared.isMusicEnabled = loaded.settings.isMusicEnabled
        
        // Set initial route based on onboarding or debug launch argument
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let routeIdx = args.firstIndex(of: "-route"), routeIdx + 1 < args.count {
            let target = args[routeIdx + 1]
            switch target {
            case "mainMenu": self.currentRoute = .mainMenu
            case "dragonPlayground": self.currentRoute = .dragonPlayground
            case "miniGamesHub": self.currentRoute = .miniGamesHub
            case "colorGarden": self.currentRoute = .miniGame(.colorGarden)
            case "shapeMagic": self.currentRoute = .miniGame(.shapeMagic)
            case "countStars": self.currentRoute = .miniGame(.countStars)
            case "dragonPuzzle": self.currentRoute = .miniGame(.dragonPuzzle)
            case "dragonCollection": self.currentRoute = .dragonCollection
            case "dragonDressUp": self.currentRoute = .dragonDressUp
            case "islandBuilder": self.currentRoute = .islandBuilder
            case "powerEncyclopedia": self.currentRoute = .powerEncyclopedia
            case "foodInventoryShop": self.currentRoute = .foodInventoryShop
            case "achievementsList": self.currentRoute = .achievementsList
            case "settings": self.currentRoute = .settings
            case "today": self.currentRoute = .today
            case "den": self.currentRoute = .den
            case "trainingHub": self.currentRoute = .trainingHub
            case "incubator": self.currentRoute = .incubator
            case "hallOfLegends": self.currentRoute = .hallOfLegends
            case "dragonDash": self.currentRoute = .trainingGame(.dragonDash)
            case "fireTarget": self.currentRoute = .trainingGame(.fireTarget)
            case "skyFlight": self.currentRoute = .trainingGame(.skyFlight)
            case "snackCatch": self.currentRoute = .trainingGame(.snackCatch)
            default: self.currentRoute = loaded.hasCompletedOnboarding ? .mainMenu : .onboarding
            }
        } else {
            self.currentRoute = loaded.hasCompletedOnboarding ? .mainMenu : .onboarding
        }
        #else
        if loaded.hasCompletedOnboarding {
            self.currentRoute = .mainMenu
        } else {
            self.currentRoute = .onboarding
        }
        #endif
    }
    
    func save() {
        persistence.saveState(state)
    }
    
    // MARK: - Navigation
    
    /// True when the selected dragon lives in the den (and so can be cared for).
    var hasActiveDenDragon: Bool {
        state.dragons.contains { $0.id == state.selectedDragonId && $0.residence == .den }
    }
    
    func navigate(to route: AppRoute) {
        // With no den dragon selected (e.g. all spirits moved on), care happens from the Den
        let destination: AppRoute = (route == .dragonPlayground && !hasActiveDenDragon) ? .den : route
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentRoute = destination
        }
    }
    
    // MARK: - Stars & Progression
    
    func awardStars(_ count: Int, forGame game: MiniGameType? = nil) {
        state.totalStars += count
        
        if let game = game {
            var stats = state.gameStats[game.rawValue] ?? GameStats()
            stats.gamesPlayed += 1
            stats.starsEarned += count
            state.gameStats[game.rawValue] = stats
            
            // Give a random food item reward for completing a mini-game!
            let possibleFoods: [FoodType] = [.fireBerries, .frostApples, .crystalShards, .starfishTreats, .sunbeamOrange]
            if let reward = possibleFoods.randomElement() {
                state.foodInventory[reward.rawValue] = (state.foodInventory[reward.rawValue] ?? 0) + 1
            }
        }
        
        AudioService.shared.playStarCollect()
        save()
        if game != nil { record(.playedLearningGame) }
    }
    
    // MARK: - Onboarding & Dragon Hatching
    
    func completeOnboarding(starterDragonName: String, careMode: CareMode = .classic) {
        state.hasCompletedOnboarding = true
        state.careMode = careMode
        if let idx = state.dragons.firstIndex(where: { $0.id == "sparkle" }) {
            state.dragons[idx].name = starterDragonName
            state.dragons[idx].residence = .den
            state.dragons[idx].stats.bornAt = clock.now()
            state.dragons[idx].stats.lastSimulatedAt = clock.now()
        }
        state.selectedDragonId = "sparkle"
        refreshDay()
        save()
        navigate(to: .dragonPlayground)
    }
    
    func selectDragon(id: String) {
        guard state.dragons.contains(where: { $0.id == id && $0.residence == .den }) else { return }
        state.selectedDragonId = id
        save()
    }
    
    func petActiveDragon() {
        let idx = activeDragonIndex
        guard hasActiveDenDragon, !state.dragons[idx].stats.condition.isSpirit else { return }
        state.dragons[idx].friendshipHearts += 1
        state.dragons[idx].stats.happiness = min(100.0, state.dragons[idx].stats.happiness + 5.0)
        
        if state.dragons[idx].stats.happiness >= 100.0 {
            updateAchievementProgress(id: "full_tummy", incrementBy: 1)
        }
        save()
        record(.petted(dragonId: state.dragons[idx].id))
    }
    
    // MARK: - Interactive Feeding & Growth System
    
    func feedActiveDragon(food: FoodType) -> (gainedXP: Int, isFavorite: Bool, leveledUp: Bool, outcome: FeedOutcome) {
        let currentCount = state.foodInventory[food.rawValue] ?? 0
        guard hasActiveDenDragon else { return (0, false, false, .refusedNotInDen) }
        guard currentCount > 0 else { return (0, false, false, .fed) }
        
        let idx = activeDragonIndex
        var stats = state.dragons[idx].stats
        let isFavorite = (food == state.dragons[idx].favoriteFoodType)
        
        let outcome = CareActions.feed(&stats, food: food, isFavorite: isFavorite, now: clock.now(), calendar: calendar,
                                       mode: state.careMode)
        switch outcome {
        case .refusedAsleep, .refusedSpirit, .refusedNotInDen:
            return (0, isFavorite, false, outcome)
        case .tummyAche:
            state.foodInventory[food.rawValue] = currentCount - 1
            state.dragons[idx].stats = stats
            HapticsService.shared.light()
            save()
            rescheduleNotifications()
            return (0, isFavorite, false, outcome)
        case .fed:
            break
        }
        
        // Decrement food
        state.foodInventory[food.rawValue] = currentCount - 1
        
        // Multiplier for favorite foods; illness halves XP
        let multiplier = isFavorite ? 2 : 1
        let baseEarned = food.baseXP * multiplier
        let illnessAdjusted = stats.condition.illness != nil ? baseEarned / 2 : baseEarned
        let xpEarned = GameManager.shinyBoosted(illnessAdjusted, isShiny: state.dragons[idx].isShiny)
        
        stats.totalFeedings += 1
        stats.lastFeedingTimestamp = clock.now()
        
        if isFavorite {
            stats.favoriteFoodDiscovered = true
            updateAchievementProgress(id: "favorite_snack", incrementBy: 1)
        }
        
        // Add XP and check for level-up
        stats.experience += xpEarned
        let oldLevel = stats.level
        let newLevel = calculateLevel(for: stats.experience)
        let leveledUp = newLevel > oldLevel
        stats.level = newLevel
        
        // Check if any powers should automatically unlock with new level
        let catalog = ElementalPowersCatalog.powers(for: state.dragons[idx].element)
        for power in catalog {
            if stats.level >= power.levelRequired && stats.growthStage >= power.stageRequired {
                stats.unlockedPowerIds.insert(power.id)
            }
        }
        
        state.dragons[idx].stats = stats
        
        // Audio & Haptics
        AudioService.shared.playFeedingSound()
        HapticsService.shared.success()
        if leveledUp {
            AudioService.shared.playLevelUp()
        }
        
        // Update Feeding Achievements
        updateAchievementProgress(id: "first_munch", incrementBy: 1)
        updateAchievementProgress(id: "gourmet_dragon", incrementBy: 1)
        if stats.hunger >= 99.0 {
            updateAchievementProgress(id: "full_tummy", incrementBy: 1)
        }
        updateAchievementProgress(id: "elemental_master", setExact: stats.unlockedPowerIds.count)
        
        save()
        record(.fed(food: food, isFavorite: isFavorite, dragonId: state.dragons[idx].id))
        rescheduleNotifications()
        return (xpEarned, isFavorite, leveledUp, outcome)
    }
    
    func calculateLevel(for xp: Int) -> Int {
        var lvl = 1
        while lvl < 50 {
            let nextXP = DragonStats.defaultStats().xpRequiredForLevel(lvl + 1)
            if xp >= nextXP {
                lvl += 1
            } else {
                break
            }
        }
        return lvl
    }
    
    // MARK: - Elemental Powers
    
    func triggerElementalPower(_ power: ElementalPower) -> Bool {
        let idx = activeDragonIndex
        var stats = state.dragons[idx].stats
        
        guard hasActiveDenDragon, !stats.condition.isSpirit, power.stageRequired <= stats.growthStage, stats.energy >= power.energyCost else {
            HapticsService.shared.light()
            return false
        }
        
        stats.energy = max(0.0, stats.energy - power.energyCost)
        stats.experience += 5 // Practice grants slight mastery XP!
        state.dragons[idx].stats = stats
        
        AudioService.shared.playElementalPowerSound(element: state.dragons[idx].element)
        HapticsService.shared.medium()
        
        updateAchievementProgress(id: "power_spark", incrementBy: 1)
        save()
        return true
    }
    
    // MARK: - Evolution System
    
    func evolveActiveDragon() -> Bool {
        let idx = activeDragonIndex
        guard hasActiveDenDragon, state.dragons[idx].stats.condition == .healthy else { return false }
        guard let next = state.dragons[idx].stats.growthStage.nextStage else { return false }
        guard state.dragons[idx].stats.level >= next.minLevel else { return false }
        
        state.dragons[idx].stats.growthStage = next
        
        // First time reaching a stage rewards a mystery egg
        if state.dragons[idx].stats.stagesRewarded.insert(next).inserted, let tier = GameManager.eggTier(forReaching: next) {
            state.eggBasket.append(Egg(tier: tier))
        }
        
        // Unlock next stage powers
        let catalog = ElementalPowersCatalog.powers(for: state.dragons[idx].element)
        for power in catalog where power.stageRequired <= next {
            state.dragons[idx].stats.unlockedPowerIds.insert(power.id)
        }
        
        // Award evolutionary celebration stars
        state.totalStars += 15
        
        AudioService.shared.playEvolutionFanfare()
        HapticsService.shared.success()
        
        // Update Evolution Achievements
        switch next {
        case .young:
            updateAchievementProgress(id: "growing_young", incrementBy: 1)
        case .adolescent:
            updateAchievementProgress(id: "mighty_wings", incrementBy: 1)
        case .adult:
            updateAchievementProgress(id: "dragon_guardian", incrementBy: 1)
        case .ancient:
            updateAchievementProgress(id: "ancient_legend", incrementBy: 1)
        case .baby:
            break
        }
        
        save()
        return true
    }
    
    // MARK: - Food Store & Pantry
    
    func purchaseFood(food: FoodType, count: Int = 1) -> Bool {
        let totalCost = food.purchaseStarCost * count
        guard state.totalStars >= totalCost else { return false }
        
        state.totalStars -= totalCost
        state.foodInventory[food.rawValue] = (state.foodInventory[food.rawValue] ?? 0) + count
        AudioService.shared.playPop()
        HapticsService.shared.selection()
        save()
        return true
    }
    
    // MARK: - Achievements System
    
    func updateAchievementProgress(id: String, incrementBy: Int = 1, setExact: Int? = nil) {
        guard let idx = state.achievements.firstIndex(where: { $0.id == id }) else { return }
        
        if let exact = setExact {
            state.achievements[idx].currentProgress = max(state.achievements[idx].currentProgress, exact)
        } else {
            state.achievements[idx].currentProgress += incrementBy
        }
        
        if state.achievements[idx].currentProgress >= state.achievements[idx].targetCount && !state.achievements[idx].isUnlocked {
            state.achievements[idx].isUnlocked = true
        }
    }
    
    func claimAchievementReward(id: String) -> Bool {
        guard let idx = state.achievements.firstIndex(where: { $0.id == id && $0.isUnlocked }) else { return false }
        let reward = state.achievements[idx].rewardStars
        state.totalStars += reward
        // Remove or mark as claimed by zeroing target
        AudioService.shared.playStarCollect()
        HapticsService.shared.success()
        save()
        return true
    }
    
    // MARK: - Dragon Customization
    
    func updateActiveDragon(
        colorHex: String? = nil,
        secondaryHex: String? = nil,
        bellyHex: String? = nil,
        hornStyle: HornStyle? = nil,
        wingStyle: WingStyle? = nil,
        tailStyle: TailStyle? = nil,
        accessory: DragonAccessory? = nil,
        backdrop: IslandBackdrop? = nil
    ) {
        let idx = activeDragonIndex
        if let colorHex = colorHex { state.dragons[idx].primaryColorHex = colorHex }
        if let secondaryHex = secondaryHex { state.dragons[idx].secondaryColorHex = secondaryHex }
        if let bellyHex = bellyHex { state.dragons[idx].bellyColorHex = bellyHex }
        if let hornStyle = hornStyle { state.dragons[idx].hornStyle = hornStyle }
        if let wingStyle = wingStyle { state.dragons[idx].wingStyle = wingStyle }
        if let tailStyle = tailStyle { state.dragons[idx].tailStyle = tailStyle }
        if let accessory = accessory { state.dragons[idx].accessory = accessory }
        if let backdrop = backdrop { state.dragons[idx].backdrop = backdrop }
        save()
    }
    
    func unlockAccessory(_ accessory: DragonAccessory) -> Bool {
        guard state.totalStars >= accessory.unlockStars else { return false }
        state.totalStars -= accessory.unlockStars
        state.unlockedAccessories.insert(accessory)
        save()
        return true
    }
    
    // MARK: - Island Builder
    
    func addIslandItem(type: IslandItemType, x: CGFloat = 0.5, y: CGFloat = 0.5) {
        let newItem = PlacedItem(itemType: type, xNormalized: x, yNormalized: y)
        state.island.placedItems.append(newItem)
        save()
    }
    
    func moveIslandItem(id: UUID, newX: CGFloat, newY: CGFloat) {
        if let idx = state.island.placedItems.firstIndex(where: { $0.id == id }) {
            state.island.placedItems[idx].xNormalized = max(0.1, min(0.9, newX))
            state.island.placedItems[idx].yNormalized = max(0.2, min(0.85, newY))
            save()
        }
    }
    
    func removeIslandItem(id: UUID) {
        state.island.placedItems.removeAll(where: { $0.id == id })
        save()
    }
    
    func resetIsland() {
        state.island = IslandState.defaultIsland()
        save()
    }
    
    func setIslandTheme(_ theme: IslandBackdrop) {
        state.island.theme = theme
        save()
    }
    
    // MARK: - Settings & Accessibility
    
    func updateSettings(
        sound: Bool? = nil,
        music: Bool? = nil,
        reduceMotion: Bool? = nil,
        highContrast: Bool? = nil,
        voice: Bool? = nil
    ) {
        if let sound = sound {
            state.settings.isSoundEnabled = sound
            AudioService.shared.isSoundEnabled = sound
        }
        if let music = music {
            state.settings.isMusicEnabled = music
            AudioService.shared.isMusicEnabled = music
        }
        if let reduceMotion = reduceMotion {
            state.settings.reduceMotion = reduceMotion
        }
        if let highContrast = highContrast {
            state.settings.highContrastHints = highContrast
        }
        if let voice = voice {
            state.settings.spokenVoiceAssistance = voice
        }
        save()
    }
    
    func resetAllProgress() {
        persistence.resetAllData()
        self.state = AppProgressState.initial()
        AudioService.shared.isSoundEnabled = true
        AudioService.shared.isMusicEnabled = true
        self.currentRoute = .onboarding
    }
}
