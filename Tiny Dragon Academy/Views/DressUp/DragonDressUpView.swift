//
//  DragonDressUpView.swift
//  Tiny Dragon Academy
//
//  Dragon Dress-Up Studio with live preview, color swaps, horns, wings,
//  accessories, background scenery, randomizer, and offline star unlocks.
//

import SwiftUI

enum DressUpTab: String, CaseIterable, Identifiable {
    case colors = "Colors"
    case horns = "Horns"
    case wings = "Wings"
    case accessories = "Outfits"
    case backdrop = "Scenery"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .colors: return "paintpalette.fill"
        case .horns: return "crown.fill"
        case .wings: return "wind"
        case .accessories: return "sparkles"
        case .backdrop: return "photo.fill"
        }
    }
}

struct DragonDressUpView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var selectedTab: DressUpTab = .colors
    @State private var showSavedAlert: Bool = false
    @State private var previewMood: DragonMood = .idle
    
    // Color swatches
    private let colorPresets: [String] = [
        "#D0C7F5", // Lavender
        "#A0E7E5", // Sky Mint
        "#FFA07A", // Peach
        "#FFEAA7", // Buttercup
        "#FFB7B2", // Rosy Pink
        "#B4F8C8", // Mint
        "#C5E3F6", // Soft Blue
        "#E0BBE4"  // Plum
    ]
    
    var body: some View {
        ZStack {
            // Live Selected Backdrop
            gameManager.activeDragon.backdrop.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header: Back, Randomize, Save, Stars
                headerView

                Spacer(minLength: 0)

                // Central Live Dragon Preview
                ZStack {
                    ClayPlatform(top: Color.white.opacity(0.9), side: ClayColor.accent.opacity(0.45), width: 240)
                        .offset(y: 95)
                    DragonView(
                        dragon: gameManager.activeDragon,
                        mood: previewMood,
                        size: 240,
                        allowInteractivePetting: true
                    ) {
                        previewMood = .happy
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            previewMood = .idle
                        }
                    }
                    
                    // Saved Checkmark Overlay
                    if showSavedAlert {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(DragonPalette.mintGreen)
                            Text("Saved!")
                                .font(.clay(16, .bold))
                                .foregroundColor(DragonPalette.textDark)
                        }
                        .padding(18)
                        .claySurface(cornerRadius: 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 290)

                Spacer(minLength: 0)

                // Tab Selection Strip
                tabStrip
                
                // Studio Options Tray
                optionsTray
                    .frame(height: 140)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            ClayIconButton(systemName: "chevron.left", accessibilityLabel: "Back") {
                gameManager.navigate(to: .foodInventoryShop)
            }
            
            Spacer()
            
            // Randomize Magic Wand Button
            Button(action: randomizeDragon) {
                HStack(spacing: 5) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16))
                    Text("Random")
                        .font(.clay(14, .bold))
                }
                .foregroundColor(DragonPalette.softPurple)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .claySurface(cornerRadius: 100, elevation: 0.7)
            }
            
            // Save Button
            Button(action: saveChanges) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                    Text("Save")
                        .font(.clay(14, .bold))
                }
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(DragonPalette.mintGreen))
            }
            
            Spacer()
            
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Tab Strip
    
    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DressUpTab.allCases) { tab in
                    let isSelected = (selectedTab == tab)
                    Button(action: {
                        HapticsService.shared.selection()
                        AudioService.shared.playPop()
                        selectedTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.clay(14, .bold))
                        }
                        .foregroundColor(isSelected ? .white : DragonPalette.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? DragonPalette.softPurple : Color.white.opacity(0.85))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Options Tray
    
    private var optionsTray: some View {
        ZStack {
            Color.clear
                .claySurface(cornerRadius: 28, elevation: 1.2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    switch selectedTab {
                    case .colors:
                        colorsOptionsView
                    case .horns:
                        hornsOptionsView
                    case .wings:
                        wingsOptionsView
                    case .accessories:
                        accessoriesOptionsView
                    case .backdrop:
                        backdropOptionsView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }
    
    // MARK: - Category Pickers
    
    private var colorsOptionsView: some View {
        ForEach(colorPresets, id: \.self) { hex in
            let color = Color(hex: hex)
            let isCurrent = (gameManager.activeDragon.primaryColorHex == hex)
            
            Button(action: {
                HapticsService.shared.light()
                AudioService.shared.playPop()
                gameManager.updateActiveDragon(colorHex: hex)
            }) {
                Circle()
                    .fill(color)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: isCurrent ? 4 : 2)
                    )
                    .shadow(color: color.opacity(0.5), radius: isCurrent ? 6 : 2)
                    .scaleEffect(isCurrent ? 1.15 : 1.0)
            }
        }
    }
    
    private var hornsOptionsView: some View {
        ForEach(HornStyle.allCases, id: \.self) { style in
            let isSelected = (gameManager.activeDragon.hornStyle == style)
            
            Button(action: {
                HapticsService.shared.light()
                AudioService.shared.playPop()
                gameManager.updateActiveDragon(hornStyle: style)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "crown")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? DragonPalette.softPurple : DragonPalette.textDark)
                    Text(style.rawValue)
                        .font(.clay(11, .bold))
                        .foregroundColor(DragonPalette.textDark)
                }
                .frame(width: 80, height: 75)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? DragonPalette.buttercup.opacity(0.4) : Color.white.opacity(0.6))
                )
            }
        }
    }
    
    private var wingsOptionsView: some View {
        ForEach(WingStyle.allCases, id: \.self) { style in
            let isSelected = (gameManager.activeDragon.wingStyle == style)
            
            Button(action: {
                HapticsService.shared.light()
                AudioService.shared.playPop()
                gameManager.updateActiveDragon(wingStyle: style)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "wind")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? DragonPalette.softPurple : DragonPalette.textDark)
                    Text(style.rawValue)
                        .font(.clay(11, .bold))
                        .foregroundColor(DragonPalette.textDark)
                }
                .frame(width: 85, height: 75)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? DragonPalette.buttercup.opacity(0.4) : Color.white.opacity(0.6))
                )
            }
        }
    }
    
    private var accessoriesOptionsView: some View {
        ForEach(DragonAccessory.allCases, id: \.self) { accessory in
            let isUnlocked = gameManager.state.unlockedAccessories.contains(accessory)
            let isSelected = (gameManager.activeDragon.accessory == accessory)
            
            Button(action: {
                if isUnlocked {
                    HapticsService.shared.light()
                    AudioService.shared.playPop()
                    gameManager.updateActiveDragon(accessory: accessory)
                } else {
                    // Try to unlock with stars
                    if gameManager.unlockAccessory(accessory) {
                        HapticsService.shared.success()
                        AudioService.shared.playVictoryFanfare()
                        gameManager.updateActiveDragon(accessory: accessory)
                    } else {
                        AudioService.shared.playEncouragement()
                    }
                }
            }) {
                VStack(spacing: 3) {
                    ZStack {
                        Image(systemName: isUnlocked ? "sparkles" : "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isUnlocked ? DragonPalette.softPurple : DragonPalette.textMuted)
                    }
                    
                    Text(accessory.rawValue)
                        .font(.clay(10, .bold))
                        .foregroundColor(DragonPalette.textDark)
                        .lineLimit(1)
                    
                    if !isUnlocked {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(DragonPalette.buttercup)
                            Text("\(accessory.unlockStars)").font(.clay(10, .heavy))
                        }
                    }
                }
                .frame(width: 78, height: 75)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? DragonPalette.mintGreen.opacity(0.4) : Color.white.opacity(0.6))
                )
            }
        }
    }
    
    private var backdropOptionsView: some View {
        ForEach(IslandBackdrop.allCases, id: \.self) { backdrop in
            let isSelected = (gameManager.activeDragon.backdrop == backdrop)
            
            Button(action: {
                HapticsService.shared.light()
                AudioService.shared.playPop()
                gameManager.updateActiveDragon(backdrop: backdrop)
            }) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(backdrop.backgroundGradient)
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    
                    Text(backdrop.rawValue)
                        .font(.clay(10, .bold))
                        .foregroundColor(DragonPalette.textDark)
                        .lineLimit(1)
                }
                .frame(width: 80, height: 75)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? DragonPalette.buttercup.opacity(0.4) : Color.white.opacity(0.6))
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func randomizeDragon() {
        HapticsService.shared.medium()
        AudioService.shared.playChime(frequency: 987.77)
        
        let randomPrimary = colorPresets.randomElement() ?? "#D0C7F5"
        let randomSecondary = colorPresets.randomElement() ?? "#FFEAA7"
        let randomHorns = HornStyle.allCases.randomElement() ?? .nubby
        let randomWings = WingStyle.allCases.randomElement() ?? .classic
        let randomTail = TailStyle.allCases.randomElement() ?? .spade
        let unlocked = Array(gameManager.state.unlockedAccessories)
        let randomAccessory = unlocked.randomElement() ?? .none
        let randomBackdrop = IslandBackdrop.allCases.randomElement() ?? .meadow
        
        gameManager.updateActiveDragon(
            colorHex: randomPrimary,
            secondaryHex: randomSecondary,
            hornStyle: randomHorns,
            wingStyle: randomWings,
            tailStyle: randomTail,
            accessory: randomAccessory,
            backdrop: randomBackdrop
        )
        
        previewMood = .celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            previewMood = .idle
        }
    }
    
    private func saveChanges() {
        HapticsService.shared.success()
        AudioService.shared.playChime(frequency: 1174.66)
        gameManager.save()
        
        withAnimation(.spring()) {
            showSavedAlert = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring()) {
                showSavedAlert = false
            }
        }
    }
}
