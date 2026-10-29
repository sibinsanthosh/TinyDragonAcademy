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

            VStack(spacing: 10) {
                ScreenTopBar(title: "Train")

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if gameManager.hasActiveDenDragon {
                            fitnessStrip
                        }

                        if !gameManager.canTrainActiveDragon {
                            Label(blockedReason, systemImage: "info.circle.fill")
                                .font(.clay(14, .bold))
                                .foregroundColor(ClayColor.coralShade)
                                .padding(.horizontal, 4)
                        }

                        sectionTitle("Training games", icon: "figure.run")
                        ForEach(TrainingGameType.allCases) { game in
                            gameCard(game)
                        }

                        sectionTitle("Learn", icon: "book.fill")
                            .padding(.top, 6)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(MiniGameType.allCases) { learning in
                                learnTile(learning)
                            }
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

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.clay(20, .heavy))
            .foregroundColor(ClayColor.ink)
            .padding(.horizontal, 4)
    }

    /// The active dragon with its energy and fitness, the two things training uses.
    private var fitnessStrip: some View {
        let dragon = gameManager.activeDragon
        return HStack(spacing: 12) {
            DragonView(dragon: dragon, mood: .happy, size: 56, allowInteractivePetting: false)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 6) {
                Text(dragon.badgedName)
                    .font(.clay(17, .heavy))
                    .foregroundColor(ClayColor.ink)
                meterRow(icon: "bolt.fill", value: dragon.stats.energy, color: ClayColor.sun)
                meterRow(icon: "figure.run", value: dragon.stats.fitness, color: ClayColor.sky)
            }
        }
        .padding(12)
        .claySurface(cornerRadius: 22)
    }

    private func meterRow(icon: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .frame(width: 16)
            ClayMeter(value: value, color: color, height: 9)
            Text("\(Int(value))")
                .font(.clay(13, .heavy))
                .foregroundColor(ClayColor.inkSoft)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func gameCard(_ game: TrainingGameType) -> some View {
        let dragon = gameManager.activeDragon
        let skill = DragonSkill.forGame(game)
        let hasTalent = gameManager.hasActiveDenDragon && dragon.talent?.game == game
        return Button {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            gameManager.navigate(to: .trainingGame(game))
        } label: {
            HStack(spacing: 14) {
                Image(systemName: game.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(game.themeColor.shadow(.inner(color: Color.black.opacity(0.15), radius: 0, x: 0, y: -4))))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(game.rawValue)
                            .font(.clay(18, .heavy))
                            .foregroundColor(ClayColor.ink)
                        if hasTalent {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ClayColor.accent)
                                .accessibilityLabel("Talent works here")
                        }
                    }
                    HStack(spacing: 6) {
                        Text(skill.title)
                            .foregroundColor(ClayColor.inkSoft)
                        if gameManager.hasActiveDenDragon {
                            Text(SkillStars.text(dragon.skillStars(skill)))
                                .foregroundColor(DragonPalette.starGold)
                        }
                    }
                    .font(.clay(13, .heavy))
                    Label("Best \(gameManager.state.trainingBests[game.rawValue] ?? 0)", systemImage: "trophy.fill")
                        .font(.clay(12, .bold))
                        .foregroundColor(ClayColor.inkSoft)
                }
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(ClayColor.accent))
            }
            .padding(12)
        }
        .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 24))
    }

    private func learnTile(_ learning: MiniGameType) -> some View {
        Button {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            gameManager.navigate(to: .miniGame(learning))
        } label: {
            VStack(spacing: 8) {
                Image(systemName: learning.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(learning.themeColor.shadow(.inner(color: Color.black.opacity(0.15), radius: 0, x: 0, y: -4))))
                Text(learning.rawValue)
                    .font(.clay(15, .heavy))
                    .foregroundColor(ClayColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(learning.ageRecommendation)
                    .font(.clay(12, .bold))
                    .foregroundColor(ClayColor.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 24))
    }
}
