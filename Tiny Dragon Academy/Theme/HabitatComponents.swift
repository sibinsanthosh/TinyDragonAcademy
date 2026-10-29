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
            // Clay backdrop, tinted by stage
            ClayBackdrop()
            habitatTint
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
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
    
    /// Older dragons get a light wash of their element; ancient ones a dusky glow.
    @ViewBuilder
    private var habitatTint: some View {
        switch stage {
        case .baby, .young:
            Color.clear
        case .adolescent, .adult:
            LinearGradient(colors: [element.themeColor.opacity(0.22), .clear], startPoint: .top, endPoint: .center)
        case .ancient:
            LinearGradient(colors: [Color(red: 0.30, green: 0.22, blue: 0.50).opacity(0.35), .clear], startPoint: .top, endPoint: .center)
        }
    }

    // MARK: - 1. Baby Nest Base
    
    private var babyNestBase: some View {
        ZStack {
            ClayPlatform(top: Color(red: 0.93, green: 0.88, blue: 1.0), side: Color(red: 0.76, green: 0.68, blue: 0.96), width: 300)
                .offset(y: 40)
            // Little stars decorating the cushion edge
            HStack(spacing: 80) {
                StarShape().fill(ClayColor.sun).frame(width: 22, height: 22)
                StarShape().fill(ClayColor.rose).frame(width: 18, height: 18)
                StarShape().fill(ClayColor.sky).frame(width: 20, height: 20)
            }
            .offset(y: 70)
        }
    }
    
    // MARK: - 2. Young Garden Base
    
    private var youngGardenBase: some View {
        ZStack {
            ClayPlatform(top: Color(red: 0.62, green: 0.90, blue: 0.66), side: Color(red: 0.42, green: 0.79, blue: 0.48), width: 320)
                .offset(y: 40)
            
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
            ClayPlatform(top: element.themeColor.opacity(0.75), side: element.themeColor, width: 330)
                .offset(y: 40)
            
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
            ClayPlatform(top: ClayColor.sun, side: ClayColor.sunShade, width: 340)
                .shadow(color: ClayColor.sun.opacity(0.6), radius: 14)
                .offset(y: 40)
            
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

/// A puffy clay disc: a light, softly shaded top over a darker side band.
struct ClayPlatform: View {
    let top: Color
    let side: Color
    var width: CGFloat = 300

    var body: some View {
        let height = width * 0.3
        ZStack {
            Ellipse()
                .fill(ClayColor.shadow)
                .frame(width: width * 1.02, height: height)
                .offset(y: height * 0.42)
            Ellipse()
                .fill(side)
                .frame(width: width, height: height)
                .offset(y: height * 0.22)
            Ellipse()
                .fill(
                    RadialGradient(colors: [Color.white.opacity(0.55), top], center: UnitPoint(x: 0.4, y: 0.25), startRadius: 4, endRadius: width * 0.55)
                )
                .background(Ellipse().fill(top))
                .frame(width: width, height: height)
        }
        .allowsHitTesting(false)
    }
}
