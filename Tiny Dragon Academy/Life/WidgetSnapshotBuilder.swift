//
//  WidgetSnapshotBuilder.swift
//  Tiny Dragon Academy
//
//  Projects the active den dragon 12 hours ahead (every 30 minutes) with the
//  life simulation, so the widget stays accurate without opening the app.
//

import Foundation
import WidgetKit

enum WidgetSnapshotBuilder {
    static let step: TimeInterval = 30 * 60
    static let horizonSteps = 24
    static let tiredBelow = 20.0

    static func build(state: AppProgressState, now: Date, calendar: Calendar) -> WidgetSnapshot {
        guard let dragon = state.dragons.first(where: { $0.id == state.selectedDragonId && $0.residence == .den }) else {
            return WidgetSnapshot(entries: [WidgetSnapshot.Entry(date: now, name: "", colors: [], stageTitle: "",
                                                                 mood: .empty, hunger: 0, energy: 0, health: 0)])
        }
        var stats = dragon.stats
        var entries: [WidgetSnapshot.Entry] = []
        var from = stats.lastSimulatedAt
        for i in 0...horizonSteps {
            let date = now.addingTimeInterval(Double(i) * step)
            if date > from {
                stats = LifeSimulator.advance(stats, from: from, to: date, calendar: calendar, mode: state.careMode).0
                from = date
            }
            entries.append(WidgetSnapshot.Entry(
                date: date,
                name: dragon.badgedName,
                colors: [dragon.primaryColorHex, dragon.secondaryColorHex, dragon.bellyColorHex],
                stageTitle: stats.growthStage.rawValue,
                mood: mood(stats, at: date, calendar: calendar),
                hunger: stats.hunger,
                energy: stats.energy,
                health: stats.health
            ))
        }
        return WidgetSnapshot(entries: entries)
    }

    static func mood(_ stats: DragonStats, at date: Date, calendar: Calendar) -> WidgetMood {
        if stats.condition.isSpirit { return .spirit }
        if stats.condition.illness != nil { return .sick }
        if LifeSimulator.isAsleep(stats, at: date, calendar: calendar) { return .asleep }
        if stats.hunger < LifeRules.hungryThreshold { return .hungry }
        if stats.energy < tiredBelow { return .tired }
        return .happy
    }
}

/// Keeps the widgets in step with the game, reloading them only when what they show changes.
enum WidgetBridge {
    private static var lastSignature: String?

    static func publish(state: AppProgressState, now: Date, calendar: Calendar) {
        let snapshot = WidgetSnapshotBuilder.build(state: state, now: now, calendar: calendar)
        guard snapshot.signature != lastSignature else { return }
        lastSignature = snapshot.signature
        WidgetStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
