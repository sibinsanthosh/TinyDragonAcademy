//
//  LifeSimulator.swift
//  Tiny Dragon Academy
//
//  Pure, minute-stepped simulation of a dragon's needs over real time.
//  Used both for live ticking and for offline catch-up, so the rules
//  behave identically whether the app was open or closed.
//

import Foundation

enum LifeSimulator {

    /// Values this close to zero are treated as zero (avoids float drift from minute steps).
    private static let epsilon = 1e-6

    static func isQuietHours(_ date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= LifeRules.sleepStartHour || hour < LifeRules.wakeHour
    }

    static func isAsleep(_ stats: DragonStats, at date: Date, calendar: Calendar) -> Bool {
        stats.isSleepingEarly || isQuietHours(date, calendar: calendar)
    }

    /// Catch-up never simulates more than `LifeRules.catchUpCap` before `to`.
    static func effectiveStart(from: Date, to: Date) -> Date {
        max(from, to.addingTimeInterval(-LifeRules.catchUpCap))
    }

    static func advance(_ stats: DragonStats, from: Date, to: Date, calendar: Calendar) -> (DragonStats, [LifeEvent]) {
        let (s, timed) = run(stats, from: from, to: to, calendar: calendar)
        return (s, timed.map(\.event))
    }

    /// Notifiable events the dragon would hit with no player action, each at its first occurrence.
    static func predict(_ stats: DragonStats, from: Date, horizon: TimeInterval, calendar: Calendar) -> [(event: LifeEvent, at: Date)] {
        let notifiable: (LifeEvent) -> Bool = { event in
            switch event {
            case .becameHungry, .starving, .needsTraining, .becameIll, .healthCritical, .died, .spiritLastChance: return true
            default: return false
            }
        }
        let (_, timed) = run(stats, from: from, to: from.addingTimeInterval(horizon), calendar: calendar)
        return firstOccurrences(timed.filter { notifiable($0.event) })
    }

    private static func run(_ stats: DragonStats, from: Date, to: Date, calendar: Calendar) -> (DragonStats, [(event: LifeEvent, at: Date)]) {
        var s = stats
        var timed: [(event: LifeEvent, at: Date)] = []
        guard to > from else {
            s.lastSimulatedAt = to
            return (s, timed)
        }
        forEachStep(from: effectiveStart(from: from, to: to), to: to) { t, dt in
            var events: [LifeEvent] = []
            step(&s, at: t, dt: dt, calendar: calendar, events: &events)
            let end = t.addingTimeInterval(dt)
            timed.append(contentsOf: events.map { (event: $0, at: end) })
        }
        s.lastSimulatedAt = to
        let livedDays = 1 + Int(to.timeIntervalSince(s.bornAt) / 86_400)
        s.ageInDays = max(s.ageInDays, livedDays)
        return (s, timed)
    }

    /// Counted steps: accumulating Date + dt can stall just short of `to` in floating point.
    private static func forEachStep(from start: Date, to end: Date, _ body: (Date, TimeInterval) -> Void) {
        let total = end.timeIntervalSince(start)
        let fullSteps = Int(total / LifeRules.simulationStep)
        for i in 0..<fullSteps {
            body(start.addingTimeInterval(Double(i) * LifeRules.simulationStep), LifeRules.simulationStep)
        }
        let remainder = total - Double(fullSteps) * LifeRules.simulationStep
        if remainder > 1e-6 {
            body(start.addingTimeInterval(Double(fullSteps) * LifeRules.simulationStep), remainder)
        }
    }

    private static func firstOccurrences(_ timed: [(event: LifeEvent, at: Date)]) -> [(event: LifeEvent, at: Date)] {
        var seen = Set<LifeEvent>()
        return timed.filter { seen.insert($0.event).inserted }
    }

    // MARK: - One step

    private static func step(_ s: inout DragonStats, at t: Date, dt: TimeInterval, calendar: Calendar, events: inout [LifeEvent]) {
        let end = t.addingTimeInterval(dt)
        let hours = dt / 3600

        if let until = s.tummyAcheUntil, end >= until {
            s.tummyAcheUntil = nil
        }

        if let diedAt = s.condition.spiritDiedAt {
            let before = t.timeIntervalSince(diedAt)
            let after = end.timeIntervalSince(diedAt)
            let lastChance = LifeRules.spiritWindow - LifeRules.spiritLastChance
            if before < lastChance && after >= lastChance { events.append(.spiritLastChance) }
            if before < LifeRules.spiritWindow && after >= LifeRules.spiritWindow { events.append(.spiritExpired) }
            return
        }

        if s.isSleepingEarly, crossesWakeTime(from: t, to: end, calendar: calendar) {
            s.isSleepingEarly = false
            events.append(.wokeUp)
        }

        if isAsleep(s, at: t, calendar: calendar) {
            s.energy = clamp(s.energy + LifeRules.energySleepGainPerHour * hours)
            return
        }

        // Illness timers count minutes that *began* under the trigger condition.
        let wasStarving = s.hunger <= epsilon
        let wasUnfit = s.fitness < LifeRules.lowFitnessThreshold
        let hungerBefore = s.hunger
        let fitnessBefore = s.fitness
        let healthBefore = s.health

        s.hunger = clamp(s.hunger - LifeRules.fullnessDecayPerHour * hours)
        s.energy = clamp(s.energy - LifeRules.energyDecayPerHour * hours)
        s.happiness = clamp(s.happiness - LifeRules.happinessDecayPerHour * hours)
        s.fitness = clamp(s.fitness - LifeRules.fitnessDecayPerHour * hours)

        if hungerBefore >= LifeRules.hungryThreshold && s.hunger < LifeRules.hungryThreshold { events.append(.becameHungry) }
        if hungerBefore > epsilon && s.hunger <= epsilon { events.append(.starving) }
        if fitnessBefore >= LifeRules.needsTrainingThreshold && s.fitness < LifeRules.needsTrainingThreshold { events.append(.needsTraining) }

        s.fullnessZeroMinutes = wasStarving ? s.fullnessZeroMinutes + dt / 60 : 0
        s.lowFitnessMinutes = wasUnfit ? s.lowFitnessMinutes + dt / 60 : 0

        if s.condition == .healthy {
            if s.fullnessZeroMinutes >= LifeRules.hungerFeverMinutes - epsilon {
                s.condition = .ill(.hungerFever)
                events.append(.becameIll(.hungerFever))
            } else if s.lowFitnessMinutes >= LifeRules.sluggishScalesMinutes - epsilon {
                s.condition = .ill(.sluggishScales)
                events.append(.becameIll(.sluggishScales))
            }
        }

        let isIll = s.condition.illness != nil
        var drain = 0.0
        if s.hunger <= epsilon { drain += LifeRules.starvingDrainPerHour }
        if isIll { drain += LifeRules.illDrainPerHour }
        if s.fitness < LifeRules.lowFitnessThreshold { drain += LifeRules.lowFitnessDrainPerHour }
        let regen = (!isIll && s.hunger >= LifeRules.healthRegenMinFullness) ? LifeRules.healthRegenPerHour : 0
        s.health = clamp(s.health + (regen - drain) * hours)

        if healthBefore >= LifeRules.healthCriticalThreshold && s.health < LifeRules.healthCriticalThreshold {
            events.append(.healthCritical)
        }
        if s.health <= epsilon {
            s.health = 0
            s.condition = .spirit(diedAt: end)
            s.isSleepingEarly = false
            events.append(.died)
        }
    }

    private static func crossesWakeTime(from t: Date, to end: Date, calendar: Calendar) -> Bool {
        guard let wake = calendar.date(bySettingHour: LifeRules.wakeHour, minute: 0, second: 0, of: end) else { return false }
        return wake > t && wake <= end
    }

    private static func clamp(_ value: Double) -> Double {
        let v = min(100, max(0, value))
        return v < epsilon ? 0 : v
    }
}

// MARK: - Incubator

extension LifeSimulator {
    static let eggWarmthDecayPerHour = 10.0
    static let eggWarmThreshold = 50.0

    /// Incubation keeps running through quiet hours; a cold egg hatches at half speed.
    static func advance(_ slot: IncubatorSlot, from: Date, to: Date) -> (IncubatorSlot, [LifeEvent]) {
        let (s, timed) = run(slot, from: from, to: to)
        return (s, timed.map(\.event))
    }

    static func predict(_ slot: IncubatorSlot, from: Date, horizon: TimeInterval) -> [(event: LifeEvent, at: Date)] {
        firstOccurrences(run(slot, from: from, to: from.addingTimeInterval(horizon)).1)
    }

    private static func run(_ slot: IncubatorSlot, from: Date, to: Date) -> (IncubatorSlot, [(event: LifeEvent, at: Date)]) {
        var s = slot
        var timed: [(event: LifeEvent, at: Date)] = []
        guard to > from, let egg = s.egg else {
            s.lastSimulatedAt = to
            return (s, timed)
        }
        forEachStep(from: effectiveStart(from: from, to: to), to: to) { t, dt in
            let end = t.addingTimeInterval(dt)
            let warmthBefore = s.warmth
            let speed = warmthBefore >= eggWarmThreshold ? 1.0 : 0.5
            s.warmth = max(0, s.warmth - eggWarmthDecayPerHour * dt / 3600)
            if warmthBefore >= eggWarmThreshold && s.warmth < eggWarmThreshold { timed.append((.eggCold, end)) }
            if s.progress < 1 {
                s.progress += dt / egg.tier.hatchDuration * speed
                if s.progress >= 1 - 1e-9 {
                    s.progress = 1
                    timed.append((.eggReady, end))
                }
            }
        }
        s.lastSimulatedAt = to
        return (s, timed)
    }
}
