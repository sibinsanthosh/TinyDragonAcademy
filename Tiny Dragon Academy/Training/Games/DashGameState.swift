//
//  DashGameState.swift
//  Tiny Dragon Academy
//
//  Dragon Dash: an endless runner. World units are normalized to the
//  screen width; y is height above the ground.
//

import Foundation

struct DashInput {
    var jumpPressed: Bool
    var jumpHeld: Bool
}

struct DashObstacle: Equatable {
    enum Kind: CaseIterable { case rock, cactus, bat }

    var kind: Kind
    /// Center x.
    var x: Double

    var width: Double {
        switch kind {
        case .rock: return 0.05
        case .cactus: return 0.035
        case .bat: return 0.06
        }
    }

    var height: Double {
        switch kind {
        case .rock: return 0.06
        case .cactus: return 0.10
        case .bat: return 0.05
        }
    }

    /// Bottom edge above the ground; bats fly just over a standing dragon's head.
    var y: Double { kind == .bat ? 0.11 : 0 }
}

struct DashGameState {
    static let dragonX = 0.2
    static let dragonWidth = 0.07
    static let dragonHeight = 0.08
    static let baseSpeed = 0.5
    static let gravity = 3.2
    static let heldGravity = 1.3
    static let jumpVelocity = 1.05
    static let maxHoldTime = 0.3
    static let spawnX = 1.1

    var elapsed: Double = 0
    var distance: Double = 0
    /// What the player sees; Sunrise Sprint counts distance 25% faster.
    var score: Int { Int(distance * (style.has(.sunriseSprint) ? 125 : 100)) }
    /// The score without talent bonuses, used for rewards and quests.
    var baseScore: Int { Int(distance * 100) }
    var isOver = false
    /// Counts Rock Hide saves so the view can pop a label.
    var talentTriggers = 0

    let style: DragonPlayStyle
    /// Stamina: +4% jump height per star above 1★.
    let jumpVelocity: Double
    let maxHoldTime: Double
    let heldGravity: Double
    var dragonY: Double = 0
    var velocityY: Double = 0
    var obstacles: [DashObstacle] = []
    var distanceToNextSpawn: Double = 1.0

    private var holdTime: Double = 0
    private var rockHideUsed = false
    private var rng: SeededRNG

    var isOnGround: Bool { dragonY <= 0 }

    init(seed: UInt64, style: DragonPlayStyle = .neutral) {
        rng = SeededRNG(seed: seed)
        self.style = style
        jumpVelocity = Self.jumpVelocity * (1 + 0.04 * style.boost(.stamina)).squareRoot()
        let glide = style.has(.leafGlide)
        maxHoldTime = glide ? 0.55 : Self.maxHoldTime
        heldGravity = glide ? 1.0 : Self.heldGravity
    }

    /// +5% speed for every full 10 seconds survived.
    static func speed(forElapsed elapsed: Double) -> Double {
        baseSpeed * pow(1.05, floor(elapsed / 10))
    }

    mutating func step(dt: Double, input: DashInput) {
        guard !isOver else { return }
        elapsed += dt
        let speed = Self.speed(forElapsed: elapsed)
        distance += speed * dt

        // Jumping: a held jump floats higher for a short while
        if input.jumpPressed && isOnGround {
            velocityY = jumpVelocity
            holdTime = 0
        }
        let floating = input.jumpHeld && velocityY > 0 && holdTime < maxHoldTime
        if floating { holdTime += dt }
        velocityY -= (floating ? heldGravity : Self.gravity) * dt
        dragonY += velocityY * dt
        if dragonY <= 0 {
            dragonY = 0
            velocityY = 0
        }

        // Obstacles scroll left; new ones spawn off-screen right
        for i in obstacles.indices { obstacles[i].x -= speed * dt }
        obstacles.removeAll { $0.x < -0.2 }
        distanceToNextSpawn -= speed * dt
        if distanceToNextSpawn <= 0 {
            spawnObstacle()
        }

        if obstacles.contains(where: collides) {
            if style.has(.rockHide) && !rockHideUsed {
                // Rock Hide: the first crash smashes the obstacle instead
                rockHideUsed = true
                talentTriggers += 1
                obstacles.removeAll(where: collides)
            } else {
                isOver = true
            }
        }
    }

    private mutating func spawnObstacle() {
        // Bats join after the first 10 seconds
        let kinds: [DashObstacle.Kind] = elapsed > 10 ? [.rock, .cactus, .bat] : [.rock, .cactus]
        let kind = kinds.randomElement(using: &rng) ?? .rock
        obstacles.append(DashObstacle(kind: kind, x: Self.spawnX))
        distanceToNextSpawn = Double.random(in: 0.55...1.1, using: &rng)
    }

    private func collides(_ o: DashObstacle) -> Bool {
        let dragonLeft = Self.dragonX - Self.dragonWidth / 2
        let dragonRight = Self.dragonX + Self.dragonWidth / 2
        let overlapX = dragonRight > o.x - o.width / 2 && dragonLeft < o.x + o.width / 2
        let overlapY = dragonY < o.y + o.height && dragonY + Self.dragonHeight > o.y
        return overlapX && overlapY
    }
}
