//
//  AwayReportSheet.swift
//  Tiny Dragon Academy
//
//  "While you were away": what happened to each dragon and egg since the last visit.
//

import SwiftUI

struct AwayReportSheet: View {
    @EnvironmentObject var gameManager: GameManager

    /// Sleep/wake are routine; once a spirit expired, the "you have 48h" lines are stale.
    static func reportable(_ events: [LifeEvent]) -> [LifeEvent] {
        let expired = events.contains(.spiritExpired)
        var seen = Set<LifeEvent>()
        return events.filter { event in
            switch event {
            case .fellAsleep, .wokeUp: return false
            case .died, .spiritLastChance where expired: return false
            default: return seen.insert(event).inserted
            }
        }
    }

    private var rows: [(title: String, lines: [String])] {
        gameManager.awayReport.keys.sorted().compactMap { key in
            let events = Self.reportable(gameManager.awayReport[key] ?? [])
            guard !events.isEmpty else { return nil }
            if key == "incubator" {
                return ("Incubator", events.map { NotificationPlanner.body(for: $0, name: "") })
            }
            let name = gameManager.awayNames[key] ?? gameManager.state.dragons.first { $0.id == key }?.name ?? key.capitalized
            return (name, events.map { NotificationPlanner.body(for: $0, name: name) })
        }
    }

    private var reportList: some View {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(rows, id: \.title) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(DragonPalette.textDark)
                            ForEach(row.lines, id: \.self) { line in
                                Text("• \(line)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(DragonPalette.textMuted)
                            }
                        }
                    }
                    if !gameManager.awayStreakNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 Care streak")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    ForEach(gameManager.awayStreakNotes, id: \.self) { note in
                        Text("• \(note)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                }
            }
            if let bonus = gameManager.dailyBonus {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("✨ Daily care bonus")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(DragonPalette.coral)
                            Text("+\(bonus.stars) stars and \(TimeProgressionService.bonusFoodCount) \(bonus.food.displayName)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 14) {
                Text("While you were away")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)

                // Short reports hug their content; long ones scroll
                ViewThatFits(in: .vertical) {
                    reportList
                    ScrollView { reportList }.frame(height: 320)
                }

                KidButton(title: "Let's go!", backgroundColor: DragonPalette.softPurple) {
                    gameManager.dismissAwayReport()
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
            .padding(.horizontal, 28)
        }
    }
}

extension AwayReportSheet {
    /// Only worth interrupting the player when something reportable happened.
    static func hasContent(_ gameManager: GameManager) -> Bool {
        if gameManager.dailyBonus != nil || !gameManager.awayStreakNotes.isEmpty { return true }
        return gameManager.awayReport.values.contains { events in
            events.contains { $0 != .fellAsleep && $0 != .wokeUp }
        }
    }
}
