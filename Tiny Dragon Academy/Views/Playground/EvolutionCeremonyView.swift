//
//  EvolutionCeremonyView.swift
//  Tiny Dragon Academy
//
//  Full-screen celebratory evolution ceremony revealing the dragon's
//  next growth stage, larger appearance, and newly awakened elemental power.
//

import SwiftUI

struct EvolutionCeremonyView: View {
    let dragon: DragonModel
    let onEvolveConfirmed: () -> Void
    let onDismiss: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var confettiOffset: CGFloat = 0.0
    
    var currentStage: GrowthStage {
        dragon.stats.growthStage
    }
    
    var nextStage: GrowthStage? {
        currentStage.nextStage
    }
    
    var nextPower: ElementalPower? {
        guard let next = nextStage else { return nil }
        let catalog = ElementalPowersCatalog.powers(for: dragon.element)
        return catalog.first(where: { $0.stageRequired == next })
    }
    
    var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
            
            // Sparkle Particle Background
            FloatingParticlesView(particleCount: 22, themeColor: DragonPalette.buttercup)
            
            VStack(spacing: 20) {
                // Celebration Title
                VStack(spacing: 6) {
                    Text("✨ Time to Evolve! ✨")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.buttercup)
                    
                    Text("\(dragon.name) is ready to grow into a \(nextStage?.rawValue ?? "Legend")!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                // Dragon Preview in New Stage
                if let next = nextStage {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [dragon.element.themeColor.opacity(0.4), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 110
                                )
                            )
                            .frame(width: 220, height: 220)
                            .scaleEffect(pulseScale)
                        
                        DragonView(
                            dragon: dragon,
                            mood: .celebration,
                            size: 180,
                            stageOverride: next,
                            allowInteractivePetting: false
                        )
                    }
                    .frame(height: 200)
                }
                
                // Stage Benefits Card
                VStack(spacing: 8) {
                    if let power = nextPower {
                        HStack(spacing: 10) {
                            Image(systemName: power.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(dragon.element.themeColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("New Power: \(power.name)")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(DragonPalette.textDark)
                                Text(power.description)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(DragonPalette.textMuted)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(DragonPalette.buttercup)
                        Text("+15 Celebration Stars Bonus!")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.coral)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.95))
                )
                .padding(.horizontal, 16)
                
                // Evolve Action Button
                KidButton(title: "Evolve Now! 🌟", backgroundColor: DragonPalette.coral) {
                    onEvolveConfirmed()
                }
                .padding(.horizontal, 24)
                
                // Cancel
                Button(action: onDismiss) {
                    Text("Not Yet")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.16, green: 0.12, blue: 0.28), Color(red: 0.26, green: 0.18, blue: 0.42)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(DragonPalette.buttercup.opacity(0.6), lineWidth: 3)
                    )
                    .shadow(color: DragonPalette.buttercup.opacity(0.4), radius: 20)
            )
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}
