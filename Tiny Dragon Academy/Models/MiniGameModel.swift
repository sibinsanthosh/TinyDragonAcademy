//
//  MiniGameModel.swift
//  Tiny Dragon Academy
//
//  Game metadata, rules, and levels for the 4 educational mini-games.
//

import SwiftUI

enum MiniGameType: String, CaseIterable, Identifiable, Codable {
    case colorGarden = "Colour Garden"
    case shapeMagic = "Shape Magic"
    case countStars = "Count the Stars"
    case dragonPuzzle = "Dragon Puzzle"
    
    var id: String { rawValue }
    
    var subtitle: String {
        switch self {
        case .colorGarden: return "Sort colorful gems into matching baskets!"
        case .shapeMagic: return "Match magical shapes to their glowing outlines!"
        case .countStars: return "Count the friendly stars and tap the number!"
        case .dragonPuzzle: return "Put the baby dragon puzzle pieces together!"
        }
    }
    
    var ageRecommendation: String {
        switch self {
        case .colorGarden: return "Ages 3–5"
        case .shapeMagic: return "Ages 3–6"
        case .countStars: return "Ages 4–7"
        case .dragonPuzzle: return "Ages 3–7"
        }
    }
    
    var iconName: String {
        switch self {
        case .colorGarden: return "paintpalette.fill"
        case .shapeMagic: return "wand.and.stars"
        case .countStars: return "star.fill"
        case .dragonPuzzle: return "puzzlepiece.fill"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .colorGarden: return DragonPalette.coral
        case .shapeMagic: return DragonPalette.softPurple
        case .countStars: return DragonPalette.buttercup
        case .dragonPuzzle: return DragonPalette.mintGreen
        }
    }
    
    var starsReward: Int { 3 }
}

struct GameStats: Codable, Equatable {
    var gamesPlayed: Int = 0
    var starsEarned: Int = 0
}
