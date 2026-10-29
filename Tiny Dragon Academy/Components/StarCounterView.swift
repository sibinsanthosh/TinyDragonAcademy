//
//  StarCounterView.swift
//  Tiny Dragon Academy
//
//  Display badge for collected stars with bouncing animation and sparkle icon.
//

import SwiftUI

struct StarCounterView: View {
    let count: Int
    var isInteractive: Bool = false
    var onTap: (() -> Void)? = nil
    
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            if isInteractive {
                HapticsService.shared.light()
                AudioService.shared.playChime()
                onTap?()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DragonPalette.buttercup, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.yellow.opacity(0.5), radius: 4)
                
                Text("\(count)")
                    .font(.clay(20, .bold))
                    .foregroundColor(DragonPalette.textDark)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.92))
                    .overlay(Capsule().stroke(DragonPalette.buttercup.opacity(0.8), lineWidth: 2))
                    .shadow(color: DragonPalette.softShadow, radius: 6, x: 0, y: 3)
            )
            .scaleEffect(bounceScale)
        }
        .disabled(!isInteractive)
        .onChange(of: count) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                bounceScale = 1.25
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) {
                    bounceScale = 1.0
                }
            }
        }
    }
}
