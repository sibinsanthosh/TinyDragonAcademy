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
    func tick() {
        _ = advanceWorld(to: clock.now())
        save()
        rescheduleNotifications()
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
        for idx in state.dragons.indices where state.dragons[idx].residence == .den {
            let stats = state.dragons[idx].stats
            let (next, events) = LifeSimulator.advance(stats, from: stats.lastSimulatedAt, to: now, calendar: calendar)
            state.dragons[idx].stats = next
            if !events.isEmpty { report[state.dragons[idx].id] = events }
            if events.contains(.spiritExpired) { expired.append(state.dragons[idx].id) }
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
        return report
    }

    func rescheduleNotifications() {
        let plan = NotificationPlanner.plan(state: state, now: clock.now(), calendar: calendar)
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

    func lightsOut() {
        CareActions.lightsOut(&state.dragons[activeDragonIndex].stats)
        save()
        rescheduleNotifications()
    }

    func wakeUp() {
        CareActions.wakeUp(&state.dragons[activeDragonIndex].stats)
        save()
        rescheduleNotifications()
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
        EggHatcher.warm(&state.incubatorSlots[slot])
        HapticsService.shared.light()
        save()
    }

    /// Cracks a ready egg. A hatched dragon is placed right away under its species name; `nameHatched` renames it.
    func crackEgg(slot: Int) -> HatchOutcome? {
        guard state.incubatorSlots.indices.contains(slot),
              state.incubatorSlots[slot].isReady,
              let egg = state.incubatorSlots[slot].egg else { return nil }
        var rng = SystemRandomNumberGenerator()
        let outcome = EggHatcher.roll(egg, dragons: state.dragons, rng: &rng)
        let now = clock.now()
        state.incubatorSlots[slot] = IncubatorSlot(lastSimulatedAt: now)
        switch outcome {
        case .dragon(let id):
            let defaultName = DragonModel.defaultDragons().first { $0.id == id }?.name ?? id.capitalized
            DenRules.placeHatched(id, name: defaultName, state: &state, now: now)
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
