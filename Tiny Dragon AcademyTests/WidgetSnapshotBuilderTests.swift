//
//  WidgetSnapshotBuilderTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class WidgetSnapshotBuilderTests: XCTestCase {
    private let cal = TestTime.utc
    private let noon = TestTime.date(day: 5, hour: 12)

    private func state(_ configure: (inout DragonModel) -> Void = { _ in }) -> AppProgressState {
        var s = AppProgressState.initial()
        let i = s.dragons.firstIndex { $0.id == "sparkle" }!
        s.dragons[i].residence = .den
        s.dragons[i].stats.lastSimulatedAt = noon
        s.dragons[i].stats.bornAt = noon
        s.dragons[i].stats.hunger = 90
        s.dragons[i].stats.energy = 90
        s.dragons[i].stats.health = 100
        s.selectedDragonId = "sparkle"
        configure(&s.dragons[i])
        return s
    }

    private func build(_ s: AppProgressState, at date: Date? = nil) -> WidgetSnapshot {
        WidgetSnapshotBuilder.build(state: s, now: date ?? noon, calendar: cal)
    }

    func test_timeline_coversTwelveHoursEveryHalfHour() {
        let snap = build(state())
        XCTAssertEqual(snap.entries.count, 25)
        XCTAssertEqual(snap.entries.first?.date, noon)
        XCTAssertEqual(snap.entries.last?.date, noon.addingTimeInterval(12 * 3600))
        XCTAssertEqual(snap.entries[1].date.timeIntervalSince(snap.entries[0].date), 1800)
        XCTAssertEqual(snap.entries.first?.name, "Sparkle")
    }

    func test_timeline_projectsHungerDown() {
        let snap = build(state())
        XCTAssertLessThan(snap.entries[6].hunger, snap.entries[0].hunger, "three hours later the dragon is hungrier")
        XCTAssertEqual(snap.entries[0].hunger, 90, accuracy: 0.01)
    }

    func test_moods() {
        XCTAssertEqual(build(state()).entries[0].mood, .happy)
        XCTAssertEqual(build(state { $0.stats.hunger = 10 }).entries[0].mood, .hungry)
        XCTAssertEqual(build(state { $0.stats.energy = 10 }).entries[0].mood, .tired)
        XCTAssertEqual(build(state { $0.stats.condition = .ill(.hungerFever) }).entries[0].mood, .sick)
        XCTAssertEqual(build(state { $0.stats.condition = .spirit(diedAt: self.noon) }).entries[0].mood, .spirit)
        let night = TestTime.date(day: 5, hour: 23)
        let asleep = build(state { $0.stats.lastSimulatedAt = night }, at: night)
        XCTAssertEqual(asleep.entries[0].mood, .asleep)
    }

    func test_emptyDen_givesOneEmptyEntry() {
        var s = state()
        let i = s.dragons.firstIndex { $0.id == "sparkle" }!
        s.dragons[i].residence = .sanctuary
        let snap = build(s)
        XCTAssertEqual(snap.entries.count, 1)
        XCTAssertEqual(snap.entries[0].mood, .empty)
    }

    func test_signature_ignoresTinyChangesButNotMoods() {
        let a = build(state { $0.stats.hunger = 80.1 })
        let b = build(state { $0.stats.hunger = 80.4 })
        XCTAssertEqual(a.signature, b.signature)
        let sick = build(state { $0.stats.condition = .ill(.hungerFever) })
        XCTAssertNotEqual(a.signature, sick.signature)
        let renamed = build(state { $0.name = "Blaze" })
        XCTAssertNotEqual(a.signature, renamed.signature)
    }

    func test_entryForDate_picksTheLatestPastEntry() {
        let snap = build(state())
        XCTAssertEqual(snap.entry(at: noon.addingTimeInterval(45 * 60))?.date, noon.addingTimeInterval(30 * 60))
        XCTAssertEqual(snap.entry(at: noon.addingTimeInterval(-60))?.date, noon, "before the first entry: the first")
        XCTAssertEqual(snap.entry(at: noon.addingTimeInterval(20 * 3600))?.date, noon.addingTimeInterval(12 * 3600))
    }

    func test_snapshot_roundTripsAsJSON() throws {
        let snap = build(state())
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: JSONEncoder().encode(snap))
        XCTAssertEqual(decoded, snap)
    }
}
