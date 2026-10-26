//
//  LifeModels.swift
//  Tiny Dragon Academy
//
//  Tamagotchi-style life rules: needs decay, illness, death & revive,
//  care items and memorials. Every tunable number lives in `LifeRules`.
//

import Foundation

// MARK: - Rules

enum LifeRules {
    static let simulationStep: TimeInterval = 60

    // Awake decay / recovery (points per hour)
    static let fullnessDecayPerHour = 12.0
    static let energyDecayPerHour = 4.0
    static let energySleepGainPerHour = 12.0
    static let happinessDecayPerHour = 5.0
    static let fitnessDecayPerHour = 4.0
    static let healthRegenPerHour = 2.0
    static let healthRegenMinFullness = 50.0

    // Health drain while neglected (cumulative, points per awake hour)
    static let starvingDrainPerHour = 2.0
    static let illDrainPerHour = 1.0
    static let lowFitnessDrainPerHour = 0.5

    // Thresholds
    static let hungryThreshold = 30.0
    static let lowFitnessThreshold = 20.0
    static let needsTrainingThreshold = 30.0
    static let healthCriticalThreshold = 25.0

    // Illness
    static let hungerFeverMinutes = 120.0
    static let sluggishScalesMinutes = 360.0
    static let tummyAcheFullness = 95.0
    static let tummyAcheDuration: TimeInterval = 3600
    static let tummyAcheHappinessPenalty = 10.0
    static let sluggishCureSessions = 2

    // Death & revive
    static let spiritWindow: TimeInterval = 172_800
    static let spiritLastChance: TimeInterval = 21_600
    static let reviveHealth = 50.0
    static let reviveFullness = 50.0

    // Time
    static let catchUpCap: TimeInterval = 604_800
    static let sleepStartHour = 22
    static let wakeHour = 7

    // Training & migration
    static let trainingEnergyCost = 15.0
    static let migratedFitness = 70.0
}

// MARK: - Condition

enum Illness: String, Codable, CaseIterable {
    case hungerFever = "Hunger Fever"
    case sluggishScales = "Sluggish Scales"

    var displayName: String { rawValue }
}

enum DragonCondition: Codable, Equatable {
    case healthy
    case ill(Illness)
    case spirit(diedAt: Date)

    var isSpirit: Bool {
        if case .spirit = self { return true }
        return false
    }

    var illness: Illness? {
        if case .ill(let illness) = self { return illness }
        return nil
    }

    var spiritDiedAt: Date? {
        if case .spirit(let diedAt) = self { return diedAt }
        return nil
    }
}

enum DragonResidence: String, Codable {
    case den
    case sanctuary
    case undiscovered
    case legend
}

// MARK: - Events

enum LifeEvent: Equatable, Hashable {
    case becameHungry
    case starving
    case needsTraining
    case becameIll(Illness)
    case healthCritical
    case died
    case spiritLastChance
    case spiritExpired
    case cured
    case fellAsleep
    case wokeUp
    case eggReady
    case eggCold

    /// Higher wins when notifications collide.
    var severity: Int {
        switch self {
        case .died: return 7
        case .spiritLastChance: return 6
        case .healthCritical: return 5
        case .becameIll: return 4
        case .starving: return 3
        case .becameHungry: return 2
        case .needsTraining: return 1
        default: return 0
        }
    }
}

// MARK: - Care items & memorials

enum CareItem: String, Codable, CaseIterable {
    case healingHerb = "Healing Herb"
    case phoenixEmber = "Phoenix Ember"

    var price: Int {
        switch self {
        case .healingHerb: return 15
        case .phoenixEmber: return 60
        }
    }

    var iconName: String {
        switch self {
        case .healingHerb: return "leaf.circle.fill"
        case .phoenixEmber: return "flame.circle.fill"
        }
    }
}

struct Memorial: Codable, Equatable, Identifiable {
    let id: UUID
    let dragonId: String
    let name: String
    let speciesTitle: String
    let stage: GrowthStage
    let level: Int
    let bornAt: Date
    let diedAt: Date
}
