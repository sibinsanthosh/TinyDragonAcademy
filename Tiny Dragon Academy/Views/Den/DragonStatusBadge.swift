//
//  DragonStatusBadge.swift
//  Tiny Dragon Academy
//
//  The single most urgent thing about a dragon, as a small colored pill.
//

import SwiftUI

struct DragonStatus: Equatable {
    let text: String
    let icon: String
    let isUrgent: Bool

    /// Most urgent first: spirit, illness, asleep, hungry, needs training. Nil when all is well.
    static func describe(_ stats: DragonStats, now: Date, calendar: Calendar, mode: CareMode = .classic) -> DragonStatus? {
        if let diedAt = stats.condition.spiritDiedAt {
            let left = max(0, LifeRules.spiritWindow - now.timeIntervalSince(diedAt))
            let label = left >= 3600 ? "\(Int(left / 3600))h" : "\(Int(left / 60))m"
            return DragonStatus(text: "Spirit • \(label) left", icon: "sparkles", isUrgent: true)
        }
        if mode == .gentle && stats.health <= LifeRules.gentleHealthFloor + 0.001 {
            return DragonStatus(text: "Deep sleep — feed me!", icon: "zzz", isUrgent: true)
        }
        if let illness = stats.condition.illness {
            return DragonStatus(text: "Sick: \(illness.displayName)", icon: "thermometer.medium", isUrgent: true)
        }
        if LifeSimulator.isAsleep(stats, at: now, calendar: calendar) {
            return DragonStatus(text: "Asleep", icon: "moon.zzz.fill", isUrgent: false)
        }
        if stats.hunger < LifeRules.hungryThreshold {
            return DragonStatus(text: "Hungry", icon: "fork.knife", isUrgent: true)
        }
        if stats.fitness < LifeRules.needsTrainingThreshold {
            return DragonStatus(text: "Needs training", icon: "figure.run", isUrgent: false)
        }
        return nil
    }
}

struct DragonStatusBadge: View {
    let status: DragonStatus

    var body: some View {
        Label(status.text, systemImage: status.icon)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(status.isUrgent ? DragonPalette.coral : DragonPalette.softPurple))
    }
}
