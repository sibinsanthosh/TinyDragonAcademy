//
//  DashGameStateTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class DashGameStateTests: XCTestCase {
    private let dt = 1.0 / 60.0

    /// A state with no obstacles and none spawning soon.
    private func emptyState() -> DashGameState {
        var s = DashGameState(seed: 7)
        s.obstacles = []
        s.distanceToNextSpawn = 1_000
        return s
    }

    private func maxHeight(holdFrames: Int) -> Double {
        var s = emptyState()
        var peak = 0.0
        for frame in 0..<180 {
            s.step(dt: dt, input: DashInput(jumpPressed: frame == 0, jumpHeld: frame < holdFrames))
            peak = max(peak, s.dragonY)
        }
        return peak
    }

    func test_jump_onlyFromGround_andLandsAgain() {
        var s = emptyState()
        s.step(dt: dt, input: DashInput(jumpPressed: true, jumpHeld: false))
        XCTAssertGreaterThan(s.dragonY, 0)
        for _ in 0..<5 { s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false)) }
        let velocity = s.velocityY
        s.step(dt: dt, input: DashInput(jumpPressed: true, jumpHeld: false))
        XCTAssertLessThan(s.velocityY, velocity, "pressing mid-air must not jump again")
        for _ in 0..<180 { s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false)) }
        XCTAssertEqual(s.dragonY, 0)
        XCTAssertTrue(s.isOnGround)
    }

    func test_holdJump_goesHigherThanTap() {
        XCTAssertGreaterThan(maxHeight(holdFrames: 30), maxHeight(holdFrames: 1) + 0.03)
    }

    func test_speedIncreasesFivePercentEveryTenSeconds() {
        XCTAssertEqual(DashGameState.speed(forElapsed: 0), DashGameState.baseSpeed, accuracy: 1e-9)
        XCTAssertEqual(DashGameState.speed(forElapsed: 9.9), DashGameState.baseSpeed, accuracy: 1e-9)
        XCTAssertEqual(DashGameState.speed(forElapsed: 20), DashGameState.baseSpeed * 1.05 * 1.05, accuracy: 1e-9)
    }

    func test_scoreTracksDistance() {
        var s = emptyState()
        for _ in 0..<60 { s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false)) }
        XCTAssertEqual(s.score, Int(DashGameState.baseSpeed * 100), accuracy: 1)
        XCTAssertEqual(s.elapsed, 1, accuracy: 1e-6)
    }

    func test_collision_endsRun() {
        var s = emptyState()
        s.obstacles = [DashObstacle(kind: .rock, x: DashGameState.dragonX)]
        s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        XCTAssertTrue(s.isOver)
        let score = s.score
        s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        XCTAssertEqual(s.score, score, "a finished run stops scoring")
    }

    func test_batAtHeadHeight_avoidedByStayingOnGround() {
        var s = emptyState()
        s.obstacles = [DashObstacle(kind: .bat, x: DashGameState.dragonX)]
        s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        XCTAssertFalse(s.isOver)
    }

    func test_jumpingIntoBat_endsRun() {
        var s = emptyState()
        s.dragonY = 0.15
        s.obstacles = [DashObstacle(kind: .bat, x: DashGameState.dragonX)]
        s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        XCTAssertTrue(s.isOver)
    }

    func test_obstaclesSpawnAndScrollOff() {
        var s = DashGameState(seed: 3)
        var sawObstacle = false
        for _ in 0..<600 {
            s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
            sawObstacle = sawObstacle || !s.obstacles.isEmpty
            if s.isOver { break }
        }
        XCTAssertTrue(sawObstacle)
        XCTAssertTrue(s.obstacles.allSatisfy { $0.x > -0.2 })
    }

    func test_sameSeed_sameObstacleSequence() {
        var a = DashGameState(seed: 11)
        var b = DashGameState(seed: 11)
        for _ in 0..<400 {
            a.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
            b.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        }
        XCTAssertEqual(a.obstacles, b.obstacles)
        XCTAssertEqual(a.isOver, b.isOver)
    }

    // MARK: - Skills & talents

    private func styledPeak(_ style: DragonPlayStyle, holdFrames: Int) -> Double {
        var s = DashGameState(seed: 7, style: style)
        s.obstacles = []
        s.distanceToNextSpawn = 1_000
        var peak = 0.0
        for frame in 0..<180 {
            s.step(dt: dt, input: DashInput(jumpPressed: frame == 0, jumpHeld: frame < holdFrames))
            peak = max(peak, s.dragonY)
        }
        return peak
    }

    func test_stamina_jumpsHigher() {
        let one = styledPeak(.neutral, holdFrames: 0)
        let five = styledPeak(DragonPlayStyle(stars: [.stamina: 5]), holdFrames: 0)
        XCTAssertEqual(five / one, 1.16, accuracy: 0.02, "+4% height per star above 1★")
    }

    func test_rockHide_survivesTheFirstCrashOnly() {
        var s = DashGameState(seed: 7, style: DragonPlayStyle(talent: .rockHide))
        s.distanceToNextSpawn = 1_000
        s.obstacles = [DashObstacle(kind: .rock, x: DashGameState.dragonX)]
        s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        XCTAssertFalse(s.isOver)
        XCTAssertTrue(s.obstacles.isEmpty, "the rock is smashed")
        XCTAssertEqual(s.talentTriggers, 1)
        s.obstacles = [DashObstacle(kind: .rock, x: DashGameState.dragonX)]
        s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false))
        XCTAssertTrue(s.isOver)
    }

    func test_leafGlide_floatsLongerWhenHeld() {
        let plain = styledPeak(.neutral, holdFrames: 60)
        let glide = styledPeak(DragonPlayStyle(talent: .leafGlide), holdFrames: 60)
        XCTAssertGreaterThan(glide, plain * 1.2)
        XCTAssertEqual(styledPeak(DragonPlayStyle(talent: .leafGlide), holdFrames: 0), styledPeak(.neutral, holdFrames: 0),
                       accuracy: 1e-9, "a tap jump is unchanged")
    }

    func test_sunriseSprint_boostsShownScoreOnly() {
        var s = DashGameState(seed: 7, style: DragonPlayStyle(talent: .sunriseSprint))
        s.obstacles = []
        s.distanceToNextSpawn = 1_000
        for _ in 0..<600 { s.step(dt: dt, input: DashInput(jumpPressed: false, jumpHeld: false)) }
        XCTAssertEqual(s.baseScore, Int(s.distance * 100))
        XCTAssertEqual(s.score, Int(s.distance * 125))
        XCTAssertEqual(emptyState().score, emptyState().baseScore)
    }
}
