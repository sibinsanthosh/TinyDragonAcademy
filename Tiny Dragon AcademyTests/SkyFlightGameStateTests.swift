//
//  SkyFlightGameStateTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class SkyFlightGameStateTests: XCTestCase {
    private let dt = 1.0 / 60.0

    private func openSky() -> SkyFlightGameState {
        var s = SkyFlightGameState(seed: 4)
        s.pillars = []
        s.gems = []
        s.distanceToNextPillar = 1_000
        return s
    }

    func test_hoversUntilFirstFlap() {
        var s = openSky()
        for _ in 0..<120 { s.step(dt: dt, input: FlapInput(flap: false)) }
        XCTAssertEqual(s.dragonY, 0.5)
        XCTAssertFalse(s.isOver)
        XCTAssertEqual(s.elapsed, 0)
    }

    func test_gravityPullsDown_flapPushesUp() {
        var s = openSky()
        s.step(dt: dt, input: FlapInput(flap: true))
        for _ in 0..<40 { s.step(dt: dt, input: FlapInput(flap: false)) }
        let start = s.dragonY
        for _ in 0..<10 { s.step(dt: dt, input: FlapInput(flap: false)) }
        XCTAssertLessThan(s.dragonY, start)
        XCTAssertLessThan(s.velocityY, 0)
        s.step(dt: dt, input: FlapInput(flap: true))
        XCTAssertGreaterThan(s.velocityY, 0)
    }

    func test_passingPillar_scoresOnce() {
        var s = openSky()
        s.pillars = [CloudPillar(x: SkyFlightGameState.dragonX + 0.1, gapCenter: s.dragonY, gapHeight: 0.6)]
        for frame in 0..<120 {
            // Hover: with these physics a flap every 47 frames keeps altitude steady
            s.step(dt: dt, input: FlapInput(flap: frame % 47 == 0))
        }
        XCTAssertFalse(s.isOver)
        XCTAssertEqual(s.score, 1)
        for frame in 0..<60 { s.step(dt: dt, input: FlapInput(flap: frame % 47 == 0)) }
        XCTAssertEqual(s.score, 1)
    }

    func test_gapShrinks_toFloor() {
        XCTAssertEqual(SkyFlightGameState.gapHeight(forPillarIndex: 0), 0.38, accuracy: 1e-9)
        XCTAssertEqual(SkyFlightGameState.gapHeight(forPillarIndex: 5), 0.33, accuracy: 1e-9)
        XCTAssertEqual(SkyFlightGameState.gapHeight(forPillarIndex: 40), 0.24, accuracy: 1e-9)
    }

    func test_hitPillar_endsRun() {
        var s = openSky()
        s.pillars = [CloudPillar(x: SkyFlightGameState.dragonX, gapCenter: 0.9, gapHeight: 0.1)]
        s.dragonY = 0.3
        s.hasStarted = true
        s.step(dt: dt, input: FlapInput(flap: false))
        XCTAssertTrue(s.isOver)
    }

    func test_hitGround_endsRun() {
        var s = openSky()
        s.hasStarted = true
        for _ in 0..<300 { s.step(dt: dt, input: FlapInput(flap: false)) }
        XCTAssertTrue(s.isOver)
    }

    func test_flyingOffTop_endsRun() {
        var s = openSky()
        for _ in 0..<300 { s.step(dt: dt, input: FlapInput(flap: true)) }
        XCTAssertTrue(s.isOver)
    }

    func test_gemPickup_addsTwo() {
        var s = openSky()
        s.gems = [CGPoint(x: SkyFlightGameState.dragonX, y: s.dragonY)]
        s.hasStarted = true
        s.step(dt: dt, input: FlapInput(flap: false))
        XCTAssertEqual(s.score, 2)
        XCTAssertTrue(s.gems.isEmpty)
    }

    func test_pillarsSpawnWithShrinkingGaps() {
        var s = SkyFlightGameState(seed: 8)
        for frame in 0..<600 {
            let target = s.pillars.first { $0.x > SkyFlightGameState.dragonX - 0.1 }?.gapCenter ?? 0.5
            s.step(dt: dt, input: FlapInput(flap: frame == 0 || (s.dragonY < target - 0.05 && frame % 6 == 0)))
        }
        XCTAssertGreaterThan(s.pillarsSpawned, 1)
    }

    // MARK: - Skills & talents

    private func openSky(_ style: DragonPlayStyle) -> SkyFlightGameState {
        var s = SkyFlightGameState(seed: 4, style: style)
        s.pillars = []
        s.gems = []
        s.distanceToNextPillar = 1_000
        return s
    }

    func test_agility_widensGaps() {
        var s = SkyFlightGameState(seed: 4, style: DragonPlayStyle(stars: [.agility: 5]))
        s.step(dt: dt, input: FlapInput(flap: true))
        while s.pillars.isEmpty && !s.isOver { s.step(dt: dt, input: FlapInput(flap: s.velocityY < -0.3)) }
        XCTAssertEqual(s.pillars[0].gapHeight, SkyFlightGameState.gapHeight(forPillarIndex: 0) * 1.24, accuracy: 1e-9)
    }

    func test_tailwind_fallsSlower() {
        var plain = openSky()
        var wind = openSky(DragonPlayStyle(talent: .tailwind))
        for frame in 0..<30 {
            plain.step(dt: dt, input: FlapInput(flap: frame == 0))
            wind.step(dt: dt, input: FlapInput(flap: frame == 0))
        }
        XCTAssertGreaterThan(wind.dragonY, plain.dragonY)
        XCTAssertEqual(wind.gravity, SkyFlightGameState.gravity * 0.8, accuracy: 1e-9)
    }

    func test_bubbleShield_bouncesOffTheFirstPillarOnly() {
        var s = openSky(DragonPlayStyle(talent: .bubbleShield))
        s.step(dt: dt, input: FlapInput(flap: true))
        s.pillars = [CloudPillar(x: SkyFlightGameState.dragonX, gapCenter: 0.9, gapHeight: 0.1)]
        s.step(dt: dt, input: FlapInput(flap: false))
        XCTAssertFalse(s.isOver)
        XCTAssertEqual(s.talentTriggers, 1)
        XCTAssertGreaterThan(s.velocityY, 0, "bounced upward")
        s.step(dt: dt, input: FlapInput(flap: false))
        XCTAssertFalse(s.isOver, "the bumped pillar can't hit again")
        s.pillars.append(CloudPillar(x: SkyFlightGameState.dragonX, gapCenter: 0.1, gapHeight: 0.05))
        s.step(dt: dt, input: FlapInput(flap: false))
        XCTAssertTrue(s.isOver)
    }

    func test_moonFloat_scrollsSlower() {
        var s = openSky(DragonPlayStyle(talent: .moonFloat))
        s.step(dt: dt, input: FlapInput(flap: true))
        s.pillars = [CloudPillar(x: 1.0, gapCenter: 0.5, gapHeight: 0.3)]
        s.step(dt: dt, input: FlapInput(flap: false))
        XCTAssertEqual(1.0 - s.pillars[0].x, SkyFlightGameState.scrollSpeed * 0.85 * dt, accuracy: 1e-9)
    }

    func test_starMagnet_pullsGemsFromFurther() {
        for (style, expected) in [(DragonPlayStyle.neutral, 0), (DragonPlayStyle(talent: .starMagnet), 2)] {
            var s = openSky(style)
            s.gems = [CGPoint(x: SkyFlightGameState.dragonX, y: 0.5 + 0.09)]
            s.step(dt: dt, input: FlapInput(flap: true))
            XCTAssertEqual(s.score, expected, "\(String(describing: style.talent))")
        }
    }
}
