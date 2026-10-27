//
//  SkyFlightGameState.swift
//  Tiny Dragon Academy
//
//  Sky Flight: tap to flap through gaps between cloud pillars.
//  World units: x 0…1 across, y 0 (ground) … 1 (top) of the play area.
//

import CoreGraphics

struct FlapInput {
    var flap: Bool
}

struct CloudPillar: Equatable {
    var x: Double
    var gapCenter: Double
    var gapHeight: Double
    var passed = false
}

struct SkyFlightGameState {
    static let dragonX = 0.25
    static let dragonRadius = 0.03
    static let gravity = 1.8
    static let flapVelocity = 0.7
    static let scrollSpeed = 0.35
    static let pillarWidth = 0.12
    static let pillarSpacing = 0.55
    static let gemRadius = 0.04

    var dragonY = 0.5
    var velocityY = 0.0
    var pillars: [CloudPillar] = []
    var gems: [CGPoint] = []
    var score = 0
    var elapsed = 0.0
    var isOver = false
    /// The dragon hovers in place until the first flap.
    var hasStarted = false
    var distanceToNextPillar = 0.6
    private(set) var pillarsSpawned = 0

    private var rng: SeededRNG

    init(seed: UInt64) {
        rng = SeededRNG(seed: seed)
    }

    /// Gaps start roomy and tighten by 0.01 per pillar down to 0.24.
    static func gapHeight(forPillarIndex index: Int) -> Double {
        max(0.24, 0.38 - 0.01 * Double(index))
    }

    mutating func step(dt: Double, input: FlapInput) {
        guard !isOver else { return }
        if input.flap { hasStarted = true }
        guard hasStarted else { return }
        elapsed += dt

        if input.flap { velocityY = Self.flapVelocity }
        velocityY -= Self.gravity * dt
        dragonY += velocityY * dt

        let shift = Self.scrollSpeed * dt
        for i in pillars.indices {
            pillars[i].x -= shift
            if !pillars[i].passed && pillars[i].x + Self.pillarWidth / 2 < Self.dragonX - Self.dragonRadius {
                pillars[i].passed = true
                score += 1
            }
        }
        pillars.removeAll { $0.x < -0.2 }
        for i in gems.indices { gems[i].x -= shift }

        let pickedUp = gems.filter { touchesDragon($0) }
        score += 2 * pickedUp.count
        let remaining = gems.filter { !touchesDragon($0) && $0.x >= -0.2 }
        gems = remaining

        distanceToNextPillar -= shift
        if distanceToNextPillar <= 0 { spawnPillar() }

        if dragonY - Self.dragonRadius < 0 || dragonY + Self.dragonRadius > 1 || pillars.contains(where: hitsPillar) {
            isOver = true
        }
    }

    private mutating func spawnPillar() {
        let gap = Self.gapHeight(forPillarIndex: pillarsSpawned)
        let margin = gap / 2 + 0.08
        let center = Double.random(in: margin...(1 - margin), using: &rng)
        let x = 1.15
        pillars.append(CloudPillar(x: x, gapCenter: center, gapHeight: gap))
        // Every other pillar carries a gem in its gap
        if pillarsSpawned % 2 == 1 {
            gems.append(CGPoint(x: x, y: center))
        }
        pillarsSpawned += 1
        distanceToNextPillar = Self.pillarSpacing
    }

    private func touchesDragon(_ gem: CGPoint) -> Bool {
        let dx = gem.x - Self.dragonX
        let dy = gem.y - dragonY
        let reach = Self.dragonRadius + Self.gemRadius
        return dx * dx + dy * dy < reach * reach
    }

    private func hitsPillar(_ p: CloudPillar) -> Bool {
        let overlapX = abs(p.x - Self.dragonX) < Self.pillarWidth / 2 + Self.dragonRadius
        let insideGap = dragonY - Self.dragonRadius > p.gapCenter - p.gapHeight / 2
            && dragonY + Self.dragonRadius < p.gapCenter + p.gapHeight / 2
        return overlapX && !insideGap
    }
}
