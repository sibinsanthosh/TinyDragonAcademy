//
//  ColorGardenGameView.swift
//  Tiny Dragon Academy
//
//  Game A: Colour Garden.
//  Children sort colourful fruits and gems into matching-colour baskets.
//  Supports both tactile drag-and-drop and tap-to-match for toddler accessibility.
//

import SwiftUI

struct ColorItem: Identifiable, Equatable {
    let id = UUID()
    let colorName: String
    let color: Color
    let iconName: String
}

struct ColorGardenGameView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var round: Int = 1
    @State private var itemsToMatch: [ColorItem] = []
    @State private var currentItemIndex: Int = 0
    @State private var selectedItemId: UUID? = nil
    @State private var showVictory: Bool = false
    @State private var hintGlowColor: String? = nil
    
    // Drag state
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    // Color definitions
    private let availableBaskets: [(name: String, color: Color, basketIcon: String)] = [
        ("Pink", DragonPalette.rosyPink, "basket.fill"),
        ("Blue", DragonPalette.skyBlue, "basket.fill"),
        ("Yellow", DragonPalette.buttercup, "basket.fill"),
        ("Green", DragonPalette.mintGreen, "basket.fill")
    ]
    
    var body: some View {
        ZStack {
            DragonPalette.meadowGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header: Back button, Round progress, Stars
                headerView
                
                // Instructions / Encouragement Banner
                instructionBanner
                
                Spacer()
                
                // Item Area (Current object to match)
                if currentItemIndex < itemsToMatch.count {
                    let currentItem = itemsToMatch[currentItemIndex]
                    itemCard(currentItem)
                }
                
                Spacer()
                
                // Color Baskets (Target drop targets)
                basketsRow
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            
            // Victory Modal
            if showVictory {
                GameVictoryModal(
                    starsEarned: 3,
                    onPlayAgain: {
                        startNewGame()
                    },
                    onBackToMenu: {
                        gameManager.navigate(to: .miniGamesHub)
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            startNewGame()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                HapticsService.shared.medium()
                AudioService.shared.playPop()
                gameManager.navigate(to: .miniGamesHub)
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DragonPalette.textDark)
                    .background(Circle().fill(Color.white.opacity(0.85)))
            }
            
            Spacer()
            
            // Round Badge
            Text("Round \(round) of 3")
                .font(.clay(16, .bold))
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .claySurface(cornerRadius: 100, elevation: 0.7)
            
            Spacer()
            
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.top, 10)
    }
    
    private var instructionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundColor(DragonPalette.softPurple)
            Text("Match the color to the basket!")
                .font(.clay(18, .bold))
                .foregroundColor(DragonPalette.textDark)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .claySurface(cornerRadius: 100, elevation: 0.7)
    }
    
    // MARK: - Draggable / Selectable Fruit Item
    
    private func itemCard(_ item: ColorItem) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // Background aura
                Circle()
                    .fill(item.color.opacity(0.3))
                    .frame(width: 140, height: 140)
                
                // Item Icon
                Image(systemName: item.iconName)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(item.color)
                    .shadow(color: item.color.opacity(0.5), radius: 8)
            }
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        isDragging = true
                        hintGlowColor = item.colorName
                    }
                    .onEnded { value in
                        isDragging = false
                        handleDragEnd(value.translation, for: item)
                    }
            )
            .onTapGesture {
                HapticsService.shared.light()
                AudioService.shared.playPop()
                selectedItemId = item.id
                hintGlowColor = item.colorName
            }
            
            Text("Drag or tap me!")
                .font(.clay(14, .semibold))
                .foregroundColor(DragonPalette.textMuted)
        }
    }
    
    // MARK: - Baskets Row
    
    private var basketsRow: some View {
        HStack(spacing: 12) {
            let activeBasketCount = min(availableBaskets.count, round + 1)
            ForEach(0..<activeBasketCount, id: \.self) { idx in
                let basket = availableBaskets[idx]
                basketView(basket)
            }
        }
    }
    
    private func basketView(_ basket: (name: String, color: Color, basketIcon: String)) -> some View {
        let isGlow = (hintGlowColor == basket.name)
        
        return Button(action: {
            // Tap to match support
            if currentItemIndex < itemsToMatch.count {
                let currentItem = itemsToMatch[currentItemIndex]
                checkMatch(item: currentItem, basketName: basket.name)
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(basket.color)
                        .frame(height: 75)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: basket.color.opacity(0.4), radius: isGlow ? 12 : 4)
                    
                    Image(systemName: basket.basketIcon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(basket.name)
                    .font(.clay(14, .bold))
                    .foregroundColor(DragonPalette.textDark)
            }
            .scaleEffect(isGlow ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isGlow)
        }
    }
    
    // MARK: - Game Mechanics
    
    private func handleDragEnd(_ translation: CGSize, for item: ColorItem) {
        // If dragged down towards the baskets (y > 60)
        if translation.height > 60 {
            // Determine which basket column based on x translation
            let activeCount = min(availableBaskets.count, round + 1)
            let widthPerBasket = 300.0 / Double(activeCount)
            let centerOffset = translation.width
            let basketIndex = Int((centerOffset + 150.0) / widthPerBasket)
            let clamped = max(0, min(activeCount - 1, basketIndex))
            let targetBasket = availableBaskets[clamped]
            checkMatch(item: item, basketName: targetBasket.name)
        }
        
        // Reset drag offset
        withAnimation(.spring()) {
            dragOffset = .zero
        }
    }
    
    private func checkMatch(item: ColorItem, basketName: String) {
        if item.colorName == basketName {
            // MATCH SUCCESS!
            HapticsService.shared.success()
            AudioService.shared.playChime(frequency: 784.0)
            
            withAnimation(.spring()) {
                currentItemIndex += 1
                hintGlowColor = nil
                dragOffset = .zero
            }
            
            // Check round completion
            if currentItemIndex >= itemsToMatch.count {
                if round < 3 {
                    // Next round
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        round += 1
                        setupRound()
                    }
                } else {
                    // ALL ROUNDS COMPLETE!
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        gameManager.awardStars(3, forGame: .colorGarden)
                        AudioService.shared.playVictoryFanfare()
                        showVictory = true
                    }
                }
            }
        } else {
            // Non-matching: gentle bounce encouragement
            HapticsService.shared.light()
            AudioService.shared.playEncouragement()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                dragOffset = CGSize(width: -15, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring()) {
                    dragOffset = .zero
                }
            }
        }
    }
    
    private func startNewGame() {
        round = 1
        showVictory = false
        setupRound()
    }
    
    private func setupRound() {
        currentItemIndex = 0
        hintGlowColor = nil
        dragOffset = .zero
        
        let count = round + 2 // Round 1: 3 items, Round 2: 4 items, Round 3: 5 items
        let activeBaskets = Array(availableBaskets.prefix(min(availableBaskets.count, round + 1)))
        
        var generated: [ColorItem] = []
        let icons = ["apple.logo", "leaf.fill", "star.fill", "heart.fill", "drop.fill"]
        
        for i in 0..<count {
            let basket = activeBaskets[i % activeBaskets.count]
            let icon = icons[i % icons.count]
            generated.append(ColorItem(colorName: basket.name, color: basket.color, iconName: icon))
        }
        
        itemsToMatch = generated.shuffled()
    }
}
