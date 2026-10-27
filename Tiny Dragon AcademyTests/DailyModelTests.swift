//
//  DailyModelTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class DailyModelTests: XCTestCase {
    private let cal = TestTime.utc

    func test_gameDay_startsAt7am() {
        XCTAssertEqual(GameDay.id(for: TestTime.date(day: 5, hour: 7), calendar: cal), "2026-01-05")
        XCTAssertEqual(GameDay.id(for: TestTime.date(day: 5, hour: 6, minute: 59), calendar: cal), "2026-01-04")
        XCTAssertEqual(GameDay.id(for: TestTime.date(day: 5, hour: 23), calendar: cal), "2026-01-05")
    }

    func test_gameDay_followsWallClockOnDSTDays() {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        func local(_ d: Int, _ h: Int, _ m: Int) -> Date { ny.date(from: DateComponents(year: 2026, month: 3, day: d, hour: h, minute: m))! }
        XCTAssertEqual(GameDay.id(for: local(8, 7, 30), calendar: ny), "2026-03-08", "spring-forward morning")
        XCTAssertEqual(GameDay.id(for: local(8, 6, 59), calendar: ny), "2026-03-07")
        XCTAssertEqual(GameDay.id(for: local(9, 7, 0), calendar: ny), "2026-03-09")
    }

    func test_malformedDaily_fallsBackInsteadOfLosingTheSave() throws {
        var root = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(AppProgressState.initial())) as? [String: Any])
        root["totalStars"] = 77
        root["daily"] = ["dayId": "2026-01-05", "quests": [["kind": ["score": ["_0": "Retired Game"]], "target": 5]]]
        root["streak"] = ["current": "oops"]
        let state = try JSONDecoder().decode(AppProgressState.self, from: JSONSerialization.data(withJSONObject: root))
        XCTAssertEqual(state.totalStars, 77)
        XCTAssertEqual(state.daily, DailyState())
        XCTAssertEqual(state.streak, StreakState())
    }

    func test_daysBetween_acrossMonthEnd() {
        XCTAssertEqual(GameDay.daysBetween("2026-01-30", "2026-02-02", calendar: cal), 3)
        XCTAssertEqual(GameDay.daysBetween("2026-01-05", "2026-01-05", calendar: cal), 0)
        XCTAssertEqual(GameDay.daysBetween("2026-01-06", "2026-01-05", calendar: cal), -1)
    }

    func test_fnv1a_isStable() {
        XCTAssertEqual(StableHash.fnv1a(""), 0xcbf29ce484222325)
        XCTAssertEqual(StableHash.fnv1a("a"), 0xaf63dc4c8601ec8c)
    }

    func test_legacyState_decodesDailyDefaults() throws {
        var root = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(AppProgressState.initial())) as? [String: Any])
        for key in ["careMode", "daily", "streak"] { root.removeValue(forKey: key) }
        root["dragons"] = (root["dragons"] as? [[String: Any]])?.map { d -> [String: Any] in
            var d = d; d.removeValue(forKey: "isShiny"); return d
        }
        let state = try JSONDecoder().decode(AppProgressState.self, from: JSONSerialization.data(withJSONObject: root))
        XCTAssertEqual(state.careMode, .classic)
        XCTAssertEqual(state.streak, StreakState())
        XCTAssertEqual(state.daily.dayId, "")
        XCTAssertFalse(state.dragons.contains { $0.isShiny })
    }

    func test_newFields_roundTrip() throws {
        var state = try JSONDecoder().decode(AppProgressState.self, from: JSONEncoder().encode(AppProgressState.initial()))
        state.careMode = .gentle
        state.streak = StreakState(current: 4, best: 9, shields: 1, recent: [StreakDay(dayId: "2026-01-04", result: .shielded)])
        state.daily = DailyState(
            dayId: "2026-01-05",
            quests: [DailyQuest(kind: .score(.dragonDash), target: 500), DailyQuest(kind: .feed, target: 3, progress: 2)],
            wishes: ["sparkle": DragonWish(kind: .eat(.fireBerries))],
            caredToday: true
        )
        state.dragons[0].isShiny = true
        let decoded = try JSONDecoder().decode(AppProgressState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded, state)
    }

    func test_badgedName_marksShiny() {
        var d = DragonModel.defaultDragons()[0]
        XCTAssertEqual(d.badgedName, "Sparkle")
        d.isShiny = true
        XCTAssertEqual(d.badgedName, "Sparkle ★")
    }

    func test_memorial_decodesWithoutShiny() throws {
        let json = #"{"id":"6809679C-A19C-4004-A60A-B8D22BEF5068","dragonId":"ember","name":"Blaze","speciesTitle":"Little Flame","stage":"Young Dragon","level":6,"bornAt":0,"diedAt":100}"#
        let m = try JSONDecoder().decode(Memorial.self, from: Data(json.utf8))
        XCTAssertFalse(m.isShiny)
    }
}
