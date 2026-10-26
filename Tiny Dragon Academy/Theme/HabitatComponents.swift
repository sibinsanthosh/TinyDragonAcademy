//
//  HabitatComponents.swift
//  Tiny Dragon Academy
//
//  Rich, offline vector environments that evolve alongside the dragon:
//  - Baby: Cozy Starlight Nest
//  - Young: Enchanted Blooming Garden
//  - Adolescent/Adult: Majestic Elemental Habitat
//  - Ancient: Legendary Ancient Lair
//

import SwiftUI

struct DragonHabitatContainerView<Content: View>: View {
    let stage: GrowthStage
    let element: DragonElement
    @ViewBuilder let content: () -> Content
    
    @State private var ambientFloat: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background Theme Gradient
            habitatGradient
                .ignoresSafeArea()
            
            // Ambient Elemental Sparkles / Mist
            FloatingParticlesView(particleCount: 18, themeColor: element.themeColor)
            
            // Habitat Terrain & Structure
            VStack {
                Spacer()
                
                ZStack {
                    switch stage {
                    case .baby:
                        babyNestBase
                    case .young:
                        youngGardenBase
                    case .adolescent, .adult:
                        adultElementalBase
                    case .ancient:
                        ancientLairBase
                    }
                    
                    // Main Central Dragon
                    content()
                        .offset(y: -40)
                }
                .offset(y: ambientFloat)
                
                Spacer().frame(height: 120)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                ambientFloat = -8.0
            }
        }
    }
    
    private var habitatGradient: LinearGradient {
        switch stage {
        case .baby:
            return DragonPalette.skyGradient
        case .young:
            return DragonPalette.meadowGradient
        case .adolescent, .adult:
            return LinearGradient(
                colors: [element.themeColor.opacity(0.4), DragonPalette.softPurple.opacity(0.3), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        case .ancient:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.12, blue: 0.35), element.themeColor.opacity(0.6), Color(red: 0.95, green: 0.88, blue: 0.70)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - 1. Baby Nest Base
    
    private var babyNestBase: some View {
        ZStack {
            // Woven Twig / Cloud Nest Shadow
            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: 330, height: 110)
                .offset(y: 55)
            
            // Soft Woven Cradle
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.86, green: 0.74, blue: 0.60), Color(red: 0.72, green: 0.58, blue: 0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 320, height: 100)
                .offset(y: 40)
            
            // Fluffy Cloud Cushion Inside Nest
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white, DragonPalette.cream],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 280, height: 80)
                .overlay(
                    Ellipse().stroke(DragonPalette.softPurple.opacity(0.3), lineWidth: 2)
                )
                .offset(y: 30)
            
            // Little stars decorating nest edge
            HStack(spacing: 80) {
                StarShape().fill(DragonPalette.buttercup).frame(width: 22, height: 22)
                StarShape().fill(DragonPalette.rosyPink).frame(width: 18, height: 18)
                StarShape().fill(DragonPalette.skyBlue).frame(width: 20, height: 20)
            }
            .offset(y: 65)
        }
    }
    
    // MARK: - 2. Young Garden Base
    
    private var youngGardenBase: some View {
        ZStack {
            // Earth Base
            Ellipse()
                .fill(Color(red: 0.60, green: 0.48, blue: 0.38))
                .frame(width: 340, height: 115)
                .offset(y: 60)
            
            // Blooming Green Lawn
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [DragonPalette.mintGreen, Color(red: 0.50, green: 0.85, blue: 0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 330, height: 95)
                .overlay(
                    Ellipse().stroke(Color.white.opacity(0.8), lineWidth: 3)
                )
                .offset(y: 35)
            
            // Flower patches & cute mushroom
            MushroomHouseView(size: 46)
                .offset(x: -115, y: 15)
            
            BlossomTreeView(size: 50)
                .offset(x: 115, y: 10)
        }
    }
    
    // MARK: - 3. Adult Elemental Base
    
    private var adultElementalBase: some View {
        ZStack {
            // Stone Terraced Citadel
            Ellipse()
                .fill(Color(red: 0.45, green: 0.48, blue: 0.55))
                .frame(width: 360, height: 125)
                .offset(y: 65)
            
            // Elemental Glowing Plateau
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [element.themeColor.opacity(0.8), element.themeColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 340, height: 100)
                .overlay(
                    Ellipse().stroke(Color.white, lineWidth: 3.5)
                )
                .offset(y: 35)
            
            // Elemental Spire Crystals Left & Right
            HStack(spacing: 230) {
                elementalSpire
                elementalSpire
            }
            .offset(y: 0)
        }
    }
    
    private var elementalSpire: some View {
        VStack(spacing: 2) {
            Image(systemName: element.iconName)
                .font(.system(size: 20))
                .foregroundStyle(Color.white)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color.white, element.themeColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14, height: 45)
        }
        .shadow(color: element.themeColor, radius: 8)
    }
    
    // MARK: - 4. Ancient Lair Base
    
    private var ancientLairBase: some View {
        ZStack {
            // Celestial Gold Base
            Ellipse()
                .fill(Color(red: 0.25, green: 0.20, blue: 0.40))
                .frame(width: 380, height: 135)
                .offset(y: 70)
            
            // Radiant Golden Obsidian Dais
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [DragonPalette.buttercup, Color(red: 0.95, green: 0.75, blue: 0.30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 360, height: 105)
                .overlay(
                    Ellipse().stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: DragonPalette.buttercup.opacity(0.8), radius: 15)
                .offset(y: 35)
            
            // Ancient Runic Pillars
            HStack(spacing: 260) {
                ancientRunePillar
                ancientRunePillar
            }
            .offset(y: -15)
        }
    }
    
    private var ancientRunePillar: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(DragonPalette.buttercup)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white)
                )
            
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.white, DragonPalette.softPurple],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: 75)
                .overlay(
                    VStack(spacing: 6) {
                        Circle().fill(DragonPalette.buttercup).frame(width: 4, height: 4)
                        Circle().fill(DragonPalette.buttercup).frame(width: 4, height: 4)
                        Circle().fill(DragonPalette.buttercup).frame(width: 4, height: 4)
                    }
                )
        }
        .shadow(color: DragonPalette.buttercup, radius: 10)
    }
}
