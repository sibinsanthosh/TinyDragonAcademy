//
//  TrainingHubView.swift
//  Tiny Dragon Academy
//
//  Pick a training game. Training keeps your dragon fit and healthy.
//

import SwiftUI

struct TrainingHubView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            DragonPalette.skyGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                ScreenTopBar(title: "Training")

                HStack(spacing: 12) {
                    DragonView(dragon: gameManager.activeDragon, mood: .happy, size: 70, allowInteractivePetting: false)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(gameManager.activeDragon.name)'s fitness")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        DragonMetersView(stats: gameManager.activeDragon.stats)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.9)))
                .padding(.horizontal, 16)

                if !gameManager.canTrainActiveDragon {
                    Text(blockedReason)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(DragonPalette.coral)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(TrainingGameType.allCases) { game in
                            gameCard(game)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear { gameManager.tick() }
    }

    private var blockedReason: String {
        let dragon = gameManager.activeDragon
        if !gameManager.hasActiveDenDragon { return "No dragon in your den. Hatch an egg or bring one back from the sanctuary." }
        if dragon.stats.condition.isSpirit { return "\(dragon.name) is a spirit. Revive them in the Playground first." }
        if gameManager.isActiveDragonAsleep { return "\(dragon.name) is asleep. Training opens again in the morning." }
        return "\(dragon.name) needs at least \(Int(LifeRules.trainingEnergyCost)) energy to train."
    }

    private func gameCard(_ game: TrainingGameType) -> some View {
        Button {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            gameManager.navigate(to: .trainingGame(game))
        } label: {
            HStack(spacing: 14) {
                Image(systemName: game.iconName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(RoundedRectangle(cornerRadius: 16).fill(game.themeColor))
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.rawValue)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    Text(game.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(DragonPalette.textMuted)
                    Text("Best \(gameManager.state.trainingBests[game.rawValue] ?? 0) • Trains \(game.trainsLabel)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(game.themeColor)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(game.themeColor)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.92)))
        }
        .buttonStyle(.plain)
    }
}
