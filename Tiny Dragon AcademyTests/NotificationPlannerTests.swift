//
//  NotificationPlannerTests.swift
//  Tiny Dragon AcademyTests
//

import XCTest
@testable import Tiny_Dragon_Academy

@MainActor
final class NotificationPlannerTests: XCTestCase {
    private let cal = TestTime.utc
    private let eight = TestTime.date(day: 5, hour: 8)

    /// Sparkle alone in the den with the given meters; incubator empty.
    private func state(hunger: Double = 100, fitness: Double = 100, at time: Date? = nil) -> AppProgressState {
        var s = AppProgressState.initial()
        let i = s.dragons.firstIndex { $0.id == "sparkle" }!
        s.dragons[i].stats.hunger = hunger
        s.dragons[i].stats.fitness = fitness
        s.dragons[i].stats.happiness = 100
        s.dragons[i].stats.energy = 100
        s.dragons[i].stats.health = 100
        s.dragons[i].stats.lastSimulatedAt = time ?? eight
        s.incubatorSlots = [IncubatorSlot(lastSimulatedAt: time ?? eight)]
        return s
    }

    private func plan(_ s: AppProgressState, now: Date? = nil) -> [PlannedNotification] {
        NotificationPlanner.plan(state: s, now: now ?? eight, calendar: cal)
    }

    func test_predict_reportsFirstCrossingTimes() throws {
        var stats = DragonStats()
        stats.hunger = 40; stats.fitness = 100; stats.health = 100
        let predicted = LifeSimulator.predict(stats, from: eight, horizon: 12 * 3600, calendar: cal)
        let hungry = try XCTUnwrap(predicted.first { $0.event == .becameHungry })
        XCTAssertEqual(hungry.at.timeIntervalSince(eight), 50 * 60, accuracy: 60)
        let starving = try XCTUnwrap(predicted.first { $0.event == .starving })
        XCTAssertEqual(starving.at.timeIntervalSince(eight), 200 * 60, accuracy: 60)
        XCTAssertEqual(predicted.filter { $0.event == .becameHungry }.count, 1)
    }

    func test_hungry_predictedAtFiftyMinutes() throws {
        let n = try XCTUnwrap(plan(state(hunger: 40)).first { $0.body == "Sparkle is hungry! 🍖" })
        XCTAssertEqual(n.fireDate.timeIntervalSince(eight), 50 * 60, accuracy: 60)
        XCTAssertEqual(n.dragonId, "sparkle")
        XCTAssertEqual(n.title, "Sparkle")
    }

    func test_copyMatchesSpec() {
        XCTAssertEqual(NotificationPlanner.body(for: .becameHungry, name: "Ember"), "Ember is hungry! 🍖")
        XCTAssertEqual(NotificationPlanner.body(for: .starving, name: "Ember"), "Ember is starving — feed them soon!")
        XCTAssertEqual(NotificationPlanner.body(for: .needsTraining, name: "Ember"), "Ember is getting restless. Time for training! 🏃")
        XCTAssertEqual(NotificationPlanner.body(for: .becameIll(.hungerFever), name: "Ember"), "Ember caught Hunger Fever 🤒")
        XCTAssertEqual(NotificationPlanner.body(for: .healthCritical, name: "Ember"), "Ember is very sick! Come quickly ❗")
        XCTAssertEqual(NotificationPlanner.body(for: .died, name: "Ember"), "Ember has become a spirit 👻 You have 48h to revive them.")
        XCTAssertEqual(NotificationPlanner.body(for: .spiritLastChance, name: "Ember"), "Last chance to save Ember's spirit!")
        XCTAssertEqual(NotificationPlanner.body(for: .eggReady, name: ""), "Your egg is hatching! 🥚")
        XCTAssertEqual(NotificationPlanner.body(for: .eggCold, name: ""), "Your egg is getting cold — warm it up!")
    }

    func test_quietHours_shiftTo7am() throws {
        let placed = TestTime.date(day: 5, hour: 21, minute: 30)
        var s = state(at: placed)
        s.incubatorSlots = [IncubatorSlot(egg: Egg(tier: .common), warmth: 100, progress: 0, lastSimulatedAt: placed)]
        let n = try XCTUnwrap(plan(s, now: placed).first { $0.body == "Your egg is hatching! 🥚" })
        XCTAssertEqual(n.fireDate, TestTime.date(day: 6, hour: 7))
        XCTAssertEqual(n.title, "Incubator")
        XCTAssertNil(n.dragonId)
    }

    func test_eventsWithin30Min_collapseToMostSevere() {
        let firstHour = plan(state(hunger: 30.5, fitness: 30.5)).filter {
            $0.dragonId == "sparkle" && $0.fireDate < eight.addingTimeInterval(3600)
        }
        XCTAssertEqual(firstHour.map(\.body), ["Sparkle is hungry! 🍖"])
    }

    func test_minimumTwoHoursBetweenNotificationsPerDragon() {
        let notes = plan(state(hunger: 50, fitness: 31)).filter { $0.dragonId == "sparkle" }.sorted { $0.fireDate < $1.fireDate }
        XCTAssertEqual(notes.first?.body, "Sparkle is getting restless. Time for training! 🏃")
        for (a, b) in zip(notes, notes.dropFirst()) {
            XCTAssertGreaterThanOrEqual(b.fireDate.timeIntervalSince(a.fireDate), 2 * 3600 - 1)
        }
        XCTAssertFalse(notes.contains { $0.body == "Sparkle is hungry! 🍖" })
    }

    func test_sanctuaryAndUndiscovered_notPlanned() {
        var s = state(hunger: 40)
        let ember = s.dragons.firstIndex { $0.id == "ember" }!
        s.dragons[ember].residence = .sanctuary
        s.dragons[ember].stats.hunger = 40
        let ids = Set(plan(s).compactMap(\.dragonId))
        XCTAssertEqual(ids, ["sparkle"])
    }

    func test_gentle_noDeathNotices_andAtMostThreePerDay() {
        var s = state(hunger: 100, fitness: 100)
        s.careMode = .gentle
        var ember = s.dragons.first { $0.id == "ember" }!
        ember.residence = .den
        ember.stats.hunger = 35; ember.stats.fitness = 35; ember.stats.health = 100
        ember.stats.lastSimulatedAt = eight
        s.dragons[s.dragons.firstIndex { $0.id == "ember" }!] = ember
        let notes = plan(s)
        XCTAssertFalse(notes.contains { $0.body.contains("spirit") })
        let perDay = Dictionary(grouping: notes) { GameDay.id(for: $0.fireDate, calendar: cal) }
        XCTAssertFalse(perDay.isEmpty)
        XCTAssertTrue(perDay.values.allSatisfy { $0.count <= 3 })
    }

    func test_gentleCopy() {
        XCTAssertEqual(NotificationPlanner.body(for: .becameHungry, name: "Pip", mode: .gentle), "Pip would love a snack 🍓")
        XCTAssertEqual(NotificationPlanner.body(for: .starving, name: "Pip", mode: .gentle), "Pip is very hungry — time to eat!")
        XCTAssertEqual(NotificationPlanner.body(for: .needsTraining, name: "Pip", mode: .gentle), "Pip wants to play! 🏃")
        XCTAssertEqual(NotificationPlanner.body(for: .becameIll(.hungerFever), name: "Pip", mode: .gentle), "Pip isn't feeling well 🤒")
        XCTAssertEqual(NotificationPlanner.body(for: .healthCritical, name: "Pip", mode: .gentle), "Pip fell into a deep sleep 💤 — food will wake them")
        XCTAssertEqual(NotificationPlanner.body(for: .becameHungry, name: "Pip"), "Pip is hungry! 🍖")
    }

    func test_remindersDisabled_planIsEmpty() {
        var s = state(hunger: 40)
        s.remindersEnabled = false
        XCTAssertTrue(plan(s).isEmpty)
    }

    func test_ids_areStablePerSourceAndEvent() {
        let ids = plan(state(hunger: 40)).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertTrue(ids.contains("sparkle.becameHungry"))
    }
}
