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
            DragonPalette.skyGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ZStack {
                    switch phase {
                    case .ready:
                        readyCard
                    case .playing:
                        content(finish, DragonPlayStyle(dragon: gameManager.activeDragon)).id(runId)
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
        HStack {
            Button {
                HapticsService.shared.medium()
                gameManager.navigate(to: .trainingHub)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.circle.fill").font(.system(size: 26))
                    Text("Back").font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.9)))
            }
            Spacer()
            Text(game.rawValue)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var readyCard: some View {
        VStack(spacing: 14) {
            DragonView(dragon: gameManager.activeDragon, mood: .happy, size: 120, allowInteractivePetting: false)
            Image(systemName: game.iconName)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(game.themeColor)
            Text(game.subtitle)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Label("Best \(gameManager.state.trainingBests[game.rawValue] ?? 0)", systemImage: "trophy.fill")
                Label("\(Int(LifeRules.trainingEnergyCost)) energy", systemImage: "bolt.fill")
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(DragonPalette.textMuted)

            if gameManager.hasActiveDenDragon {
                skillSummary
            }

            if gameManager.canTrainActiveDragon {
                KidButton(title: "Start!", icon: "play.fill", backgroundColor: game.themeColor) { start() }
            } else {
                Text(cannotTrainReason)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.coral)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.92)))
        .padding(.horizontal, 24)
    }

    /// The active dragon's skill for this game and where its talent works.
    private var skillSummary: some View {
        let dragon = gameManager.activeDragon
        let skill = DragonSkill.forGame(game)
        return VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: skill.iconName)
                Text("\(dragon.name)'s \(skill.title)")
                Text(SkillStars.text(dragon.skillStars(skill)))
                    .foregroundColor(game.themeColor)
            }
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundColor(DragonPalette.textDark)

            if let talent = dragon.talent {
                Text(talent.game == game
                     ? "✨ Talent: \(talent.title) — \(talent.summary)"
                     : "\(dragon.name)'s talent \(talent.title) shines in \(talent.game.rawValue).")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(talent.game == game ? DragonPalette.textDark : DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var cannotTrainReason: String {
        let dragon = gameManager.activeDragon
        if !gameManager.hasActiveDenDragon { return "No dragon in your den to train." }
        if dragon.stats.condition.isSpirit { return "\(dragon.name) is a spirit and can't train." }
        if gameManager.isActiveDragonAsleep { return "\(dragon.name) is asleep. Training resumes in the morning!" }
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
