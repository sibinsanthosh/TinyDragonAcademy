//
//  SnackCatchView.swift
//  Tiny Dragon Academy
//
//  Renders Catch the Snacks: drag to slide the dragon, catch food, dodge storms.
//

import SwiftUI

struct SnackCatchView: View {
    var body: some View {
        TrainingGameShell(game: .snackCatch) { finish, style in
            SnackCatchPlayView(style: style, onFinish: finish)
        }
    }
}

private struct SnackCatchPlayView: View {
    @EnvironmentObject var gameManager: GameManager
    let onFinish: (TrainingSessionSummary) -> Void

    @State private var state: SnackCatchGameState
    @State private var targetX: Double?
    @State private var reported = false

    init(style: DragonPlayStyle, onFinish: @escaping (TrainingSessionSummary) -> Void) {
        self.onFinish = onFinish
        _state = State(initialValue: SnackCatchGameState(seed: UInt64.random(in: 1...UInt64.max), style: style))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            GameLoop(isRunning: !state.isOver) { dt in
                state.step(dt: dt, input: CatchInput(targetX: targetX))
                if state.isOver && !reported {
                    reported = true
                    HapticsService.shared.medium()
                    onFinish(TrainingSessionSummary(score: state.score, baseScore: state.baseScore, duration: state.elapsed,
                                                    completedRound: state.timeRemaining == 0, caughtSnacks: state.caught))
                }
            } content: {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(state.items.enumerated()), id: \.offset) { _, item in
                        itemView(item.kind, size: w * 0.11)
                            .position(x: item.x * w, y: (1 - item.y) * h)
                    }

                    DragonView(dragon: gameManager.activeDragon, mood: .anticipatingFood, size: w * 0.2, allowInteractivePetting: false)
                        .position(x: state.dragonX * w, y: (1 - SnackCatchGameState.dragonY) * h)

                    HStack {
                        Label("\(Int(state.timeRemaining.rounded(.up)))s", systemImage: "timer")
                        Spacer()
                        Text(state.style.has(.sweetTooth) ? "Caught \(state.baseScore) • \(state.score) pts" : "Caught \(state.baseScore)")
                        Spacer()
                        Text(String(repeating: "❤️", count: state.lives))
                    }
                    .font(.clay(18, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .frame(width: w)
                }
                .frame(width: w, height: h)
                .overlay {
                    TalentHUD(talent: state.style.talent, game: .snackCatch, triggers: state.talentTriggers, badgeAtTop: true)
                        .frame(maxWidth: .infinity)
                }
                .clipped()
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in targetX = value.location.x / w }
                    .onEnded { _ in targetX = nil }
            )
        }
    }

    @ViewBuilder
    private func itemView(_ kind: FallingItem.Kind, size: CGFloat) -> some View {
        switch kind {
        case .food(let food):
            Image(systemName: food.icon)
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(food.primaryColor))
        case .storm:
            Text("⛈️").font(.system(size: size * 0.9))
        }
    }
}
