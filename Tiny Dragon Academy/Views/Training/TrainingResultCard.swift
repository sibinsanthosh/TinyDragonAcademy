//
//  TrainingResultCard.swift
//  Tiny Dragon Academy
//
//  End-of-round summary: score, personal best and rewards earned.
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

    var body: some View {
        VStack(spacing: 12) {
            Text(result.isNewBest ? "New Best! 🏆" : "Training Complete!")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
            Text("Score \(score)  •  Best \(best)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(DragonPalette.textMuted)

            if let reward = result.reward {
                VStack(spacing: 6) {
                    rewardRow("figure.run", "+\(Int(reward.fitness)) fitness")
                    rewardRow("sparkles", "+\(reward.xp) XP")
                    rewardRow("star.fill", "+\(reward.stars) stars")
                    if result.cured { rewardRow("cross.case.fill", "Sluggish Scales cured!") }
                    if result.earnedEgg { rewardRow("oval.portrait.fill", "Training egg earned!") }
                    if result.droppedEmber { rewardRow("flame.circle.fill", "A Phoenix Ember dropped!") }
                }
            } else {
                Text("Too short to count — train for at least 20 seconds.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DragonPalette.coral)
                    .multilineTextAlignment(.center)
            }
            if !result.snacksAdded.isEmpty {
                rewardRow("basket.fill", "+\(result.snacksAdded.count) snacks to your pantry")
            }

            HStack(spacing: 12) {
                if canPlayAgain {
                    KidButton(title: "Again", icon: "arrow.clockwise", backgroundColor: game.themeColor, minWidth: 120, action: onPlayAgain)
                }
                KidButton(title: "Done", backgroundColor: DragonPalette.softPurple, minWidth: 120, action: onDone)
            }
            .padding(.top, 6)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.95)).shadow(color: DragonPalette.popShadow, radius: 12))
        .padding(.horizontal, 24)
    }

    private func rewardRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(game.themeColor)
            Text(text).foregroundColor(DragonPalette.textDark)
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
    }
}
