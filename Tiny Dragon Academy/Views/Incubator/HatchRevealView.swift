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

            VStack(spacing: 14) {
                switch outcome {
                case .dragon(let id):
                    if let dragon = gameManager.state.dragons.first(where: { $0.id == id }) {
                        if dragon.isShiny {
                            Text("✨ SHINY! ✨")
                                .font(.clay(28, .heavy))
                                .foregroundColor(DragonPalette.coral)
                            Text("Only 1 in 20 eggs hatches like this.")
                                .font(.clay(13, .bold))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                        Text("It's a \(dragon.speciesTitle)! 🎉")
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
                            .background(RoundedRectangle(cornerRadius: 14).fill(DragonPalette.cream))
                            .onAppear { name = dragon.name }
                        KidButton(title: "Welcome home!", backgroundColor: DragonPalette.coral) {
                            gameManager.nameHatched(id: id, name: name)
                            onDone()
                        }
                    }
                case .stars(let stars):
                    Text("✨ +\(stars) stars ✨")
                        .font(.clay(26, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    Text("Every dragon from this egg is already living with you, so it hatched into stardust!")
                        .font(.clay(15, .medium))
                        .foregroundColor(DragonPalette.textMuted)
                        .multilineTextAlignment(.center)
                    KidButton(title: "Yay!", backgroundColor: DragonPalette.softPurple, action: onDone)
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color.white))
            .padding(.horizontal, 28)
        }
    }
}
