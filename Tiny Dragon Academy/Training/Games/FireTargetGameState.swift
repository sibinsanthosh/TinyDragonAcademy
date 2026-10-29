//
//  FireTargetGameState.swift
//  Tiny Dragon Academy
//
//  Fire Target: point at a spot, release to launch a fireball that arcs
//  through exactly that spot. World units: x 0…1 across the screen width,
//  y up from the ground.
//

import CoreGraphics
import Foundation

struct FireInput {
    /// The world point the player let go on; the fireball passes through it.
    var release: CGPoint?
}

struct FireTarget: Equatable {
    enum Kind { case dummy, balloon, shield }

    var id = UUID()
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
    /// Laser Shot: no gravity, and the ball keeps flying after a hit.
    var straight = false
    var hitIds: Set<UUID> = []
}

/// A short-lived 💥 where a fireball struck; `points` is 0 for a shield that survived.
struct HitBurst: Equatable {
    var position: CGPoint
    var points: Int
    var age = 0.0
}

struct FireTargetGameState {
    static let roundDuration = 45.0
    static let launchOrigin = CGPoint(x: 0.15, y: 0.2)
    static let gravity = 2.0
    static let targetRadius = 0.075
    static let fireballRadius = 0.03
    static let maxTargets = 3
    static let spawnInterval = 1.5
    static let fireCooldown = 0.25
    static let burstLifetime = 0.6
    /// Balloons that drift above this float away.
    static let maxTargetY = 1.2
    static let minAimX = 0.2
    static let minAimY = 0.05
    static let minFlightTime = 0.35
    static let maxFlightTime = 0.8
    /// Splash Blast reach around the struck target.
    static let splashRadius = 0.15
    private static let stepDuration = 1.0 / 60.0

    var timeRemaining = roundDuration
    var elapsed: Double { Self.roundDuration - timeRemaining }
    var score = 0
    var combo = 0
    var targets: [FireTarget] = []
    var fireballs: [Fireball] = []
    var bursts: [HitBurst] = []
    var isOver = false
    var spawnTimer = 0.5
    /// Counts visible talent moments (splash, chain, pierce) so the view can pop a label.
    var talentTriggers = 0
    /// Talents don't change Fire Target's points, so rewards use the shown score.
    var baseScore: Int { score }

    let style: DragonPlayStyle
    /// Aim makes targets easier to hit: +10% radius per star above 1★.
    let hitRadius: Double

    private var cooldown = 0.0
    /// A release that came in while cooling down; it fires as soon as the dragon is ready.
    private var pendingAim: CGPoint?
    private var rng: SeededRNG

    init(seed: UInt64, style: DragonPlayStyle = .neutral) {
        rng = SeededRNG(seed: seed)
        self.style = style
        hitRadius = Self.targetRadius * (1 + 0.10 * style.boost(.aim))
    }

    static func kind(forElapsed elapsed: Double) -> FireTarget.Kind {
        switch elapsed {
        case ..<15: return .dummy
        case ..<30: return .balloon
        default: return .shield
        }
    }

    /// Keeps the aim above the ground and in front of the dragon.
    static func clampAim(_ aim: CGPoint) -> CGPoint {
        CGPoint(x: max(aim.x, minAimX), y: max(aim.y, minAimY))
    }

    /// Whole 60 Hz steps to reach `aim`: short hops are quick, long lobs take a little longer.
    static func flightSteps(from origin: CGPoint, to aim: CGPoint) -> Int {
        let distance = hypot(aim.x - origin.x, aim.y - origin.y)
        let time = min(maxFlightTime, max(minFlightTime, minFlightTime + 0.45 * distance))
        return max(1, Int((time / stepDuration).rounded()))
    }

    /// The launch velocity whose stepped flight lands exactly on `aim` after `flightSteps`.
    static func launchVelocity(from origin: CGPoint, to aim: CGPoint, straight: Bool = false) -> CGVector {
        let n = Double(flightSteps(from: origin, to: aim))
        let h = stepDuration
        // Semi-implicit Euler: after n steps, y = y0 + vy·n·h − g·h²·n(n+1)/2
        let drop = straight ? 0 : gravity * h * h * n * (n + 1) / 2
        return CGVector(dx: (aim.x - origin.x) / (n * h), dy: (aim.y - origin.y + drop) / (n * h))
    }

    /// Positions after each of `steps` fixed 60 Hz steps — the same integration the fireball uses.
    static func trajectory(origin: CGPoint, aim: CGPoint, steps: Int, straight: Bool = false) -> [CGPoint] {
        var p = origin
        var v = launchVelocity(from: origin, to: aim, straight: straight)
        var points: [CGPoint] = []
        for _ in 0..<steps {
            integrate(&p, &v, dt: 1.0 / 60.0, straight: straight)
            points.append(p)
        }
        return points
    }

    private static func integrate(_ p: inout CGPoint, _ v: inout CGVector, dt: Double, straight: Bool) {
        if !straight { v.dy -= gravity * dt }
        p.x += v.dx * dt
        p.y += v.dy * dt
    }

    mutating func step(dt: Double, input: FireInput) {
        guard !isOver else { return }
        timeRemaining = max(0, timeRemaining - dt)
        cooldown = max(0, cooldown - dt)

        if let aim = input.release { pendingAim = aim }
        if let aim = pendingAim, cooldown == 0 {
            let straight = style.has(.laserShot)
            let velocity = Self.launchVelocity(from: Self.launchOrigin, to: Self.clampAim(aim), straight: straight)
            fireballs.append(Fireball(position: Self.launchOrigin, velocity: velocity, straight: straight))
            cooldown = Self.fireCooldown
            pendingAim = nil
        }

        for i in bursts.indices { bursts[i].age += dt }
        bursts.removeAll { $0.age >= Self.burstLifetime }

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
            Self.integrate(&ball.position, &ball.velocity, dt: dt, straight: ball.straight)
            if let primary = targets.first(where: { !ball.hitIds.contains($0.id) && hits(ball, $0) }) {
                ball.hitIds.insert(primary.id)
                let extras = talentStrikes(around: primary)
                if !extras.isEmpty || ball.hitIds.count == 2 { talentTriggers += 1 }
                strike(primary.id, at: ball.position)
                for id in extras { strike(id, at: nil) }
                // Ordinary fireballs end on a hit; a laser keeps going
                if !ball.straight { continue }
            }
            let offScreen = ball.position.x > 1.1 || ball.position.x < -0.1
                || ball.position.y < -0.1 || ball.position.y > Self.maxTargetY + 0.5
            if offScreen {
                if ball.hitIds.isEmpty { combo = 0 }
            } else {
                remaining.append(ball)
            }
        }
        fireballs = remaining
    }

    /// Extra targets a talent strikes alongside `primary` (Splash Blast, Chain Bolt).
    private func talentStrikes(around primary: FireTarget) -> [UUID] {
        let others = targets.filter { $0.id != primary.id }
        if style.has(.splashBlast) {
            // Measured from the struck target's center, so "nearby" matches what the player sees
            return others.filter { hypot($0.position.x - primary.position.x, $0.position.y - primary.position.y) < Self.splashRadius }.map(\.id)
        }
        if style.has(.chainBolt) {
            let distance = { (t: FireTarget) in hypot(t.position.x - primary.position.x, t.position.y - primary.position.y) }
            return others.min { distance($0) < distance($1) }.map { [$0.id] } ?? []
        }
        return []
    }

    /// One hit on a target: raises the combo and scores it if the target breaks.
    private mutating func strike(_ id: UUID, at impact: CGPoint?) {
        guard let index = targets.firstIndex(where: { $0.id == id }) else { return }
        combo += 1
        targets[index].hitsRemaining -= 1
        let position = impact ?? targets[index].position
        var points = 0
        if targets[index].hitsRemaining <= 0 {
            targets.remove(at: index)
            points = combo
            score += points
        }
        bursts.append(HitBurst(position: position, points: points))
    }

    private mutating func moveTargets(dt: Double) {
        let pace = style.has(.frozenField) ? 0.5 : 1.0
        for i in targets.indices {
            targets[i].position.x += targets[i].velocity.dx * dt * pace
            targets[i].position.y += targets[i].velocity.dy * dt * pace
            // Shields patrol the right side of the field
            if targets[i].kind == .shield, targets[i].position.x < 0.45 || targets[i].position.x > 0.95 {
                targets[i].position.x = min(0.95, max(0.45, targets[i].position.x))
                targets[i].velocity.dx = -targets[i].velocity.dx
            }
        }
        targets.removeAll { $0.position.y > Self.maxTargetY }
    }

    private mutating func spawnTarget() {
        let kind = Self.kind(forElapsed: elapsed)
        let position = CGPoint(x: Double.random(in: 0.5...0.9, using: &rng), y: Double.random(in: 0.3...0.95, using: &rng))
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
        let reach = hitRadius + Self.fireballRadius
        return dx * dx + dy * dy < reach * reach
    }
}
