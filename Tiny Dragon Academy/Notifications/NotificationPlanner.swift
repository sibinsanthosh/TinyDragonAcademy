//
//  NotificationPlanner.swift
//  Tiny Dragon Academy
//
//  Predicts when each den dragon and incubator egg will need attention
//  (assuming the player does nothing) and turns that into a polite,
//  throttled list of local notifications.
//

import Foundation

struct PlannedNotification: Equatable {
    let id: String
    let title: String
    let body: String
    let fireDate: Date
    let dragonId: String?
}

enum NotificationPlanner {
    static let horizon: TimeInterval = 72 * 3600
    static let collapseWindow: TimeInterval = 30 * 60
    static let minimumSpacing: TimeInterval = 2 * 3600

    static func plan(state: AppProgressState, now: Date, calendar: Calendar) -> [PlannedNotification] {
        guard state.remindersEnabled else { return [] }
        var result: [PlannedNotification] = []

        for dragon in state.denDragons {
            let predicted = LifeSimulator.predict(dragon.stats, from: now, horizon: horizon, calendar: calendar)
            result += throttle(predicted, calendar: calendar).map { item in
                PlannedNotification(
                    id: "\(dragon.id).\(key(for: item.event))",
                    title: dragon.name,
                    body: body(for: item.event, name: dragon.name),
                    fireDate: item.at,
                    dragonId: dragon.id
                )
            }
        }

        for (index, slot) in state.incubatorSlots.enumerated() {
            let predicted = LifeSimulator.predict(slot, from: now, horizon: horizon)
            result += throttle(predicted, calendar: calendar).map { item in
                PlannedNotification(
                    id: "egg\(index).\(key(for: item.event))",
                    title: "Incubator",
                    body: body(for: item.event, name: ""),
                    fireDate: item.at,
                    dragonId: nil
                )
            }
        }
        return result.sorted { $0.fireDate < $1.fireDate }
    }

    static func body(for event: LifeEvent, name: String) -> String {
        switch event {
        case .becameHungry: return "\(name) is hungry! 🍖"
        case .starving: return "\(name) is starving — feed them soon!"
        case .needsTraining: return "\(name) is getting restless. Time for training! 🏃"
        case .becameIll(let illness): return "\(name) caught \(illness.displayName) 🤒"
        case .healthCritical: return "\(name) is very sick! Come quickly ❗"
        case .died: return "\(name) has become a spirit 👻 You have 48h to revive them."
        case .spiritLastChance: return "Last chance to save \(name)'s spirit!"
        case .eggReady: return "Your egg is hatching! 🥚"
        case .eggCold: return "Your egg is getting cold — warm it up!"
        case .spiritExpired: return "\(name)'s spirit has joined the Hall of Legends."
        case .cured: return "\(name) feels better!"
        case .fellAsleep: return "\(name) fell asleep."
        case .wokeUp: return "\(name) woke up!"
        }
    }

    // MARK: - Helpers

    /// Moves quiet-hour events to 07:00, then keeps at most one event per 2h,
    /// letting a more severe event replace one less than 30 min before it.
    private static func throttle(_ predicted: [(event: LifeEvent, at: Date)], calendar: Calendar) -> [(event: LifeEvent, at: Date)] {
        let shifted = predicted
            .map { (event: $0.event, at: deliveryTime(for: $0.at, calendar: calendar)) }
            .enumerated()
            .sorted { ($0.element.at, $0.offset) < ($1.element.at, $1.offset) }
            .map(\.element)

        var kept: [(event: LifeEvent, at: Date)] = []
        for item in shifted {
            guard let last = kept.last else {
                kept.append(item)
                continue
            }
            let gap = item.at.timeIntervalSince(last.at)
            if gap < collapseWindow {
                if item.event.severity > last.event.severity {
                    kept[kept.count - 1] = item
                }
            } else if gap >= minimumSpacing {
                kept.append(item)
            }
        }
        return kept
    }

    private static func deliveryTime(for date: Date, calendar: Calendar) -> Date {
        guard LifeSimulator.isQuietHours(date, calendar: calendar) else { return date }
        let hour = calendar.component(.hour, from: date)
        let day = hour >= LifeRules.sleepStartHour ? calendar.date(byAdding: .day, value: 1, to: date) ?? date : date
        return calendar.date(bySettingHour: LifeRules.wakeHour, minute: 0, second: 0, of: day) ?? date
    }

    private static func key(for event: LifeEvent) -> String {
        switch event {
        case .becameIll(let illness): return "becameIll.\(illness)"
        default: return "\(event)"
        }
    }
}
