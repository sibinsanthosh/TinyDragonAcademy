//
//  DailyRulesTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class DailyRulesTests: XCTestCase {
    private let cal = TestTime.utc
    private let full = QuestContext(hasIncubatingEgg: true, knowsAFavorite: true, hasDenDragon: true)

    private func daily(_ quests: [DailyQuest], wishes: [String: DragonWish] = [:]) -> DailyState {
        DailyState(dayId: "2026-01-05", quests: quests, wishes: wishes)
    }

    // MARK: - Quest generation

    func test_quests_threeDistinctKinds() {
        let quests = DailyRules.quests(for: "2026-01-05", mode: .classic, context: full)
        XCTAssertEqual(quests.count, 3)
        XCTAssertEqual(Set(quests.map(\.kind)).count, 3)
        XCTAssertTrue(quests.allSatisfy { $0.progress == 0 && $0.target > 0 })
    }

    func test_quests_stableForSameDay() {
        XCTAssertEqual(DailyRules.quests(for: "2026-01-05", mode: .classic, context: full),
                       DailyRules.quests(for: "2026-01-05", mode: .classic, context: full))
        let week = (1...7).map { DailyRules.quests(for: String(format: "2026-01-%02d", $0), mode: .classic, context: full).map(\.kind) }
        XCTAssertGreaterThan(Set(week.map { "\($0)" }).count, 1, "different days get different quests")
    }

    func test_quests_respectContext() {
        let bare = QuestContext(hasIncubatingEgg: false, knowsAFavorite: false, hasDenDragon: true)
        for day in 1...28 {
            let kinds = DailyRules.quests(for: String(format: "2026-02-%02d", day), mode: .classic, context: bare).map(\.kind)
            XCTAssertFalse(kinds.contains(.warmEgg))
            XCTAssertFalse(kinds.contains(.feedFavorite))
        }
    }

    func test_gentleQuests_noScoreAndSmallerCounts() {
        for day in 1...28 {
            let quests = DailyRules.quests(for: String(format: "2026-02-%02d", day), mode: .gentle, context: full)
            XCTAssertFalse(quests.contains { if case .score = $0.kind { return true } else { return false } })
            if let feed = quests.first(where: { $0.kind == .feed }) { XCTAssertEqual(feed.target, 2) }
            if let pet = quests.first(where: { $0.kind == .pet }) { XCTAssertEqual(pet.target, 3) }
        }
    }

    // MARK: - Recording progress

    func test_feeding_progressesAndCompletesOnce() {
        var d = daily([DailyQuest(kind: .feed, target: 2), DailyQuest(kind: .pet, target: 5), DailyQuest(kind: .warmEgg, target: 5)])
        let first = DailyRules.record(.fed(food: .frostApples, isFavorite: false, dragonId: "sparkle"), daily: &d)
        XCTAssertTrue(first.completedQuests.isEmpty)
        let second = DailyRules.record(.fed(food: .frostApples, isFavorite: false, dragonId: "sparkle"), daily: &d)
        XCTAssertEqual(second.completedQuests.map(\.kind), [.feed])
        let third = DailyRules.record(.fed(food: .frostApples, isFavorite: false, dragonId: "sparkle"), daily: &d)
        XCTAssertTrue(third.completedQuests.isEmpty, "a finished quest only completes once")
        XCTAssertTrue(d.caredToday)
    }

    func test_feedFavorite_needsFavorite() {
        var d = daily([DailyQuest(kind: .feedFavorite, target: 1)])
        _ = DailyRules.record(.fed(food: .frostApples, isFavorite: false, dragonId: "sparkle"), daily: &d)
        XCTAssertFalse(d.quests[0].isComplete)
        _ = DailyRules.record(.fed(food: .starfishTreats, isFavorite: true, dragonId: "sparkle"), daily: &d)
        XCTAssertTrue(d.quests[0].isComplete)
    }

    func test_scoreQuest_usesBestScoreForThatGame() {
        var d = daily([DailyQuest(kind: .score(.dragonDash), target: 500)])
        _ = DailyRules.record(.trained(game: .skyFlight, score: 900, dragonId: "sparkle"), daily: &d)
        XCTAssertEqual(d.quests[0].progress, 0)
        _ = DailyRules.record(.trained(game: .dragonDash, score: 320, dragonId: "sparkle"), daily: &d)
        _ = DailyRules.record(.trained(game: .dragonDash, score: 120, dragonId: "sparkle"), daily: &d)
        XCTAssertEqual(d.quests[0].progress, 320)
        let done = DailyRules.record(.trained(game: .dragonDash, score: 640, dragonId: "sparkle"), daily: &d)
        XCTAssertEqual(done.completedQuests.count, 1)
    }

    func test_allClear_rewardedOnce() {
        var d = daily([DailyQuest(kind: .warmEgg, target: 1), DailyQuest(kind: .learningGame, target: 1), DailyQuest(kind: .pet, target: 1)])
        _ = DailyRules.record(.warmedEgg, daily: &d)
        _ = DailyRules.record(.playedLearningGame, daily: &d)
        let last = DailyRules.record(.petted(dragonId: "sparkle"), daily: &d)
        XCTAssertTrue(last.allClearedNow)
        XCTAssertTrue(d.allClearRewarded)
        XCTAssertFalse(DailyRules.record(.petted(dragonId: "sparkle"), daily: &d).allClearedNow)
    }

    func test_onlyFeedingAndTrainingCountAsCare() {
        var d = daily([])
        _ = DailyRules.record(.petted(dragonId: "sparkle"), daily: &d)
        _ = DailyRules.record(.warmedEgg, daily: &d)
        XCTAssertFalse(d.caredToday)
        _ = DailyRules.record(.trained(game: .fireTarget, score: 3, dragonId: "sparkle"), daily: &d)
        XCTAssertTrue(d.caredToday)
    }

    // MARK: - Wishes

    func test_wish_isDeterministicPerDragonAndDay() {
        let dragon = DragonModel.defaultDragons()[0]
        XCTAssertEqual(DailyRules.wish(for: dragon, dayId: "2026-01-05"), DailyRules.wish(for: dragon, dayId: "2026-01-05"))
        let kinds = (1...20).map { DailyRules.wish(for: dragon, dayId: String(format: "2026-03-%02d", $0)).kind }
        XCTAssertTrue(kinds.contains { if case .eat = $0 { return true } else { return false } })
        XCTAssertTrue(kinds.contains { if case .play = $0 { return true } else { return false } })
        XCTAssertTrue(kinds.contains(.pet))
    }

    func test_eatWish_grantedOnlyByThatFoodForThatDragon() {
        var d = daily([DailyQuest(kind: .grantWish, target: 1)], wishes: ["sparkle": DragonWish(kind: .eat(.fireBerries))])
        XCTAssertTrue(DailyRules.record(.fed(food: .fireBerries, isFavorite: false, dragonId: "ember"), daily: &d).grantedWishDragonIds.isEmpty)
        XCTAssertTrue(DailyRules.record(.fed(food: .frostApples, isFavorite: false, dragonId: "sparkle"), daily: &d).grantedWishDragonIds.isEmpty)
        let outcome = DailyRules.record(.fed(food: .fireBerries, isFavorite: false, dragonId: "sparkle"), daily: &d)
        XCTAssertEqual(outcome.grantedWishDragonIds, ["sparkle"])
        XCTAssertTrue(d.wishes["sparkle"]!.granted)
        XCTAssertEqual(outcome.completedQuests.map(\.kind), [.grantWish], "granting a wish counts for the quest")
        XCTAssertTrue(DailyRules.record(.fed(food: .fireBerries, isFavorite: false, dragonId: "sparkle"), daily: &d).grantedWishDragonIds.isEmpty)
    }

    func test_petWish_needsThreePets() {
        var d = daily([], wishes: ["sparkle": DragonWish(kind: .pet)])
        XCTAssertTrue(DailyRules.record(.petted(dragonId: "sparkle"), daily: &d).grantedWishDragonIds.isEmpty)
        XCTAssertTrue(DailyRules.record(.petted(dragonId: "sparkle"), daily: &d).grantedWishDragonIds.isEmpty)
        XCTAssertEqual(DailyRules.record(.petted(dragonId: "sparkle"), daily: &d).grantedWishDragonIds, ["sparkle"])
    }

    func test_playWish_grantedByThatGame() {
        var d = daily([], wishes: ["sparkle": DragonWish(kind: .play(.skyFlight))])
        XCTAssertTrue(DailyRules.record(.trained(game: .dragonDash, score: 10, dragonId: "sparkle"), daily: &d).grantedWishDragonIds.isEmpty)
        XCTAssertEqual(DailyRules.record(.trained(game: .skyFlight, score: 1, dragonId: "sparkle"), daily: &d).grantedWishDragonIds, ["sparkle"])
    }

    // MARK: - Streak

    private func day(_ id: String, cared: Bool = true, ill: Bool = false) -> DailyState {
        DailyState(dayId: id, caredToday: cared, illnessToday: ill)
    }

    func test_rollover_countedDayIncrements() {
        var streak = StreakState()
        let rewards = DailyRules.rollover(streak: &streak, previous: day("2026-01-05"), toDayId: "2026-01-06", calendar: cal)
        XCTAssertEqual(streak.current, 1)
        XCTAssertEqual(streak.best, 1)
        XCTAssertEqual(streak.recent, [StreakDay(dayId: "2026-01-05", result: .counted)])
        XCTAssertTrue(rewards.isEmpty)
    }

    func test_rollover_illnessOrNoCareBreaksStreak() {
        var streak = StreakState(current: 5, best: 5)
        _ = DailyRules.rollover(streak: &streak, previous: day("2026-01-05", ill: true), toDayId: "2026-01-06", calendar: cal)
        XCTAssertEqual(streak.current, 0)
        XCTAssertEqual(streak.best, 5)
        XCTAssertEqual(streak.recent.last?.result, .missed)
        streak.current = 3
        _ = DailyRules.rollover(streak: &streak, previous: day("2026-01-06", cared: false), toDayId: "2026-01-07", calendar: cal)
        XCTAssertEqual(streak.current, 0)
    }

    func test_rollover_gapUsesShieldsThenResets() {
        var streak = StreakState(current: 4, best: 4, shields: 2)
        _ = DailyRules.rollover(streak: &streak, previous: day("2026-01-05"), toDayId: "2026-01-09", calendar: cal)
        XCTAssertEqual(streak.recent.map(\.result), [.counted, .shielded, .shielded, .missed])
        XCTAssertEqual(streak.recent.map(\.dayId), ["2026-01-05", "2026-01-06", "2026-01-07", "2026-01-08"])
        XCTAssertEqual(streak.shields, 0)
        XCTAssertEqual(streak.current, 0)
        XCTAssertEqual(streak.best, 5)
    }

    func test_rollover_shieldKeepsStreak() {
        var streak = StreakState(current: 9, best: 9, shields: 1)
        _ = DailyRules.rollover(streak: &streak, previous: day("2026-01-05", cared: false), toDayId: "2026-01-06", calendar: cal)
        XCTAssertEqual(streak.current, 9)
        XCTAssertEqual(streak.shields, 0)
    }

    func test_milestones() {
        func reach(_ from: Int, shields: Int = 0) -> ([StreakReward], StreakState) {
            var streak = StreakState(current: from, best: from, shields: shields)
            let rewards = DailyRules.rollover(streak: &streak, previous: day("2026-01-05"), toDayId: "2026-01-06", calendar: cal)
            return (rewards, streak)
        }
        XCTAssertEqual(reach(2).0, [.stars(15)])
        XCTAssertEqual(reach(6).0, [.shield, .stars(25)])
        XCTAssertEqual(reach(6).1.shields, 1)
        XCTAssertEqual(reach(6, shields: 2).1.shields, 2, "shields cap at 2")
        XCTAssertEqual(reach(13).0, [.egg(.uncommon)])
        XCTAssertEqual(reach(29).0, [.egg(.rare)])
        XCTAssertEqual(reach(59).0, [.egg(.rare)])
        XCTAssertEqual(reach(10).0, [])
    }

    func test_milestone_rewardedOnce() {
        var streak = StreakState(current: 2, best: 2)
        XCTAssertEqual(DailyRules.rollover(streak: &streak, previous: day("2026-01-05"), toDayId: "2026-01-06", calendar: cal), [.stars(15)])
        XCTAssertEqual(DailyRules.rollover(streak: &streak, previous: day("2026-01-05"), toDayId: "2026-01-05", calendar: cal), [])
        XCTAssertEqual(streak.current, 3)
    }

    func test_rollover_freshStateIsNoOp() {
        var streak = StreakState()
        XCTAssertEqual(DailyRules.rollover(streak: &streak, previous: DailyState(), toDayId: "2026-01-06", calendar: cal), [])
        XCTAssertEqual(streak, StreakState())
    }

    func test_recent_cappedAt14() {
        var streak = StreakState()
        _ = DailyRules.rollover(streak: &streak, previous: day("2026-01-01"), toDayId: "2026-01-25", calendar: cal)
        XCTAssertEqual(streak.recent.count, 14)
        XCTAssertEqual(streak.recent.last?.dayId, "2026-01-24")
    }
}
