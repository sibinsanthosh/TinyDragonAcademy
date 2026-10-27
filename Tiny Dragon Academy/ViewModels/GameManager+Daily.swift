//
//  GameManager+Daily.swift
//  Tiny Dragon Academy
//
//  Connects the daily habit rules (quests, wishes, care streak, Care Mode)
//  to the app state and pays out their rewards.
//

import SwiftUI

extension GameManager {

    var questContext: QuestContext {
        QuestContext(
            hasIncubatingEgg: state.incubatorSlots.contains { $0.egg != nil && !$0.isReady },
            knowsAFavorite: state.denDragons.contains { $0.stats.favoriteFoodDiscovered },
            hasDenDragon: !state.denDragons.isEmpty
        )
    }

    var todayQuestsDone: Int { state.daily.quests.filter(\.isComplete).count }

    /// Starts a new game day when needed: judges the streak, then deals fresh quests and wishes.
    /// `illnessDays` are game days on which a den dragon fell ill (credited before judging).
    func refreshDay(illnessDays: Set<String> = []) {
        guard state.hasCompletedOnboarding else { return }
        let today = GameDay.id(for: clock.now(), calendar: calendar)

        if illnessDays.contains(state.daily.dayId) {
            state.daily.illnessToday = true
        }
        if state.daily.dayId != today {
            let rewards = DailyRules.rollover(streak: &state.streak, previous: state.daily, toDayId: today, calendar: calendar)
            apply(rewards)
            state.daily = DailyState(
                dayId: today,
                quests: DailyRules.quests(for: today, mode: state.careMode, context: questContext)
            )
        }
        if illnessDays.contains(today) {
            state.daily.illnessToday = true
        }
        for dragon in state.denDragons where state.daily.wishes[dragon.id] == nil {
            state.daily.wishes[dragon.id] = DailyRules.wish(for: dragon, dayId: today)
        }
    }

    /// Feeds a player action to quests and wishes and pays whatever it completed.
    func record(_ action: PlayerAction) {
        refreshDay()
        let outcome = DailyRules.record(action, daily: &state.daily)

        for quest in outcome.completedQuests {
            state.totalStars += DailyRules.questReward
            showToast("Quest done: \(quest.title) +\(DailyRules.questReward)★")
        }
        if outcome.allClearedNow {
            state.totalStars += DailyRules.allClearStars
            state.itemInventory[CareItem.healingHerb.rawValue] = state.itemCount(.healingHerb) + 1
            showToast("All quests done! +\(DailyRules.allClearStars)★ and a Healing Herb")
        }
        for dragonId in outcome.grantedWishDragonIds {
            guard let idx = state.dragons.firstIndex(where: { $0.id == dragonId }) else { continue }
            state.dragons[idx].stats.happiness = min(100, state.dragons[idx].stats.happiness + DailyRules.wishHappiness)
            state.dragons[idx].stats.experience += DailyRules.wishXP
            state.dragons[idx].stats.level = calculateLevel(for: state.dragons[idx].stats.experience)
            state.totalStars += DailyRules.wishStars
            showToast("\(state.dragons[idx].name)'s wish came true! 💫")
        }
        save()
    }

    private func apply(_ rewards: [StreakReward]) {
        for reward in rewards {
            switch reward {
            case .stars(let stars):
                state.totalStars += stars
            case .shield:
                break // already added to the streak by the rules
            case .egg(let tier):
                state.eggBasket.append(Egg(tier: tier))
            }
        }
        if !rewards.isEmpty {
            showToast("🔥 \(state.streak.current)-day care streak! Rewards added.")
        }
    }

    func showToast(_ message: String) {
        toast = message
    }

    // MARK: - Care Mode

    func setCareMode(_ mode: CareMode) {
        state.careMode = mode
        save()
        rescheduleNotifications()
    }
}
