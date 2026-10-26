//
//  TrainingSessionRules.swift
//  Tiny Dragon Academy
//
//  When a training session counts and how its score turns into rewards.
//

import Foundation

struct TrainingResult: Equatable {
    let counted: Bool
    let reward: TrainingReward?
    let isNewBest: Bool
    let droppedEmber: Bool
    let earnedEgg: Bool
    let snacksAdded: [FoodType]
    let cured: Bool
}

enum TrainingSessionRules {
    static let minimumCountedDuration = 20.0
    static let emberDropChance = 0.03
    static let sessionsPerEgg = 10
    static let maxSnacksPerRound = 5

    /// Quitting straight away must not farm rewards: a session counts after 20s,
    /// a finished timed round, or the game's minimum score.
    static func counts(_ game: TrainingGameType, duration: Double, score: Int, completedRound: Bool) -> Bool {
        if duration >= minimumCountedDuration { return true }
        if game.isTimed { return completedRound }
        guard let minimum = game.minimumCountedScore else { return false }
        return score >= minimum
    }

    static func normalizedScore(_ game: TrainingGameType, score: Int) -> Double {
        min(1, max(0, Double(score) / game.scoreForFullMarks))
    }
}
