//
//  IslandModel.swift
//  Tiny Dragon Academy
//
//  Model representing placable decorations, island layout, and themes for the Magical Island.
//

import SwiftUI

enum IslandItemCategory: String, CaseIterable, Codable {
    case houses = "Homes"
    case nature = "Trees"
    case flowers = "Flowers"
    case magical = "Magic"
    case play = "Fun"
}

enum IslandItemType: String, Codable, CaseIterable {
    // Homes & Habitats
    case mushroomCottage = "Mushroom Cottage"
    case dragonNest = "Cozy Dragon Nest"
    case crystalTower = "Crystal Spire"
    case cloudGazebo = "Cloud Pavilion"
    
    // Trees & Nature
    case pinkBlossomTree = "Pink Blossom Tree"
    case magicFruitTree = "Golden Star Tree"
    case gentlePine = "Sweet Mint Pine"
    case fairyWillow = "Lavender Willow"
    
    // Flowers & Mushrooms
    case giantToadstool = "Polka-dot Mushroom"
    case rainbowTulips = "Rainbow Flowers"
    case glowingLotus = "Sparkle Lotus"
    case crystalCluster = "Shimmer Crystals"
    
    // Water & Magic
    case cozyPond = "Lilypad Pond"
    case rainbowBridge = "Rainbow Arch"
    case starryFountain = "Starlight Well"
    
    // Play Structures
    case dragonSlide = "Dragon Slide"
    case starrySwing = "Star Swing"
    case cloudTrampoline = "Cloud Bouncer"
    
    var category: IslandItemCategory {
        switch self {
        case .mushroomCottage, .dragonNest, .crystalTower, .cloudGazebo:
            return .houses
        case .pinkBlossomTree, .magicFruitTree, .gentlePine, .fairyWillow:
            return .nature
        case .giantToadstool, .rainbowTulips, .glowingLotus, .crystalCluster:
            return .flowers
        case .cozyPond, .rainbowBridge, .starryFountain:
            return .magical
        case .dragonSlide, .starrySwing, .cloudTrampoline:
            return .play
        }
    }
    
    var unlockStars: Int {
        switch self {
        case .pinkBlossomTree, .giantToadstool, .dragonNest, .rainbowTulips:
            return 0 // Free starter items!
        case .cozyPond, .gentlePine, .magicFruitTree:
            return 3
        case .mushroomCottage, .crystalCluster, .cloudTrampoline:
            return 6
        case .rainbowBridge, .starrySwing, .glowingLotus:
            return 10
        case .starryFountain, .fairyWillow, .dragonSlide:
            return 15
        case .crystalTower, .cloudGazebo:
            return 20
        }
    }
    
    var iconName: String {
        switch self {
        case .mushroomCottage: return "house.fill"
        case .dragonNest: return "circle.inset.filled"
        case .crystalTower: return "building.columns.fill"
        case .cloudGazebo: return "tent.fill"
        case .pinkBlossomTree: return "leaf.arrow.triangle.circlepath"
        case .magicFruitTree: return "tree.fill"
        case .gentlePine: return "tree"
        case .fairyWillow: return "leaf.fill"
        case .giantToadstool: return "circle.grid.cross.fill"
        case .rainbowTulips: return "camera.macro"
        case .glowingLotus: return "sparkles"
        case .crystalCluster: return "suit.diamond.fill"
        case .cozyPond: return "drop.fill"
        case .rainbowBridge: return "rainbow"
        case .starryFountain: return "water.waves"
        case .dragonSlide: return "figure.walk"
        case .starrySwing: return "star.fill"
        case .cloudTrampoline: return "cloud.fill"
        }
    }
}

struct PlacedItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var itemType: IslandItemType
    var xNormalized: CGFloat // 0.0 to 1.0 (relative to island canvas)
    var yNormalized: CGFloat // 0.0 to 1.0
    var scale: CGFloat = 1.0
}

struct IslandState: Codable, Equatable {
    var theme: IslandBackdrop = .meadow
    var placedItems: [PlacedItem] = []
    
    static func defaultIsland() -> IslandState {
        return IslandState(
            theme: .meadow,
            placedItems: [
                PlacedItem(itemType: .mushroomCottage, xNormalized: 0.30, yNormalized: 0.38, scale: 1.1),
                PlacedItem(itemType: .dragonNest, xNormalized: 0.70, yNormalized: 0.42, scale: 1.0),
                PlacedItem(itemType: .pinkBlossomTree, xNormalized: 0.18, yNormalized: 0.65, scale: 1.0),
                PlacedItem(itemType: .giantToadstool, xNormalized: 0.82, yNormalized: 0.68, scale: 0.9),
                PlacedItem(itemType: .cozyPond, xNormalized: 0.50, yNormalized: 0.72, scale: 1.1)
            ]
        )
    }
}
