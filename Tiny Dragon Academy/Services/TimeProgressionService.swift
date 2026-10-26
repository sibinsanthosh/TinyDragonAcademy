//
//  TimeProgressionService.swift
//  Tiny Dragon Academy
//
//  Offline time-progression manager. Computes elapsed time safely,
//  clamping intervals to prevent manipulation or punitive decay,
//  and rewards returning children with a positive welcome bonus.
//

import Foundation

struct CareSummary {
    let hoursElapsed: Double
    let hungerChange: Double
    let energyRecovered: Double
    let dailyBonusAwarded: Bool
    let bonusStars: Int
    let bonusFood: FoodType?
}

final class TimeProgressionService {
    static let shared = TimeProgressionService()
    
    private init() {}
    
    /// Processes offline elapsed time and returns a gentle summary
    func processOfflineProgression(
        dragonStats: inout DragonStats,
        lastDailyClaim: inout Date?,
        inventory: inout [String: Int],
        totalStars: inout Int
    ) -> CareSummary {
        let now = Date()
        let rawSeconds = now.timeIntervalSince(dragonStats.lastCareTimestamp)
        
        // Clamp elapsed time between 0 and 24 hours (86,400 seconds)
        // This ensures children are NEVER punished for missing days.
        let clampedSeconds = max(0, min(rawSeconds, 86_400))
        let hoursElapsed = clampedSeconds / 3600.0
        
        var hungerDecay = 0.0
        var energyGained = 0.0
        
        if hoursElapsed > 0.25 { // At least 15 minutes away
            // Gentle hunger decay: ~2% per hour, never drops below 25% (dragon is never starved)
            let rawDecay = hoursElapsed * 2.0
            let newHunger = max(25.0, dragonStats.hunger - rawDecay)
            hungerDecay = dragonStats.hunger - newHunger
            dragonStats.hunger = newHunger
            
            // Energy recovers during rest: ~10% per hour, up to 100%
            let rawEnergyGain = hoursElapsed * 10.0
            let newEnergy = min(100.0, dragonStats.energy + rawEnergyGain)
            energyGained = newEnergy - dragonStats.energy
            dragonStats.energy = newEnergy
            
            // Dragon ages gently: 1 age day every 12 real hours
            let addedDays = Int(hoursElapsed / 12.0)
            dragonStats.ageInDays += addedDays
        }
        
        dragonStats.lastCareTimestamp = now
        
        // Check Daily Care Bonus (calendar day check)
        var dailyBonusAwarded = false
        var bonusStars = 0
        var bonusFood: FoodType? = nil
        
        let calendar = Calendar.current
        let isNewDay: Bool
        if let last = lastDailyClaim {
            isNewDay = !calendar.isDate(last, inSameDayAs: now)
        } else {
            isNewDay = true
        }
        
        if isNewDay {
            dailyBonusAwarded = true
            lastDailyClaim = now
            bonusStars = 8
            totalStars += bonusStars
            
            // Pick a delightful random bonus food
            let treats: [FoodType] = [.goldenFruit, .fireBerries, .frostApples, .crystalShards, .sunbeamOrange]
            let chosen = treats.randomElement() ?? .goldenFruit
            bonusFood = chosen
            inventory[chosen.rawValue] = (inventory[chosen.rawValue] ?? 0) + 2
        }
        
        return CareSummary(
            hoursElapsed: hoursElapsed,
            hungerChange: hungerDecay,
            energyRecovered: energyGained,
            dailyBonusAwarded: dailyBonusAwarded,
            bonusStars: bonusStars,
            bonusFood: bonusFood
        )
    }
}
