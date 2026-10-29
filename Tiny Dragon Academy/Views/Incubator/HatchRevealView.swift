//
//  HatchRevealView.swift
//  Tiny Dragon Academy
//
//  Shows what hatched and lets the player name their new dragon.
//

import SwiftUI

struct HatchRevealView: View {
    @EnvironmentObject var gameManager: GameManager
    let outcome: HatchOutcome
    let onDone: () -> Void

    @State private var name = ""

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            VStack(spacing: 14) {
                switch outcome {
                case .dragon(let id):
                    if let dragon = gameManager.state.dragons.first(where: { $0.id == id }) {
                        if dragon.isShiny {
                            Label("Shiny!", systemImage: "sparkles")
                                .font(.clay(22, .heavy))
                                .foregroundColor(ClayColor.ink)
                                .padding(.horizontal, 16).padding(.vertical, 6)
                                .background(Capsule().fill(ClayColor.sun))
                            Text("Only 1 in 20 eggs hatches like this.")
                                .font(.clay(13, .bold))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                        Text("It's a \(dragon.speciesTitle)!")
                            .font(.clay(24, .heavy))
                            .foregroundColor(DragonPalette.textDark)
                        DragonView(dragon: dragon, mood: .celebration, size: 150, allowInteractivePetting: false)
                        Text(dragon.residence == .den ? "They moved into your den." : "Your den is full, so they're resting in the sanctuary.")
                            .font(.clay(13, .medium))
                            .foregroundColor(DragonPalette.textMuted)
                            .multilineTextAlignment(.center)
                        TextField("Name your dragon", text: $name)
                            .font(.clay(18, .bold))
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.shadow(.inner(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2))))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(ClayColor.accent.opacity(0.3), lineWidth: 2))
                            .onAppear { name = dragon.name }
                        KidButton(title: "Welcome home", icon: "house.fill", backgroundColor: ClayColor.accent) {
                            gameManager.nameHatched(id: id, name: name)
                            onDone()
                        }
                    }
                case .stars(let stars):
                    Label("+\(stars) stars", systemImage: "star.fill")
                        .font(.clay(26, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    Text("Every dragon from this egg is already living with you, so it hatched into stardust!")
                        .font(.clay(15, .medium))
                        .foregroundColor(DragonPalette.textMuted)
                        .multilineTextAlignment(.center)
                    KidButton(title: "Collect", icon: "star.fill", backgroundColor: ClayColor.accent, action: onDone)
                }
            }
            .padding(24)
            .claySurface(cornerRadius: 30, elevation: 1.4)
            .padding(.horizontal, 28)
        }
    }
}
