//
//  PostcardTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class PostcardTests: XCTestCase {
    private func dragon(_ id: String) -> DragonModel {
        DragonModel.defaultDragons().first { $0.id == id }!
    }

    func test_content_describesTheDragon() {
        var ember = dragon("ember")
        ember.stats.level = 7
        let content = PostcardContent(dragon: ember)
        XCTAssertEqual(content.title, "Ember")
        XCTAssertEqual(content.subtitle, "Lvl 7 · \(ember.stats.growthStage.rawValue)")
        XCTAssertEqual(content.talentTitle, "Splash Blast")
        XCTAssertEqual(content.bestSkill, .aim)
        XCTAssertEqual(content.bestSkillStars, 3)
        XCTAssertFalse(content.isShiny)
    }

    func test_bestSkill_followsTrainingAndBreaksTiesInOrder() {
        var frosty = dragon("frosty")          // aim 3, reflexes 3: aim wins the tie
        XCTAssertEqual(PostcardContent(dragon: frosty).bestSkill, .aim)
        frosty.stats.skillPoints = ["reflexes": 10]
        XCTAssertEqual(PostcardContent(dragon: frosty).bestSkill, .reflexes)
        XCTAssertEqual(PostcardContent(dragon: frosty).bestSkillStars, 4)
    }

    func test_shinyDragon_isMarked() {
        var sparkle = dragon("sparkle")
        sparkle.isShiny = true
        let content = PostcardContent(dragon: sparkle)
        XCTAssertTrue(content.isShiny)
        XCTAssertEqual(content.title, "Sparkle ★")
    }

    func test_posesMapToMoods() {
        XCTAssertEqual(PostcardPose.allCases.count, 4)
        XCTAssertEqual(PostcardPose.happy.mood, .happy)
        XCTAssertEqual(PostcardPose.cheeky.mood, .celebration)
        XCTAssertEqual(PostcardPose.sleepy.mood, .sleepy)
        XCTAssertEqual(PostcardPose.power.mood, .castingPower)
        XCTAssertEqual(PostcardFrame.allCases.count, 4)
    }

    /// DragonView grows with the stage; the postcard cancels that so an adult fits like a baby.
    func test_dragonSize_fillsTheSameSpaceAtEveryStage() {
        for stage in GrowthStage.allCases {
            XCTAssertEqual(PostcardView.dragonSize(for: stage) * stage.scaleMultiplier, 210, accuracy: 0.01, "\(stage)")
        }
    }
}
