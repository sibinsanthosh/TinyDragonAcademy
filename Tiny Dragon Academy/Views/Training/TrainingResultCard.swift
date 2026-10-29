//
//  TrainingResultCard.swift
//  Tiny Dragon Academy
//
//  End-of-round summary: the score counts up, rewards pop in one by one,
//  and a new best or a new skill star rains confetti.
//

import SwiftUI

struct TrainingResultCard: View {
    let game: TrainingGameType
    let score: Int
    let best: Int
    let result: TrainingResult
    let canPlayAgain: Bool
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    @State private var shownScore: Double = 0
    @State private var revealed = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Row: Identifiable {
        let id: Int
        let icon: String
        let text: String
        let color: Color
    }

    private var rows: [Row] {
        var items: [(String, String, Color)] = []
        if let reward = result.reward {
            items.append(("star.fill", "+\(reward.stars) stars", ClayColor.sunShade))
            items.append(("sparkles", "+\(reward.xp) XP", ClayColor.accent))
            items.append(("figure.run", "+\(Int(reward.fitness)) fitness", ClayColor.skyShade))
            if let gain = result.skillGain {
                items.append((gain.skill.iconName, "+\(gain.points) \(gain.skill.title) points", game.themeColor))
                if gain.gainedStar {
                    items.append(("star.circle.fill", "\(gain.skill.title) \(SkillStars.text(gain.starsAfter))", ClayColor.sunShade))
                }
            }
            if result.cured { items.append(("cross.case.fill", "Sluggish Scales cured", ClayColor.mintShade)) }
            if result.earnedEgg { items.append(("oval.portrait.fill", "Training egg earned", ClayColor.coral)) }
            if result.droppedEmber { items.append(("flame.circle.fill", "Phoenix Ember found", ClayColor.coralShade)) }
        }
        if !result.snacksAdded.isEmpty {
            items.append(("basket.fill", "+\(result.snacksAdded.count) snacks", ClayColor.mintShade))
        }
        return items.enumerated().map { Row(id: $0.offset, icon: $0.element.0, text: $0.element.1, color: $0.element.2) }
    }

    private var celebrates: Bool {
        result.isNewBest || result.skillGain?.gainedStar == true
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 14) {
                if result.isNewBest {
                    Label("New best!", systemImage: "trophy.fill")
                        .font(.clay(16, .heavy))
                        .foregroundColor(ClayColor.ink)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Capsule().fill(ClayColor.sun))
                } else {
                    Text(result.counted ? "Nice training!" : "Too short to count")
                        .font(.clay(20, .heavy))
                        .foregroundColor(ClayColor.ink)
                }

                CountUpText(value: shownScore)
                Text("Best \(best)")
                    .font(.clay(15, .bold))
                    .foregroundColor(ClayColor.inkSoft)
                    .padding(.top, -12)

                if result.reward == nil {
                    Text("Train for at least 20 seconds to earn rewards.")
                        .font(.clay(14, .bold))
                        .foregroundColor(ClayColor.inkSoft)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    ForEach(rows) { row in
                        if row.id < revealed {
                            HStack(spacing: 10) {
                                Image(systemName: row.icon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(row.color)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(row.color.opacity(0.14)))
                                Text(row.text)
                                    .font(.clay(16, .heavy))
                                    .foregroundColor(ClayColor.ink)
                                Spacer()
                            }
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 6)

                HStack(spacing: 12) {
                    Button(action: {
                        HapticsService.shared.light()
                        onDone()
                    }) {
                        Text("Done")
                            .font(.clay(19, .heavy))
                            .frame(minWidth: 110, minHeight: 54)
                    }
                    .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 22))
                    if canPlayAgain {
                        KidButton(title: "Again", icon: "arrow.clockwise", backgroundColor: ClayColor.accent, minWidth: 130, minHeight: 54, action: onPlayAgain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(22)
            .claySurface(cornerRadius: 30, elevation: 1.3)
            .padding(.horizontal, 22)

            if celebrates {
                ConfettiView()
                    .frame(height: 600)
            }
        }
        .onAppear(perform: reveal)
    }

    private func reveal() {
        if reduceMotion {
            shownScore = Double(score)
            revealed = rows.count
            return
        }
        withAnimation(.easeOut(duration: 0.9)) { shownScore = Double(score) }
        for i in 0..<rows.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * 0.18) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { revealed = i + 1 }
                HapticsService.shared.light()
            }
        }
    }
}
