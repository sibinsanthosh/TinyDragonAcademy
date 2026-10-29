//
//  MainMenuView.swift
//  Tiny Dragon Academy
//
//  Home when no dragon lives in the den: a friendly welcome that points to
//  the eggs (and the shop for more), with stars, streak and settings on top.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showParentGate = false
    @State private var bob: CGFloat = 0

    private var readyEggs: Int {
        gameManager.state.incubatorSlots.filter(\.isReady).count
    }

    private var hasEggs: Bool {
        !gameManager.state.eggBasket.isEmpty || gameManager.state.incubatorSlots.contains { $0.egg != nil }
    }

    var body: some View {
        ZStack {
            ClayBackdrop()

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    StarCounterView(count: gameManager.totalStars)
                    ClayPill(systemName: "flame.fill", iconColor: ClayColor.coral,
                             value: "\(gameManager.state.streak.current)", accessibilityLabel: "Care streak")
                    Spacer()
                    ClayIconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings") {
                        showParentGate = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer(minLength: 0)

                ZStack {
                    ClayPlatform(top: Color(red: 0.93, green: 0.88, blue: 1.0), side: Color(red: 0.76, green: 0.68, blue: 0.96), width: 260)
                        .offset(y: 56)
                    EggView(eggColor: ClayColor.sun, spotColor: .white, crackStage: readyEggs > 0 ? 2 : 0, size: 120) {
                        gameManager.navigate(to: .incubator)
                    }
                    .offset(y: bob)
                }
                .frame(height: 220)

                VStack(spacing: 8) {
                    Text(readyEggs > 0 ? "An egg is ready to hatch!" : "Your den is empty")
                        .font(.clay(26, .heavy))
                        .foregroundColor(ClayColor.ink)
                        .multilineTextAlignment(.center)
                    Text(hasEggs ? "Warm your eggs in the incubator and meet a new dragon."
                                 : "Get an egg from the shop to hatch your next dragon.")
                        .font(.clay(16, .bold))
                        .foregroundColor(ClayColor.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    KidButton(title: hasEggs ? "Go to eggs" : "Visit the shop", icon: hasEggs ? "oval.portrait.fill" : "basket.fill",
                              backgroundColor: ClayColor.accent, minWidth: 240) {
                        gameManager.navigate(to: hasEggs ? .incubator : .foodInventoryShop)
                    }
                    Button {
                        HapticsService.shared.light()
                        gameManager.navigate(to: .dragonCollection)
                    } label: {
                        Label("See your dragons", systemImage: "books.vertical.fill")
                            .font(.clay(17, .heavy))
                            .frame(minWidth: 240, minHeight: 50)
                    }
                    .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 22))
                }
                .padding(.bottom, 16)
            }

            if showParentGate {
                ParentGateView(
                    onSuccess: {
                        showParentGate = false
                        gameManager.navigate(to: .settings)
                    },
                    onCancel: { showParentGate = false }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            guard !gameManager.state.settings.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { bob = -10 }
        }
    }
}
