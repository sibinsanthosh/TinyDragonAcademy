//
//  ScreenTopBar.swift
//  Tiny Dragon Academy
//
//  Round clay back button, centered Baloo title and the star pill.
//  Tab roots have no back button: the tab bar is how you leave them.
//

import SwiftUI

struct ScreenTopBar: View {
    @EnvironmentObject var gameManager: GameManager
    let title: String
    var backTo: AppRoute = .mainMenu

    private var showsBack: Bool {
        !AppTab.isRoot(gameManager.currentRoute)
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.clay(24, .heavy))
                .foregroundColor(ClayColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 64)
            HStack {
                if showsBack {
                    ClayIconButton(systemName: "chevron.left", accessibilityLabel: "Back") {
                        gameManager.navigate(to: backTo)
                    }
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
                Spacer()
                StarCounterView(count: gameManager.totalStars)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
