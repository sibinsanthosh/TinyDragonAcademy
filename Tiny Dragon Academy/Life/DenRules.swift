//
//  DenRules.swift
//  Tiny Dragon Academy
//
//  Who lives in the den (simulated, needs care) versus the sanctuary
//  (frozen in time), and what happens when a spirit's window runs out.
//

import Foundation

enum DenRules {
    static let denSlotPrices: [Int: Int] = [4: 200, 5: 400]
    static let maxDenCapacity = 5
    static let incubatorSlotPrice = 150
    static let maxIncubatorSlots = 2

    /// Only healthy dragons may rest in the sanctuary, so a dying dragon can't be parked to dodge death.
    static func moveToSanctuary(_ id: String, state: inout AppProgressState) -> Bool {
        guard let idx = state.dragons.firstIndex(where: { $0.id == id }),
              state.dragons[idx].residence == .den,
              state.dragons[idx].stats.condition == .healthy else { return false }
        state.dragons[idx].residence = .sanctuary
        ensureActiveInDen(&state)
        return true
    }

    static func moveToDen(_ id: String, state: inout AppProgressState, now: Date) -> Bool {
        guard let idx = state.dragons.firstIndex(where: { $0.id == id }),
              state.dragons[idx].residence == .sanctuary,
              state.denDragons.count < state.denCapacity else { return false }
        state.dragons[idx].residence = .den
        state.dragons[idx].stats.lastSimulatedAt = now
        state.dragons[idx].stats.isSleepingEarly = false
        ensureActiveInDen(&state)
        return true
    }

    static func placeHatched(_ id: String, name: String, state: inout AppProgressState, now: Date) {
        guard let idx = state.dragons.firstIndex(where: { $0.id == id }) else { return }
        var stats = DragonStats.defaultStats(for: state.dragons[idx].element)
        stats.bornAt = now
        stats.lastSimulatedAt = now
        state.dragons[idx].stats = stats
        state.dragons[idx].name = name
        state.dragons[idx].residence = state.denDragons.count < state.denCapacity ? .den : .sanctuary
        ensureActiveInDen(&state)
    }

    /// Memorializes the dragon and returns an egg of the same species to the basket.
    static func expireSpirit(_ id: String, state: inout AppProgressState, now: Date) {
        guard let idx = state.dragons.firstIndex(where: { $0.id == id }) else { return }
        let dragon = state.dragons[idx]
        state.hallOfLegends.append(Memorial(
            id: UUID(),
            dragonId: dragon.id,
            name: dragon.name,
            speciesTitle: dragon.speciesTitle,
            stage: dragon.stats.growthStage,
            level: dragon.stats.level,
            bornAt: dragon.stats.bornAt,
            diedAt: dragon.stats.condition.spiritDiedAt ?? now
        ))
        state.eggBasket.append(Egg(tier: EggTier.tier(forSpecies: id) ?? .common, fixedSpeciesId: id))

        let defaults = DragonModel.defaultDragons().first { $0.id == id }
        state.dragons[idx].residence = .legend
        state.dragons[idx].name = defaults?.name ?? dragon.name
        state.dragons[idx].stats = DragonStats.defaultStats(for: dragon.element)
        ensureActiveInDen(&state)
    }

    /// The active dragon must live in the den; with an empty den the selection is left as is.
    static func ensureActiveInDen(_ state: inout AppProgressState) {
        let den = state.denDragons
        guard !den.contains(where: { $0.id == state.selectedDragonId }), let first = den.first else { return }
        state.selectedDragonId = first.id
    }
}
