//
//  TalentHUD.swift
//  Tiny Dragon Academy
//
//  In-game talent feedback: a small badge while the dragon's talent is
//  active in this game, and a short pop each time it triggers.
//

import SwiftUI

struct TalentHUD: View {
    let talent: DragonTalent?
    let game: TrainingGameType
    /// The game state's trigger counter; each change shows the pop.
    let triggers: Int
    /// Games that need the bottom of the field (Catch the Snacks) put the badge up top.
    var badgeAtTop = false

    @State private var popToken = 0
    @State private var showPop = false

    var body: some View {
        if let talent, talent.game == game {
            VStack {
                if badgeAtTop { badge(talent) }
                if showPop {
                    Text("✨ \(talent.title)!")
                        .font(.clay(24, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(game.themeColor))
                        .shadow(color: DragonPalette.softShadow, radius: 6, y: 3)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer()
                if !badgeAtTop { badge(talent) }
            }
            .padding(.top, 48)
            .padding(.bottom, 10)
            .allowsHitTesting(false)
            .onChange(of: triggers) { _, _ in pop() }
        }
    }

    private func badge(_ talent: DragonTalent) -> some View {
        Label(talent.title, systemImage: "sparkles")
            .font(.clay(13, .heavy))
            .foregroundColor(DragonPalette.textDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .claySurface(cornerRadius: 100, elevation: 0.7)
    }

    private func pop() {
        popToken += 1
        let token = popToken
        HapticsService.shared.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showPop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard token == popToken else { return }
            withAnimation(.easeOut(duration: 0.25)) { showPop = false }
        }
    }
}
