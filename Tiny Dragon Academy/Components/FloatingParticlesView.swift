//
//  FloatingParticlesView.swift
//  Tiny Dragon Academy
//
//  Calming, gentle ambient sparkles, clouds, and stars floating in the background.
//

import SwiftUI

struct FloatingParticlesView: View {
    var particleCount: Int = 12
    var themeColor: Color = DragonPalette.softPurple
    
    @State private var animate: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { i in
                    ParticleItem(
                        index: i,
                        containerSize: geo.size,
                        color: (i % 2 == 0) ? themeColor.opacity(0.35) : DragonPalette.buttercup.opacity(0.4),
                        animate: animate
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}

private struct ParticleItem: View {
    let index: Int
    let containerSize: CGSize
    let color: Color
    let animate: Bool
    
    // Seeded pseudo-random coordinates
    private var startX: CGFloat {
        let normalized = CGFloat((index * 37) % 100) / 100.0
        return normalized * containerSize.width
    }
    
    private var startY: CGFloat {
        let normalized = CGFloat((index * 53) % 100) / 100.0
        return normalized * containerSize.height
    }
    
    private var particleSize: CGFloat {
        CGFloat(12 + (index * 7) % 16)
    }
    
    @State private var offsetDeltaX: CGFloat = 0
    @State private var offsetDeltaY: CGFloat = 0
    @State private var opacity: Double = 0.4
    
    var body: some View {
        Image(systemName: (index % 3 == 0) ? "sparkle" : (index % 3 == 1 ? "star.fill" : "circle.fill"))
            .font(.system(size: particleSize))
            .foregroundStyle(color)
            .position(x: startX + offsetDeltaX, y: startY + offsetDeltaY)
            .opacity(opacity)
            .onAppear {
                let duration = Double(3 + (index % 4) * 2)
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    offsetDeltaX = CGFloat((index % 2 == 0 ? 1 : -1) * 25)
                    offsetDeltaY = CGFloat((index % 2 == 0 ? -1 : 1) * 35)
                    opacity = 0.8
                }
            }
    }
}
