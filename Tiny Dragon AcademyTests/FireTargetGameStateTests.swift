//
//  FireTargetGameStateTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class FireTargetGameStateTests: XCTestCase {
    private let dt = 1.0 / 60.0
    private let aim = CGPoint(x: 0.7, y: 0.6)
    private let origin = FireTargetGameState.launchOrigin

    private func quietState() -> FireTargetGameState {
        var s = FireTargetGameState(seed: 5)
        s.targets = []
        s.spawnTimer = 1_000
        return s
    }

    private func idle(_ s: inout FireTargetGameState, frames: Int) {
        for _ in 0..<frames { s.step(dt: dt, input: FireInput(release: nil)) }
    }

    /// Places a target at the aim point, fires at it and lets the shot land.
    private func fireAt(_ s: inout FireTargetGameState, kind: FireTarget.Kind) {
        s.targets.append(FireTarget(kind: kind, position: aim))
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: 60)
    }

    func test_roundEndsAt45Seconds() {
        var s = quietState()
        idle(&s, frames: 44 * 60)
        XCTAssertFalse(s.isOver)
        idle(&s, frames: 61)
        XCTAssertTrue(s.isOver)
        XCTAssertEqual(s.timeRemaining, 0)
    }

    func test_shot_passesExactlyThroughAimPoint() {
        for target in [CGPoint(x: 0.9, y: 0.25), CGPoint(x: 0.5, y: 1.0), CGPoint(x: 0.92, y: 1.3), CGPoint(x: 0.3, y: 0.1)] {
            let steps = FireTargetGameState.flightSteps(from: origin, to: target)
            let path = FireTargetGameState.trajectory(origin: origin, aim: target, steps: steps)
            XCTAssertEqual(path[steps - 1].x, target.x, accuracy: 1e-6, "\(target)")
            XCTAssertEqual(path[steps - 1].y, target.y, accuracy: 1e-6, "\(target)")
        }
    }

    func test_flightTime_fasterWhenCloser() {
        let near = FireTargetGameState.flightSteps(from: origin, to: CGPoint(x: 0.3, y: 0.25))
        let far = FireTargetGameState.flightSteps(from: origin, to: CGPoint(x: 0.92, y: 1.1))
        XCTAssertLessThan(near, far)
        XCTAssertGreaterThanOrEqual(near, 21, "at least 0.35 s")
        XCTAssertLessThanOrEqual(far, 48, "at most 0.8 s")
    }

    func test_fireball_followsTrajectoryPreview() throws {
        var s = quietState()
        let path = FireTargetGameState.trajectory(origin: origin, aim: aim, steps: 15)
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: 14)
        let ball = try XCTUnwrap(s.fireballs.first)
        XCTAssertEqual(ball.position.x, path[14].x, accuracy: 1e-6)
        XCTAssertEqual(ball.position.y, path[14].y, accuracy: 1e-6)
    }

    func test_aimBelowGroundOrBehindDragon_isClamped() {
        let clamped = FireTargetGameState.clampAim(CGPoint(x: -0.2, y: -0.5))
        XCTAssertGreaterThanOrEqual(clamped.x, FireTargetGameState.minAimX)
        XCTAssertGreaterThanOrEqual(clamped.y, FireTargetGameState.minAimY)
    }

    func test_dummyDestroyedByOneHit_leavesBurst() {
        var s = quietState()
        s.targets.append(FireTarget(kind: .dummy, position: aim))
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: FireTargetGameState.flightSteps(from: origin, to: aim))
        XCTAssertTrue(s.targets.isEmpty)
        XCTAssertEqual(s.score, 1)
        XCTAssertEqual(s.bursts.count, 1)
        XCTAssertEqual(s.bursts.first?.points, 1)
        idle(&s, frames: 60)
        XCTAssertTrue(s.bursts.isEmpty, "bursts fade away")
    }

    func test_shieldNeedsTwoHits() {
        var s = quietState()
        fireAt(&s, kind: .shield)
        XCTAssertEqual(s.targets.count, 1)
        XCTAssertEqual(s.targets.first?.hitsRemaining, 1)
        XCTAssertEqual(s.score, 0)
        // Shields move; pin it back on the aim point for the second shot
        s.targets[0].position = aim
        s.targets[0].velocity = .zero
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: 60)
        XCTAssertTrue(s.targets.isEmpty)
    }

    func test_comboMultiplier_increasesAndResetsOnMiss() {
        var s = quietState()
        fireAt(&s, kind: .dummy)
        fireAt(&s, kind: .dummy)
        XCTAssertEqual(s.score, 3, "second consecutive hit is worth 2")
        XCTAssertEqual(s.combo, 2)
        s.step(dt: dt, input: FireInput(release: aim))
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

    func test_targets_stayInReachableArea() {
        for seed in UInt64(1)...30 {
            for start in [45.0, 28.0, 12.0] { // dummies, balloons, shields
                var s = FireTargetGameState(seed: seed)
                s.timeRemaining = start
                for _ in 0..<(10 * 60) {
                    s.step(dt: dt, input: FireInput(release: nil))
                    for t in s.targets {
                        XCTAssertTrue((0.4...0.95).contains(t.position.x), "seed \(seed): x \(t.position.x)")
                        XCTAssertTrue((0.25...FireTargetGameState.maxTargetY).contains(t.position.y), "seed \(seed): y \(t.position.y)")
                    }
                }
            }
        }
    }

    func test_cooldownLimitsFireRate() {
        var s = quietState()
        s.step(dt: dt, input: FireInput(release: aim))
        s.step(dt: dt, input: FireInput(release: aim))
        XCTAssertEqual(s.fireballs.count, 1)
        XCTAssertEqual(FireTargetGameState.fireCooldown, 0.25)
    }

    func test_tapDuringCooldown_firesWhenReady() {
        var s = quietState()
        let second = CGPoint(x: 0.5, y: 0.9)
        s.step(dt: dt, input: FireInput(release: aim))
        s.step(dt: dt, input: FireInput(release: second))
        XCTAssertEqual(s.fireballs.count, 1, "still cooling down")
        idle(&s, frames: Int(FireTargetGameState.fireCooldown * 60))
        XCTAssertEqual(s.fireballs.count, 2, "queued shot goes off without another tap")
        idle(&s, frames: 30)
        XCTAssertEqual(s.fireballs.count, 2, "fires only once")
    }

    // MARK: - Skills & talents

    private func styled(_ talent: DragonTalent? = nil, aim: Int = 1) -> FireTargetGameState {
        var s = FireTargetGameState(seed: 5, style: DragonPlayStyle(stars: [.aim: aim], talent: talent))
        s.targets = []
        s.spawnTimer = 1_000
        return s
    }

    func test_aimSkill_widensHitRadius() {
        XCTAssertEqual(quietState().hitRadius, FireTargetGameState.targetRadius, accuracy: 1e-9)
        XCTAssertEqual(styled(aim: 5).hitRadius, FireTargetGameState.targetRadius * 1.4, accuracy: 1e-9)
    }

    func test_aimSkill_hitsAShotThatWouldMiss() {
        let offset = CGPoint(x: aim.x, y: aim.y + FireTargetGameState.targetRadius + FireTargetGameState.fireballRadius + 0.01)
        for (stars, expectHit) in [(1, false), (5, true)] {
            var s = styled(aim: stars)
            s.targets = [FireTarget(kind: .dummy, position: offset)]
            s.step(dt: dt, input: FireInput(release: aim))
            idle(&s, frames: 60)
            XCTAssertEqual(s.targets.isEmpty, expectHit, "Aim \(stars)★")
        }
    }

    func test_splashBlast_hitsNearbyTargetsOnly() {
        var s = styled(.splashBlast)
        s.targets = [FireTarget(kind: .dummy, position: aim),
                     FireTarget(kind: .dummy, position: CGPoint(x: aim.x + 0.1, y: aim.y)),
                     FireTarget(kind: .dummy, position: CGPoint(x: aim.x, y: aim.y + 0.3))]
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: 60)
        XCTAssertEqual(s.targets.count, 1)
        XCTAssertEqual(s.targets.first?.position.y ?? 0, aim.y + 0.3, accuracy: 1e-9, "the far target survives")
        XCTAssertEqual(s.score, 3, "two hits in a row: 1 + 2")
        XCTAssertEqual(s.talentTriggers, 1)
    }

    func test_chainBolt_zapsTheNearestOtherTarget() {
        var s = styled(.chainBolt)
        let near = CGPoint(x: 0.75, y: 0.95)
        let far = CGPoint(x: 0.95, y: 0.3)
        s.targets = [FireTarget(kind: .dummy, position: aim),
                     FireTarget(kind: .dummy, position: far),
                     FireTarget(kind: .dummy, position: near)]
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: 60)
        XCTAssertEqual(s.targets.map(\.position), [far])
        XCTAssertEqual(s.talentTriggers, 1)
    }

    func test_chainBolt_withNoOtherTarget_isJustAHit() {
        var s = styled(.chainBolt)
        s.targets = [FireTarget(kind: .dummy, position: aim)]
        s.step(dt: dt, input: FireInput(release: aim))
        idle(&s, frames: 60)
        XCTAssertEqual(s.score, 1)
        XCTAssertEqual(s.talentTriggers, 0)
    }

    func test_frozenField_slowsTargetMovement() {
        var normal = quietState()
        var frozen = styled(.frozenField)
        let balloon = FireTarget(kind: .balloon, position: CGPoint(x: 0.7, y: 0.5), velocity: CGVector(dx: 0, dy: 0.04))
        normal.targets = [balloon]
        frozen.targets = [balloon]
        idle(&normal, frames: 60)
        idle(&frozen, frames: 60)
        XCTAssertEqual(normal.targets[0].position.y - 0.5, 0.04, accuracy: 1e-6)
        XCTAssertEqual(frozen.targets[0].position.y - 0.5, 0.02, accuracy: 1e-6)
    }

    func test_laserShot_fliesStraight() {
        let target = CGPoint(x: 0.75, y: 0.5)
        let steps = FireTargetGameState.flightSteps(from: origin, to: target)
        let path = FireTargetGameState.trajectory(origin: origin, aim: target, steps: steps, straight: true)
        XCTAssertEqual(path[steps - 1].x, target.x, accuracy: 1e-6)
        XCTAssertEqual(path[steps - 1].y, target.y, accuracy: 1e-6)
        let mid = path[steps / 2 - 1]
        let t = (mid.x - origin.x) / (target.x - origin.x)
        XCTAssertEqual(mid.y, origin.y + t * (target.y - origin.y), accuracy: 1e-6, "on the straight line")
    }

    func test_laserShot_piercesEachTargetOnce() {
        var s = styled(.laserShot)
        let target = CGPoint(x: 0.75, y: 0.5)
        let between = CGPoint(x: origin.x + 0.6 * (target.x - origin.x), y: origin.y + 0.6 * (target.y - origin.y))
        s.targets = [FireTarget(kind: .shield, position: between), FireTarget(kind: .dummy, position: target)]
        s.step(dt: dt, input: FireInput(release: target))
        idle(&s, frames: 90)
        XCTAssertEqual(s.targets.count, 1, "the dummy behind the shield is destroyed")
        XCTAssertEqual(s.targets.first?.hitsRemaining, 1, "the shield is hit only once by one ball")
        XCTAssertEqual(s.talentTriggers, 1)
        XCTAssertGreaterThan(s.combo, 0, "a piercing ball that hit something isn't a miss")
    }
}
