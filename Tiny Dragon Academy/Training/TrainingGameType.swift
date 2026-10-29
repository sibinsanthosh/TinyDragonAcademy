//
//  TrainingGameType.swift
//  Tiny Dragon Academy
//
//  The four arcade training games that keep a dragon fit.
//

import SwiftUI

enum TrainingGameType: String, CaseIterable, Codable, Identifiable {
    case dragonDash = "Dragon Dash"
    case fireTarget = "Fire Target"
    case skyFlight = "Sky Flight"
    case snackCatch = "Catch the Snacks"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .dragonDash: return "Run and jump over rocks, cacti and bats!"
        case .fireTarget: return "Touch a target, let go and blast it!"
        case .skyFlight: return "Tap to flap through the cloud gaps!"
        case .snackCatch: return "Catch falling snacks, dodge the storms!"
        }
    }

    var iconName: String {
        switch self {
        case .dragonDash: return "figure.run"
        case .fireTarget: return "scope"
        case .skyFlight: return "cloud.fill"
        case .snackCatch: return "basket.fill"
        }
    }

    var trainsLabel: String {
        switch self {
        case .dragonDash: return "Stamina"
        case .fireTarget: return "Aim"
        case .skyFlight: return "Agility"
        case .snackCatch: return "Reflexes"
        }
    }

    var themeColor: Color {
        switch self {
        case .dragonDash: return DragonPalette.coral
        case .fireTarget: return DragonPalette.buttercup
        case .skyFlight: return DragonPalette.skyBlue
        case .snackCatch: return DragonPalette.mintGreen
        }
    }

    var isTimed: Bool { roundDuration != nil }

    /// Seconds per round for timed games.
    var roundDuration: Double? {
        switch self {
        case .fireTarget: return 45
        case .snackCatch: return 60
        case .dragonDash, .skyFlight: return nil
        }
    }

    /// Endless games also count once this score is reached.
    var minimumCountedScore: Int? {
        switch self {
        case .dragonDash: return 200
        case .skyFlight: return 5
        case .fireTarget, .snackCatch: return nil
        }
    }

    /// Score that earns the maximum reward.
    var scoreForFullMarks: Double {
        switch self {
        case .dragonDash: return 2000
        case .fireTarget: return 30
        case .skyFlight: return 40
        case .snackCatch: return 40
        }
    }
}
