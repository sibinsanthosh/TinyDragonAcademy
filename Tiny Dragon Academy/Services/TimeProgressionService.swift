//
//  TimeProgressionService.swift
//  Tiny Dragon Academy
//
//  Daily care bonus on the first visit of each calendar day.
//  Needs decay over time is handled by LifeSimulator.
//

import Foundation

struct DailyBonus: Equatable {
    let stars: Int
    let food: FoodType
}

final class TimeProgressionService {
    static let shared = TimeProgressionService()
    
    static let bonusStars = 8
    static let bonusFoodCount = 2
    
    private init() {}
    
    /// Awards the daily bonus when `now` is on a new calendar day; returns nil otherwise.
    func claimDailyBonus(
        lastDailyClaim: inout Date?,
        inventory: inout [String: Int],
        totalStars: inout Int,
        now: Date,
        calendar: Calendar
    ) -> DailyBonus? {
        if let last = lastDailyClaim, calendar.isDate(last, inSameDayAs: now) {
            return nil
        }
        lastDailyClaim = now
        totalStars += Self.bonusStars
        
        let treats: [FoodType] = [.goldenFruit, .fireBerries, .frostApples, .crystalShards, .sunbeamOrange]
        let chosen = treats.randomElement() ?? .goldenFruit
        inventory[chosen.rawValue] = (inventory[chosen.rawValue] ?? 0) + Self.bonusFoodCount
        return DailyBonus(stars: Self.bonusStars, food: chosen)
    }
}
