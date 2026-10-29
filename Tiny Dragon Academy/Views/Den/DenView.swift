//
//  DenView.swift
//  Tiny Dragon Academy
//
//  The dragons that live with you and need care. Tap one to look after it.
//

import SwiftUI

struct DenView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var remindersDenied = false

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 260), spacing: 14)]

    var body: some View {
        ZStack {
            ClayBackdrop()

            VStack(spacing: 12) {
                ScreenTopBar(title: "Dragon Den", backTo: .dragonCollection)

                if remindersDenied && gameManager.state.remindersEnabled {
                    Label("Reminders are off in Settings — your dragons could get sick without you noticing.", systemImage: "bell.slash.fill")
                        .font(.clay(13, .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(ClayColor.coralShade))
                        .padding(.horizontal, 16)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(gameManager.state.denDragons) { dragon in
                            dragonCard(dragon)
                        }
                        ForEach(0..<max(0, gameManager.state.denCapacity - gameManager.state.denDragons.count), id: \.self) { _ in
                            emptySlot
                        }
                    }
                    .padding(.horizontal, 16)

                    if let price = gameManager.nextDenSlotPrice {
                        ClayUnlockRow(title: "Another den spot", detail: "Raise one more dragon at a time",
                                      price: price, stars: gameManager.totalStars) {
                            _ = gameManager.purchaseDenSlot()
                        }
                        .padding(16)
                    }
                }
            }
        }
        .onAppear { gameManager.tick() }
        .task { remindersDenied = await gameManager.notifications.authorizationDenied() }
    }

    private func dragonCard(_ dragon: DragonModel) -> some View {
        let status = DragonStatus.describe(dragon.stats, now: gameManager.clock.now(), calendar: gameManager.calendar, mode: gameManager.state.careMode)
        return Button {
            HapticsService.shared.medium()
            gameManager.selectDragon(id: dragon.id)
            gameManager.navigate(to: .dragonPlayground)
        } label: {
            VStack(spacing: 8) {
                DragonView(dragon: dragon, mood: dragon.stats.condition.isSpirit ? .sleepy : .idle,
                           size: 90, allowInteractivePetting: false)
                    .opacity(dragon.stats.condition.isSpirit ? 0.4 : 1)
                    .frame(height: 96)
                Text(dragon.badgedName)
                    .font(.clay(17, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                if let status {
                    DragonStatusBadge(status: status)
                } else {
                    Text("Happy & healthy")
                        .font(.clay(12, .bold))
                        .foregroundColor(DragonPalette.textMuted)
                }
                DragonMetersView(stats: dragon.stats, compact: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .claySurface(cornerRadius: 24)
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(dragon.id == gameManager.state.selectedDragonId ? ClayColor.accent : .clear, lineWidth: 3))
        }
        .buttonStyle(.plain)
    }

    private var emptySlot: some View {
        Button {
            gameManager.navigate(to: .incubator)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "oval.portrait.fill")
                    .font(.system(size: 40))
                    .foregroundColor(ClayColor.accent.opacity(0.35))
                Text("Empty spot")
                    .font(.clay(15, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                Label("Hatch an egg", systemImage: "arrow.right")
                    .font(.clay(13, .bold))
                    .foregroundColor(DragonPalette.textMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2.5, dash: [8]))
                    .foregroundColor(ClayColor.accent.opacity(0.35))
            )
        }
        .buttonStyle(.plain)
    }
}
