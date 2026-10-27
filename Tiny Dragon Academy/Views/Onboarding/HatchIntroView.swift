//
//  HatchIntroView.swift
//  Tiny Dragon Academy
//
//  Delightful onboarding experience introducing the dragon world and
//  letting the child tap to hatch their very first baby dragon.
//

import SwiftUI

struct HatchIntroView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var step: Int = 0 // 0: story intro, 1: egg tapping, 2: hatched dragon & naming
    @State private var eggCrackStage: Int = 0
    @State private var isHatched: Bool = false
    @State private var chosenName: String = "Sparkle"
    @State private var celebrationConfetti: Bool = false
    @State private var showParentGate: Bool = false
    
    private let presetNames = ["Sparkle", "Puff", "Bubbles", "Twinkle", "Sunny", "Pip"]
    
    var body: some View {
        ZStack {
            // Background
            DragonPalette.skyGradient
                .ignoresSafeArea()
            
            FloatingParticlesView(particleCount: 14, themeColor: DragonPalette.softPurple)
            
            VStack {
                Spacer()
                
                if step == 0 {
                    storyIntroStep
                        .transition(.scale.combined(with: .opacity))
                } else if step == 1 {
                    eggHatchingStep
                        .transition(.scale.combined(with: .opacity))
                } else if step == 2 {
                    namingAndWelcomeStep
                        .transition(.scale.combined(with: .opacity))
                } else {
                    careModeStep
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            if showParentGate {
                ParentGateView(
                    onSuccess: {
                        showParentGate = false
                        finishOnboarding(.classic)
                    },
                    onCancel: { showParentGate = false }
                )
            }
        }
    }
    
    // MARK: - Step 3: Care Mode
    
    private var finalName: String {
        chosenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sparkle" : chosenName
    }
    
    private func finishOnboarding(_ mode: CareMode) {
        gameManager.completeOnboarding(starterDragonName: finalName, careMode: mode)
    }
    
    private var careModeStep: some View {
        VStack(spacing: 16) {
            Text("Who's raising \(finalName)?")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .multilineTextAlignment(.center)
            
            careModeCard(
                title: "Little ones",
                subtitle: "Gentle mode. \(finalName) gets hungry and sleepy but always waits for you.",
                icon: "heart.circle.fill",
                color: DragonPalette.mintGreen
            ) { finishOnboarding(.gentle) }
            
            careModeCard(
                title: "Big kids & grown-ups",
                subtitle: "Classic mode. Real stakes: neglected dragons can become spirits. A grown-up confirms this.",
                icon: "flame.circle.fill",
                color: DragonPalette.coral
            ) { showParentGate = true }
            
            Text("A grown-up can change this later in Settings.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(DragonPalette.textMuted)
        }
        .padding(24)
        .kidCard()
    }
    
    private func careModeCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(DragonPalette.textMuted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(color.opacity(0.15)))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.6), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 0: Welcome Story
    
    private var storyIntroStep: some View {
        VStack(spacing: 24) {
            // Academy Crest
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 130, height: 130)
                    .shadow(color: DragonPalette.popShadow, radius: 10, x: 0, y: 5)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DragonPalette.softPurple, DragonPalette.rosyPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Tiny Dragon Academy")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                    .multilineTextAlignment(.center)
                
                Text("A magical island where friendly baby dragons play, learn, and grow!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            KidButton(
                title: "Find My Dragon Egg!",
                icon: "sparkles",
                backgroundColor: DragonPalette.softPurple,
                minWidth: 260
            ) {
                withAnimation(.spring()) {
                    step = 1
                }
            }
            .padding(.top, 16)
        }
        .padding(32)
        .kidCard()
    }
    
    // MARK: - Step 1: Interactive Egg Hatching
    
    private var eggHatchingStep: some View {
        VStack(spacing: 24) {
            // Visual Hint Prompt
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DragonPalette.softPurple)
                Text(eggPromptText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white.opacity(0.9)))
            
            // Nest and Egg
            ZStack {
                // Nest
                Ellipse()
                    .fill(Color(red: 0.85, green: 0.72, blue: 0.55))
                    .frame(width: 220, height: 70)
                    .overlay(
                        Ellipse()
                            .stroke(Color(red: 0.75, green: 0.60, blue: 0.45), lineWidth: 3)
                    )
                    .offset(y: 80)
                
                // Baby Dragon or Egg
                if isHatched {
                    DragonView(
                        dragon: gameManager.activeDragon,
                        mood: .celebration,
                        size: 220,
                        allowInteractivePetting: true
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    EggView(
                        eggColor: DragonPalette.lavender,
                        spotColor: DragonPalette.buttercup,
                        crackStage: eggCrackStage,
                        size: 190
                    ) {
                        handleEggTap()
                    }
                }
            }
            .frame(height: 250)
            
            if isHatched {
                KidButton(
                    title: "Meet Your Baby Dragon!",
                    icon: "heart.fill",
                    backgroundColor: DragonPalette.rosyPink,
                    minWidth: 260
                ) {
                    withAnimation(.spring()) {
                        step = 2
                    }
                }
                .transition(.scale)
            }
        }
    }
    
    private var eggPromptText: String {
        if isHatched {
            return "Hooray! It's a baby dragon!"
        }
        switch eggCrackStage {
        case 0: return "Tap the glowing egg!"
        case 1: return "It's cracking! Tap again!"
        case 2: return "Almost here! One more tap!"
        default: return "Tap to hatch!"
        }
    }
    
    private func handleEggTap() {
        guard !isHatched else { return }
        
        HapticsService.shared.medium()
        
        if eggCrackStage < 2 {
            eggCrackStage += 1
            AudioService.shared.playEggCrack(intensity: eggCrackStage)
        } else {
            // HATCH TIME!
            eggCrackStage = 3
            AudioService.shared.playVictoryFanfare()
            HapticsService.shared.success()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isHatched = true
                celebrationConfetti = true
            }
        }
    }
    
    // MARK: - Step 2: Dragon Naming & Start
    
    private var namingAndWelcomeStep: some View {
        VStack(spacing: 20) {
            Text("Name Your Dragon!")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
            
            DragonView(
                dragon: gameManager.activeDragon,
                mood: .happy,
                size: 160,
                allowInteractivePetting: true
            )
            
            // Name Presets Buttons
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ForEach(presetNames.prefix(3), id: \.self) { name in
                        nameSelectionPill(name)
                    }
                }
                HStack(spacing: 10) {
                    ForEach(presetNames.suffix(3), id: \.self) { name in
                        nameSelectionPill(name)
                    }
                }
            }
            
            // Optional custom name field
            TextField("Or type a name...", text: $chosenName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DragonPalette.softPurple.opacity(0.4), lineWidth: 2)
                        )
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
            
            KidButton(
                title: "Enter Dragon Island!",
                icon: "arrow.right.circle.fill",
                backgroundColor: DragonPalette.mintGreen,
                foregroundColor: DragonPalette.textDark,
                minWidth: 260
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step = 3 }
            }
            .padding(.top, 10)
        }
        .padding(26)
        .kidCard()
    }
    
    private func nameSelectionPill(_ name: String) -> some View {
        Button(action: {
            HapticsService.shared.selection()
            AudioService.shared.playPop()
            chosenName = name
        }) {
            Text(name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(chosenName == name ? .white : DragonPalette.textDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(chosenName == name ? DragonPalette.softPurple : Color.white)
                        .overlay(
                            Capsule().stroke(DragonPalette.softPurple.opacity(0.5), lineWidth: 1.5)
                        )
                        .shadow(color: DragonPalette.softShadow, radius: 3, x: 0, y: 2)
                )
        }
    }
}
