//
//  IncubatorView.swift
//  Tiny Dragon Academy
//
//  Warm your eggs until they hatch, and place new eggs from the basket.
//

import SwiftUI

struct IncubatorView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var reveal: HatchOutcome?

    var body: some View {
        ZStack {
            ClayBackdrop()

            VStack(spacing: 12) {
                ScreenTopBar(title: "Eggs")

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(gameManager.state.incubatorSlots.indices, id: \.self) { index in
                            slotCard(index)
                        }

                        if gameManager.state.incubatorCapacity < DenRules.maxIncubatorSlots {
                            secondIncubatorOffer
                        }

                        basket
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }

            if let outcome = reveal {
                HatchRevealView(outcome: outcome) { reveal = nil }
            }
        }
        .onAppear { gameManager.tick() }
    }

    private func slotCard(_ index: Int) -> some View {
        let slot = gameManager.state.incubatorSlots[index]
        return VStack(spacing: 10) {
            if let egg = slot.egg {
                EggView(
                    eggColor: egg.tier.shellColor,
                    spotColor: .white,
                    crackStage: slot.isReady ? 3 : min(2, Int(slot.progress * 3)),
                    size: 130
                ) {
                    if slot.isReady {
                        reveal = gameManager.crackEgg(slot: index)
                    } else {
                        gameManager.warmEgg(slot: index)
                    }
                }
                Text(egg.tier.displayName)
                    .font(.clay(17, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                if slot.isReady {
                    Label("Ready! Tap the egg to hatch", systemImage: "sparkles")
                        .font(.clay(16, .heavy))
                        .foregroundColor(ClayColor.ink)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(ClayColor.sun))
                } else {
                    progressRow(label: "Hatching", value: slot.progress, color: egg.tier.shellColor,
                                trailing: timeLeft(slot, tier: egg.tier))
                    progressRow(label: "Warmth", value: slot.warmth / 100,
                                color: slot.warmth >= LifeSimulator.eggWarmThreshold ? DragonPalette.coral : DragonPalette.skyBlue,
                                trailing: slot.warmth >= LifeSimulator.eggWarmThreshold ? "Cozy" : "Cold — tap to warm!")
                }
            } else {
                ZStack {
                    ClayPlatform(top: Color(red: 1.0, green: 0.90, blue: 0.80), side: Color(red: 0.93, green: 0.72, blue: 0.56), width: 150)
                        .offset(y: 30)
                    Image(systemName: "oval.portrait")
                        .font(.system(size: 54, weight: .light))
                        .foregroundColor(ClayColor.inkSoft.opacity(0.5))
                }
                .frame(height: 100)
                Text("Empty incubator")
                    .font(.clay(16, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                Text(gameManager.state.eggBasket.isEmpty ? "Earn eggs by growing and training dragons, or buy one in the shop." : "Place an egg from your basket below.")
                    .font(.clay(13, .medium))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .claySurface(cornerRadius: 22)
    }

    private func progressRow(label: String, value: Double, color: Color, trailing: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(trailing)
            }
            .font(.clay(13, .bold))
            .foregroundColor(ClayColor.inkSoft)
            ClayMeter(value: max(0, min(1, value)) * 100, color: color, height: 10)
        }
    }

    private func timeLeft(_ slot: IncubatorSlot, tier: EggTier) -> String {
        let speed = slot.warmth >= LifeSimulator.eggWarmThreshold ? 1.0 : 0.5
        let seconds = (1 - slot.progress) * tier.hatchDuration / speed
        let minutes = Int(seconds / 60)
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m left" : "\(max(1, minutes))m left"
    }

    private var secondIncubatorOffer: some View {
        ClayUnlockRow(title: "Second incubator", detail: "Hatch two eggs at once",
                      price: DenRules.incubatorSlotPrice, stars: gameManager.totalStars) {
            _ = gameManager.purchaseIncubatorSlot()
        }
    }

    private var basket: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Egg basket · \(gameManager.state.eggBasket.count)", systemImage: "basket.fill")
                .font(.clay(18, .heavy))
                .foregroundColor(DragonPalette.textDark)
            if gameManager.state.eggBasket.isEmpty {
                Text("No eggs waiting.")
                    .font(.clay(14, .medium))
                    .foregroundColor(DragonPalette.textMuted)
            }
            ForEach(gameManager.state.eggBasket) { egg in
                HStack {
                    Circle().fill(egg.tier.shellColor).frame(width: 26, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(egg.tier.displayName)
                            .font(.clay(15, .heavy))
                        if let species = egg.fixedSpeciesId,
                           let dragon = gameManager.state.dragons.first(where: { $0.id == species }) {
                            Text("Carries \(dragon.speciesTitle)")
                                .font(.clay(12, .medium))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                    }
                    .foregroundColor(DragonPalette.textDark)
                    Spacer()
                    let free = gameManager.state.incubatorSlots.firstIndex { $0.egg == nil }
                    Button {
                        if let free { _ = gameManager.placeEgg(egg.id, slot: free) }
                    } label: {
                        Text("Place")
                            .font(.clay(15, .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                    .buttonStyle(ClayButtonStyle(color: ClayColor.coral, cornerRadius: 16))
                    .disabled(free == nil)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(red: 1.0, green: 0.96, blue: 0.93)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .claySurface(cornerRadius: 22)
    }
}
