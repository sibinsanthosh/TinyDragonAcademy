//
//  TrainingGameShell.swift
//  Tiny Dragon Academy
//
//  Shared frame for every training game: header, pre-game card that spends
//  energy, the game itself, and the results card that applies rewards.
//

import SwiftUI

struct TrainingSessionSummary {
    var score: Int
    /// The score without talent bonuses; nil when it equals `score`.
    var baseScore: Int? = nil
    var duration: Double
    var completedRound: Bool
    var caughtSnacks: [FoodType] = []
}

struct TrainingGameShell<Content: View>: View {
    @EnvironmentObject var gameManager: GameManager

    let game: TrainingGameType
    let content: (_ finish: @escaping (TrainingSessionSummary) -> Void, _ style: DragonPlayStyle) -> Content

    private enum Phase {
        case ready
        case playing
        case finished(score: Int, result: TrainingResult)
    }

    @State private var phase: Phase = .ready
    @State private var runId = 0

    init(game: TrainingGameType, @ViewBuilder content: @escaping (_ finish: @escaping (TrainingSessionSummary) -> Void, _ style: DragonPlayStyle) -> Content) {
        self.game = game
        self.content = content
    }

    var body: some View {
        ZStack {
            if case .playing = phase {
                Color(red: 0.80, green: 0.91, blue: 1.0).ignoresSafeArea()
            } else {
                ClayBackdrop()
            }

            VStack(spacing: 0) {
                header
                ZStack {
                    switch phase {
                    case .ready:
                        readyCard
                    case .playing:
                        content(finish, DragonPlayStyle(dragon: gameManager.activeDragon))
                            .id(runId)
                    case .finished(let score, let result):
                        TrainingResultCard(
                            game: game,
                            score: score,
                            best: gameManager.state.trainingBests[game.rawValue] ?? score,
                            result: result,
                            canPlayAgain: gameManager.canTrainActiveDragon,
                            onPlayAgain: start,
                            onDone: { gameManager.navigate(to: .trainingHub) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var header: some View {
        ZStack {
            Text(game.rawValue)
                .font(.clay(22, .heavy))
                .foregroundColor(ClayColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 64)
            HStack {
                ClayIconButton(systemName: "xmark", accessibilityLabel: "Close") {
                    gameManager.navigate(to: .trainingHub)
                }
                Spacer()
                StarCounterView(count: gameManager.totalStars)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var readyCard: some View {
        let dragon = gameManager.activeDragon
        let skill = DragonSkill.forGame(game)
        return VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                DragonView(dragon: dragon, mood: .happy, size: 120, allowInteractivePetting: false)
                Image(systemName: game.iconName)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(game.themeColor))
                    .shadow(color: game.themeColor.opacity(0.4), radius: 6, y: 3)
            }
            Text(game.subtitle)
                .font(.clay(17, .bold))
                .foregroundColor(ClayColor.ink)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ClayPill(systemName: "trophy.fill", iconColor: ClayColor.sunShade,
                         value: "\(gameManager.state.trainingBests[game.rawValue] ?? 0)", accessibilityLabel: "Best")
                ClayPill(systemName: "bolt.fill", iconColor: ClayColor.sunShade,
                         value: "\(Int(LifeRules.trainingEnergyCost))", accessibilityLabel: "Energy cost")
            }

            if gameManager.hasActiveDenDragon {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: skill.iconName).foregroundColor(game.themeColor)
                        Text("\(skill.title)")
                            .foregroundColor(ClayColor.ink)
                        Text(SkillStars.text(dragon.skillStars(skill)))
                            .foregroundColor(DragonPalette.starGold)
                    }
                    .font(.clay(16, .heavy))
                    if let talent = dragon.talent {
                        Label(talent.game == game ? "\(talent.title): \(talent.summary)" : "\(talent.title) shines in \(talent.game.rawValue)",
                              systemImage: "sparkles")
                            .font(.clay(13, .bold))
                            .foregroundColor(talent.game == game ? ClayColor.ink : ClayColor.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(talent.game == game ? ClayColor.accent.opacity(0.12) : Color.clear))
                    }
                }
            }

            if gameManager.canTrainActiveDragon {
                KidButton(title: "Start", icon: "play.fill", backgroundColor: ClayColor.accent, minWidth: 200) { start() }
                    .padding(.top, 4)
            } else {
                Text(cannotTrainReason)
                    .font(.clay(15, .bold))
                    .foregroundColor(ClayColor.coralShade)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(22)
        .claySurface(cornerRadius: 30, elevation: 1.3)
        .padding(.horizontal, 22)
    }

    private var cannotTrainReason: String {
        let dragon = gameManager.activeDragon
        if !gameManager.hasActiveDenDragon { return "No dragon in your den to train." }
        if dragon.stats.condition.isSpirit { return "\(dragon.name) is a spirit and can't train." }
        if gameManager.isActiveDragonAsleep { return "\(dragon.name) is asleep. Training opens in the morning." }
        return "\(dragon.name) is too tired. Feed or rest to restore energy."
    }

    private func start() {
        guard gameManager.startTraining(game) else { return }
        HapticsService.shared.medium()
        runId += 1
        phase = .playing
    }

    private func finish(_ summary: TrainingSessionSummary) {
        var rng = SystemRandomNumberGenerator()
        let result = gameManager.finishTraining(
            game,
            score: summary.score,
            baseScore: summary.baseScore,
            duration: summary.duration,
            completedRound: summary.completedRound,
            caughtSnacks: summary.caughtSnacks,
            rng: &rng
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            phase = .finished(score: summary.score, result: result)
        }
    }
}
