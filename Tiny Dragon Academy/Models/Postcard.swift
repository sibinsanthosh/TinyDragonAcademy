//
//  Postcard.swift
//  Tiny Dragon Academy
//
//  What a photo-booth postcard shows: its frame, the dragon's pose, and the
//  name, level, talent and best skill printed on it.
//

import SwiftUI

enum PostcardFrame: String, CaseIterable, Identifiable {
    case classic, starry, garden, party

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    /// Top and bottom of the frame's own background.
    var colors: [Color] {
        switch self {
        case .classic: return [ClayColor.backdropTop, ClayColor.backdropBottom]
        case .starry: return [Color(red: 0.24, green: 0.22, blue: 0.48), Color(red: 0.50, green: 0.40, blue: 0.75)]
        case .garden: return [Color(red: 0.78, green: 0.93, blue: 0.82), Color(red: 0.96, green: 0.95, blue: 0.80)]
        case .party: return [Color(red: 1.0, green: 0.86, blue: 0.62), Color(red: 1.0, green: 0.72, blue: 0.80)]
        }
    }

    /// Small repeated decoration scattered around the frame.
    var decoration: String {
        switch self {
        case .classic: return "sparkle"
        case .starry: return "star.fill"
        case .garden: return "leaf.fill"
        case .party: return "balloon.fill"
        }
    }

    var accent: Color {
        switch self {
        case .classic: return ClayColor.accent
        case .starry: return ClayColor.sun
        case .garden: return ClayColor.mintShade
        case .party: return ClayColor.coral
        }
    }

    /// Light text on the dark starry frame, ink elsewhere.
    var isDark: Bool { self == .starry }
}

enum PostcardPose: String, CaseIterable, Identifiable {
    case happy, cheeky, sleepy, power

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var mood: DragonMood {
        switch self {
        case .happy: return .happy
        case .cheeky: return .celebration
        case .sleepy: return .sleepy
        case .power: return .castingPower
        }
    }

    var iconName: String {
        switch self {
        case .happy: return "face.smiling"
        case .cheeky: return "party.popper"
        case .sleepy: return "moon.zzz"
        case .power: return "flame"
        }
    }
}

/// The words printed on a postcard.
struct PostcardContent: Equatable {
    let title: String
    let subtitle: String
    let talentTitle: String?
    let bestSkill: DragonSkill
    let bestSkillStars: Int
    let isShiny: Bool

    init(dragon: DragonModel) {
        title = dragon.badgedName
        subtitle = "Lvl \(dragon.stats.level) · \(dragon.stats.growthStage.rawValue)"
        talentTitle = dragon.talent?.title
        // Highest stars; ties go to the earlier skill in the list
        let best = DragonSkill.allCases.reduce(DragonSkill.allCases[0]) { best, skill in
            dragon.skillStars(skill) > dragon.skillStars(best) ? skill : best
        }
        bestSkill = best
        bestSkillStars = dragon.skillStars(best)
        isShiny = dragon.isShiny
    }
}
