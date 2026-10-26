//
//  DragonView.swift
//  Tiny Dragon Academy
//
//  Richly animated procedural vector baby dragon view. Supports idle breathing,
//  happy bouncing, sleepy snoozing with Zzz bubbles, celebration dancing,
//  and tactile petting interactions with hearts.
//

import SwiftUI

struct DragonView: View {
    let dragon: DragonModel
    var mood: DragonMood = .idle
    var size: CGFloat = 200
    var stageOverride: GrowthStage? = nil
    var allowInteractivePetting: Bool = true
    var onPetted: (() -> Void)? = nil
    
    // Animation states
    @State private var breatheOffset: CGFloat = 0.0
    @State private var wingAngle: Double = 0.0
    @State private var isBlinking: Bool = false
    @State private var pettingHearts: [PetHeart] = []
    @State private var localMoodOverride: DragonMood? = nil
    @State private var bounceScale: CGFloat = 1.0
    @State private var chewMouthCycle: Bool = false
    @State private var chewHeadBob: CGFloat = 0.0
    @State private var cheeksPuff: CGFloat = 1.0
    @State private var ancientAuraRotation: Double = 0.0
    
    struct PetHeart: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double = 1.0
        var scale: CGFloat = 0.5
    }
    
    var activeStage: GrowthStage {
        stageOverride ?? dragon.stats.growthStage
    }
    
    private var activeMood: DragonMood {
        localMoodOverride ?? mood
    }
    
    var body: some View {
        ZStack {
            // ANCIENT / ADULT AURA LAYER
            auraLayer
            
            // BACK LAYER: Wings & Tail
            wingsLayer
            tailLayer
            
            // MIDDLE LAYER: Body, Belly, Legs, Horns, Face
            bodyLayer
            hornsLayer
            faceLayer
            
            // FRONT LAYER: Accessories (Hats, Spectacles, Capes, Scarves)
            accessoriesLayer
            
            // Interactive Mood FX (Zzz bubbles, hearts, sparkles)
            effectsLayer
        }
        .frame(width: size, height: size)
        .scaleEffect(bounceScale * activeStage.scaleMultiplier * 0.85)
        .offset(y: breatheOffset)
        .contentShape(Rectangle())
        .onTapGesture {
            if allowInteractivePetting {
                petDragon()
            }
        }
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: mood) { _, newMood in
            handleMoodChange(newMood)
        }
    }
    
    // MARK: - Elemental & Growth Aura
    
    @ViewBuilder
    private var auraLayer: some View {
        if activeStage == .ancient {
            // Radiant golden celestial halo
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [DragonPalette.buttercup, dragon.element.themeColor, DragonPalette.rosyPink, DragonPalette.buttercup],
                            center: .center
                        ),
                        lineWidth: 5
                    )
                    .frame(width: size * 0.95, height: size * 0.95)
                    .rotationEffect(.degrees(ancientAuraRotation))
                    .blur(radius: 2)
                
                ForEach(0..<8) { i in
                    StarShape()
                        .fill(DragonPalette.buttercup)
                        .frame(width: 14, height: 14)
                        .offset(y: -size * 0.48)
                        .rotationEffect(.degrees(Double(i) * 45 + ancientAuraRotation))
                }
            }
            .offset(y: -size * 0.05)
            .onAppear {
                withAnimation(Animation.linear(duration: 12.0).repeatForever(autoreverses: false)) {
                    ancientAuraRotation = 360.0
                }
            }
        } else if activeStage == .adult {
            // Soft elemental glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [dragon.element.themeColor.opacity(0.4), dragon.element.themeColor.opacity(0.0)],
                        center: .center,
                        startRadius: size * 0.25,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)
                .offset(y: -size * 0.05)
        }
    }
    
    // MARK: - Body & Anatomy Layers
    
    private var wingsLayer: some View {
        HStack(spacing: size * 0.42) {
            // Left Wing
            DragonWingShape(isFairy: dragon.wingStyle == .fairy || dragon.wingStyle == .crystal)
                .fill(
                    LinearGradient(
                        colors: [dragon.secondaryColor.opacity(0.85), dragon.primaryColor.opacity(0.75)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: size * 0.38, height: size * 0.38)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .rotationEffect(.degrees(-15 + wingAngle))
            
            // Right Wing
            DragonWingShape(isFairy: dragon.wingStyle == .fairy || dragon.wingStyle == .crystal)
                .fill(
                    LinearGradient(
                        colors: [dragon.secondaryColor.opacity(0.85), dragon.primaryColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.38, height: size * 0.38)
                .rotationEffect(.degrees(15 - wingAngle))
        }
        .offset(y: -size * 0.08)
    }
    
    private var tailLayer: some View {
        ZStack {
            // Tail Curve
            Path { path in
                path.move(to: CGPoint(x: size * 0.58, y: size * 0.72))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.88, y: size * 0.68),
                    control: CGPoint(x: size * 0.82, y: size * 0.82)
                )
            }
            .stroke(dragon.primaryColor, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
            
            // Tail Tip Ornament
            tailTipOrnament
                .position(x: size * 0.88, y: size * 0.65)
        }
    }
    
    @ViewBuilder
    private var tailTipOrnament: some View {
        switch dragon.tailStyle {
        case .spade:
            HeartShape()
                .fill(dragon.secondaryColor)
                .frame(width: size * 0.16, height: size * 0.16)
                .rotationEffect(.degrees(45))
        case .star:
            StarShape()
                .fill(DragonPalette.buttercup)
                .frame(width: size * 0.16, height: size * 0.16)
        case .flower:
            Image(systemName: "camera.macro")
                .font(.system(size: size * 0.16))
                .foregroundStyle(dragon.secondaryColor)
        case .cloud:
            Image(systemName: "cloud.fill")
                .font(.system(size: size * 0.18))
                .foregroundStyle(dragon.secondaryColor.opacity(0.9))
        case .gem:
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: size * 0.16))
                .foregroundStyle(dragon.secondaryColor)
        }
    }
    
    private var bodyLayer: some View {
        ZStack {
            // Spine Crest Spikes (Young, Adolescent, Adult, Ancient)
            if activeStage >= .young {
                HStack(spacing: size * 0.08) {
                    ForEach(0..<(activeStage == .young ? 2 : (activeStage == .adolescent ? 3 : 4)), id: \.self) { _ in
                        TriangleShape()
                            .fill(dragon.secondaryColor)
                            .frame(width: size * 0.08, height: size * 0.10)
                    }
                }
                .offset(y: -size * 0.32)
            }
            
            // Main chubby pear body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [dragon.primaryColor, dragon.primaryColor.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.58, height: size * 0.62)
                .offset(y: size * 0.12)
            
            // Soft belly patch
            Ellipse()
                .fill(dragon.bellyColor)
                .frame(width: size * 0.36, height: size * 0.44)
                .offset(y: size * 0.17)
            
            // Chest scale ridges for Adolescent, Adult, and Ancient
            if activeStage >= .adolescent {
                VStack(spacing: size * 0.06) {
                    Capsule().fill(dragon.secondaryColor.opacity(0.45)).frame(width: size * 0.22, height: 3)
                    Capsule().fill(dragon.secondaryColor.opacity(0.45)).frame(width: size * 0.26, height: 3)
                    Capsule().fill(dragon.secondaryColor.opacity(0.45)).frame(width: size * 0.20, height: 3)
                }
                .offset(y: size * 0.17)
            }
            
            // Feet / paws
            HStack(spacing: size * 0.22) {
                Circle()
                    .fill(dragon.secondaryColor)
                    .frame(width: size * 0.15, height: size * 0.13)
                Circle()
                    .fill(dragon.secondaryColor)
                    .frame(width: size * 0.15, height: size * 0.13)
            }
            .offset(y: size * 0.38)
            
            // Dragon Head
            Circle()
                .fill(dragon.primaryColor)
                .frame(width: size * 0.56, height: size * 0.54)
                .offset(y: -size * 0.14 + chewHeadBob)
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 3)
        }
    }
    
    private var hornsLayer: some View {
        HStack(spacing: size * 0.22) {
            // Left Horn
            hornShapeView
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .rotationEffect(.degrees(-20))
            
            // Right Horn
            hornShapeView
                .rotationEffect(.degrees(20))
        }
        .offset(y: -size * 0.38 + chewHeadBob)
    }
    
    @ViewBuilder
    private var hornShapeView: some View {
        switch dragon.hornStyle {
        case .curved:
            DragonHornShape(isCurved: true)
                .fill(dragon.secondaryColor)
                .frame(width: size * 0.12, height: size * 0.22)
        case .nubby:
            Capsule()
                .fill(dragon.secondaryColor)
                .frame(width: size * 0.1, height: size * 0.14)
        case .spiral:
            VStack(spacing: 1) {
                Capsule().fill(dragon.secondaryColor).frame(width: size * 0.08, height: size * 0.08)
                Capsule().fill(DragonPalette.buttercup).frame(width: size * 0.10, height: size * 0.07)
                Capsule().fill(dragon.secondaryColor).frame(width: size * 0.12, height: size * 0.07)
            }
        case .star:
            VStack(spacing: 0) {
                StarShape().fill(DragonPalette.buttercup).frame(width: size * 0.12, height: size * 0.12)
                Capsule().fill(dragon.secondaryColor).frame(width: size * 0.04, height: size * 0.10)
            }
        case .crown:
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.14))
                .foregroundStyle(DragonPalette.buttercup)
        }
    }
    
    private var faceLayer: some View {
        ZStack {
            // Eyes
            if activeMood == .sleepy {
                // Closed, snoozing eyes (arcs)
                HStack(spacing: size * 0.2) {
                    Circle()
                        .trim(from: 0.1, to: 0.5)
                        .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: size * 0.14, height: size * 0.14)
                    Circle()
                        .trim(from: 0.1, to: 0.5)
                        .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: size * 0.14, height: size * 0.14)
                }
                .offset(y: -size * 0.14)
            } else if activeMood == .eating {
                // Chewing delicious blissful eyes (happy closed crescents ⌒ ⌒)
                HStack(spacing: size * 0.18) {
                    Circle()
                        .trim(from: 0.55, to: 0.95)
                        .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: size * 0.13, height: size * 0.13)
                    Circle()
                        .trim(from: 0.55, to: 0.95)
                        .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: size * 0.13, height: size * 0.13)
                }
                .offset(y: -size * 0.14)
            } else if activeMood == .anticipatingFood {
                // Wide, excited sparkling anime eyes eager for snack
                HStack(spacing: size * 0.18) {
                    eyeView.scaleEffect(1.15)
                    eyeView.scaleEffect(1.15)
                }
                .offset(y: -size * 0.14)
            } else if isBlinking {
                // Blinking slit
                HStack(spacing: size * 0.2) {
                    Capsule().fill(DragonPalette.textDark).frame(width: size * 0.12, height: 3.5)
                    Capsule().fill(DragonPalette.textDark).frame(width: size * 0.12, height: 3.5)
                }
                .offset(y: -size * 0.14)
            } else {
                // Big Kawaii Anime Eyes with double highlights
                HStack(spacing: size * 0.18) {
                    eyeView
                    eyeView
                }
                .offset(y: -size * 0.14)
            }
            
            // Blushing Cheeks
            HStack(spacing: size * 0.32) {
                Ellipse()
                    .fill(DragonPalette.coral.opacity(activeMood == .eating || activeMood == .anticipatingFood ? 0.75 : 0.55))
                    .frame(width: size * 0.12, height: size * 0.07)
                    .scaleEffect(cheeksPuff)
                Ellipse()
                    .fill(DragonPalette.coral.opacity(activeMood == .eating || activeMood == .anticipatingFood ? 0.75 : 0.55))
                    .frame(width: size * 0.12, height: size * 0.07)
                    .scaleEffect(cheeksPuff)
            }
            .offset(y: -size * 0.08)
            
            // Friendly Smiling / Eating / Anticipating / Power-Casting Mouth
            if activeMood == .castingPower {
                // Roaring open mouth with glowing elemental light
                ZStack {
                    Ellipse()
                        .fill(dragon.element.themeColor)
                        .frame(width: size * 0.16, height: size * 0.12)
                    Ellipse()
                        .stroke(DragonPalette.textDark, lineWidth: 2.5)
                        .frame(width: size * 0.16, height: size * 0.12)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.08, height: size * 0.06)
                }
                .offset(y: -size * 0.06)
            } else if activeMood == .anticipatingFood {
                // Eager open "O" mouth waiting to be fed
                ZStack {
                    Ellipse()
                        .fill(DragonPalette.coral)
                        .frame(width: size * 0.12, height: size * 0.10)
                    Ellipse()
                        .stroke(DragonPalette.textDark, lineWidth: 2)
                        .frame(width: size * 0.12, height: size * 0.10)
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.52, blue: 0.65))
                        .frame(width: size * 0.07, height: size * 0.04)
                        .offset(y: size * 0.02)
                }
                .offset(y: -size * 0.065)
            } else if activeMood == .eating {
                // Chewing animated mouth with nom nom motion
                ZStack {
                    Ellipse()
                        .fill(DragonPalette.coral)
                        .frame(width: size * 0.11, height: chewMouthCycle ? size * 0.085 : size * 0.035)
                        .overlay(
                            Ellipse()
                                .stroke(DragonPalette.textDark, lineWidth: 2)
                        )
                    if chewMouthCycle {
                        Capsule()
                            .fill(Color(red: 1.0, green: 0.55, blue: 0.65))
                            .frame(width: size * 0.05, height: size * 0.03)
                            .offset(y: size * 0.015)
                    }
                }
                .offset(y: -size * 0.07)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                        chewMouthCycle = true
                    }
                }
            } else if activeMood == .happy || activeMood == .celebration {
                // Open joyful smile
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .fill(DragonPalette.coral)
                    .frame(width: size * 0.11, height: size * 0.08)
                    .overlay(
                        Circle()
                            .trim(from: 0.0, to: 0.5)
                            .stroke(DragonPalette.textDark, lineWidth: 2)
                    )
                .offset(y: -size * 0.07)
            } else {
                // Gentle closed smile
                Circle()
                    .trim(from: 0.05, to: 0.45)
                    .stroke(DragonPalette.textDark, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: size * 0.10, height: size * 0.08)
                    .offset(y: -size * 0.07)
            }
            
            // Cute tiny dragon nostrils
            HStack(spacing: size * 0.05) {
                Circle().fill(DragonPalette.textDark.opacity(0.4)).frame(width: 3, height: 3)
                Circle().fill(DragonPalette.textDark.opacity(0.4)).frame(width: 3, height: 3)
            }
            .offset(y: -size * 0.10)
        }
        .offset(y: chewHeadBob)
    }
    
    private var eyeView: some View {
        ZStack {
            // Eyeball
            Circle()
                .fill(DragonPalette.textDark)
                .frame(width: size * 0.14, height: size * 0.14)
            
            // Iris colored ring
            Circle()
                .fill(dragon.secondaryColor.opacity(0.5))
                .frame(width: size * 0.11, height: size * 0.11)
            
            // Specular Highlight 1 (large)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.05, height: size * 0.05)
                .offset(x: -size * 0.025, y: -size * 0.025)
            
            // Specular Highlight 2 (small)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.025, height: size * 0.025)
                .offset(x: size * 0.025, y: size * 0.02)
        }
    }
    
    // MARK: - Accessories Layer
    
    @ViewBuilder
    private var accessoriesLayer: some View {
        switch dragon.accessory {
        case .none:
            EmptyView()
        case .flowerCrown:
            HStack(spacing: -size * 0.02) {
                Image(systemName: "camera.macro").foregroundStyle(DragonPalette.rosyPink)
                Image(systemName: "camera.macro").foregroundStyle(DragonPalette.buttercup)
                Image(systemName: "camera.macro").foregroundStyle(DragonPalette.skyBlue)
                Image(systemName: "camera.macro").foregroundStyle(DragonPalette.lavender)
            }
            .font(.system(size: size * 0.12))
            .offset(y: -size * 0.32)
        case .royalTiara:
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.22))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DragonPalette.buttercup, Color.yellow],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Circle().fill(DragonPalette.rosyPink).frame(width: size * 0.04, height: size * 0.04).offset(y: -size * 0.02)
                )
                .offset(y: -size * 0.35)
        case .wizardHat:
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: size * 0.5, y: -size * 0.5))
                    path.addLine(to: CGPoint(x: size * 0.65, y: -size * 0.28))
                    path.addLine(to: CGPoint(x: size * 0.35, y: -size * 0.28))
                    path.closeSubpath()
                }
                .fill(DragonPalette.softPurple)
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: size * 0.08))
                    .foregroundStyle(DragonPalette.buttercup)
                    .offset(x: size * 0.02, y: -size * 0.38)
            }
        case .partyHat:
            Path { path in
                path.move(to: CGPoint(x: size * 0.5, y: -size * 0.48))
                path.addLine(to: CGPoint(x: size * 0.62, y: -size * 0.28))
                path.addLine(to: CGPoint(x: size * 0.38, y: -size * 0.28))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [DragonPalette.rosyPink, DragonPalette.buttercup, DragonPalette.skyBlue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Circle().fill(Color.white).frame(width: size * 0.06, height: size * 0.06).offset(y: -size * 0.49)
            )
        case .starGlasses:
            HStack(spacing: size * 0.06) {
                StarShape().fill(DragonPalette.buttercup).frame(width: size * 0.16, height: size * 0.16)
                Rectangle().fill(DragonPalette.buttercup).frame(width: size * 0.05, height: 3)
                StarShape().fill(DragonPalette.buttercup).frame(width: size * 0.16, height: size * 0.16)
            }
            .offset(y: -size * 0.14)
        case .heartGlasses:
            HStack(spacing: size * 0.06) {
                HeartShape().fill(DragonPalette.coral).frame(width: size * 0.16, height: size * 0.16)
                Rectangle().fill(DragonPalette.coral).frame(width: size * 0.05, height: 3)
                HeartShape().fill(DragonPalette.coral).frame(width: size * 0.16, height: size * 0.16)
            }
            .offset(y: -size * 0.14)
        case .leafScarf:
            Capsule()
                .fill(DragonPalette.mintGreen)
                .frame(width: size * 0.38, height: size * 0.10)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                )
                .offset(y: size * 0.05)
        case .magicCape:
            RoundedRectangle(cornerRadius: 12)
                .fill(DragonPalette.coral)
                .frame(width: size * 0.50, height: size * 0.40)
                .offset(y: size * 0.20)
                .zIndex(-1)
        case .warmBeanie:
            ZStack {
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .fill(DragonPalette.skyBlue)
                    .frame(width: size * 0.44, height: size * 0.38)
                    .offset(y: -size * 0.28)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(y: -size * 0.42)
            }
        }
    }
    
    // MARK: - Animated Mood Effects
    
    private var effectsLayer: some View {
        ZStack {
            // Snooze Zzz
            if activeMood == .sleepy {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("z").font(.system(size: size * 0.08, weight: .bold)).foregroundStyle(DragonPalette.softPurple)
                    Text("Z").font(.system(size: size * 0.11, weight: .bold)).foregroundStyle(DragonPalette.softPurple)
                    Text("Z").font(.system(size: size * 0.14, weight: .bold)).foregroundStyle(DragonPalette.softPurple)
                }
                .offset(x: size * 0.32, y: -size * 0.35)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Petting Hearts
            ForEach(pettingHearts) { heart in
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.14))
                    .foregroundStyle(DragonPalette.rosyPink)
                    .position(x: heart.x, y: heart.y)
                    .scaleEffect(heart.scale)
                    .opacity(heart.opacity)
            }
            
            // Celebration Sparkles
            if activeMood == .celebration {
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.20))
                    .foregroundStyle(DragonPalette.buttercup)
                    .offset(x: -size * 0.32, y: -size * 0.25)
                
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.15))
                    .foregroundStyle(DragonPalette.rosyPink)
                    .offset(x: size * 0.35, y: -size * 0.20)
            }
        }
    }
    
    // MARK: - Animations & Pet Interaction
    
    private func startIdleAnimations() {
        // Idle gentle breathing
        withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            breatheOffset = -size * 0.03
            wingAngle = 8.0
        }
        
        // Random cute blinking
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            guard activeMood != .sleepy else { return }
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isBlinking = false
                }
            }
        }
    }
    
    private func handleMoodChange(_ newMood: DragonMood) {
        switch newMood {
        case .anticipatingFood:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                bounceScale = 1.08
                cheeksPuff = 1.12
                chewHeadBob = -3.0
            }
        case .eating:
            withAnimation(Animation.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                chewHeadBob = 4.0
                chewMouthCycle = true
                cheeksPuff = 1.22
            }
        case .happy, .celebration:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                bounceScale = 1.15
                chewHeadBob = 0.0
                cheeksPuff = 1.0
                chewMouthCycle = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring()) {
                    bounceScale = 1.0
                }
            }
        default:
            withAnimation(.spring()) {
                bounceScale = 1.0
                chewHeadBob = 0.0
                cheeksPuff = 1.0
                chewMouthCycle = false
            }
        }
    }
    
    private func petDragon() {
        HapticsService.shared.medium()
        AudioService.shared.playDragonGiggle()
        
        // Trigger temporary happy mood
        localMoodOverride = .happy
        withAnimation(.spring(response: 0.28, dampingFraction: 0.4)) {
            bounceScale = 1.18
        }
        
        // Add floating heart
        let randomX = size * 0.5 + CGFloat.random(in: -size * 0.25...size * 0.25)
        let newHeart = PetHeart(x: randomX, y: size * 0.4)
        pettingHearts.append(newHeart)
        
        // Animate heart floating up and fading
        withAnimation(.easeOut(duration: 0.8)) {
            if let idx = pettingHearts.firstIndex(where: { $0.id == newHeart.id }) {
                pettingHearts[idx].y -= size * 0.45
                pettingHearts[idx].scale = 1.2
                pettingHearts[idx].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            pettingHearts.removeAll(where: { $0.id == newHeart.id })
            withAnimation(.spring()) {
                bounceScale = 1.0
                localMoodOverride = nil
            }
        }
        
        onPetted?()
    }
}
