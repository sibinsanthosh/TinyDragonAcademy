//
//  KidButton.swift
//  Tiny Dragon Academy
//
//  The main call-to-action button: a big puffy clay button that squishes
//  when pressed. Light backgrounds get plum text so the label stays readable.
//

import SwiftUI

struct KidButton: View {
    let title: String
    var icon: String? = nil
    var backgroundColor: Color = DragonPalette.softPurple
    var foregroundColor: Color = .white
    var minWidth: CGFloat = 160
    var minHeight: CGFloat = 58
    var fontSize: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize, weight: .heavy))
                }
                Text(title)
                    .font(.clay(fontSize + 2, .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(labelColor)
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .frame(minWidth: minWidth, minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(ClayButtonStyle(color: backgroundColor, cornerRadius: minHeight * 0.42))
        .accessibilityLabel(title)
    }

    private var labelColor: Color {
        foregroundColor == .white && backgroundColor.isLightClay ? ClayColor.ink : foregroundColor
    }
}

extension Color {
    /// True for light fills (sun, mint, sky, coral) where white text would be hard to read.
    var isLightClay: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return false }
        return 0.299 * r + 0.587 * g + 0.114 * b > 0.6
    }
}
