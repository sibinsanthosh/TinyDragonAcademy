//
//  SnackCatchGameState.swift
//  Tiny Dragon Academy
//
//  Catch the Snacks: slide the dragon along the bottom to catch falling
//  food and dodge storm clouds. World units: x 0…1, y 0 (bottom) … 1 (top).
//

import Foundation

struct CatchInput {
    /// Where the finger is; the dragon glides toward it at a capped speed.
    var targetX: Double?
}

struct FallingItem: Equatable {
    enum Kind: Equatable {
        case food(FoodType)
        case storm
    }

    var kind: Kind
    var x: Double
    var y: Double
    var speed: Double
}

struct SnackCatchGameState {
    static let roundDuration = 60.0
    static let startingLives = 3
    static let dragonY = 0.08
    static let maxMoveSpeed = 1.5
    static let catchHalfWidth = 0.07
    static let catchHalfHeight = 0.06
    static let stormChance = 0.25
    static let snackFoods: [FoodType] = [.fireBerries, .frostApples, .crystalShards, .starfishTreats, .sunbeamOrange, .moonbeamPudding]

    var timeRemaining = roundDuration
    var elapsed: Double { Self.roundDuration - timeRemaining }
    var lives = startingLives
    var dragonX = 0.5
    var items: [FallingItem] = []
    var score = 0
    var caught: [FoodType] = []
    var isOver = false
    var spawnTimer = 0.6

    private var rng: SeededRNG

    init(seed: UInt64) {
        rng = SeededRNG(seed: seed)
    }

    mutating func step(dt: Double, input: CatchInput) {
        guard !isOver else { return }
        timeRemaining = max(0, timeRemaining - dt)

        if let target = input.targetX {
            let clamped = min(1, max(0, target))
            let maxStep = Self.maxMoveSpeed * dt
            dragonX += max(-maxStep, min(maxStep, clamped - dragonX))
        }

        var remaining: [FallingItem] = []
        for var item in items {
            item.y -= item.speed * dt
            if abs(item.x - dragonX) < Self.catchHalfWidth && abs(item.y - Self.dragonY) < Self.catchHalfHeight {
                switch item.kind {
                case .food(let food):
                    score += 1
                    caught.append(food)
                case .storm:
                    lives -= 1
                }
            } else if item.y > -0.05 {
                remaining.append(item)
            }
        }
        items = remaining

        spawnTimer -= dt
        if spawnTimer <= 0 { spawnItem() }

        if lives <= 0 || timeRemaining == 0 {
            lives = max(0, lives)
            isOver = true
        }
    }

    private mutating func spawnItem() {
        // Items fall a little faster and more often as the round goes on
        let progress = elapsed / Self.roundDuration
        let isStorm = Double.random(in: 0..<1, using: &rng) < Self.stormChance
        let kind: FallingItem.Kind = isStorm ? .storm : .food(Self.snackFoods.randomElement(using: &rng) ?? .fireBerries)
        let speed = Double.random(in: 0.3...0.45, using: &rng) + 0.2 * progress
        items.append(FallingItem(kind: kind, x: Double.random(in: 0.1...0.9, using: &rng), y: 1.05, speed: speed))
        spawnTimer = max(0.35, 0.8 - 0.4 * progress)
    }
}
