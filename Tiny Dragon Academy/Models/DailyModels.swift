//
//  DailyModels.swift
//  Tiny Dragon Academy
//
//  Care Mode, the 07:00 game day, daily quests, dragon wishes and the care streak.
//

import Foundation

enum CareMode: String, Codable, CaseIterable {
    /// Young kids: dragons never die.
    case gentle
    /// Real stakes: neglect can lead to a spirit.
    case classic

    var title: String {
        switch self {
        case .gentle: return "Gentle"
        case .classic: return "Classic"
        }
    }
}

// MARK: - Game day

enum GameDay {
    /// The game day starts at wake-up (07:00), so late-night play still counts for "today".
    static func id(for date: Date, calendar: Calendar) -> String {
        let shifted = date.addingTimeInterval(-Double(LifeRules.wakeHour) * 3600)
        let c = calendar.dateComponents([.year, .month, .day], from: shifted)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func daysBetween(_ from: String, _ to: String, calendar: Calendar) -> Int {
        guard let a = date(from), let b = date(to),
              let start = calendar.date(from: a), let end = calendar.date(from: b) else { return 0 }
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func adding(_ days: Int, to id: String, calendar: Calendar) -> String {
        guard let parts = date(id), let base = calendar.date(from: parts),
              let moved = calendar.date(byAdding: .day, value: days, to: base) else { return id }
        let c = calendar.dateComponents([.year, .month, .day], from: moved)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static func date(_ id: String) -> DateComponents? {
        let parts = id.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)
    }
}

/// Seeds that stay the same across launches (`hashValue` is randomized per process).
enum StableHash {
    static func fnv1a(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}

// MARK: - Quests

enum QuestKind: Codable, Equatable, Hashable {
    case feed
    case feedFavorite
    case train
    case score(TrainingGameType)
    case warmEgg
    case pet
    case grantWish
    case learningGame
}

struct DailyQuest: Codable, Equatable {
    var kind: QuestKind
    var target: Int
    var progress: Int = 0

    var isComplete: Bool { progress >= target }
}

// MARK: - Wishes

enum WishKind: Codable, Equatable {
    case eat(FoodType)
    case play(TrainingGameType)
    case pet
}

struct DragonWish: Codable, Equatable {
    var kind: WishKind
    var progress: Int = 0
    var granted: Bool = false
}

// MARK: - Day & streak state

struct DailyState: Codable, Equatable {
    var dayId: String = ""
    var quests: [DailyQuest] = []
    /// Wish per den dragon id.
    var wishes: [String: DragonWish] = [:]
    var caredToday: Bool = false
    var illnessToday: Bool = false
    var allClearRewarded: Bool = false
}

enum StreakDayResult: String, Codable {
    case counted
    case shielded
    case missed
}

struct StreakDay: Codable, Equatable {
    var dayId: String
    var result: StreakDayResult
}

struct StreakState: Codable, Equatable {
    var current: Int = 0
    var best: Int = 0
    var shields: Int = 0
    /// Most recent last; capped at 14 days.
    var recent: [StreakDay] = []
}

// MARK: - Player actions

/// Things the player did that daily quests and wishes listen for.
enum PlayerAction: Equatable {
    case fed(food: FoodType, isFavorite: Bool, dragonId: String)
    case trained(game: TrainingGameType, score: Int, dragonId: String)
    case warmedEgg
    case petted(dragonId: String)
    case wishGranted
    case playedLearningGame
}
