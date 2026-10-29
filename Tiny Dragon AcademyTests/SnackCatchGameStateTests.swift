//
//  SnackCatchGameStateTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class SnackCatchGameStateTests: XCTestCase {
    private let dt = 1.0 / 60.0

    private func quiet() -> SnackCatchGameState {
        var s = SnackCatchGameState(seed: 6)
        s.items = []
        s.spawnTimer = 1_000
        return s
    }

    private func item(_ kind: FallingItem.Kind, at s: SnackCatchGameState) -> FallingItem {
        FallingItem(kind: kind, x: s.dragonX, y: SnackCatchGameState.dragonY, speed: 0.3)
    }

    func test_catchFood_addsScoreAndCaught() {
        var s = quiet()
        s.items = [item(.food(.fireBerries), at: s)]
        s.step(dt: dt, input: CatchInput(targetX: nil))
        XCTAssertEqual(s.score, 1)
        XCTAssertEqual(s.caught, [.fireBerries])
        XCTAssertTrue(s.items.isEmpty)
    }

    func test_storm_costsLife_threeStormsEnd() {
        var s = quiet()
        s.items = [item(.storm, at: s)]
        s.step(dt: dt, input: CatchInput(targetX: nil))
        XCTAssertEqual(s.lives, 2)
        XCTAssertFalse(s.isOver)
        for _ in 0..<2 {
            s.items = [item(.storm, at: s)]
            s.step(dt: dt, input: CatchInput(targetX: nil))
        }
        XCTAssertEqual(s.lives, 0)
        XCTAssertTrue(s.isOver)
    }

    func test_missedItemsFallAwayWithoutPenalty() {
        var s = quiet()
        s.items = [FallingItem(kind: .storm, x: 0.95, y: 0.05, speed: 0.5)]
        s.dragonX = 0.1
        for _ in 0..<60 { s.step(dt: dt, input: CatchInput(targetX: nil)) }
        XCTAssertTrue(s.items.isEmpty)
        XCTAssertEqual(s.lives, 3)
    }

    func test_roundEndsAt60Seconds() {
        var s = quiet()
        for _ in 0..<(59 * 60) { s.step(dt: dt, input: CatchInput(targetX: nil)) }
        XCTAssertFalse(s.isOver)
        for _ in 0..<61 { s.step(dt: dt, input: CatchInput(targetX: nil)) }
        XCTAssertTrue(s.isOver)
        XCTAssertEqual(s.timeRemaining, 0)
    }

    func test_dragonMoveSpeedCapped() {
        var s = quiet()
        s.dragonX = 0.5
        s.step(dt: dt, input: CatchInput(targetX: 1.0))
        XCTAssertEqual(s.dragonX, 0.5 + SnackCatchGameState.maxMoveSpeed * dt, accuracy: 1e-9)
        for _ in 0..<120 { s.step(dt: dt, input: CatchInput(targetX: 0.7)) }
        XCTAssertEqual(s.dragonX, 0.7, accuracy: 1e-9)
    }

    func test_spawnsMixOfFoodAndStorms() {
        var s = SnackCatchGameState(seed: 12)
        var sawFood = false, sawStorm = false
        for _ in 0..<(20 * 60) {
            s.step(dt: dt, input: CatchInput(targetX: 0.02))
            for item in s.items {
                if case .storm = item.kind { sawStorm = true } else { sawFood = true }
            }
        }
        XCTAssertTrue(sawFood)
        XCTAssertTrue(sawStorm)
    }

    // MARK: - Skills & talents

    private func quiet(_ style: DragonPlayStyle) -> SnackCatchGameState {
        var s = SnackCatchGameState(seed: 6, style: style)
        s.items = []
        s.spawnTimer = 1_000
        return s
    }

    /// Spawns `count` items one at a time and returns them as they were spawned.
    private func spawned(_ style: DragonPlayStyle, count: Int) -> [FallingItem] {
        var s = quiet(style)
        var out: [FallingItem] = []
        for _ in 0..<count {
            s.items = []
            s.spawnTimer = 0
            s.lives = 3
            s.timeRemaining = SnackCatchGameState.roundDuration
            s.step(dt: dt, input: CatchInput(targetX: nil))
            out += s.items
        }
        return out
    }

    func test_reflexes_widenTheCatch() {
        for (stars, expected) in [(1, 0), (5, 1)] {
            var s = quiet(DragonPlayStyle(stars: [.reflexes: stars]))
            s.items = [FallingItem(kind: .food(.fireBerries), x: s.dragonX + 0.08, y: SnackCatchGameState.dragonY, speed: 0.3)]
            s.step(dt: dt, input: CatchInput(targetX: nil))
            XCTAssertEqual(s.score, expected, "Reflexes \(stars)★")
        }
        XCTAssertEqual(quiet(DragonPlayStyle(stars: [.reflexes: 5])).catchHalfWidth, SnackCatchGameState.catchHalfWidth * 1.4, accuracy: 1e-9)
    }

    func test_waveGuard_blocksTheFirstStormOnly() {
        var s = quiet(DragonPlayStyle(talent: .waveGuard))
        s.items = [item(.storm, at: s)]
        s.step(dt: dt, input: CatchInput(targetX: nil))
        XCTAssertEqual(s.lives, SnackCatchGameState.startingLives)
        XCTAssertEqual(s.talentTriggers, 1)
        s.items = [item(.storm, at: s)]
        s.step(dt: dt, input: CatchInput(targetX: nil))
        XCTAssertEqual(s.lives, SnackCatchGameState.startingLives - 1)
    }

    func test_sweetTooth_doublesShownScoreOnly() {
        var s = quiet(DragonPlayStyle(talent: .sweetTooth))
        s.items = [item(.food(.fireBerries), at: s)]
        s.step(dt: dt, input: CatchInput(targetX: nil))
        XCTAssertEqual(s.score, 2)
        XCTAssertEqual(s.baseScore, 1)
        var plain = quiet()
        plain.items = [item(.food(.fireBerries), at: plain)]
        plain.step(dt: dt, input: CatchInput(targetX: nil))
        XCTAssertEqual(plain.score, plain.baseScore)
    }

    func test_blossomDrift_slowsSnacksNotStorms() {
        let items = spawned(DragonPlayStyle(talent: .blossomDrift), count: 200)
        let food = items.filter { $0.kind != .storm }.map(\.speed)
        let storms = items.filter { $0.kind == .storm }.map(\.speed)
        XCTAssertFalse(food.isEmpty)
        XCTAssertFalse(storms.isEmpty)
        XCTAssertLessThan(food.max()!, 0.37)
        XCTAssertGreaterThanOrEqual(food.min()!, 0.24)
        XCTAssertGreaterThanOrEqual(storms.min()!, 0.3)
    }

    func test_rainbowLuck_halvesStorms() {
        func stormShare(_ style: DragonPlayStyle) -> Double {
            let items = spawned(style, count: 600)
            return Double(items.filter { $0.kind == .storm }.count) / Double(items.count)
        }
        XCTAssertEqual(stormShare(.neutral), 0.25, accuracy: 0.05)
        XCTAssertEqual(stormShare(DragonPlayStyle(talent: .rainbowLuck)), 0.125, accuracy: 0.04)
    }
}
