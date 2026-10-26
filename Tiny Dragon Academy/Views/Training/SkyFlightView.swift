//
//  SkyFlightView.swift
//  Tiny Dragon Academy
//
//  Renders Sky Flight: tap anywhere to flap through cloud-pillar gaps.
//

import SwiftUI

struct SkyFlightView: View {
    var body: some View {
        TrainingGameShell(game: .skyFlight) { finish in
            SkyFlightPlayView(onFinish: finish)
        }
    }
}

private struct SkyFlightPlayView: View {
    @EnvironmentObject var gameManager: GameManager
    let onFinish: (TrainingSessionSummary) -> Void

    @State private var state = SkyFlightGameState(seed: UInt64.random(in: 1...UInt64.max))
    @State private var flapQueued = false
    @State private var touching = false
    @State private var reported = false

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
                    onFinish(TrainingSessionSummary(score: state.score, duration: state.elapsed, completedRound: false))
                }
            } content: {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(state.pillars.enumerated()), id: \.offset) { _, pillar in
                        let gapTop = (1 - (pillar.gapCenter + pillar.gapHeight / 2)) * h
                        let gapBottom = (1 - (pillar.gapCenter - pillar.gapHeight / 2)) * h
                        cloud(width: pillarWidth, height: gapTop)
                            .position(x: pillar.x * w, y: gapTop / 2)
                        cloud(width: pillarWidth, height: h - gapBottom)
                            .position(x: pillar.x * w, y: (gapBottom + h) / 2)
                    }

                    ForEach(Array(state.gems.enumerated()), id: \.offset) { _, gem in
                        Text("💎").font(.system(size: SkyFlightGameState.gemRadius * h))
                            .position(x: gem.x * w, y: (1 - gem.y) * h)
                    }

                    DragonView(dragon: gameManager.activeDragon, mood: state.isOver ? .sleepy : .happy,
                               size: SkyFlightGameState.dragonRadius * h * 3.2, allowInteractivePetting: false)
                        .rotationEffect(.degrees(max(-25, min(25, -state.velocityY * 30))))
                        .position(x: SkyFlightGameState.dragonX * w, y: (1 - state.dragonY) * h)

                    if !state.hasStarted {
                        Text("Tap to flap!")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.9)))
                            .position(x: w / 2, y: h * 0.7)
                    }

                    Text("\(state.score)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                        .frame(width: w)
                        .padding(.top, 8)
                }
                .frame(width: w, height: h)
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

    private func cloud(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(Color.white.opacity(0.95))
            .overlay(RoundedRectangle(cornerRadius: width / 2).stroke(DragonPalette.skyBlue, lineWidth: 3))
            .frame(width: width, height: max(0, height))
    }
}
