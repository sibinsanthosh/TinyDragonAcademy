//
//  ClayComponents.swift
//  Tiny Dragon Academy
//
//  Toy Clay building blocks: the soft backdrop, puffy surfaces and
//  buttons, pills, round icon buttons and meters every screen is made of.
//

import SwiftUI

/// The warm pink-to-sky backdrop with two soft blobs, behind every non-game screen.
struct ClayBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [ClayColor.backdropTop, ClayColor.backdropBottom], startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(ClayColor.blobPink)
                    .frame(width: geo.size.width * 0.75)
                    .position(x: geo.size.width * 0.05, y: geo.size.height * 0.32)
                Circle()
                    .fill(ClayColor.blobSky)
                    .frame(width: geo.size.width * 0.62)
                    .position(x: geo.size.width * 1.0, y: geo.size.height * 0.16)
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: geo.size.width * 0.5)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.82)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// White clay surface: soft plum drop shadow, a darker inner bottom edge and a light top edge.
struct ClaySurface: ViewModifier {
    var cornerRadius: CGFloat = 22
    var fill: Color = ClayColor.surface
    var elevation: CGFloat = 1

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    fill
                        .shadow(.inner(color: ClayColor.innerShade, radius: 0.5, x: 0, y: -5))
                        .shadow(.inner(color: Color.white.opacity(0.7), radius: 0, x: 0, y: 2))
                )
                .shadow(color: ClayColor.shadow, radius: 14 * elevation, x: 0, y: 6 * elevation)
        )
    }
}

extension View {
    func claySurface(cornerRadius: CGFloat = 22, fill: Color = ClayColor.surface, elevation: CGFloat = 1) -> some View {
        modifier(ClaySurface(cornerRadius: cornerRadius, fill: fill, elevation: elevation))
    }
}

/// Puffy coloured button that squishes when pressed.
struct ClayButtonStyle: ButtonStyle {
    var color: Color = ClayColor.accent
    var cornerRadius: CGFloat = 24
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        color
                            .shadow(.inner(color: Color.black.opacity(0.18), radius: 0.5, x: 0, y: -6))
                            .shadow(.inner(color: Color.white.opacity(0.38), radius: 0, x: 0, y: 3))
                    )
                    .shadow(color: color.opacity(configuration.isPressed ? 0.18 : 0.35), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 3 : 8)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(isEnabled ? 1 : 0.55)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Puffy white button for secondary actions.
struct ClaySecondaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(ClayColor.ink)
            .claySurface(cornerRadius: cornerRadius, elevation: configuration.isPressed ? 0.4 : 0.8)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Round clay button with an icon: back, close, settings and care actions.
struct ClayIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = ClayColor.ink
    var fill: Color = ClayColor.surface
    var badge: Int = 0
    var accessibilityLabel: String = ""
    let action: () -> Void

    var body: some View {
        Button {
            HapticsService.shared.light()
            AudioService.shared.playPop()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.clay(11, .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Capsule().fill(ClayColor.coral))
                            .offset(x: 6, y: -6)
                    }
                }
        }
        .buttonStyle(ClayRoundStyle(fill: fill, size: size))
        .accessibilityLabel(accessibilityLabel.isEmpty ? systemName : accessibilityLabel)
    }
}

private struct ClayRoundStyle: ButtonStyle {
    let fill: Color
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .claySurface(cornerRadius: size * 0.36, fill: fill, elevation: configuration.isPressed ? 0.4 : 0.8)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Icon and number on a small clay surface; bumps when the value changes.
struct ClayPill: View {
    let systemName: String
    let iconColor: Color
    let value: String
    var accessibilityLabel: String = ""

    @State private var bump: CGFloat = 1

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(iconColor)
            Text(value)
                .font(.clay(16, .heavy))
                .foregroundColor(ClayColor.ink)
                .monospacedDigit()
        }
        .padding(.leading, 9)
        .padding(.trailing, 12)
        .frame(height: 34)
        .claySurface(cornerRadius: 17, elevation: 0.7)
        .scaleEffect(bump)
        .onChange(of: value) { _, _ in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { bump = 1.15 }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) { bump = 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel.isEmpty ? value : "\(accessibilityLabel) \(value)")
    }
}

/// Inset white track with a rounded coloured fill (0…100).
struct ClayMeter: View {
    let value: Double
    let color: Color
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.shadow(.inner(color: Color.black.opacity(0.12), radius: 1.5, x: 0, y: 1.5)))
                Capsule()
                    .fill(color.shadow(.inner(color: Color.white.opacity(0.35), radius: 0, x: 0, y: 2)))
                    .frame(width: max(height, geo.size.width * min(max(value, 0), 100) / 100))
                    .opacity(value <= 0 ? 0 : 1)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
    }
}

/// A rounded-top clay panel used for sheets and pop-ups.
struct ClayPanel<Content: View>: View {
    var cornerRadius: CGFloat = 30
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .claySurface(cornerRadius: cornerRadius, elevation: 1.4)
    }
}

/// Something to buy with stars: shows the price, or how many stars are still needed.
struct ClayUnlockRow: View {
    let title: String
    let detail: String
    let price: Int
    let stars: Int
    let action: () -> Void

    private var affordable: Bool { stars >= price }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: affordable ? "plus.circle.fill" : "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(affordable ? ClayColor.accent : ClayColor.inkSoft)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.clay(16, .heavy))
                    .foregroundColor(ClayColor.ink)
                Text(affordable ? detail : "\(price - stars)★ more to unlock")
                    .font(.clay(13, .bold))
                    .foregroundColor(ClayColor.inkSoft)
            }
            Spacer()
            Button {
                HapticsService.shared.medium()
                action()
            } label: {
                Text("\(price)★")
                    .font(.clay(16, .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 9)
            }
            .buttonStyle(ClayButtonStyle(color: ClayColor.accent, cornerRadius: 16))
            .disabled(!affordable)
        }
        .padding(14)
        .claySurface(cornerRadius: 22)
    }
}

/// A row of clay tabs for switching sections within a screen.
struct ClaySegmented<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isOn = option == selection
                Button {
                    HapticsService.shared.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.clay(14, .heavy))
                        .foregroundColor(isOn ? .white : ClayColor.inkSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            Capsule()
                                .fill(ClayColor.accent.shadow(.inner(color: Color.black.opacity(0.15), radius: 0, x: 0, y: -3)))
                                .opacity(isOn ? 1 : 0)
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(5)
        .claySurface(cornerRadius: 100, elevation: 0.7)
    }
}
