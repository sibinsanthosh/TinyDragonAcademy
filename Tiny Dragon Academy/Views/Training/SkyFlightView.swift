//
//  SkyFlightView.swift
//  Tiny Dragon Academy
//
//  Renders Sky Flight: tap anywhere to flap through cloud-pillar gaps.
//

import SwiftUI

struct SkyFlightView: View {
    var body: some View {
        TrainingGameShell(game: .skyFlight) { finish, style in
            SkyFlightPlayView(style: style, onFinish: finish)
        }
    }
}

private struct SkyFlightPlayView: View {
    @EnvironmentObject var gameManager: GameManager
    let onFinish: (TrainingSessionSummary) -> Void

    @State private var state: SkyFlightGameState
    @State private var flapQueued = false
    @State private var touching = false
    @State private var reported = false

    init(style: DragonPlayStyle, onFinish: @escaping (TrainingSessionSummary) -> Void) {
        self.onFinish = onFinish
        _state = State(initialValue: SkyFlightGameState(seed: UInt64.random(in: 1...UInt64.max), style: style))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pillarWidth = SkyFlightGameState.pillarWidth * w

            GameLoop(isRunning: !state.isOver) { dt in
                state.step(dt: dt, input: FlapInput(flap: flapQueued))
                flapQueued = false
                if state.isOver && !reported {
                    reported = true
                    HapticsService.shared.medium()
                    onFinish(TrainingSessionSummary(score: state.score, baseScore: state.baseScore, duration: state.elapsed, completedRound: false))
                }
            } content: {
                ZStack(alignment: .topLeading) {
                    SkyScene(size: geo.size)

                    ForEach(Array(state.pillars.enumerated()), id: \.offset) { _, pillar in
                        let gapTop = (1 - (pillar.gapCenter + pillar.gapHeight / 2)) * h
                        let gapBottom = (1 - (pillar.gapCenter - pillar.gapHeight / 2)) * h
                        ClayCloudPillar(width: pillarWidth, height: gapTop, capAtBottom: true)
                            .position(x: pillar.x * w, y: gapTop / 2)
                        ClayCloudPillar(width: pillarWidth, height: h - gapBottom, capAtBottom: false)
                            .position(x: pillar.x * w, y: (gapBottom + h) / 2)
                    }

                    ForEach(Array(state.gems.enumerated()), id: \.offset) { _, gem in
                        ClayGem(size: SkyFlightGameState.gemRadius * h * 1.6)
                            .position(x: gem.x * w, y: (1 - gem.y) * h)
                    }

                    DragonView(dragon: gameManager.activeDragon, mood: state.isOver ? .sleepy : .happy,
                               size: SkyFlightGameState.dragonRadius * h * 3.2, allowInteractivePetting: false)
                        .rotationEffect(.degrees(max(-25, min(25, -state.velocityY * 30))))
                        .position(x: SkyFlightGameState.dragonX * w, y: (1 - state.dragonY) * h)

                    if !state.hasStarted {
                        Text("Tap to flap!")
                            .font(.clay(24, .heavy))
                            .foregroundColor(DragonPalette.textDark)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .claySurface(cornerRadius: 100, elevation: 0.7)
                            .position(x: w / 2, y: h * 0.7)
                    }

                    ClayGameHUD(score: "\(state.score)", scoreIcon: "cloud.fill")
                        .frame(width: w)
                }
                .frame(width: w, height: h)
                .overlay {
                    TalentHUD(talent: state.style.talent, game: .skyFlight, triggers: state.talentTriggers)
                        .frame(maxWidth: .infinity)
                }
                .clipped()
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !touching { flapQueued = true }
                        touching = true
                    }
                    .onEnded { _ in touching = false }
            )
        }
    }

}
