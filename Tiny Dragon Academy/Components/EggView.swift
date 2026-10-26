//
//  EggView.swift
//  Tiny Dragon Academy
//
//  Magical dragon egg with multi-stage cracking, glowing particles,
//  shaking animations, and celebration reveal.
//

import SwiftUI

struct EggView: View {
    let eggColor: Color
    let spotColor: Color
    var crackStage: Int // 0: pristine, 1: small crack, 2: medium crack, 3: ready to hatch
    var size: CGFloat = 180
    var onTap: (() -> Void)? = nil
    
    @State private var wobbleAngle: Double = 0
    @State private var isGlowPulsing: Bool = false
    
    var body: some View {
        ZStack {
            // Glowing background aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [eggColor.opacity(0.55), Color.clear],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.75
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(isGlowPulsing ? 1.15 : 0.95)
            
            // Dragon Egg Body
            EggShape()
                .fill(
                    LinearGradient(
                        colors: [eggColor.opacity(0.9), eggColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.82, height: size)
                .overlay(
                    // Egg decorative pastel spots
                    ZStack {
                        Circle()
                            .fill(spotColor.opacity(0.8))
                            .frame(width: size * 0.18, height: size * 0.18)
                            .offset(x: -size * 0.15, y: -size * 0.1)
                        
                        Circle()
                            .fill(spotColor.opacity(0.75))
                            .frame(width: size * 0.22, height: size * 0.22)
                            .offset(x: size * 0.16, y: size * 0.12)
                        
                        Circle()
                            .fill(spotColor.opacity(0.7))
                            .frame(width: size * 0.14, height: size * 0.14)
                            .offset(x: -size * 0.08, y: size * 0.25)
                        
                        // Egg highlight
                        Ellipse()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: size * 0.15, height: size * 0.35)
                            .rotationEffect(.degrees(-25))
                            .offset(x: -size * 0.2, y: -size * 0.15)
                    }
                )
                .overlay(
                    // Cracks overlay based on stage
                    cracksOverlay
                )
                .shadow(color: DragonPalette.softShadow, radius: 10, x: 0, y: 8)
                .rotationEffect(.degrees(wobbleAngle))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            triggerTapAnimation()
            onTap?()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isGlowPulsing = true
            }
        }
    }
    
    @ViewBuilder
    private var cracksOverlay: some View {
        if crackStage >= 1 {
            // First crack line
            Path { path in
                path.move(to: CGPoint(x: size * 0.41, y: size * 0.35))
                path.addLine(to: CGPoint(x: size * 0.46, y: size * 0.45))
                path.addLine(to: CGPoint(x: size * 0.38, y: size * 0.52))
            }
            .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        
        if crackStage >= 2 {
            // Additional branch cracks
            Path { path in
                path.move(to: CGPoint(x: size * 0.46, y: size * 0.45))
                path.addLine(to: CGPoint(x: size * 0.58, y: size * 0.42))
                path.addLine(to: CGPoint(x: size * 0.52, y: size * 0.58))
                
                path.move(to: CGPoint(x: size * 0.38, y: size * 0.52))
                path.addLine(to: CGPoint(x: size * 0.32, y: size * 0.65))
            }
            .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
        }
        
        if crackStage >= 3 {
            // Glowing light seeping through wide fissures
            Path { path in
                path.move(to: CGPoint(x: size * 0.25, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.65, y: size * 0.48))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            .shadow(color: DragonPalette.buttercup, radius: 8)
        }
    }
    
    private func triggerTapAnimation() {
        // Dramatic wobble when tapped
        let intensity = Double(crackStage + 1) * 6.0
        withAnimation(.spring(response: 0.15, dampingFraction: 0.25)) {
            wobbleAngle = intensity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.25)) {
                wobbleAngle = -intensity
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring()) {
                wobbleAngle = 0
            }
        }
    }
}
