//
//  ScreenTopBar.swift
//  Tiny Dragon Academy
//
//  Back pill, centered title and star counter used across screens.
//

import SwiftUI

struct ScreenTopBar: View {
    @EnvironmentObject var gameManager: GameManager
    let title: String
    var backTo: AppRoute = .mainMenu

    var body: some View {
        HStack {
            Button {
                HapticsService.shared.medium()
                AudioService.shared.playPop()
                gameManager.navigate(to: backTo)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.circle.fill").font(.system(size: 26))
                    Text("Back").font(.clay(17, .bold))
                }
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.9)))
            }
            Spacer()
            Text(title)
                .font(.clay(22, .heavy))
                .foregroundColor(DragonPalette.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}
