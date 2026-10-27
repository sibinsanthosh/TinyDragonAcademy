//
//  FireTargetGameState.swift
//  Tiny Dragon Academy
//
//  Fire Target: pull back to aim, release to launch an arcing fireball.
//  World units: x 0…1 across the screen width, y up from the ground.
//

import CoreGraphics

struct FireInput {
    /// The pull vector (from the dragon toward the finger) when the drag is released.
    var release: CGVector?
}

struct FireTarget: Equatable {
    enum Kind { case dummy, balloon, shield }

    var kind: Kind
    var position: CGPoint
    var hitsRemaining: Int
    var velocity: CGVector

    init(kind: Kind, position: CGPoint, hitsRemaining: Int? = nil, velocity: CGVector = .zero) {
        self.kind = kind
        self.position = position
        self.hitsRemaining = hitsRemaining ?? (kind == .shield ? 2 : 1)
        self.velocity = velocity
    }
}

struct Fireball: Equatable {
    var position: CGPoint
    var velocity: CGVector
}

struct FireTargetGameState {
    static let roundDuration = 45.0
    static let launchOrigin = CGPoint(x: 0.15, y: 0.2)
    static let launchPower = 3.0
    static let gravity = 1.2
    static let targetRadius = 0.06
    static let fireballRadius = 0.025
    static let maxTargets = 3
    static let spawnInterval = 1.5
    static let fireCooldown = 0.35
    static let worldHeight = 1.5

    var timeRemaining = roundDuration
    var elapsed: Double { Self.roundDuration - timeRemaining }
    var score = 0
    var combo = 0
    var targets: [FireTarget] = []
    var fireballs: [Fireball] = []
    var isOver = false
    var spawnTimer = 0.5

    private var cooldown = 0.0
    private var rng: SeededRNG

    init(seed: UInt64) {
        rng = SeededRNG(seed: seed)
    }

    static func kind(forElapsed elapsed: Double) -> FireTarget.Kind {
        switch elapsed {
        case ..<15: return .dummy
        case ..<30: return .balloon
        default: return .shield
        }
    }

    static func launchVelocity(pull: CGVector) -> CGVector {
        CGVector(dx: -pull.dx * launchPower, dy: -pull.dy * launchPower)
    }

    /// Positions after each of `steps` fixed 60 Hz steps — the same integration the fireball uses.
    static func trajectory(origin: CGPoint, pull: CGVector, steps: Int) -> [CGPoint] {
        var p = origin
        var v = launchVelocity(pull: pull)
        var points: [CGPoint] = []
        for _ in 0..<steps {
            integrate(&p, &v, dt: 1.0 / 60.0)
            points.append(p)
        }
        return points
    }

    private static func integrate(_ p: inout CGPoint, _ v: inout CGVector, dt: Double) {
        v.dy -= gravity * dt
        p.x += v.dx * dt
        p.y += v.dy * dt
    }

    mutating func step(dt: Double, input: FireInput) {
        guard !isOver else { return }
        timeRemaining = max(0, timeRemaining - dt)
        cooldown = max(0, cooldown - dt)

        if let pull = input.release, cooldown == 0 {
            fireballs.append(Fireball(position: Self.launchOrigin, velocity: Self.launchVelocity(pull: pull)))
            cooldown = Self.fireCooldown
        }

        moveTargets(dt: dt)
        moveFireballs(dt: dt)

        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = Self.spawnInterval
            if targets.count < Self.maxTargets { spawnTarget() }
        }

        if timeRemaining == 0 { isOver = true }
    }

    private mutating func moveFireballs(dt: Double) {
        var remaining: [Fireball] = []
        for var ball in fireballs {
            Self.integrate(&ball.position, &ball.velocity, dt: dt)
            if let hit = targets.firstIndex(where: { hits(ball, $0) }) {
                combo += 1
                targets[hit].hitsRemaining -= 1
                if targets[hit].hitsRemaining <= 0 {
                    targets.remove(at: hit)
                    score += combo
                }
                continue
            }
            let offScreen = ball.position.x > 1.1 || ball.position.x < -0.1 || ball.position.y < -0.1
            if offScreen {
                combo = 0
            } else {
                remaining.append(ball)
            }
        }
        fireballs = remaining
    }

    private mutating func moveTargets(dt: Double) {
        for i in targets.indices {
            targets[i].position.x += targets[i].velocity.dx * dt
            targets[i].position.y += targets[i].velocity.dy * dt
            // Shields patrol the right side of the field
            if targets[i].kind == .shield, targets[i].position.x < 0.45 || targets[i].position.x > 0.95 {
                targets[i].velocity.dx = -targets[i].velocity.dx
            }
        }
        targets.removeAll { $0.position.y > Self.worldHeight }
    }

    private mutating func spawnTarget() {
        let kind = Self.kind(forElapsed: elapsed)
        let position = CGPoint(x: Double.random(in: 0.5...0.92, using: &rng), y: Double.random(in: 0.3...1.15, using: &rng))
        let velocity: CGVector
        switch kind {
        case .dummy: velocity = .zero
        case .balloon: velocity = CGVector(dx: 0, dy: 0.04)
        case .shield: velocity = CGVector(dx: Bool.random(using: &rng) ? 0.2 : -0.2, dy: 0)
        }
        targets.append(FireTarget(kind: kind, position: position, velocity: velocity))
    }

    private func hits(_ ball: Fireball, _ target: FireTarget) -> Bool {
        let dx = ball.position.x - target.position.x
        let dy = ball.position.y - target.position.y
        let reach = Self.targetRadius + Self.fireballRadius
        return dx * dx + dy * dy < reach * reach
    }
}
