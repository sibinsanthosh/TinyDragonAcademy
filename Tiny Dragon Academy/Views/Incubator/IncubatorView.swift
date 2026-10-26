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
            DragonPalette.sunsetGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                ScreenTopBar(title: "Incubator")

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(gameManager.state.incubatorSlots.indices, id: \.self) { index in
                            slotCard(index)
                        }

                        if gameManager.state.incubatorCapacity < DenRules.maxIncubatorSlots {
                            KidButton(title: "Second incubator • \(DenRules.incubatorSlotPrice)★", icon: "plus.circle.fill",
                                      backgroundColor: DragonPalette.softPurple, fontSize: 16) {
                                _ = gameManager.purchaseIncubatorSlot()
                            }
                            .disabled(gameManager.totalStars < DenRules.incubatorSlotPrice)
                            .opacity(gameManager.totalStars < DenRules.incubatorSlotPrice ? 0.5 : 1)
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
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                if slot.isReady {
                    Text("Ready! Tap to hatch 🐣")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.coral)
                } else {
                    progressRow(label: "Hatching", value: slot.progress, color: egg.tier.shellColor,
                                trailing: timeLeft(slot, tier: egg.tier))
                    progressRow(label: "Warmth", value: slot.warmth / 100,
                                color: slot.warmth >= LifeSimulator.eggWarmThreshold ? DragonPalette.coral : DragonPalette.skyBlue,
                                trailing: slot.warmth >= LifeSimulator.eggWarmThreshold ? "Cozy" : "Cold — tap to warm!")
                }
            } else {
                Image(systemName: "flame")
                    .font(.system(size: 36))
                    .foregroundColor(DragonPalette.coral.opacity(0.6))
                Text("Empty incubator")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                Text(gameManager.state.eggBasket.isEmpty ? "Earn eggs by growing and training dragons, or buy one in the shop." : "Place an egg from your basket below.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }

    private func progressRow(label: String, value: Double, color: Color, trailing: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(trailing)
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(DragonPalette.textMuted)
            ProgressView(value: max(0, min(1, value)))
                .tint(color)
        }
    }

    private func timeLeft(_ slot: IncubatorSlot, tier: EggTier) -> String {
        let speed = slot.warmth >= LifeSimulator.eggWarmThreshold ? 1.0 : 0.5
        let seconds = (1 - slot.progress) * tier.hatchDuration / speed
        let minutes = Int(seconds / 60)
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m left" : "\(max(1, minutes))m left"
    }

    private var basket: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Egg Basket (\(gameManager.state.eggBasket.count))", systemImage: "basket.fill")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
            if gameManager.state.eggBasket.isEmpty {
                Text("No eggs waiting.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
            }
            ForEach(gameManager.state.eggBasket) { egg in
                HStack {
                    Circle().fill(egg.tier.shellColor).frame(width: 26, height: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(egg.tier.displayName)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                        if let species = egg.fixedSpeciesId,
                           let dragon = gameManager.state.dragons.first(where: { $0.id == species }) {
                            Text("Carries \(dragon.speciesTitle)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                    }
                    .foregroundColor(DragonPalette.textDark)
                    Spacer()
                    let free = gameManager.state.incubatorSlots.firstIndex { $0.egg == nil }
                    Button("Place") {
                        if let free { _ = gameManager.placeEgg(egg.id, slot: free) }
                    }
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .buttonStyle(.borderedProminent)
                    .tint(DragonPalette.coral)
                    .disabled(free == nil)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(DragonPalette.cream))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }
}
