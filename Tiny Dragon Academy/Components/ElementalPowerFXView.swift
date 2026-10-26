//
//  ElementalPowerFXView.swift
//  Tiny Dragon Academy
//
//  Dynamic, particle-rich elemental animation canvas.
//  Renders spectacular Fire streams, Ice storms, Lightning bolts,
//  Laser beams, Earth seismic waves, and Starlight bursts.
//

import SwiftUI

struct ElementalPowerFXView: View {
    let power: ElementalPower
    let onFinished: () -> Void
    
    @State private var animProgress: CGFloat = 0.0
    @State private var beamPulse: CGFloat = 1.0
    @State private var shockwaveRadius: CGFloat = 0.0
    @State private var particles: [FXParticle] = []
    
    struct FXParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var scale: CGFloat
        var color: Color
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch power.animationStyle {
                case .flameBreath:
                    flameStream(in: geo.size)
                case .frostBlast:
                    frostTempest(in: geo.size)
                case .lightningBolt:
                    lightningArcs(in: geo.size)
                case .laserBeam:
                    laserCannon(in: geo.size)
                case .earthShockwave:
                    earthTremor(in: geo.size)
                case .starlightBurst, .bubbleStream, .petalWhirl:
                    starlightShow(in: geo.size)
                }
            }
            .onAppear {
                spawnParticles(for: geo.size)
                runFXTimeline()
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Flame Breath FX
    
    private func flameStream(in size: CGSize) -> some View {
        ZStack {
            // Roaring Fire Cone
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: 22 * p.scale, height: 22 * p.scale)
                    .blur(radius: 3)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
            
            // Core Plasma Burst
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color(red: 1.0, green: 0.85, blue: 0.2), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 60 * animProgress
                    )
                )
                .frame(width: 120 * animProgress, height: 120 * animProgress)
                .position(x: size.width * 0.5, y: size.height * 0.45)
        }
    }
    
    // MARK: - Frost Blast FX
    
    private func frostTempest(in size: CGSize) -> some View {
        ZStack {
            ForEach(particles) { p in
                Image(systemName: "snowflake")
                    .font(.system(size: 24 * p.scale))
                    .foregroundStyle(p.color)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(Double(animProgress * 360)))
            }
            
            // Subzero icy ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.7, green: 0.9, blue: 1.0), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 6
                )
                .frame(width: 200 * animProgress, height: 200 * animProgress)
                .position(x: size.width * 0.5, y: size.height * 0.45)
                .opacity(Double(1.0 - animProgress))
        }
    }
    
    // MARK: - Lightning Bolts FX
    
    private func lightningArcs(in size: CGSize) -> some View {
        ZStack {
            // Jagged electric bolt path
            Path { path in
                let start = CGPoint(x: size.width * 0.5, y: size.height * 0.35)
                path.move(to: start)
                path.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.45))
                path.addLine(to: CGPoint(x: size.width * 0.58, y: size.height * 0.52))
                path.addLine(to: CGPoint(x: size.width * 0.46, y: size.height * 0.62))
                path.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.75))
            }
            .stroke(
                LinearGradient(
                    colors: [Color.white, Color(red: 0.75, green: 0.55, blue: 1.0), Color(red: 0.4, green: 0.8, blue: 1.0)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: Color(red: 0.6, green: 0.3, blue: 1.0), radius: 12)
            .opacity(animProgress > 0.1 && animProgress < 0.85 ? 1.0 : 0.0)
            
            // Sparking electric particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: 14 * p.scale, height: 14 * p.scale)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
    }
    
    // MARK: - Laser Cannon FX
    
    private func laserCannon(in size: CGSize) -> some View {
        ZStack {
            // Glowing neon core laser beam
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.2, green: 0.95, blue: 0.75), Color(red: 0.95, green: 0.2, blue: 0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 22 * beamPulse, height: size.height * 0.65 * animProgress)
                .shadow(color: Color(red: 0.1, green: 0.95, blue: 0.7), radius: 14)
                .position(x: size.width * 0.5, y: size.height * 0.5)
            
            // Emitting energy rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color(red: 0.2, green: 0.95, blue: 0.75).opacity(0.8), lineWidth: 4)
                    .frame(width: (60 + CGFloat(i * 30)) * animProgress, height: (60 + CGFloat(i * 30)) * animProgress)
                    .position(x: size.width * 0.5, y: size.height * 0.38)
                    .opacity(Double(1.0 - animProgress))
            }
            
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: 12 * p.scale, height: 12 * p.scale)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
    }
    
    // MARK: - Earth Tremor FX
    
    private func earthTremor(in size: CGSize) -> some View {
        ZStack {
            // Ground ripple shockwaves
            ForEach(0..<3) { i in
                Ellipse()
                    .stroke(
                        Color(red: 0.65, green: 0.85, blue: 0.55).opacity(Double(1.0 - animProgress)),
                        lineWidth: 5
                    )
                    .frame(width: (120 + CGFloat(i * 60)) * animProgress, height: (60 + CGFloat(i * 30)) * animProgress)
                    .position(x: size.width * 0.5, y: size.height * 0.68)
            }
            
            // Bouncing boulder particles
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 6)
                    .fill(p.color)
                    .frame(width: 26 * p.scale, height: 22 * p.scale)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(Double(p.vx * 10)))
            }
        }
    }
    
    // MARK: - Starlight / Celestial FX
    
    private func starlightShow(in size: CGSize) -> some View {
        ZStack {
            ForEach(particles) { p in
                StarShape()
                    .fill(p.color)
                    .frame(width: 24 * p.scale, height: 24 * p.scale)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(Double(animProgress * 180)))
            }
        }
    }
    
    // MARK: - Particle Generation & Animation
    
    private func spawnParticles(for size: CGSize) {
        var generated: [FXParticle] = []
        let colors = particleColors(for: power.element)
        let count = 28
        
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...190)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed
            
            generated.append(
                FXParticle(
                    x: size.width * 0.5,
                    y: size.height * 0.45,
                    vx: vx,
                    vy: vy,
                    scale: CGFloat.random(in: 0.7...1.6),
                    color: colors.randomElement() ?? DragonPalette.buttercup,
                    opacity: 1.0
                )
            )
        }
        self.particles = generated
    }
    
    private func particleColors(for element: DragonElement) -> [Color] {
        switch element {
        case .fire:
            return [Color(red: 1.0, green: 0.35, blue: 0.15), Color(red: 1.0, green: 0.75, blue: 0.1), Color(red: 1.0, green: 0.95, blue: 0.5)]
        case .ice:
            return [Color.white, Color(red: 0.7, green: 0.92, blue: 1.0), Color(red: 0.45, green: 0.8, blue: 1.0)]
        case .lightning:
            return [Color.white, Color(red: 0.75, green: 0.55, blue: 1.0), Color(red: 0.4, green: 0.85, blue: 1.0)]
        case .laser:
            return [Color(red: 0.15, green: 0.95, blue: 0.75), Color(red: 0.95, green: 0.25, blue: 0.65), Color.white]
        case .earth:
            return [Color(red: 0.55, green: 0.78, blue: 0.5), Color(red: 0.78, green: 0.62, blue: 0.45), Color(red: 0.9, green: 0.82, blue: 0.5)]
        default:
            return [DragonPalette.softPurple, DragonPalette.buttercup, Color.white, DragonPalette.rosyPink]
        }
    }
    
    private func runFXTimeline() {
        withAnimation(.easeOut(duration: 1.4)) {
            animProgress = 1.0
            beamPulse = 1.4
            
            // Move particles outward
            for i in 0..<particles.count {
                particles[i].x += particles[i].vx * 1.3
                particles[i].y += particles[i].vy * 1.3
                particles[i].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onFinished()
        }
    }
}
