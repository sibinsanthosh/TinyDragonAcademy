//
//  CareActions.swift
//  Tiny Dragon Academy
//
//  Pure care rules applied to a dragon's stats: feeding, medicine,
//  revive, bedtime and training rewards. XP, inventory and stars are
//  handled by GameManager.
//

import Foundation

enum FeedOutcome: Equatable {
    case fed
    case tummyAche
    case refusedAsleep
    case refusedSpirit
}

struct TrainingReward: Equatable {
    let fitness: Double
    let xp: Int
    let stars: Int
}

enum CareActions {

    static func feed(_ stats: inout DragonStats, food: FoodType, isFavorite: Bool, now: Date, calendar: Calendar) -> FeedOutcome {
        if stats.condition.isSpirit { return .refusedSpirit }
        if LifeSimulator.isAsleep(stats, at: now, calendar: calendar) { return .refusedAsleep }

        if stats.hunger > LifeRules.tummyAcheFullness {
            stats.tummyAcheUntil = now.addingTimeInterval(LifeRules.tummyAcheDuration)
            stats.happiness = max(0, stats.happiness - LifeRules.tummyAcheHappinessPenalty)
            return .tummyAche
        }

        let multiplier = isFavorite ? 2.0 : 1.0
        stats.hunger = min(100, stats.hunger + food.hungerRestored)
        stats.happiness = min(100, stats.happiness + food.happinessRestored * multiplier)
        stats.energy = min(100, stats.energy + food.energyRestored)
        return .fed
    }

    static func useHealingHerb(_ stats: inout DragonStats) -> Bool {
        guard stats.condition.illness != nil else { return false }
        stats.condition = .healthy
        resetIllnessTimers(&stats)
        return true
    }

    static func revive(_ stats: inout DragonStats) -> Bool {
        guard stats.condition.isSpirit else { return false }
        stats.condition = .healthy
        stats.health = LifeRules.reviveHealth
        stats.hunger = LifeRules.reviveFullness
        stats.growthStage = stats.growthStage.previousStage ?? .baby
        stats.isSleepingEarly = false
        resetIllnessTimers(&stats)
        return true
    }

    static func lightsOut(_ stats: inout DragonStats) {
        guard !stats.condition.isSpirit else { return }
        stats.isSleepingEarly = true
    }

    static func wakeUp(_ stats: inout DragonStats) {
        stats.isSleepingEarly = false
    }

    static func canTrain(_ stats: DragonStats, now: Date, calendar: Calendar) -> Bool {
        !stats.condition.isSpirit
            && !LifeSimulator.isAsleep(stats, at: now, calendar: calendar)
            && stats.energy >= LifeRules.trainingEnergyCost
    }

    static func trainingReward(normalizedScore: Double, isIll: Bool) -> TrainingReward {
        let s = min(1, max(0, normalizedScore))
        let baseXP = Int((10 + 30 * s).rounded())
        return TrainingReward(
            fitness: 25 + 15 * s,
            xp: isIll ? baseXP / 2 : baseXP,
            stars: 1 + Int((4 * s).rounded())
        )
    }

    /// Applies a counted training session. Returns true when it cured Sluggish Scales.
    static func applyCountedSession(_ stats: inout DragonStats, reward: TrainingReward) -> Bool {
        stats.fitness = min(100, stats.fitness + reward.fitness)
        guard stats.condition == .ill(.sluggishScales) else { return false }
        if stats.cureSessionsRemaining <= 0 {
            stats.cureSessionsRemaining = LifeRules.sluggishCureSessions
        }
        stats.cureSessionsRemaining -= 1
        guard stats.cureSessionsRemaining == 0 else { return false }
        stats.condition = .healthy
        resetIllnessTimers(&stats)
        return true
    }

    private static func resetIllnessTimers(_ stats: inout DragonStats) {
        stats.fullnessZeroMinutes = 0
        stats.lowFitnessMinutes = 0
        stats.cureSessionsRemaining = 0
    }
}
