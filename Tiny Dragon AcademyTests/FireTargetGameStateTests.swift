//
//  FireTargetGameStateTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class FireTargetGameStateTests: XCTestCase {
    private let dt = 1.0 / 60.0
    private let pull = CGVector(dx: -0.25, dy: -0.2)

    private func quietState() -> FireTargetGameState {
        var s = FireTargetGameState(seed: 5)
        s.targets = []
        s.spawnTimer = 1_000
        return s
    }

    private func idle(_ s: inout FireTargetGameState, frames: Int) {
        for _ in 0..<frames { s.step(dt: dt, input: FireInput(release: nil)) }
    }

    /// Fires and places a target where the fireball will be after `frames` steps.
    private func fireAt(_ s: inout FireTargetGameState, kind: FireTarget.Kind, frames: Int = 20) {
        let path = FireTargetGameState.trajectory(origin: FireTargetGameState.launchOrigin, pull: pull, steps: frames)
        s.targets.append(FireTarget(kind: kind, position: path[frames - 1]))
        s.step(dt: dt, input: FireInput(release: pull))
        idle(&s, frames: frames + 5)
    }

    func test_roundEndsAt45Seconds() {
        var s = quietState()
        idle(&s, frames: 44 * 60)
        XCTAssertFalse(s.isOver)
        idle(&s, frames: 61)
        XCTAssertTrue(s.isOver)
        XCTAssertEqual(s.timeRemaining, 0)
    }

    func test_fireball_followsTrajectoryPreview() throws {
        var s = quietState()
        let path = FireTargetGameState.trajectory(origin: FireTargetGameState.launchOrigin, pull: pull, steps: 30)
        s.step(dt: dt, input: FireInput(release: pull))
        idle(&s, frames: 29)
        let ball = try XCTUnwrap(s.fireballs.first)
        XCTAssertEqual(ball.position.x, path[29].x, accuracy: 1e-6)
        XCTAssertEqual(ball.position.y, path[29].y, accuracy: 1e-6)
    }

    func test_dummyDestroyedByOneHit() {
        var s = quietState()
        fireAt(&s, kind: .dummy)
        XCTAssertTrue(s.targets.isEmpty)
        XCTAssertEqual(s.score, 1)
    }

    func test_shieldNeedsTwoHits() {
        var s = quietState()
        fireAt(&s, kind: .shield)
        XCTAssertEqual(s.targets.count, 1)
        XCTAssertEqual(s.targets.first?.hitsRemaining, 1)
        XCTAssertEqual(s.score, 0)
        // Shields move; aim at its current spot again
        let shield = s.targets[0]
        s.targets = [FireTarget(kind: .shield, position: shield.position, hitsRemaining: 1)]
        let path = FireTargetGameState.trajectory(origin: FireTargetGameState.launchOrigin, pull: pull, steps: 20)
        s.targets[0].position = path[19]
        s.targets[0].velocity = .zero
        s.step(dt: dt, input: FireInput(release: pull))
        idle(&s, frames: 25)
        XCTAssertTrue(s.targets.isEmpty)
    }

    func test_comboMultiplier_increasesAndResetsOnMiss() {
        var s = quietState()
        fireAt(&s, kind: .dummy)
        fireAt(&s, kind: .dummy)
        XCTAssertEqual(s.score, 3, "second consecutive hit is worth 2")
        XCTAssertEqual(s.combo, 2)
        s.step(dt: dt, input: FireInput(release: pull))
        idle(&s, frames: 400)
        XCTAssertEqual(s.combo, 0)
        XCTAssertTrue(s.fireballs.isEmpty)
    }

    func test_targetMix_changesOverTime() {
        XCTAssertEqual(FireTargetGameState.kind(forElapsed: 5), .dummy)
        XCTAssertEqual(FireTargetGameState.kind(forElapsed: 20), .balloon)
        XCTAssertEqual(FireTargetGameState.kind(forElapsed: 35), .shield)
    }

    func test_spawnsUpToThreeTargets() {
        var s = FireTargetGameState(seed: 9)
        idle(&s, frames: 10 * 60)
        XCTAssertEqual(s.targets.count, FireTargetGameState.maxTargets)
    }

    func test_cooldownLimitsFireRate() {
        var s = quietState()
        s.step(dt: dt, input: FireInput(release: pull))
        s.step(dt: dt, input: FireInput(release: pull))
        XCTAssertEqual(s.fireballs.count, 1)
    }
}
