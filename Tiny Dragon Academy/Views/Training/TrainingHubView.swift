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
            ClayBackdrop()

            VStack(spacing: 12) {
                ScreenTopBar(title: "Training")

                HStack(spacing: 12) {
                    DragonView(dragon: gameManager.activeDragon, mood: .happy, size: 70, allowInteractivePetting: false)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(gameManager.activeDragon.name)'s fitness")
                            .font(.clay(15, .heavy))
                            .foregroundColor(DragonPalette.textDark)
                        DragonMetersView(stats: gameManager.activeDragon.stats)
                    }
                }
                .padding(14)
                .claySurface(cornerRadius: 20)
                .padding(.horizontal, 16)

                if !gameManager.canTrainActiveDragon {
                    Text(blockedReason)
                        .font(.clay(14, .bold))
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

    /// "Best 12 • Aim ★★★ ✨" — the active dragon's skill here, ✨ where its talent works.
    private func skillLine(for game: TrainingGameType) -> String {
        let best = "Best \(gameManager.state.trainingBests[game.rawValue] ?? 0)"
        guard gameManager.hasActiveDenDragon else { return "\(best) • Trains \(game.trainsLabel)" }
        let dragon = gameManager.activeDragon
        let skill = DragonSkill.forGame(game)
        let sparkle = dragon.talent?.game == game ? " ✨" : ""
        return "\(best) • \(skill.title) \(SkillStars.text(dragon.skillStars(skill)))\(sparkle)"
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
                        .font(.clay(18, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    Text(game.subtitle)
                        .font(.clay(13, .medium))
                        .foregroundColor(DragonPalette.textMuted)
                    Text(skillLine(for: game))
                        .font(.clay(12, .bold))
                        .foregroundColor(game.themeColor)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(game.themeColor)
            }
            .padding(14)
            .claySurface(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}
