//
//  ClayTabBar.swift
//  Tiny Dragon Academy
//
//  The floating white tab bar shown on the five tab screens.
//

import SwiftUI

struct ClayTabBar: View {
    @EnvironmentObject var gameManager: GameManager

    private var selected: AppTab? { AppTab.forRoute(gameManager.currentRoute) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 66)
        .claySurface(cornerRadius: 28, elevation: 1.2)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isOn = selected == tab
        return Button {
            guard !isOn else { return }
            HapticsService.shared.light()
            AudioService.shared.playPop()
            gameManager.navigate(to: tab.root)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 21, weight: .bold))
                    .frame(width: 46, height: 30)
                    .background(
                        Capsule()
                            .fill(ClayColor.accent.opacity(0.14))
                            .opacity(isOn ? 1 : 0)
                    )
                    .overlay(alignment: .topTrailing) {
                        let badge = badgeCount(tab)
                        if badge > 0 {
                            Text("\(badge)")
                                .font(.clay(11, .heavy))
                                .foregroundColor(.white)
                                .frame(minWidth: 17, minHeight: 17)
                                .background(Circle().fill(ClayColor.coral))
                                .offset(x: 4, y: -4)
                        }
                    }
                Text(tab.title)
                    .font(.clay(12, .bold))
            }
            .foregroundColor(isOn ? ClayColor.accent : ClayColor.inkSoft)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    /// Eggs ready to hatch show on the Eggs tab.
    private func badgeCount(_ tab: AppTab) -> Int {
        tab == .eggs ? gameManager.state.incubatorSlots.filter(\.isReady).count : 0
    }
}
