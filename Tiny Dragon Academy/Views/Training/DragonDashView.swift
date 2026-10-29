//
//  DragonDashView.swift
//  Tiny Dragon Academy
//
//  Renders Dragon Dash: tap to jump, hold to jump higher.
//

import SwiftUI

struct DragonDashView: View {
    var body: some View {
        TrainingGameShell(game: .dragonDash) { finish, style in
            DragonDashPlayView(style: style, onFinish: finish)
        }
    }
}

private struct DragonDashPlayView: View {
    @EnvironmentObject var gameManager: GameManager
    let onFinish: (TrainingSessionSummary) -> Void

    @State private var state: DashGameState
    @State private var isHeld = false
    @State private var pressQueued = false
    @State private var reported = false

    init(style: DragonPlayStyle, onFinish: @escaping (TrainingSessionSummary) -> Void) {
        self.onFinish = onFinish
        _state = State(initialValue: DashGameState(seed: UInt64.random(in: 1...UInt64.max), style: style))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let groundY = geo.size.height * 0.72
            GameLoop(isRunning: !state.isOver) { dt in
                state.step(dt: dt, input: DashInput(jumpPressed: pressQueued, jumpHeld: isHeld))
                pressQueued = false
                if state.isOver && !reported {
                    reported = true
                    HapticsService.shared.medium()
                    onFinish(TrainingSessionSummary(score: state.score, baseScore: state.baseScore, duration: state.elapsed, completedRound: false))
                }
            } content: {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(DragonPalette.mintGreen)
                        .frame(width: w, height: geo.size.height - groundY)
                        .offset(y: groundY)

                    ForEach(Array(state.obstacles.enumerated()), id: \.offset) { _, obstacle in
                        Text(emoji(for: obstacle.kind))
                            .font(.system(size: obstacle.height * w * 1.1))
                            .position(x: obstacle.x * w, y: groundY - (obstacle.y + obstacle.height / 2) * w)
                    }

                    DragonView(dragon: gameManager.activeDragon, mood: state.isOver ? .sleepy : .happy,
                               size: DashGameState.dragonHeight * w * 2.0, allowInteractivePetting: false)
                        .position(x: DashGameState.dragonX * w,
                                  y: groundY - (state.dragonY + DashGameState.dragonHeight / 2) * w)

                    Text("\(state.score)")
                        .font(.clay(32, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                        .frame(width: w)
                        .padding(.top, 12)
                }
                .frame(width: w, height: geo.size.height)
                .overlay {
                    TalentHUD(talent: state.style.talent, game: .dragonDash, triggers: state.talentTriggers)
                        .frame(maxWidth: .infinity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHeld { pressQueued = true }
                        isHeld = true
                    }
                    .onEnded { _ in isHeld = false }
            )
        }
    }

    private func emoji(for kind: DashObstacle.Kind) -> String {
        switch kind {
        case .rock: return "🪨"
        case .cactus: return "🌵"
        case .bat: return "🦇"
        }
    }
}
