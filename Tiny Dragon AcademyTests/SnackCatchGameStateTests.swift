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
}
