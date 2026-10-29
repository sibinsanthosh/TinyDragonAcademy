//
//  ClayCelebration.swift
//  Tiny Dragon Academy
//
//  Celebration effects: falling clay confetti and a number that counts up.
//

import SwiftUI

/// Clay confetti that falls once across its frame. Skipped when motion is reduced.
struct ConfettiView: View {
    var pieceCount: Int = 42
    @State private var fallen = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @EnvironmentObject private var gameManager: GameManager

    private var reduceMotion: Bool { systemReduceMotion || gameManager.state.settings.reduceMotion }

    private static let colors: [Color] = [ClayColor.accent, ClayColor.sun, ClayColor.coral, ClayColor.mint, ClayColor.sky, ClayColor.rose]

    var body: some View {
        GeometryReader { geo in
            if !reduceMotion {
                ForEach(0..<pieceCount, id: \.self) { i in
                    let x = CGFloat((i * 37) % 100) / 100 * geo.size.width
                    let drift = CGFloat((i * 53) % 60) - 30
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Self.colors[i % Self.colors.count])
                        .frame(width: i.isMultiple(of: 3) ? 10 : 8, height: i.isMultiple(of: 2) ? 14 : 9)
                        .rotationEffect(.degrees(fallen ? Double(i * 47 % 360) + 360 : 0))
                        .position(x: x + (fallen ? drift : 0),
                                  y: fallen ? geo.size.height + 40 : -20 - CGFloat(i % 7) * 18)
                        .opacity(fallen ? 0 : 1)
                        .animation(.easeIn(duration: 1.8 + Double(i % 5) * 0.2).delay(Double(i % 6) * 0.05), value: fallen)
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear { fallen = true }
    }
}

/// A whole number that animates from its previous value to `value`.
struct CountUpText: View, Animatable {
    var value: Double
    var font: Font = .clay(56, .heavy)
    var color: Color = ClayColor.ink

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value.rounded()))")
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
    }
}
