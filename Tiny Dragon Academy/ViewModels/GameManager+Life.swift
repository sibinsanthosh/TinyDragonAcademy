//
//  GameManager+Life.swift
//  Tiny Dragon Academy
//
//  Connects the pure life rules (LifeSimulator, CareActions, EggHatcher,
//  DenRules, NotificationPlanner) to the app state: ticking, catch-up,
//  care actions, eggs, den moves, shop upgrades and reminders.
//

import SwiftUI

extension GameManager {

    // MARK: - Simulation

    /// Advances every den dragon and incubator egg to now.
    /// Reminders are replanned on catch-up, care actions and backgrounding — not here,
    /// so the 30s tick stays cheap while arcade games are running.
    func tick() {
        _ = advanceWorld(to: clock.now())
        save()
    }

    /// Like `tick`, but records what happened for the "While you were away" sheet and claims the daily bonus.
    func catchUp() {
        let now = clock.now()
        let report = advanceWorld(to: now)
        for (key, events) in report {
            awayReport[key, default: []] += events
        }
        var lastClaim = state.lastDailyBonusClaimDate
        var inventory = state.foodInventory
        var stars = state.totalStars
        if let bonus = TimeProgressionService.shared.claimDailyBonus(
            lastDailyClaim: &lastClaim, inventory: &inventory, totalStars: &stars, now: now, calendar: calendar
        ) {
            state.lastDailyBonusClaimDate = lastClaim
            state.foodInventory = inventory
            state.totalStars = stars
            dailyBonus = bonus
        }
        save()
        rescheduleNotifications()
    }

    private func advanceWorld(to now: Date) -> [String: [LifeEvent]] {
        var report: [String: [LifeEvent]] = [:]
        var expired: [String] = []
        var illnessDays: Set<String> = []
        for idx in state.dragons.indices where state.dragons[idx].residence == .den {
            let stats = state.dragons[idx].stats
            let (next, timed) = LifeSimulator.advanceTimed(stats, from: stats.lastSimulatedAt, to: now,
                                                           calendar: calendar, mode: state.careMode)
            let events = timed.map(\.event)
            for item in timed {
                if case .becameIll = item.event { illnessDays.insert(GameDay.id(for: item.at, calendar: calendar)) }
            }
            state.dragons[idx].stats = next
            if !events.isEmpty { report[state.dragons[idx].id] = events }
            if events.contains(.spiritExpired) { expired.append(state.dragons[idx].id) }
        }
        for idx in state.dragons.indices where report[state.dragons[idx].id] != nil {
            awayNames[state.dragons[idx].id] = state.dragons[idx].name
        }
        for id in expired {
            DenRules.expireSpirit(id, state: &state, now: now)
        }
        for idx in state.incubatorSlots.indices {
            let slot = state.incubatorSlots[idx]
            let (next, events) = LifeSimulator.advance(slot, from: slot.lastSimulatedAt, to: now)
            state.incubatorSlots[idx] = next
            if !events.isEmpty { report["incubator", default: []] += events }
        }
        DenRules.ensureActiveInDen(&state)
        refreshDay(illnessDays: illnessDays)
        return report
    }

    func rescheduleNotifications() {
        let now = clock.now()
        let plan = NotificationPlanner.plan(state: state, now: now, calendar: calendar)
        if state.careMode == .gentle {
            // Remember today's reminders so the daily cap holds across reschedules
            let today = state.daily.dayId
            let delivered = state.daily.reminderDates.filter { $0 <= now }
            let upcoming = plan.map(\.fireDate).filter { GameDay.id(for: $0, calendar: calendar) == today }
            state.daily.reminderDates = delivered + upcoming
        }
        // Under a debug time scale, game-time dates must be converted back to real time.
        let realPlan = plan.map {
            PlannedNotification(id: $0.id, title: $0.title, body: $0.body,
                                fireDate: clock.realDate(forGame: $0.fireDate), dragonId: $0.dragonId)
        }
        notifications.schedule(realPlan)
    }

    func handleNotificationTap(dragonId: String) {
        selectDragon(id: dragonId)
        navigate(to: .dragonPlayground)
    }

    // MARK: - Care

    var isActiveDragonAsleep: Bool {
        LifeSimulator.isAsleep(activeDragon.stats, at: clock.now(), calendar: calendar)
    }

    func useHealingHerb() -> Bool {
        guard state.itemCount(.healingHerb) > 0 else { return false }
        let idx = activeDragonIndex
        guard CareActions.useHealingHerb(&state.dragons[idx].stats) else { return false }
        state.itemInventory[CareItem.healingHerb.rawValue] = state.itemCount(.healingHerb) - 1
        HapticsService.shared.success()
        save()
        rescheduleNotifications()
        return true
    }

    func reviveActiveDragon() -> Bool {
        guard state.itemCount(.phoenixEmber) > 0 else { return false }
        let idx = activeDragonIndex
        guard CareActions.revive(&state.dragons[idx].stats) else { return false }
        state.dragons[idx].stats.lastSimulatedAt = clock.now()
        state.itemInventory[CareItem.phoenixEmber.rawValue] = state.itemCount(.phoenixEmber) - 1
        AudioService.shared.playEvolutionFanfare()
        HapticsService.shared.success()
        save()
        rescheduleNotifications()
        return true
    }

    var canLightsOut: Bool {
        hasActiveDenDragon && CareActions.isLightsOutWindow(clock.now(), calendar: calendar)
    }

    @discardableResult
    func lightsOut() -> Bool {
        guard hasActiveDenDragon,
              CareActions.lightsOut(&state.dragons[activeDragonIndex].stats, now: clock.now(), calendar: calendar) else { return false }
        save()
        rescheduleNotifications()
        return true
    }

    func wakeUp() {
        CareActions.wakeUp(&state.dragons[activeDragonIndex].stats)
        save()
        rescheduleNotifications()
    }

    static let shinyXPMultiplier = 1.1

    static func shinyBoosted(_ xp: Int, isShiny: Bool) -> Int {
        isShiny ? Int((Double(xp) * shinyXPMultiplier).rounded()) : xp
    }

    static func eggTier(forReaching stage: GrowthStage) -> EggTier? {
        switch stage {
        case .baby: return nil
        case .young: return .common
        case .adolescent: return .uncommon
        case .adult: return .rare
        case .ancient: return .legendary
        }
    }

    // MARK: - Shop

    private func spendStars(_ cost: Int) -> Bool {
        guard state.totalStars >= cost else { return false }
        state.totalStars -= cost
        AudioService.shared.playPop()
        HapticsService.shared.selection()
        return true
    }

    func purchaseCareItem(_ item: CareItem) -> Bool {
        guard spendStars(item.price) else { return false }
        state.itemInventory[item.rawValue] = state.itemCount(item) + 1
        save()
        return true
    }

    func purchaseEgg(_ tier: EggTier) -> Bool {
        guard let price = tier.shopPrice, spendStars(price) else { return false }
        state.eggBasket.append(Egg(tier: tier))
        save()
        return true
    }

    func purchaseIncubatorSlot() -> Bool {
        guard state.incubatorCapacity < DenRules.maxIncubatorSlots, spendStars(DenRules.incubatorSlotPrice) else { return false }
        state.incubatorSlots.append(IncubatorSlot(lastSimulatedAt: clock.now()))
        save()
        return true
    }

    var nextDenSlotPrice: Int? { DenRules.denSlotPrices[state.denCapacity + 1] }

    func purchaseDenSlot() -> Bool {
        guard state.denCapacity < DenRules.maxDenCapacity, let price = nextDenSlotPrice, spendStars(price) else { return false }
        state.denCapacity += 1
        save()
        return true
    }

    // MARK: - Eggs

    func placeEgg(_ eggId: UUID, slot: Int) -> Bool {
        guard state.incubatorSlots.indices.contains(slot),
              state.incubatorSlots[slot].egg == nil,
              let basketIdx = state.eggBasket.firstIndex(where: { $0.id == eggId }) else { return false }
        let egg = state.eggBasket.remove(at: basketIdx)
        state.incubatorSlots[slot] = IncubatorSlot(egg: egg, warmth: 100, progress: 0, lastSimulatedAt: clock.now())
        save()
        rescheduleNotifications()
        return true
    }

    func warmEgg(slot: Int) {
        guard state.incubatorSlots.indices.contains(slot) else { return }
        guard state.incubatorSlots[slot].egg != nil else { return }
        EggHatcher.warm(&state.incubatorSlots[slot])
        HapticsService.shared.light()
        save()
        record(.warmedEgg)
    }

    /// Cracks a ready egg. A hatched dragon is placed right away under its species name; `nameHatched` renames it.
    func crackEgg(slot: Int) -> HatchOutcome? {
        var rng = SystemRandomNumberGenerator()
        return crackEgg(slot: slot, rng: &rng)
    }

    func crackEgg(slot: Int, rng: inout some RandomNumberGenerator) -> HatchOutcome? {
        guard state.incubatorSlots.indices.contains(slot),
              state.incubatorSlots[slot].isReady,
              let egg = state.incubatorSlots[slot].egg else { return nil }
        let outcome = EggHatcher.roll(egg, dragons: state.dragons, rng: &rng)
        let now = clock.now()
        state.incubatorSlots[slot] = IncubatorSlot(lastSimulatedAt: now)
        switch outcome {
        case .dragon(let id):
            let defaultName = DragonModel.defaultDragons().first { $0.id == id }?.name ?? id.capitalized
            DenRules.placeHatched(id, name: defaultName, state: &state, now: now)
            if EggHatcher.rollShiny(rng: &rng), let idx = state.dragons.firstIndex(where: { $0.id == id }) {
                let colors = ShinyPalette.colors(for: state.dragons[idx].element)
                state.dragons[idx].isShiny = true
                state.dragons[idx].primaryColorHex = colors.primary
                state.dragons[idx].secondaryColorHex = colors.secondary
                state.dragons[idx].bellyColorHex = colors.belly
            }
            if state.denDragons.count == 1 { state.selectedDragonId = id }
            AudioService.shared.playVictoryFanfare()
        case .stars(let stars):
            state.totalStars += stars
            AudioService.shared.playStarCollect()
        }
        HapticsService.shared.success()
        save()
        rescheduleNotifications()
        return outcome
    }

    func nameHatched(id: String, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = state.dragons.firstIndex(where: { $0.id == id }) else { return }
        state.dragons[idx].name = String(trimmed.prefix(20))
        save()
    }

    // MARK: - Den

    func moveToSanctuary(_ id: String) -> Bool {
        guard DenRules.moveToSanctuary(id, state: &state) else { return false }
        save()
        rescheduleNotifications()
        return true
    }

    func moveToDen(_ id: String) -> Bool {
        guard DenRules.moveToDen(id, state: &state, now: clock.now()) else { return false }
        save()
        rescheduleNotifications()
        return true
    }
}

// MARK: - Training

extension GameManager {

    var canTrainActiveDragon: Bool {
        hasActiveDenDragon && CareActions.canTrain(activeDragon.stats, now: clock.now(), calendar: calendar)
    }

    /// Spends the session's energy. Returns false (spending nothing) when the dragon can't train.
    func startTraining(_ game: TrainingGameType) -> Bool {
        let idx = activeDragonIndex
        guard canTrainActiveDragon else { return false }
        state.dragons[idx].stats.energy = max(0, state.dragons[idx].stats.energy - LifeRules.trainingEnergyCost)
        save()
        return true
    }

    func finishTraining(
        _ game: TrainingGameType,
        score: Int,
        baseScore: Int? = nil,
        duration: Double,
        completedRound: Bool,
        caughtSnacks: [FoodType] = [],
        rng: inout some RandomNumberGenerator
    ) -> TrainingResult {
        let idx = activeDragonIndex
        // Talent bonuses (Sweet Tooth, Sunrise Sprint) show in the score and best, not in rewards or quests
        let rewardScore = baseScore ?? score
        let isNewBest = score > (state.trainingBests[game.rawValue] ?? 0)
        if isNewBest { state.trainingBests[game.rawValue] = score }

        let snacks = Array(caughtSnacks.prefix(TrainingSessionRules.maxSnacksPerRound))
        for food in snacks {
            state.foodInventory[food.rawValue] = (state.foodInventory[food.rawValue] ?? 0) + 1
        }

        guard TrainingSessionRules.counts(game, duration: duration, score: rewardScore, completedRound: completedRound) else {
            save()
            return TrainingResult(counted: false, reward: nil, isNewBest: isNewBest, droppedEmber: false,
                                  earnedEgg: false, snacksAdded: snacks, cured: false)
        }

        let isIll = state.dragons[idx].stats.condition.illness != nil
        let normalized = TrainingSessionRules.normalizedScore(game, score: rewardScore)
        let reward = CareActions.trainingReward(normalizedScore: normalized, isIll: isIll)
        let skillGain = growSkill(for: game, normalizedScore: normalized, dragonIndex: idx)
        let cured = CareActions.applyCountedSession(&state.dragons[idx].stats, reward: reward)
        state.dragons[idx].stats.experience += GameManager.shinyBoosted(reward.xp, isShiny: state.dragons[idx].isShiny)
        state.dragons[idx].stats.level = calculateLevel(for: state.dragons[idx].stats.experience)
        state.totalStars += reward.stars

        state.trainingSessionsCompleted += 1
        let earnedEgg = state.trainingSessionsCompleted % TrainingSessionRules.sessionsPerEgg == 0
        if earnedEgg { state.eggBasket.append(Egg(tier: .common)) }

        let droppedEmber = isNewBest && Double.random(in: 0..<1, using: &rng) < TrainingSessionRules.emberDropChance
        if droppedEmber {
            state.itemInventory[CareItem.phoenixEmber.rawValue] = state.itemCount(.phoenixEmber) + 1
        }

        AudioService.shared.playStarCollect()
        save()
        record(.trained(game: game, score: rewardScore, dragonId: state.dragons[idx].id))
        rescheduleNotifications()
        return TrainingResult(counted: true, reward: reward, isNewBest: isNewBest, droppedEmber: droppedEmber,
                              earnedEgg: earnedEgg, snacksAdded: snacks, cured: cured, skillGain: skillGain)
    }

    private func growSkill(for game: TrainingGameType, normalizedScore: Double, dragonIndex idx: Int) -> SkillGain {
        let skill = DragonSkill.forGame(game)
        let before = state.dragons[idx].skillStars(skill)
        let points = SkillRules.points(forNormalizedScore: normalizedScore)
        state.dragons[idx].stats.skillPoints[skill.rawValue, default: 0] += points
        return SkillGain(skill: skill, points: points, starsBefore: before, starsAfter: state.dragons[idx].skillStars(skill))
    }
}

// MARK: - Reminders & away report

extension GameManager {

    var shouldShowReminderPrimer: Bool {
        state.hasCompletedOnboarding && !state.hasSeenReminderPrimer
    }

    func markReminderPrimerSeen() {
        state.hasSeenReminderPrimer = true
        save()
    }

    /// Shows the system permission prompt, then schedules reminders.
    func enableReminders() async {
        _ = await notifications.requestAuthorization()
        markReminderPrimerSeen()
        rescheduleNotifications()
    }

    func setRemindersEnabled(_ enabled: Bool) {
        state.remindersEnabled = enabled
        save()
        rescheduleNotifications()
    }

    func dismissAwayReport() {
        awayReport = [:]
        awayNames = [:]
        awayStreakNotes = []
        dailyBonus = nil
    }
}
