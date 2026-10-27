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
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(DragonPalette.coral)
                            Text("Only 1 in 20 eggs hatches like this.")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                        Text("It's a \(dragon.speciesTitle)! 🎉")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        DragonView(dragon: dragon, mood: .celebration, size: 150, allowInteractivePetting: false)
                        Text(dragon.residence == .den ? "They moved into your den." : "Your den is full, so they're resting in the sanctuary.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(DragonPalette.textMuted)
                            .multilineTextAlignment(.center)
                        TextField("Name your dragon", text: $name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
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
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    Text("Every dragon from this egg is already living with you, so it hatched into stardust!")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
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
