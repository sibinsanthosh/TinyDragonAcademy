//
//  DragonPlaygroundView.swift
//  Tiny Dragon Academy
//
//  Main interactive dragon raising sanctuary:
//  - Evolving habitat background
//  - Large interactive dragon with petting, breathing, and moods
//  - Care meters: Hunger, Happiness, Energy, Health
//  - Level & XP progress bar, Growth stage badge with evolution trigger
//  - Interactive Feeding tray with animated food giving & eating reactions (drag-to-feed & tap-to-feed)
//  - Elemental power trigger with full-screen particle canvas effects
//

import SwiftUI

struct DragonPlaygroundView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var playgroundMood: DragonMood = .idle
    @State private var activePowerFX: ElementalPower? = nil
    @State private var showEvolutionModal: Bool = false
    @State private var showPowersBook: Bool = false
    @State private var showFoodPantry: Bool = false
    @State private var showAchievements: Bool = false
    @State private var floatingXPBadge: Int? = nil
    @State private var showFavoriteCelebration: Bool = false
    @State private var selectedFood: FoodType? = nil
    
    // Dragon mouth position in playground coordinate space
    @State private var dragonMouthPosition: CGPoint = CGPoint(x: 200, y: 380)
    
    // Drag-and-drop feeding state
    @State private var draggedFood: FoodType? = nil
    @State private var dragCurrentPosition: CGPoint = .zero
    @State private var isDraggingFood: Bool = false
    @State private var isNearMouth: Bool = false
    @State private var dragStardustTrail: [CGPoint] = []
    
    // Flying food animation state (tap-to-feed or animated giving)
    @State private var flyingFood: FoodType? = nil
    @State private var flyingFoodPosition: CGPoint = .zero
    @State private var flyingFoodScale: CGFloat = 1.0
    @State private var flyingFoodRotation: Double = 0.0
    @State private var flyingFoodOpacity: Double = 1.0
    
    // Dragon eating sequence state
    @State private var isEatingSequenceRunning: Bool = false
    @State private var eatingCrumbs: [BiteCrumb] = []
    @State private var nomNomSpeechText: String? = nil
    @State private var nomNomSpeechScale: CGFloat = 0.0
    
    var activeDragon: DragonModel {
        gameManager.activeDragon
    }
    
    var stats: DragonStats {
        activeDragon.stats
    }
    
    var availablePowers: [ElementalPower] {
        let catalog = ElementalPowersCatalog.powers(for: activeDragon.element)
        return catalog.filter { stats.unlockedPowerIds.contains($0.id) }
    }
    
    var isAsleep: Bool { gameManager.isActiveDragonAsleep }
    var isSpirit: Bool { stats.condition.isSpirit }
    
    var primaryPower: ElementalPower {
        availablePowers.last ?? ElementalPowersCatalog.powers(for: activeDragon.element)[0]
    }
    
    var body: some View {
        ZStack {
            // 1. Evolving Habitat Background & Terrain
            DragonHabitatContainerView(stage: stats.growthStage, element: activeDragon.element) {
                // Main Interactive Dragon
                VStack(spacing: 8) {
                    // Dragon View with geometry preference tracking
                    DragonView(
                        dragon: activeDragon,
                        mood: (isAsleep || isSpirit) ? .sleepy : playgroundMood,
                        size: 210,
                        allowInteractivePetting: !isEatingSequenceRunning && !isDraggingFood && !isSpirit
                    ) {
                        gameManager.petActiveDragon()
                        setTemporaryMood(.happy, duration: 1.2)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: DragonMouthPreferenceKey.self,
                                    value: CGPoint(
                                        x: geo.frame(in: .named("playgroundSpace")).midX,
                                        y: geo.frame(in: .named("playgroundSpace")).midY - 15
                                    )
                                )
                        }
                    )
                    
                    // Dragon Name & Species Pill
                    dragonTitleBadge
                }
            }
            
            // 2. Active Elemental Visual FX Overlay (when power triggered)
            if let power = activePowerFX {
                ElementalPowerFXView(power: power) {
                    activePowerFX = nil
                    playgroundMood = .idle
                }
                .transition(.opacity)
                .zIndex(20)
            }
            
            // 3. Drop Target Halo (shows when dragging food toward dragon)
            if isDraggingFood {
                dropTargetHalo
                    .zIndex(22)
            }
            
            // 4. Main UI HUD Overlay (Top & Bottom)
            VStack {
                // Top Navigation & Stats Bar
                topHUDBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Growth & Vitals Gauges
                vitalsStatusCard
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                
                Spacer()
                
                // Bottom Interactive Controls (Feeding Tray + Power Button)
                bottomControlsBar
                    .padding(.bottom, 16)
            }
            .zIndex(10)
            
            // 4b. Night-time sleep tint
            if isAsleep && !isSpirit {
                sleepOverlay
                    .zIndex(9)
            }
            
            // 4c. Spirit state: revive window
            if isSpirit {
                spiritOverlay
                    .zIndex(45)
            }
            
            // 5. Nom Nom Speech Bubble
            if let speech = nomNomSpeechText {
                nomNomBubble(text: speech)
                    .position(x: dragonMouthPosition.x, y: max(dragonMouthPosition.y - 120, 160))
                    .scaleEffect(nomNomSpeechScale)
                    .zIndex(35)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 6. Flying Food Token
            if let food = flyingFood {
                flyingFoodToken(food: food)
                    .position(flyingFoodPosition)
                    .scaleEffect(flyingFoodScale)
                    .rotationEffect(.degrees(flyingFoodRotation))
                    .opacity(flyingFoodOpacity)
                    .zIndex(40)
                    .allowsHitTesting(false)
            }
            
            // 7. Bite Crumbs Burst
            ForEach(eatingCrumbs) { crumb in
                Circle()
                    .fill(crumb.color)
                    .frame(width: crumb.size, height: crumb.size)
                    .position(crumb.position)
                    .opacity(crumb.opacity)
                    .zIndex(42)
                    .allowsHitTesting(false)
            }
            
            // 8. Dragged Food Item with Trailing Stardust
            if isDraggingFood, let food = draggedFood {
                draggedFoodToken(food: food)
                    .zIndex(45)
                    .allowsHitTesting(false)
            }
            
            // 9. Floating XP Pop-up
            if let xp = floatingXPBadge {
                VStack(spacing: 4) {
                    Text("+\(xp) XP!")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.coral)
                    if showFavoriteCelebration {
                        Text("✨ Favorite Food! 2x Bonus! ✨")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(DragonPalette.buttercup)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: DragonPalette.softShadow, radius: 8, x: 0, y: 4)
                )
                .transition(.scale.combined(with: .opacity))
                .position(x: dragonMouthPosition.x, y: max(dragonMouthPosition.y - 100, 150))
                .zIndex(48)
            }
            
            // 11. Evolution Ceremony Sheet
            if showEvolutionModal {
                EvolutionCeremonyView(
                    dragon: activeDragon,
                    onEvolveConfirmed: {
                        _ = gameManager.evolveActiveDragon()
                        showEvolutionModal = false
                        setTemporaryMood(.celebration, duration: 2.0)
                    },
                    onDismiss: {
                        showEvolutionModal = false
                    }
                )
                .zIndex(60)
            }
        }
        .coordinateSpace(name: "playgroundSpace")
        .onPreferenceChange(DragonMouthPreferenceKey.self) { pos in
            if pos != .zero {
                dragonMouthPosition = pos
            }
        }
        .sheet(isPresented: $showPowersBook) {
            PowerEncyclopediaView(dragon: activeDragon)
                .environmentObject(gameManager)
        }
        .sheet(isPresented: $showFoodPantry) {
            FoodInventoryView()
                .environmentObject(gameManager)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(gameManager)
        }
    }
    
    // MARK: - Animated Visual Elements
    
    private var dropTargetHalo: some View {
        ZStack {
            Circle()
                .stroke(
                    isNearMouth ? DragonPalette.mintGreen : DragonPalette.buttercup,
                    style: StrokeStyle(lineWidth: 3.5, dash: [7, 7])
                )
                .frame(width: 140, height: 140)
                .background(
                    Circle()
                        .fill((isNearMouth ? DragonPalette.mintGreen : DragonPalette.buttercup).opacity(0.16))
                )
            
            Text(isNearMouth ? "Drop to Munch! 😋" : "Bring Treat Here! 🍓")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.96))
                        .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
                )
                .offset(y: 84)
        }
        .position(dragonMouthPosition)
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }
    
    private func nomNomBubble(text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.96))
                .shadow(color: DragonPalette.softShadow, radius: 8, x: 0, y: 3)
        )
    }
    
    private func flyingFoodToken(food: FoodType) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 54, height: 54)
                .shadow(color: food.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
            Circle()
                .fill(food.primaryColor.opacity(0.2))
                .frame(width: 48, height: 48)
            Image(systemName: food.icon)
                .font(.system(size: 26))
                .foregroundColor(food.primaryColor)
        }
    }
    
    private func draggedFoodToken(food: FoodType) -> some View {
        ZStack {
            // Stardust particle trail
            ForEach(Array(dragStardustTrail.enumerated()), id: \.offset) { idx, point in
                Circle()
                    .fill(food.primaryColor.opacity(Double(idx + 1) / Double(max(dragStardustTrail.count, 1)) * 0.75))
                    .frame(width: CGFloat(idx) * 2.0 + 4, height: CGFloat(idx) * 2.0 + 4)
                    .position(point)
            }
            
            // Dragged Treat
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 58, height: 58)
                    .shadow(color: food.primaryColor.opacity(0.45), radius: 10, x: 0, y: 5)
                Circle()
                    .fill(food.primaryColor.opacity(0.22))
                    .frame(width: 52, height: 52)
                Image(systemName: food.icon)
                    .font(.system(size: 28))
                    .foregroundColor(food.primaryColor)
            }
            .scaleEffect(isNearMouth ? 1.25 : 1.1)
            .position(dragCurrentPosition)
        }
    }
    
    // MARK: - Dragon Title Badge
    
    private var dragonTitleBadge: some View {
        HStack(spacing: 8) {
            Text(activeDragon.name)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
            
            HStack(spacing: 4) {
                Image(systemName: activeDragon.element.iconName)
                    .font(.system(size: 13))
                Text(activeDragon.element.rawValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(activeDragon.element.themeColor))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.92))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Top HUD Bar
    
    private var topHUDBar: some View {
        HStack {
            // Back to Main Menu Button
            Button(action: {
                HapticsService.shared.light()
                AudioService.shared.playPop()
                gameManager.navigate(to: .mainMenu)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16))
                    Text("Home")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
                )
            }
            
            Spacer()
            
            // Quick Action Buttons (Powers Book, Food Pantry, Achievements)
            HStack(spacing: 10) {
                hudIconButton(icon: "sparkles.rectangle.stack.fill", badge: availablePowers.count) {
                    showPowersBook = true
                }
                
                hudIconButton(icon: "fork.knife", badge: totalFoodCount) {
                    showFoodPantry = true
                }
                
                hudIconButton(icon: "trophy.fill", badge: unlockedAchievementsCount) {
                    showAchievements = true
                }
                
                StarCounterView(count: gameManager.totalStars)
            }
        }
    }
    
    private var totalFoodCount: Int {
        gameManager.state.foodInventory.values.reduce(0, +)
    }
    
    private var unlockedAchievementsCount: Int {
        gameManager.state.achievements.filter { $0.isUnlocked }.count
    }
    
    private func hudIconButton(icon: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(DragonPalette.textDark)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
                    )
                
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(DragonPalette.coral))
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
    
    // MARK: - Vitals Status Card
    
    private var vitalsStatusCard: some View {
        VStack(spacing: 8) {
            // Stage & Level Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(DragonPalette.buttercup)
                    Text(stats.growthStage.rawValue)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.softPurple)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(DragonPalette.softPurple.opacity(0.15)))
                
                Text("Age: \(stats.ageInDays) days")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                
                Spacer()
                
                // Evolution Alert Button if Ready
                if stats.canEvolve && stats.condition == .healthy {
                    Button(action: {
                        HapticsService.shared.medium()
                        showEvolutionModal = true
                    }) {
                        HStack(spacing: 4) {
                            Text("Evolve!")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(DragonPalette.coral))
                    }
                }
                
                Text("Lvl \(stats.level)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
            }
            
            // Level XP Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DragonPalette.skyBlue, DragonPalette.lavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(stats.currentLevelProgress))
                }
            }
            .frame(height: 6)
            
            // Care Gauges Grid (Hunger, Happiness, Energy, Health)
            HStack(spacing: 8) {
                vitalMeter(icon: "fork.knife", label: "Hunger", value: stats.hunger, color: DragonPalette.coral)
                vitalMeter(icon: "heart.fill", label: "Happy", value: stats.happiness, color: DragonPalette.rosyPink)
                vitalMeter(icon: "bolt.fill", label: "Energy", value: stats.energy, color: DragonPalette.buttercup)
                vitalMeter(icon: "figure.run", label: "Fitness", value: stats.fitness, color: DragonPalette.skyBlue)
                vitalMeter(icon: "shield.fill", label: "Health", value: stats.health, color: DragonPalette.mintGreen)
            }
            
            careActionsRow
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .shadow(color: DragonPalette.softShadow, radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - Care Actions (illness, bedtime)
    
    private var careActionsRow: some View {
        HStack(spacing: 8) {
            if let illness = stats.condition.illness {
                Label(illness.displayName, systemImage: "thermometer.medium")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(DragonPalette.coral))
                Button {
                    if !gameManager.useHealingHerb() { gameManager.navigate(to: .foodInventoryShop) }
                } label: {
                    Text(gameManager.state.itemCount(.healingHerb) > 0 ? "Cure (Herb ×\(gameManager.state.itemCount(.healingHerb)))" : "Buy Healing Herb")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(DragonPalette.mintGreen))
                }
            } else if stats.tummyAcheUntil != nil {
                Label("Tummy ache", systemImage: "face.dashed")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.coral)
            }
            Spacer()
            if !isSpirit {
                Button {
                    HapticsService.shared.light()
                    if stats.isSleepingEarly { gameManager.wakeUp() } else { gameManager.lightsOut() }
                } label: {
                    Label(stats.isSleepingEarly ? "Wake up" : "Lights out",
                          systemImage: stats.isSleepingEarly ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(DragonPalette.lavender))
                }
                .disabled(isAsleep && !stats.isSleepingEarly)
                .opacity(isAsleep && !stats.isSleepingEarly ? 0.5 : 1)
            }
        }
    }
    
    private var sleepOverlay: some View {
        ZStack(alignment: .top) {
            Color(red: 0.12, green: 0.10, blue: 0.30).opacity(0.35)
                .ignoresSafeArea()
            Text("💤 \(activeDragon.name) is sleeping")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .padding(.top, 250)
        }
        .allowsHitTesting(false)
    }
    
    private var spiritOverlay: some View {
        let status = DragonStatus.describe(stats, now: gameManager.clock.now(), calendar: gameManager.calendar)
        let embers = gameManager.state.itemCount(.phoenixEmber)
        return ZStack {
            Color(red: 0.20, green: 0.18, blue: 0.40).opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                DragonView(dragon: activeDragon, mood: .sleepy, size: 130, allowInteractivePetting: false)
                    .opacity(0.45)
                    .colorMultiply(Color(red: 0.8, green: 0.85, blue: 1.0))
                Text("\(activeDragon.name) has become a spirit 👻")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                    .multilineTextAlignment(.center)
                if let status { DragonStatusBadge(status: status) }
                Text("A Phoenix Ember can bring them back. They'll keep their level but lose one growth stage.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                if embers > 0 {
                    KidButton(title: "Revive (Ember ×\(embers))", icon: "flame.fill", backgroundColor: DragonPalette.coral) {
                        if gameManager.reviveActiveDragon() { setTemporaryMood(.celebration, duration: 2.0) }
                    }
                } else {
                    KidButton(title: "Buy Ember • \(CareItem.phoenixEmber.price)★", icon: "cart.fill", backgroundColor: DragonPalette.coral) {
                        _ = gameManager.purchaseCareItem(.phoenixEmber)
                    }
                    .disabled(gameManager.totalStars < CareItem.phoenixEmber.price)
                    .opacity(gameManager.totalStars < CareItem.phoenixEmber.price ? 0.5 : 1)
                }
                Button("Back to the Den") { gameManager.navigate(to: .den) }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.softPurple)
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.95)))
            .padding(.horizontal, 26)
        }
    }
    
    private func vitalMeter(icon: String, label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text("\(Int(value))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * (min(max(value, 0.0), 100.0) / 100.0))
                }
            }
            .frame(height: 5)
        }
    }
    
    // MARK: - Bottom Controls Bar
    
    private var bottomControlsBar: some View {
        VStack(spacing: 10) {
            // Food Selection Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FoodType.allCases) { food in
                        foodChip(food: food)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Action Buttons: Elemental Power Trigger & Petting
            HStack(spacing: 16) {
                // Trigger Equipped Elemental Power
                Button(action: {
                    castElementalPower()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: primaryPower.iconName)
                            .font(.system(size: 18, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(primaryPower.name)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                            Text("-\(Int(primaryPower.energyCost)) Energy")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .opacity(0.85)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [activeDragon.element.themeColor, activeDragon.element.themeColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: activeDragon.element.themeColor.opacity(0.5), radius: 6, x: 0, y: 3)
                    )
                }
                .disabled(stats.energy < primaryPower.energyCost || isSpirit || isAsleep)
                .opacity(stats.energy < primaryPower.energyCost || isSpirit || isAsleep ? 0.6 : 1.0)
                
                // Pet Dragon Shortcut
                Button(action: {
                    gameManager.petActiveDragon()
                    setTemporaryMood(.happy, duration: 1.2)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16))
                        Text("Pet")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(DragonPalette.textDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.92))
                            .shadow(color: DragonPalette.softShadow, radius: 5, x: 0, y: 2)
                    )
                }
            }
        }
    }
    
    private func foodChip(food: FoodType) -> some View {
        let count = gameManager.state.foodInventory[food.rawValue] ?? 0
        let isFavorite = (food == activeDragon.favoriteFoodType)
        
        return VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(food.primaryColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: food.icon)
                            .font(.system(size: 20))
                            .foregroundColor(food.primaryColor)
                    )
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(food.primaryColor))
                        .offset(x: 2, y: -2)
                }
            }
            
            Text(food.displayName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .lineLimit(1)
            
            if isFavorite && activeDragon.stats.favoriteFoodDiscovered {
                Text("❤️ Fav")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.rosyPink)
            }
        }
        .frame(width: 76, height: 86)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(count > 0 ? 0.95 : 0.6))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .opacity(count > 0 ? 1.0 : 0.5)
        .gesture(
            SpatialTapGesture(coordinateSpace: .named("playgroundSpace"))
                .onEnded { value in
                    guard count > 0 && !isEatingSequenceRunning && !isDraggingFood else { return }
                    launchFlyingFood(food: food, from: value.location)
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.22)
                .sequenced(before: DragGesture(coordinateSpace: .named("playgroundSpace")))
                .onChanged { value in
                    guard count > 0 && !isEatingSequenceRunning else { return }
                    switch value {
                    case .second(true, let drag):
                        if let drag = drag {
                            if draggedFood == nil {
                                draggedFood = food
                                isDraggingFood = true
                                HapticsService.shared.light()
                            }
                            dragCurrentPosition = drag.location
                            
                            // Trailing stardust
                            dragStardustTrail.append(drag.location)
                            if dragStardustTrail.count > 6 {
                                dragStardustTrail.removeFirst()
                            }
                            
                            let dist = hypot(drag.location.x - dragonMouthPosition.x, drag.location.y - dragonMouthPosition.y)
                            let near = dist < 170
                            if near != isNearMouth {
                                isNearMouth = near
                                if near {
                                    playgroundMood = .anticipatingFood
                                    HapticsService.shared.light()
                                } else {
                                    playgroundMood = .idle
                                }
                            }
                        }
                    default:
                        break
                    }
                }
                .onEnded { value in
                    guard isDraggingFood, let food = draggedFood else { return }
                    switch value {
                    case .second(true, let drag):
                        if let drag = drag {
                            let dist = hypot(drag.location.x - dragonMouthPosition.x, drag.location.y - dragonMouthPosition.y)
                            if dist < 170 {
                                startFeedingSequence(food: food, from: drag.location)
                                return
                            }
                        }
                    default:
                        break
                    }
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isDraggingFood = false
                        draggedFood = nil
                        isNearMouth = false
                        dragStardustTrail.removeAll()
                        if playgroundMood == .anticipatingFood {
                            playgroundMood = .idle
                        }
                    }
                }
        )
    }
    
    // MARK: - Animated Feeding Sequence
    
    /// Sleeping dragons and spirits can't eat; say so instead of animating.
    private func refuseFeedingIfNeeded() -> Bool {
        guard isAsleep || isSpirit else { return false }
        isDraggingFood = false
        draggedFood = nil
        nomNomSpeechText = isSpirit ? "👻 Spirits can't eat…" : "💤 Shh… sleeping"
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { nomNomSpeechScale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                nomNomSpeechScale = 0.0
                nomNomSpeechText = nil
            }
        }
        return true
    }
    
    private func launchFlyingFood(food: FoodType, from source: CGPoint) {
        guard !isEatingSequenceRunning, !refuseFeedingIfNeeded() else { return }
        isEatingSequenceRunning = true
        
        flyingFood = food
        flyingFoodPosition = source
        flyingFoodScale = 0.7
        flyingFoodRotation = -15.0
        flyingFoodOpacity = 1.0
        
        playgroundMood = .anticipatingFood
        AudioService.shared.playPop()
        
        // Arc towards dragon's mouth
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            flyingFoodPosition = dragonMouthPosition
            flyingFoodScale = 1.05
            flyingFoodRotation = 15.0
        }
        
        // Trigger chomp upon arrival
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            isEatingSequenceRunning = false
            startFeedingSequence(food: food, from: dragonMouthPosition)
        }
    }
    
    private func startFeedingSequence(food: FoodType, from startPoint: CGPoint) {
        guard !isEatingSequenceRunning, !refuseFeedingIfNeeded() else { return }
        isEatingSequenceRunning = true
        isDraggingFood = false
        draggedFood = nil
        isNearMouth = false
        dragStardustTrail.removeAll()
        
        // 1. Position food at mouth
        flyingFood = food
        flyingFoodPosition = startPoint
        flyingFoodScale = 1.0
        flyingFoodRotation = 0.0
        flyingFoodOpacity = 1.0
        
        playgroundMood = .anticipatingFood
        
        withAnimation(.interpolatingSpring(stiffness: 240, damping: 20)) {
            flyingFoodPosition = dragonMouthPosition
            flyingFoodRotation = 25.0
        }
        
        // 2. Chomp moment (at 0.28s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            AudioService.shared.playMunchChompSound()
            HapticsService.shared.medium()
            
            // Squash and shrink food into mouth
            withAnimation(.easeIn(duration: 0.12)) {
                flyingFoodScale = 0.0
                flyingFoodOpacity = 0.0
            }
            
            // Spawn bite crumbs!
            spawnBiteCrumbs(at: dragonMouthPosition, color: food.primaryColor)
            
            // Dragon enters chewing mood
            playgroundMood = .eating
            let isFav = (food == activeDragon.favoriteFoodType)
            nomNomSpeechText = isFav ? "❤️ YUMMY!! Favorite Treat! ✨" : "Nom nom nom! 😋"
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                nomNomSpeechScale = 1.0
            }
            
            // Play chewing sounds
            AudioService.shared.playFeedingSound()
            
            // 3. Swallow & Joyful Celebration (after 1.35s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
                flyingFood = nil
                AudioService.shared.playSwallowSound()
                HapticsService.shared.light()
                
                // Apply feeding in GameManager
                let result = gameManager.feedActiveDragon(food: food)
                
                withAnimation(.easeOut(duration: 0.25)) {
                    nomNomSpeechScale = 0.0
                    nomNomSpeechText = nil
                }
                
                if result.outcome == .tummyAche {
                    nomNomSpeechText = "Ugh… too full! 🤢"
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { nomNomSpeechScale = 1.0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { nomNomSpeechScale = 0.0; nomNomSpeechText = nil }
                    }
                    playgroundMood = .sleepy
                } else {
                    // Joyful dragon reaction
                    playgroundMood = .happy
                    AudioService.shared.playDragonGiggle()
                }
                
                // Display XP Badge
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    floatingXPBadge = result.gainedXP
                    showFavoriteCelebration = result.isFavorite
                }
                
                // 4. Return to idle (after 1.2s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut) {
                        floatingXPBadge = nil
                        showFavoriteCelebration = false
                        playgroundMood = .idle
                        isEatingSequenceRunning = false
                    }
                }
            }
        }
    }
    
    private func spawnBiteCrumbs(at center: CGPoint, color: Color) {
        var newCrumbs: [BiteCrumb] = []
        let palette = [color, DragonPalette.buttercup, DragonPalette.coral, color.opacity(0.8)]
        for i in 0..<8 {
            let angle = Double(i) * (.pi / 4.0) + Double.random(in: -0.25...0.25)
            let speed = CGFloat.random(in: 25...45)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed - 8
            newCrumbs.append(
                BiteCrumb(
                    position: center,
                    velocity: CGPoint(x: vx, y: vy),
                    color: palette.randomElement() ?? color,
                    size: CGFloat.random(in: 4...8),
                    opacity: 1.0
                )
            )
        }
        eatingCrumbs = newCrumbs
        
        withAnimation(.easeOut(duration: 0.5)) {
            for idx in eatingCrumbs.indices {
                eatingCrumbs[idx].position.x += eatingCrumbs[idx].velocity.x
                eatingCrumbs[idx].position.y += eatingCrumbs[idx].velocity.y
                eatingCrumbs[idx].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            eatingCrumbs.removeAll()
        }
    }
    
    private func castElementalPower() {
        guard gameManager.triggerElementalPower(primaryPower) else { return }
        
        setTemporaryMood(.castingPower, duration: 1.6)
        activePowerFX = primaryPower
    }
    
    private func setTemporaryMood(_ mood: DragonMood, duration: Double) {
        playgroundMood = mood
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            playgroundMood = .idle
        }
    }
}

// MARK: - Preference Key & Crumb Model

struct DragonMouthPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

struct BiteCrumb: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double = 1.0
}
