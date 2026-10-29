//
//  DragonPalette.swift
//  Tiny Dragon Academy
//
//  Design tokens, pastel palettes, typography, and styling for children aged 3-7.
//

import SwiftUI

enum DragonPalette {
    // Primary Pastel Hues
    static let lavender = Color(red: 0.82, green: 0.78, blue: 0.96)
    static let skyBlue = ClayColor.sky
    static let mintGreen = ClayColor.mint
    static let peach = Color(red: 1.0, green: 0.80, blue: 0.72)
    static let buttercup = ClayColor.sun
    static let rosyPink = ClayColor.rose
    static let cream = Color(red: 0.99, green: 0.98, blue: 0.93)
    static let softPurple = ClayColor.accent
    static let coral = ClayColor.coral
    static let turquoise = Color(red: 0.52, green: 0.86, blue: 0.84)
    /// Deeper gold for star ratings, readable on white cards.
    static let starGold = Color(red: 0.92, green: 0.60, blue: 0.08)
    
    // Background Gradients
    static let skyGradient = LinearGradient(
        colors: [ClayColor.backdropTop, ClayColor.backdropBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let sunsetGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.80, blue: 0.75), Color(red: 0.92, green: 0.75, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let meadowGradient = LinearGradient(
        colors: [Color(red: 0.72, green: 0.93, blue: 0.85), Color(red: 0.88, green: 0.96, blue: 0.80)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let nightGradient = LinearGradient(
        colors: [Color(red: 0.22, green: 0.24, blue: 0.45), Color(red: 0.45, green: 0.38, blue: 0.62)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardBackground = ClayColor.surface
    static let textDark = ClayColor.ink
    static let textMuted = ClayColor.inkSoft
    
    // Shadow definitions
    static let softShadow = Color.black.opacity(0.08)
    static let popShadow = ClayColor.shadow
}

// Custom ViewModifier for playful, tactile kid-friendly buttons and cards
struct KidCardStyle: ViewModifier {
    var backgroundColor: Color = DragonPalette.cardBackground
    var cornerRadius: CGFloat = 26
    var borderColor: Color = Color.white
    var borderWidth: CGFloat = 3
    var shadowRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(color: DragonPalette.popShadow, radius: shadowRadius, x: 0, y: 6)
            )
    }
}

extension View {
    func kidCard(
        background: Color = DragonPalette.cardBackground,
        cornerRadius: CGFloat = 26,
        borderColor: Color = .white,
        borderWidth: CGFloat = 3,
        shadowRadius: CGFloat = 10
    ) -> some View {
        self.modifier(KidCardStyle(
            backgroundColor: background,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth,
            shadowRadius: shadowRadius
        ))
    }
}
