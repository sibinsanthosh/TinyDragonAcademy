//
//  DragonCollectionView.swift
//  Tiny Dragon Academy
//
//  Complete 12-dragon collection browser, friendship feeding, petting, and incubator hatching.
//

import SwiftUI

struct DragonCollectionView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var selectedDragonForDetail: DragonModel? = nil
    @State private var showIncubatorModal: Bool = false
    @State private var dragonToHatch: DragonModel? = nil
    @State private var hatchCrackStage: Int = 0
    @State private var isHatchCelebration: Bool = false
    
    let columns = [
        GridItem(.adaptive(minimum: 155, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            DragonPalette.skyGradient
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    Button(action: {
                        HapticsService.shared.medium()
                        AudioService.shared.playPop()
                        gameManager.navigate(to: .mainMenu)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 26))
                            Text("Back")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.9)))
                    }
                    
                    Spacer()
                    
                    StarCounterView(count: gameManager.totalStars)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Title
                VStack(spacing: 2) {
                    Text("My Dragon Family")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    
                    Text("\(unlockedCount) of \(gameManager.state.dragons.count) baby dragons unlocked")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(DragonPalette.textMuted)
                }
                
                // Collection Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(gameManager.state.dragons) { dragon in
                            dragonCard(dragon)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
            
            // Dragon Details & Petting Modal
            if let detail = selectedDragonForDetail {
                dragonDetailModal(detail)
            }
            
            // Hatching Incubator Modal
            if showIncubatorModal, let toHatch = dragonToHatch {
                incubatorModal(toHatch)
            }
        }
    }
    
    private var unlockedCount: Int {
        gameManager.state.dragons.filter { $0.isUnlocked }.count
    }
    
    // MARK: - Dragon Grid Card
    
    private func dragonCard(_ dragon: DragonModel) -> some View {
        let isCurrentCompanion = (dragon.id == gameManager.state.selectedDragonId)
        
        return Button(action: {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            if dragon.isUnlocked {
                selectedDragonForDetail = dragon
            } else {
                dragonToHatch = dragon
                hatchCrackStage = 0
                isHatchCelebration = false
                showIncubatorModal = true
            }
        }) {
            VStack(spacing: 8) {
                // Companion Crown Pill
                if isCurrentCompanion {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill").font(.system(size: 10))
                        Text("Companion").font(.system(size: 10, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(DragonPalette.textDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(DragonPalette.buttercup))
                } else {
                    Spacer().frame(height: 17)
                }
                
                // Visual Avatar: Mini dragon or Egg
                if dragon.isUnlocked {
                    DragonView(
                        dragon: dragon,
                        mood: .idle,
                        size: 100,
                        allowInteractivePetting: false
                    )
                    .frame(height: 90)
                } else {
                    // Locked Egg
                    ZStack {
                        Circle()
                            .fill(dragon.element.themeColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        EggShape()
                            .fill(dragon.element.themeColor)
                            .frame(width: 48, height: 60)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(height: 90)
                }
                
                // Name & Element
                VStack(spacing: 2) {
                    Text(dragon.isUnlocked ? dragon.name : "Mystery Dragon")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: dragon.element.iconName)
                            .font(.system(size: 10))
                        Text(dragon.element.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(dragon.element.themeColor)
                }
                
                // Action Indicator (Hearts or Stars to Unlock)
                if dragon.isUnlocked {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill").font(.system(size: 11)).foregroundColor(DragonPalette.rosyPink)
                        Text("\(dragon.friendshipHearts)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(DragonPalette.textDark)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(DragonPalette.buttercup)
                        Text("\(dragon.hatchCost)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(DragonPalette.textDark)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.9)))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .kidCard(
                background: isCurrentCompanion ? DragonPalette.buttercup.opacity(0.25) : Color.white.opacity(0.88),
                borderColor: isCurrentCompanion ? DragonPalette.buttercup : .white
            )
        }
    }
    
    // MARK: - Detail & Petting Modal
    
    private func dragonDetailModal(_ dragon: DragonModel) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { selectedDragonForDetail = nil }
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dragon.name)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        Text(dragon.speciesTitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(dragon.element.themeColor)
                    }
                    Spacer()
                    Button(action: { selectedDragonForDetail = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                }
                
                // Big Interactive Dragon (Touch to giggle and heart!)
                DragonView(
                    dragon: dragon,
                    mood: .happy,
                    size: 180,
                    allowInteractivePetting: true
                ) {
                    gameManager.petActiveDragon()
                    if let idx = gameManager.state.dragons.firstIndex(where: { $0.id == dragon.id }) {
                        selectedDragonForDetail = gameManager.state.dragons[idx]
                    }
                }
                
                Text("Tap to cuddle your baby dragon!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                
                // Lore & Snack card
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "leaf.fill").foregroundColor(DragonPalette.mintGreen)
                        Text("Snack: \(dragon.favoriteSnack)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        Spacer()
                    }
                    Text(dragon.personality)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(DragonPalette.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)))
                
                // Growth & Raising Summary Pill
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: dragon.stats.growthStage.iconName)
                        Text(dragon.stats.growthStage.rawValue)
                    }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(dragon.stats.growthStage.badgeColor)
                    
                    Text("•")
                        .foregroundColor(DragonPalette.textMuted)
                    
                    Text("Level \(dragon.stats.level)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    
                    Text("•")
                        .foregroundColor(DragonPalette.textMuted)
                    
                    Text("\(dragon.stats.unlockedPowerIds.count) Powers")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(DragonPalette.coral)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.9)))
                
                // Select Companion & Go to Sanctuary Buttons
                VStack(spacing: 10) {
                    KidButton(
                        title: "Raise in Sanctuary 🌟",
                        icon: "sparkles",
                        backgroundColor: DragonPalette.coral,
                        minWidth: 240
                    ) {
                        gameManager.selectDragon(id: dragon.id)
                        selectedDragonForDetail = nil
                        gameManager.navigate(to: .dragonPlayground)
                    }
                    
                    KidButton(
                        title: (dragon.id == gameManager.state.selectedDragonId) ? "Current Companion" : "Choose Companion",
                        icon: "heart.fill",
                        backgroundColor: (dragon.id == gameManager.state.selectedDragonId) ? DragonPalette.mintGreen : DragonPalette.softPurple,
                        minWidth: 240
                    ) {
                        gameManager.selectDragon(id: dragon.id)
                        selectedDragonForDetail = nil
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.99, green: 0.98, blue: 1.0))
                    .shadow(color: DragonPalette.popShadow, radius: 20)
            )
            .padding(.horizontal, 28)
        }
    }
    
    // MARK: - Incubator Hatching Modal
    
    private func incubatorModal(_ dragon: DragonModel) -> some View {
        let canAfford = gameManager.totalStars >= dragon.hatchCost
        
        return ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isHatchCelebration { showIncubatorModal = false }
                }
            
            VStack(spacing: 20) {
                // Title
                Text(isHatchCelebration ? "Hatched!" : "Dragon Incubator")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                
                if isHatchCelebration {
                    // Hatched Baby Dragon
                    DragonView(
                        dragon: dragon,
                        mood: .celebration,
                        size: 180,
                        allowInteractivePetting: true
                    )
                    
                    Text("Welcome to the island, \(dragon.name)!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    
                    KidButton(
                        title: "Hooray!",
                        icon: "sparkles",
                        backgroundColor: DragonPalette.rosyPink,
                        minWidth: 200
                    ) {
                        showIncubatorModal = false
                        dragonToHatch = nil
                    }
                } else {
                    // Egg to Tap
                    EggView(
                        eggColor: dragon.element.themeColor,
                        spotColor: DragonPalette.buttercup,
                        crackStage: hatchCrackStage,
                        size: 160
                    ) {
                        if canAfford {
                            handleIncubatorTap(dragon: dragon)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text(dragon.speciesTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        
                        Text(canAfford ? "Tap the egg to hatch!" : "Earn more stars to unlock this egg!")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(canAfford ? DragonPalette.mintGreen : DragonPalette.coral)
                    }
                    
                    // Cost Pill
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").foregroundColor(DragonPalette.buttercup)
                        Text("\(dragon.hatchCost) Stars required").font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white))
                    
                    if !canAfford {
                        Button(action: { showIncubatorModal = false }) {
                            Text("Go Back")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(DragonPalette.textMuted)
                        }
                    }
                }
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.99, green: 0.98, blue: 1.0))
                    .shadow(color: DragonPalette.popShadow, radius: 20)
            )
            .padding(.horizontal, 30)
        }
    }
    
    private func handleIncubatorTap(dragon: DragonModel) {
        HapticsService.shared.medium()
        
        if hatchCrackStage < 2 {
            hatchCrackStage += 1
            AudioService.shared.playEggCrack(intensity: hatchCrackStage)
        } else {
            // HATCH!
            let success = gameManager.hatchDragon(id: dragon.id)
            if success {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isHatchCelebration = true
                }
            }
        }
    }
}
