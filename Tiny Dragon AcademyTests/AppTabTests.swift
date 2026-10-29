//
//  AppTabTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class AppTabTests: XCTestCase {
    func test_routesMapToTheirTab() {
        XCTAssertEqual(AppTab.forRoute(.mainMenu), .home)
        XCTAssertEqual(AppTab.forRoute(.dragonPlayground), .home)
        XCTAssertEqual(AppTab.forRoute(.den), .dragons)
        XCTAssertEqual(AppTab.forRoute(.trainingHub), .train)
        XCTAssertEqual(AppTab.forRoute(.miniGamesHub), .train)
        XCTAssertEqual(AppTab.forRoute(.incubator), .eggs)
        XCTAssertEqual(AppTab.forRoute(.dragonCollection), .dragons)
        XCTAssertEqual(AppTab.forRoute(.hallOfLegends), .dragons)
        XCTAssertEqual(AppTab.forRoute(.foodInventoryShop), .shop)
    }

    func test_fullScreenRoutes_haveNoTab() {
        let fullScreen: [AppRoute] = [.onboarding, .settings, .today, .dragonDressUp, .islandBuilder,
                                      .powerEncyclopedia, .achievementsList, .trainingGame(.fireTarget),
                                      .miniGame(.colorGarden)]
        for route in fullScreen {
            XCTAssertNil(AppTab.forRoute(route), "\(route)")
        }
    }

    func test_eachTabOpensARouteThatMapsBackToIt() {
        XCTAssertEqual(AppTab.allCases.count, 5)
        for tab in AppTab.allCases {
            XCTAssertEqual(AppTab.forRoute(tab.root), tab)
            XCTAssertTrue(AppTab.isRoot(tab.root))
        }
    }

    func test_onlyTabRootsHideTheBackButton() {
        XCTAssertTrue(AppTab.isRoot(.mainMenu))
        XCTAssertTrue(AppTab.isRoot(.dragonPlayground), "Home is also reached as the playground")
        XCTAssertFalse(AppTab.isRoot(.hallOfLegends), "Legends sits inside Dragons and keeps a back button")
        XCTAssertFalse(AppTab.isRoot(.den))
        XCTAssertFalse(AppTab.isRoot(.miniGamesHub))
        XCTAssertFalse(AppTab.isRoot(.settings))
    }
}
