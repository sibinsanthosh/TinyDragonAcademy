//
//  FireTargetView.swift
//  Tiny Dragon Academy
//
//  Renders Fire Target: touch where the fireball should go (a dotted arc
//  runs from the dragon to the finger), release to launch it there.
//

import SwiftUI

struct FireTargetView: View {
    var body: some View {
        TrainingGameShell(game: .fireTarget) { finish, style in
            FireTargetPlayView(style: style, onFinish: finish)
        }
    }
}

private struct FireTargetPlayView: View {
    @EnvironmentObject var gameManager: GameManager
    let onFinish: (TrainingSessionSummary) -> Void

    @State private var state: FireTargetGameState
    @State private var aimPoint: CGPoint?
    @State private var queuedRelease: CGPoint?
    @State private var reported = false

    init(style: DragonPlayStyle, onFinish: @escaping (TrainingSessionSummary) -> Void) {
        self.onFinish = onFinish
        _state = State(initialValue: FireTargetGameState(seed: UInt64.random(in: 1...UInt64.max), style: style))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let groundY = geo.size.height * 0.9
            let toScreen: (CGPoint) -> CGPoint = { p in CGPoint(x: p.x * w, y: groundY - p.y * w) }
            let toWorld: (CGPoint) -> CGPoint = { p in
                FireTargetGameState.clampAim(CGPoint(x: p.x / w, y: (groundY - p.y) / w))
            }
            let color = gameManager.activeDragon.element.themeColor

            GameLoop(isRunning: !state.isOver) { dt in
                state.step(dt: dt, input: FireInput(release: queuedRelease))
                queuedRelease = nil
                if state.isOver && !reported {
                    reported = true
                    onFinish(TrainingSessionSummary(score: state.score, baseScore: state.baseScore, duration: FireTargetGameState.roundDuration, completedRound: true))
                }
            } content: {
                ZStack(alignment: .topLeading) {
                    MeadowScene(size: geo.size, groundY: groundY)

                    if let aim = aimPoint {
                        aimGuide(aim: aim, color: color, toScreen: toScreen)
                    }

                    ForEach(Array(state.targets.enumerated()), id: \.offset) { _, target in
                        targetView(target, size: FireTargetGameState.targetRadius * w * 2.1)
                        .scaleEffect(isAimed(at: target) ? 1.2 : 1)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isAimed(at: target))
                        .position(toScreen(target.position))
                    }

                    ForEach(Array(state.bursts.enumerated()), id: \.offset) { _, burst in
                        let progress = burst.age / FireTargetGameState.burstLifetime
                        VStack(spacing: 0) {
                            if burst.points > 0 {
                                Text("+\(burst.points)")
                                    .font(.clay(22, .heavy))
                                    .foregroundColor(ClayColor.coralShade)
                            }
                            ClayBurst(size: 40)
                        }
                        .scaleEffect(0.7 + 0.6 * progress)
                        .opacity(1 - progress)
                        .position(toScreen(burst.position))
                        .offset(y: -30 * progress)
                    }

                    ForEach(Array(state.fireballs.enumerated()), id: \.offset) { _, ball in
                        Circle()
                            .fill(RadialGradient(colors: [.white, color, color.opacity(0.2)], center: .center, startRadius: 1, endRadius: 14))
                            .frame(width: FireTargetGameState.fireballRadius * w * 2.4, height: FireTargetGameState.fireballRadius * w * 2.4)
                            .position(toScreen(ball.position))
                    }

                    DragonView(dragon: gameManager.activeDragon, mood: .castingPower, size: w * 0.2, allowInteractivePetting: false)
                        .position(toScreen(CGPoint(x: FireTargetGameState.launchOrigin.x, y: FireTargetGameState.launchOrigin.y - 0.02)))

                    ClayGameHUD(seconds: Int(state.timeRemaining.rounded(.up)),
                                score: "\(state.score)",
                                scoreIcon: "scope",
                                trailing: state.combo > 1 ? ("flame.fill", "×\(state.combo)", ClayColor.coral) : nil)
                        .frame(width: w)
                }
                .frame(width: w, height: geo.size.height)
                .overlay {
                    TalentHUD(talent: state.style.talent, game: .fireTarget, triggers: state.talentTriggers)
                        .frame(maxWidth: .infinity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                // Touch anywhere to aim; a plain tap fires straight at that spot
                DragGesture(minimumDistance: 0)
                    .onChanged { value in aimPoint = toWorld(value.location) }
                    .onEnded { value in
                        queuedRelease = toWorld(value.location)
                        aimPoint = nil
                        HapticsService.shared.light()
                    }
            )
        }
    }

    /// Dotted arc from the dragon to the finger, ending in an aim ring.
    @ViewBuilder
    private func aimGuide(aim: CGPoint, color: Color, toScreen: @escaping (CGPoint) -> CGPoint) -> some View {
        let origin = FireTargetGameState.launchOrigin
        let steps = FireTargetGameState.flightSteps(from: origin, to: aim)
        let path = FireTargetGameState.trajectory(origin: origin, aim: aim, steps: steps, straight: state.style.has(.laserShot))
        ForEach(Array(path.enumerated()), id: \.offset) { index, point in
            if index % 3 == 2 && index < steps - 2 {
                Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7).position(toScreen(point))
            }
        }
        Circle()
            .stroke(color, lineWidth: 3)
            .background(Circle().fill(color.opacity(0.15)))
            .frame(width: 34, height: 34)
            .overlay(Circle().fill(color).frame(width: 6, height: 6))
            .position(toScreen(aim))
    }

    private func isAimed(at target: FireTarget) -> Bool {
        guard let aim = aimPoint else { return false }
        return hypot(aim.x - target.position.x, aim.y - target.position.y) < state.hitRadius
    }

    @ViewBuilder
    private func targetView(_ target: FireTarget, size: CGFloat) -> some View {
        switch target.kind {
        case .dummy: ClayTargetBoard(size: size)
        case .balloon: ClayBalloon(size: size, color: ClayColor.rose)
        case .shield: ClayShieldDummy(size: size, hits: target.hitsRemaining)
        }
    }
}
