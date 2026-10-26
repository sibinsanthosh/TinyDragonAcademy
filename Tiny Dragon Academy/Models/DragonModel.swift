//
//  DragonModel.swift
//  Tiny Dragon Academy
//
//  Data model representing cute dragon species, their customizable traits,
//  animations, personality traits, and raising/growth stats.
//

import SwiftUI

enum DragonElement: String, Codable, CaseIterable {
    case stars = "Star"
    case fire = "Fire"
    case water = "Water"
    case nature = "Nature"
    case ice = "Ice"
    case lightning = "Lightning"
    case laser = "Laser"
    case earth = "Earth"
    case wind = "Wind"
    case sun = "Sun"
    case flower = "Flower"
    case ocean = "Ocean"
    case moon = "Moon"
    case sweet = "Berry"
    case rainbow = "Rainbow"
    
    var iconName: String {
        switch self {
        case .stars: return "sparkles"
        case .fire: return "flame.fill"
        case .water: return "drop.fill"
        case .nature: return "leaf.fill"
        case .ice: return "snowflake"
        case .lightning: return "bolt.fill"
        case .laser: return "waveform.path.badge.plus"
        case .earth: return "mountain.2.fill"
        case .wind: return "wind"
        case .sun: return "sun.max.fill"
        case .flower: return "camera.macro"
        case .ocean: return "water.waves"
        case .moon: return "moon.stars.fill"
        case .sweet: return "heart.fill"
        case .rainbow: return "rainbow"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .stars: return DragonPalette.softPurple
        case .fire: return DragonPalette.coral
        case .water: return DragonPalette.skyBlue
        case .nature: return DragonPalette.mintGreen
        case .ice: return Color(red: 0.70, green: 0.90, blue: 1.0)
        case .lightning: return Color(red: 0.65, green: 0.45, blue: 1.0)
        case .laser: return Color(red: 0.15, green: 0.90, blue: 0.75)
        case .earth: return Color(red: 0.45, green: 0.72, blue: 0.45)
        case .wind: return Color(red: 0.78, green: 0.88, blue: 0.98)
        case .sun: return DragonPalette.buttercup
        case .flower: return DragonPalette.rosyPink
        case .ocean: return DragonPalette.turquoise
        case .moon: return Color(red: 0.55, green: 0.50, blue: 0.85)
        case .sweet: return Color(red: 0.98, green: 0.70, blue: 0.80)
        case .rainbow: return DragonPalette.lavender
        }
    }
}

enum HornStyle: String, Codable, CaseIterable {
    case nubby = "Little Nubs"
    case curved = "Curved Horns"
    case spiral = "Magic Swirl"
    case star = "Star Antennas"
    case crown = "Dragon Crown"
}

enum WingStyle: String, Codable, CaseIterable {
    case classic = "Dragon Wings"
    case fairy = "Fairy Wings"
    case leaf = "Leaf Flutter"
    case feather = "Feather Wings"
    case crystal = "Crystal Glider"
}

enum TailStyle: String, Codable, CaseIterable {
    case spade = "Heart Spade"
    case star = "Star Puff"
    case flower = "Blossom Tip"
    case cloud = "Cloud Fluff"
    case gem = "Magic Gem"
}

enum DragonAccessory: String, Codable, CaseIterable {
    case none = "None"
    case flowerCrown = "Flower Crown"
    case royalTiara = "Royal Tiara"
    case wizardHat = "Wizard Hat"
    case partyHat = "Party Hat"
    case starGlasses = "Star Spectacles"
    case heartGlasses = "Heart Glasses"
    case leafScarf = "Cozy Scarf"
    case magicCape = "Hero Cape"
    case warmBeanie = "Winter Beanie"
    
    var unlockStars: Int {
        switch self {
        case .none: return 0
        case .flowerCrown: return 3
        case .starGlasses: return 5
        case .partyHat: return 8
        case .leafScarf: return 12
        case .heartGlasses: return 15
        case .wizardHat: return 20
        case .warmBeanie: return 25
        case .royalTiara: return 30
        case .magicCape: return 40
        }
    }
}

enum IslandBackdrop: String, Codable, CaseIterable {
    case meadow = "Sunny Meadow"
    case sunset = "Peach Sunset"
    case starry = "Starry Night"
    case crystal = "Crystal Cavern"
    case clouds = "Cloud Kingdom"
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .meadow: return DragonPalette.meadowGradient
        case .sunset: return DragonPalette.sunsetGradient
        case .starry: return DragonPalette.nightGradient
        case .crystal:
            return LinearGradient(
                colors: [Color(red: 0.65, green: 0.85, blue: 0.95), Color(red: 0.80, green: 0.70, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .clouds: return DragonPalette.skyGradient
        }
    }
}

enum DragonMood: String {
    case idle
    case happy
    case sleepy
    case celebration
    case eating
    case anticipatingFood
    case castingPower
}

struct DragonModel: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    let speciesTitle: String
    let element: DragonElement
    var primaryColorHex: String
    var secondaryColorHex: String
    var bellyColorHex: String
    var hornStyle: HornStyle
    var wingStyle: WingStyle
    var tailStyle: TailStyle
    var accessory: DragonAccessory
    var backdrop: IslandBackdrop
    var isUnlocked: Bool
    var hatchCost: Int
    let favoriteSnack: String
    let personality: String
    var friendshipHearts: Int
    
    // Growth & Raising State
    var stats: DragonStats
    var favoriteFoodType: FoodType
    
    var primaryColor: Color { Color(hex: primaryColorHex) }
    var secondaryColor: Color { Color(hex: secondaryColorHex) }
    var bellyColor: Color { Color(hex: bellyColorHex) }
    
    // Standard Initializer
    init(
        id: String,
        name: String,
        speciesTitle: String,
        element: DragonElement,
        primaryColorHex: String,
        secondaryColorHex: String,
        bellyColorHex: String,
        hornStyle: HornStyle,
        wingStyle: WingStyle,
        tailStyle: TailStyle,
        accessory: DragonAccessory,
        backdrop: IslandBackdrop,
        isUnlocked: Bool,
        hatchCost: Int,
        favoriteSnack: String,
        personality: String,
        friendshipHearts: Int = 0,
        stats: DragonStats? = nil,
        favoriteFoodType: FoodType = .goldenFruit
    ) {
        self.id = id
        self.name = name
        self.speciesTitle = speciesTitle
        self.element = element
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.bellyColorHex = bellyColorHex
        self.hornStyle = hornStyle
        self.wingStyle = wingStyle
        self.tailStyle = tailStyle
        self.accessory = accessory
        self.backdrop = backdrop
        self.isUnlocked = isUnlocked
        self.hatchCost = hatchCost
        self.favoriteSnack = favoriteSnack
        self.personality = personality
        self.friendshipHearts = friendshipHearts
        self.stats = stats ?? DragonStats.defaultStats(for: element)
        self.favoriteFoodType = favoriteFoodType
    }
    
    // MARK: - Backward-Compatible Codable Migration
    
    enum CodingKeys: String, CodingKey {
        case id, name, speciesTitle, element
        case primaryColorHex, secondaryColorHex, bellyColorHex
        case hornStyle, wingStyle, tailStyle, accessory, backdrop
        case isUnlocked, hatchCost, favoriteSnack, personality, friendshipHearts
        case stats, favoriteFoodType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        speciesTitle = try container.decode(String.self, forKey: .speciesTitle)
        element = try container.decode(DragonElement.self, forKey: .element)
        primaryColorHex = try container.decode(String.self, forKey: .primaryColorHex)
        secondaryColorHex = try container.decode(String.self, forKey: .secondaryColorHex)
        bellyColorHex = try container.decode(String.self, forKey: .bellyColorHex)
        hornStyle = try container.decode(HornStyle.self, forKey: .hornStyle)
        wingStyle = try container.decode(WingStyle.self, forKey: .wingStyle)
        tailStyle = try container.decode(TailStyle.self, forKey: .tailStyle)
        accessory = try container.decode(DragonAccessory.self, forKey: .accessory)
        backdrop = try container.decode(IslandBackdrop.self, forKey: .backdrop)
        isUnlocked = try container.decode(Bool.self, forKey: .isUnlocked)
        hatchCost = try container.decode(Int.self, forKey: .hatchCost)
        favoriteSnack = try container.decode(String.self, forKey: .favoriteSnack)
        personality = try container.decode(String.self, forKey: .personality)
        friendshipHearts = try container.decode(Int.self, forKey: .friendshipHearts)
        
        // Safe migration for newly added fields
        var loadedStats = try container.decodeIfPresent(DragonStats.self, forKey: .stats) ?? DragonStats.defaultStats(for: element)
        let startingPower = ElementalPowersCatalog.powers(for: element).first?.id ?? "fire_1"
        if !loadedStats.unlockedPowerIds.contains(startingPower) {
            loadedStats.unlockedPowerIds.insert(startingPower)
        }
        stats = loadedStats
        favoriteFoodType = try container.decodeIfPresent(FoodType.self, forKey: .favoriteFoodType) ?? .goldenFruit
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(speciesTitle, forKey: .speciesTitle)
        try container.encode(element, forKey: .element)
        try container.encode(primaryColorHex, forKey: .primaryColorHex)
        try container.encode(secondaryColorHex, forKey: .secondaryColorHex)
        try container.encode(bellyColorHex, forKey: .bellyColorHex)
        try container.encode(hornStyle, forKey: .hornStyle)
        try container.encode(wingStyle, forKey: .wingStyle)
        try container.encode(tailStyle, forKey: .tailStyle)
        try container.encode(accessory, forKey: .accessory)
        try container.encode(backdrop, forKey: .backdrop)
        try container.encode(isUnlocked, forKey: .isUnlocked)
        try container.encode(hatchCost, forKey: .hatchCost)
        try container.encode(favoriteSnack, forKey: .favoriteSnack)
        try container.encode(personality, forKey: .personality)
        try container.encode(friendshipHearts, forKey: .friendshipHearts)
        try container.encode(stats, forKey: .stats)
        try container.encode(favoriteFoodType, forKey: .favoriteFoodType)
    }
    
    static func defaultDragons() -> [DragonModel] {
        return [
            DragonModel(
                id: "sparkle",
                name: "Sparkle",
                speciesTitle: "Star Baby",
                element: .stars,
                primaryColorHex: "#D0C7F5",
                secondaryColorHex: "#FFEAA7",
                bellyColorHex: "#FFF9E6",
                hornStyle: .star,
                wingStyle: .fairy,
                tailStyle: .star,
                accessory: .none,
                backdrop: .starry,
                isUnlocked: true, // First starter dragon!
                hatchCost: 0,
                favoriteSnack: "Starfish Cookies",
                personality: "Curious, gentle and loves stargazing.",
                friendshipHearts: 3,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .starfishTreats
            ),
            DragonModel(
                id: "ember",
                name: "Ember",
                speciesTitle: "Little Flame",
                element: .fire,
                primaryColorHex: "#FFA07A",
                secondaryColorHex: "#FFE066",
                bellyColorHex: "#FFF3D1",
                hornStyle: .curved,
                wingStyle: .classic,
                tailStyle: .spade,
                accessory: .none,
                backdrop: .sunset,
                isUnlocked: false,
                hatchCost: 5,
                favoriteSnack: "Fire Berries",
                personality: "Playful, energetic and gives the warmest hugs.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .fireBerries
            ),
            DragonModel(
                id: "frosty",
                name: "Frosty",
                speciesTitle: "Snow Shimmer",
                element: .ice,
                primaryColorHex: "#C4E0E5",
                secondaryColorHex: "#FFFFFF",
                bellyColorHex: "#EBF4F6",
                hornStyle: .crown,
                wingStyle: .crystal,
                tailStyle: .gem,
                accessory: .none,
                backdrop: .crystal,
                isUnlocked: false,
                hatchCost: 10,
                favoriteSnack: "Frost Apples",
                personality: "Sparkly and loves making snowflake patterns.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .frostApples
            ),
            DragonModel(
                id: "volt",
                name: "Volt",
                speciesTitle: "Storm Spark",
                element: .lightning,
                primaryColorHex: "#BDB2FF",
                secondaryColorHex: "#FDFFB6",
                bellyColorHex: "#F5F3FF",
                hornStyle: .spiral,
                wingStyle: .classic,
                tailStyle: .star,
                accessory: .none,
                backdrop: .starry,
                isUnlocked: false,
                hatchCost: 12,
                favoriteSnack: "Crystal Candies",
                personality: "Zippy, vibrant and crackles with joyful electric energy.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .crystalShards
            ),
            DragonModel(
                id: "nova",
                name: "Nova",
                speciesTitle: "Prism Ray",
                element: .laser,
                primaryColorHex: "#99F6E4",
                secondaryColorHex: "#F472B6",
                bellyColorHex: "#F0FDFA",
                hornStyle: .star,
                wingStyle: .crystal,
                tailStyle: .gem,
                accessory: .starGlasses,
                backdrop: .crystal,
                isUnlocked: false,
                hatchCost: 15,
                favoriteSnack: "Sunbeam Orange",
                personality: "High-tech and radiant, glowing with focused light beams.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .sunbeamOrange
            ),
            DragonModel(
                id: "terra",
                name: "Terra",
                speciesTitle: "Stone Pebble",
                element: .earth,
                primaryColorHex: "#A7D7C5",
                secondaryColorHex: "#D8B48F",
                bellyColorHex: "#F4EBD9",
                hornStyle: .nubby,
                wingStyle: .leaf,
                tailStyle: .spade,
                accessory: .none,
                backdrop: .meadow,
                isUnlocked: false,
                hatchCost: 15,
                favoriteSnack: "Dragon Roast",
                personality: "Sturdy, patient and loves rolling smooth pebbles.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .dragonRoast
            ),
            DragonModel(
                id: "splash",
                name: "Splash",
                speciesTitle: "Bubble Diver",
                element: .water,
                primaryColorHex: "#A0E7E5",
                secondaryColorHex: "#68C4FF",
                bellyColorHex: "#E0F7FA",
                hornStyle: .spiral,
                wingStyle: .feather,
                tailStyle: .cloud,
                accessory: .none,
                backdrop: .meadow,
                isUnlocked: false,
                hatchCost: 18,
                favoriteSnack: "Sweet Coral Melons",
                personality: "Cheerful water baby who loves blowing bubbles.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .starfishTreats
            ),
            DragonModel(
                id: "sprout",
                name: "Sprout",
                speciesTitle: "Forest Seedling",
                element: .nature,
                primaryColorHex: "#B4F8C8",
                secondaryColorHex: "#77DD77",
                bellyColorHex: "#F0FFF0",
                hornStyle: .nubby,
                wingStyle: .leaf,
                tailStyle: .flower,
                accessory: .flowerCrown,
                backdrop: .meadow,
                isUnlocked: false,
                hatchCost: 20,
                favoriteSnack: "Dewdrop Honey Apples",
                personality: "Shy, peaceful and loves naps under oak trees.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .frostApples
            ),
            DragonModel(
                id: "zephyr",
                name: "Zephyr",
                speciesTitle: "Breeze Dancer",
                element: .wind,
                primaryColorHex: "#C5E3F6",
                secondaryColorHex: "#E8D7FF",
                bellyColorHex: "#F9F9FF",
                hornStyle: .spiral,
                wingStyle: .feather,
                tailStyle: .cloud,
                accessory: .none,
                backdrop: .clouds,
                isUnlocked: false,
                hatchCost: 25,
                favoriteSnack: "Fluffy Cloud Cotton",
                personality: "Always gliding gently in the sky with butterflies.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .moonbeamPudding
            ),
            DragonModel(
                id: "sunny",
                name: "Sunny",
                speciesTitle: "Golden Beam",
                element: .sun,
                primaryColorHex: "#FFEAA7",
                secondaryColorHex: "#FFB347",
                bellyColorHex: "#FFFDF0",
                hornStyle: .crown,
                wingStyle: .fairy,
                tailStyle: .star,
                accessory: .starGlasses,
                backdrop: .meadow,
                isUnlocked: false,
                hatchCost: 30,
                favoriteSnack: "Sunbeam Oranges",
                personality: "Beams brightly and brightens everyone's day.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .sunbeamOrange
            ),
            DragonModel(
                id: "flora",
                name: "Flora",
                speciesTitle: "Petal Blossom",
                element: .flower,
                primaryColorHex: "#FFB7B2",
                secondaryColorHex: "#FFD1DC",
                bellyColorHex: "#FFF0F5",
                hornStyle: .nubby,
                wingStyle: .leaf,
                tailStyle: .flower,
                accessory: .none,
                backdrop: .meadow,
                isUnlocked: false,
                hatchCost: 35,
                favoriteSnack: "Rose Petal Nectar",
                personality: "Loves singing to blooming flower buds.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .goldenFruit
            ),
            DragonModel(
                id: "bubble",
                name: "Bubble",
                speciesTitle: "Pearl Whimsy",
                element: .ocean,
                primaryColorHex: "#89CFF0",
                secondaryColorHex: "#B0E0E6",
                bellyColorHex: "#F0F8FF",
                hornStyle: .spiral,
                wingStyle: .classic,
                tailStyle: .spade,
                accessory: .none,
                backdrop: .clouds,
                isUnlocked: false,
                hatchCost: 40,
                favoriteSnack: "Sea Grape Jelly",
                personality: "Bounces like a little beach ball with joy.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .starfishTreats
            ),
            DragonModel(
                id: "twinkle",
                name: "Twinkle",
                speciesTitle: "Moon Whisper",
                element: .moon,
                primaryColorHex: "#9B90B8",
                secondaryColorHex: "#DFD8F7",
                bellyColorHex: "#EAE6F8",
                hornStyle: .curved,
                wingStyle: .fairy,
                tailStyle: .star,
                accessory: .none,
                backdrop: .starry,
                isUnlocked: false,
                hatchCost: 45,
                favoriteSnack: "Moonbeam Cookies",
                personality: "Quiet guardian who loves humming gentle lullabies.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .moonbeamPudding
            ),
            DragonModel(
                id: "berry",
                name: "Berry",
                speciesTitle: "Sweet Plum",
                element: .sweet,
                primaryColorHex: "#F4C2C2",
                secondaryColorHex: "#E0BBE4",
                bellyColorHex: "#FFF5F7",
                hornStyle: .nubby,
                wingStyle: .classic,
                tailStyle: .spade,
                accessory: .none,
                backdrop: .sunset,
                isUnlocked: false,
                hatchCost: 50,
                favoriteSnack: "Wild Strawberries",
                personality: "Sweetest little dragon who loves cuddle time.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .fireBerries
            ),
            DragonModel(
                id: "rainbow",
                name: "Rainbow",
                speciesTitle: "Prism Wonder",
                element: .rainbow,
                primaryColorHex: "#D5AAFF",
                secondaryColorHex: "#FFABAB",
                bellyColorHex: "#FFFFD1",
                hornStyle: .crown,
                wingStyle: .fairy,
                tailStyle: .gem,
                accessory: .royalTiara,
                backdrop: .meadow,
                isUnlocked: false,
                hatchCost: 60,
                favoriteSnack: "Rainbow Sherbet",
                personality: "Rare prismatic marvel whose wings shimmer with color.",
                friendshipHearts: 0,
                stats: DragonStats.defaultStats(),
                favoriteFoodType: .goldenFruit
            )
        ]
    }
}

// Color hex helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 200, 200, 200)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
