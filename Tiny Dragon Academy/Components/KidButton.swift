//
//  KidButton.swift
//  Tiny Dragon Academy
//
//  Large, tactile, friendly buttons designed specifically for toddlers and young children.
//  Features 3D push-down feel, high-contrast icons, and accessibility.
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
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize + 2, weight: .bold))
                }
                Text(title)
                    .font(.clay(fontSize, .bold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(minWidth: minWidth, minHeight: minHeight)
            .background(
                ZStack {
                    // Deep bottom shadow for 3D pressable depth
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(backgroundColor.opacity(0.8))
                        .offset(y: isPressed ? 1 : 5)
                    
                    // Main button pill
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [backgroundColor, backgroundColor.opacity(0.92)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .offset(y: isPressed ? 4 : 0)
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isPressed)
        }
        .buttonStyle(KidPressButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(title)
    }
}

private struct KidPressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}
