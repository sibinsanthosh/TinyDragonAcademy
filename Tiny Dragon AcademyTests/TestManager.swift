//
//  TestManager.swift
//  Tiny Dragon AcademyTests
//
//  Builds a GameManager over a temp save file with a frozen clock.
//

import Foundation
@testable import Tiny_Dragon_Academy

/// Always returns the same raw value: 0 makes `Double.random` return 0, `.max` makes it ≈1.
struct FixedRNG: RandomNumberGenerator {
    let value: UInt64
    mutating func next() -> UInt64 { value }
}

@MainActor
func makeTestManager(
    fileURL: URL,
    notifications: NotificationScheduling,
    now: Date,
    configure: (inout AppProgressState) -> Void = { _ in }
) -> GameManager {
    var state = AppProgressState.initial()
    state.hasCompletedOnboarding = true
    state.lastDailyBonusClaimDate = now
    for idx in state.dragons.indices {
        state.dragons[idx].stats.lastSimulatedAt = now
        state.dragons[idx].stats.bornAt = now
    }
    state.incubatorSlots = [IncubatorSlot(lastSimulatedAt: now)]
    configure(&state)
    PersistenceService(fileURL: fileURL).saveState(state)
    return GameManager(
        persistence: PersistenceService(fileURL: fileURL),
        clock: GameClock(timeScale: 0, origin: now),
        notifications: notifications,
        calendar: TestTime.utc
    )
}
