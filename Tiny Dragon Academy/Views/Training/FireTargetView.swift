//
//  FireTargetView.swift
//  Tiny Dragon Academy
//
//  Renders Fire Target: drag back from anywhere to aim (dotted arc),
//  release to launch an element-colored fireball.
//

import SwiftUI

struct FireTargetView: View {
    var body: some View {
        TrainingGameShell(game: .fireTarget) { finish in
            FireTargetPlayView(onFinish: finish)
        }
    }
}

private struct FireTargetPlayView: View {
    @EnvironmentObject var gameManager: GameManager
    let onFinish: (TrainingSessionSummary) -> Void

    @State private var state = FireTargetGameState(seed: UInt64.random(in: 1...UInt64.max))
    @State private var aimPull: CGVector?
    @State private var queuedRelease: CGVector?
    @State private var reported = false

    private let maxPull = 0.4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let groundY = geo.size.height * 0.9
            let toScreen: (CGPoint) -> CGPoint = { p in CGPoint(x: p.x * w, y: groundY - p.y * w) }
            let color = gameManager.activeDragon.element.themeColor

            GameLoop(isRunning: !state.isOver) { dt in
                state.step(dt: dt, input: FireInput(release: queuedRelease))
                queuedRelease = nil
                if state.isOver && !reported {
                    reported = true
                    onFinish(TrainingSessionSummary(score: state.score, duration: FireTargetGameState.roundDuration, completedRound: true))
                }
            } content: {
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(DragonPalette.mintGreen.opacity(0.7))
                        .frame(width: w, height: geo.size.height - groundY)
                        .offset(y: groundY)

                    if let pull = aimPull {
                        ForEach(Array(FireTargetGameState.trajectory(origin: FireTargetGameState.launchOrigin, pull: pull, steps: 60).enumerated()), id: \.offset) { index, point in
                            if index % 4 == 3 {
                                Circle().fill(color.opacity(0.6)).frame(width: 6, height: 6).position(toScreen(point))
                            }
                        }
                    }

                    ForEach(Array(state.targets.enumerated()), id: \.offset) { _, target in
                        ZStack {
                            Text(emoji(for: target.kind)).font(.system(size: FireTargetGameState.targetRadius * w * 1.8))
                            if target.kind == .shield && target.hitsRemaining > 1 {
                                Text("×\(target.hitsRemaining)").font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white).padding(3).background(Circle().fill(DragonPalette.coral))
                                    .offset(x: 18, y: -18)
                            }
                        }
                        .position(toScreen(target.position))
                    }

                    ForEach(Array(state.fireballs.enumerated()), id: \.offset) { _, ball in
                        Circle()
                            .fill(RadialGradient(colors: [.white, color, color.opacity(0.2)], center: .center, startRadius: 1, endRadius: 14))
                            .frame(width: FireTargetGameState.fireballRadius * w * 2.4, height: FireTargetGameState.fireballRadius * w * 2.4)
                            .position(toScreen(ball.position))
                    }

                    DragonView(dragon: gameManager.activeDragon, mood: .castingPower, size: w * 0.2, allowInteractivePetting: false)
                        .position(toScreen(CGPoint(x: FireTargetGameState.launchOrigin.x, y: FireTargetGameState.launchOrigin.y - 0.02)))

                    HStack {
                        Label("\(Int(state.timeRemaining.rounded(.up)))s", systemImage: "timer")
                        Spacer()
                        Text("Score \(state.score)")
                        Spacer()
                        Text(state.combo > 1 ? "Combo ×\(state.combo)" : " ")
                            .foregroundColor(DragonPalette.coral)
                    }
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .frame(width: w)
                }
                .frame(width: w, height: geo.size.height)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in aimPull = clampedPull(value.translation, width: w) }
                    .onEnded { value in
                        queuedRelease = clampedPull(value.translation, width: w)
                        aimPull = nil
                        HapticsService.shared.light()
                    }
            )
        }
    }

    /// Screen drag → world pull vector (y up), limited in length.
    private func clampedPull(_ translation: CGSize, width: CGFloat) -> CGVector {
        var dx = translation.width / width
        var dy = -translation.height / width
        let length = (dx * dx + dy * dy).squareRoot()
        if length > maxPull {
            dx *= maxPull / length
            dy *= maxPull / length
        }
        return CGVector(dx: dx, dy: dy)
    }

    private func emoji(for kind: FireTarget.Kind) -> String {
        switch kind {
        case .dummy: return "🎯"
        case .balloon: return "🎈"
        case .shield: return "🛡️"
        }
    }
}
