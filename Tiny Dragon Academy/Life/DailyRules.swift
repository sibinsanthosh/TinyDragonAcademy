//
//  DailyRules.swift
//  Tiny Dragon Academy
//
//  Pure rules for the daily habit loop: which quests appear each game day,
//  what each dragon wishes for, and how player actions move them forward.
//

import Foundation

struct QuestContext {
    var hasIncubatingEgg: Bool
    var knowsAFavorite: Bool
    var hasDenDragon: Bool
}

enum StreakReward: Equatable {
    case stars(Int)
    case shield
    case egg(EggTier)
}

struct DailyOutcome: Equatable {
    var completedQuests: [DailyQuest] = []
    var allClearedNow = false
    var grantedWishDragonIds: [String] = []
}

enum DailyRules {
    static let questsPerDay = 3
    static let questReward = 5
    static let allClearStars = 10
    static let wishHappiness = 15.0
    static let wishXP = 10
    static let wishStars = 2
    static let petWishCount = 3
    static let scoreTargets: [TrainingGameType: Int] = [
        .dragonDash: 500, .fireTarget: 10, .skyFlight: 8, .snackCatch: 10
    ]

    // MARK: - Generation

    /// Three quests for the day, stable for the whole day and fitted to what the player can do now.
    static func quests(for dayId: String, mode: CareMode, context: QuestContext) -> [DailyQuest] {
        let gentle = mode == .gentle
        var pool: [DailyQuest] = [
            DailyQuest(kind: .feed, target: gentle ? 2 : 3),
            DailyQuest(kind: .train, target: gentle ? 1 : 2),
            DailyQuest(kind: .pet, target: gentle ? 3 : 5),
            DailyQuest(kind: .learningGame, target: 1)
        ]
        if context.hasDenDragon { pool.append(DailyQuest(kind: .grantWish, target: 1)) }
        if context.knowsAFavorite { pool.append(DailyQuest(kind: .feedFavorite, target: 1)) }
        if context.hasIncubatingEgg { pool.append(DailyQuest(kind: .warmEgg, target: gentle ? 3 : 5)) }

        var rng = SeededRNG(seed: StableHash.fnv1a("quests:" + dayId))
        if !gentle, let game = TrainingGameType.allCases.randomElement(using: &rng) {
            pool.append(DailyQuest(kind: .score(game), target: scoreTargets[game] ?? 100))
        }
        return Array(pool.shuffled(using: &rng).prefix(questsPerDay))
    }

    /// Each dragon wishes for one thing a day: a food (often its favorite), a game, or pets.
    static func wish(for dragon: DragonModel, dayId: String) -> DragonWish {
        var rng = SeededRNG(seed: StableHash.fnv1a("wish:\(dayId):\(dragon.id)"))
        switch Int.random(in: 0..<3, using: &rng) {
        case 0:
            let favorite = Bool.random(using: &rng)
            let food = favorite ? dragon.favoriteFoodType : (FoodType.allCases.randomElement(using: &rng) ?? .fireBerries)
            return DragonWish(kind: .eat(food))
        case 1:
            return DragonWish(kind: .play(TrainingGameType.allCases.randomElement(using: &rng) ?? .dragonDash))
        default:
            return DragonWish(kind: .pet)
        }
    }

    // MARK: - Recording

    static func record(_ action: PlayerAction, daily: inout DailyState) -> DailyOutcome {
        var outcome = DailyOutcome()

        switch action {
        case .fed, .trained: daily.caredToday = true
        default: break
        }

        if let dragonId = grantsWish(action, daily: &daily) {
            outcome.grantedWishDragonIds.append(dragonId)
        }

        outcome.completedQuests = progress(action, daily: &daily)
        if !outcome.grantedWishDragonIds.isEmpty {
            outcome.completedQuests += progress(.wishGranted, daily: &daily)
        }

        if !daily.allClearRewarded, !daily.quests.isEmpty, daily.quests.allSatisfy(\.isComplete) {
            daily.allClearRewarded = true
            outcome.allClearedNow = true
        }
        return outcome
    }

    /// Advances matching quests; returns the ones that just completed.
    private static func progress(_ action: PlayerAction, daily: inout DailyState) -> [DailyQuest] {
        var completed: [DailyQuest] = []
        for i in daily.quests.indices {
            let wasComplete = daily.quests[i].isComplete
            switch (daily.quests[i].kind, action) {
            case (.feed, .fed), (.train, .trained), (.warmEgg, .warmedEgg), (.pet, .petted),
                 (.grantWish, .wishGranted), (.learningGame, .playedLearningGame):
                daily.quests[i].progress += 1
            case (.feedFavorite, .fed(_, true, _)):
                daily.quests[i].progress += 1
            case (.score(let game), .trained(let played, let score, _)) where game == played:
                daily.quests[i].progress = max(daily.quests[i].progress, score)
            default:
                continue
            }
            if !wasComplete && daily.quests[i].isComplete {
                completed.append(daily.quests[i])
            }
        }
        return completed
    }

    /// Returns the dragon whose wish this action just granted, if any.
    private static func grantsWish(_ action: PlayerAction, daily: inout DailyState) -> String? {
        let dragonId: String
        switch action {
        case .fed(_, _, let id), .trained(_, _, let id), .petted(let id): dragonId = id
        default: return nil
        }
        guard var wish = daily.wishes[dragonId], !wish.granted else { return nil }

        switch (wish.kind, action) {
        case (.eat(let wanted), .fed(let food, _, _)) where wanted == food:
            wish.granted = true
        case (.play(let wanted), .trained(let game, _, _)) where wanted == game:
            wish.granted = true
        case (.pet, .petted):
            wish.progress += 1
            wish.granted = wish.progress >= petWishCount
        default:
            return nil
        }
        daily.wishes[dragonId] = wish
        return wish.granted ? dragonId : nil
    }

    // MARK: - Streak

    static let maxShields = 2
    static let recentDaysKept = 14

    /// Judges the finished day and every unopened day up to `toDayId`.
    /// A day that doesn't count uses a shield if one is held, otherwise resets the streak.
    static func rollover(streak: inout StreakState, previous: DailyState, toDayId: String, calendar: Calendar) -> [StreakReward] {
        guard !previous.dayId.isEmpty else { return [] }
        let gap = GameDay.daysBetween(previous.dayId, toDayId, calendar: calendar)
        guard gap > 0 else { return [] }

        var rewards: [StreakReward] = []
        let firstCounted = previous.caredToday && !previous.illnessToday
        for offset in 0..<gap {
            let dayId = GameDay.adding(offset, to: previous.dayId, calendar: calendar)
            if offset == 0 && firstCounted {
                streak.current += 1
                streak.best = max(streak.best, streak.current)
                streak.recent.append(StreakDay(dayId: dayId, result: .counted))
                rewards += milestoneRewards(for: streak.current, streak: &streak)
            } else if streak.shields > 0 {
                streak.shields -= 1
                streak.recent.append(StreakDay(dayId: dayId, result: .shielded))
            } else {
                streak.current = 0
                streak.recent.append(StreakDay(dayId: dayId, result: .missed))
            }
        }
        if streak.recent.count > recentDaysKept {
            streak.recent.removeFirst(streak.recent.count - recentDaysKept)
        }
        return rewards
    }

    private static func milestoneRewards(for days: Int, streak: inout StreakState) -> [StreakReward] {
        switch days {
        case 3:
            return [.stars(15)]
        case 7:
            streak.shields = min(maxShields, streak.shields + 1)
            return [.shield, .stars(25)]
        case 14:
            return [.egg(.uncommon)]
        case let d where d >= 30 && d % 30 == 0:
            return [.egg(.rare)]
        default:
            return []
        }
    }
}
