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
    @State private var showAchievements: Bool = false
    @State private var floatingXPBadge: Int? = nil
    @State private var showFavoriteCelebration: Bool = false
    @State private var selectedFood: FoodType? = nil
    @State private var showFoodTray: Bool = false
    @State private var showParentGate: Bool = false
    
    // Dragon mouth position in playground coordinate space
    @State private var dragonMouthPosition: CGPoint = CGPoint(x: 200, y: 380)
    
    // Drag-and-drop feeding state
    @State private var draggedFood: FoodType? = nil
    @State private var dragCurrentPosition: CGPoint = .zero
    @State private var isDraggingFood: Bool = false
    @State private var isNearMouth: Bool = false
    @State private var dragStardustTrail: [CGPoint] = []
    @State private var playgroundOrigin: CGPoint = .zero
    
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
                    // Today's wish, as a speech bubble above the dragon
                    if let wish = gameManager.state.daily.wishes[activeDragon.id], !wish.granted, !isSpirit {
                        Label(wish.title, systemImage: wish.iconName)
                            .font(.clay(13, .heavy))
                            .foregroundColor(DragonPalette.textDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.white.opacity(0.95)).shadow(color: DragonPalette.softShadow, radius: 4, y: 2))
                    }
                    
                    // Dragon View with geometry preference tracking
                    DragonView(
                        dragon: activeDragon,
                        mood: (isAsleep || isSpirit) ? .sleepy : playgroundMood,
                        // Smaller on short phones so the dragon card doesn't cover its head
                        size: UIScreen.main.bounds.height < 750 ? 150 : 210,
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
            
            // 4. Home HUD: top bar, dragon card, then Today, the food tray and the care dock
            VStack(spacing: 10) {
                topHUDBar
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                dragonCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 0)

                if showFoodTray {
                    foodTray
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    todayCard
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                }

                careDock
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .overlay { denSwitcher }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showFoodTray)
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
                        .font(.clay(24, .heavy))
                        .foregroundColor(ClayColor.coralShade)
                    if showFavoriteCelebration {
                        Label("Favorite food · 2× XP", systemImage: "heart.fill")
                            .font(.clay(15, .bold))
                            .foregroundColor(ClayColor.rose)
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
            
            // 10. Settings sit behind the parent gate
            if showParentGate {
                ParentGateView(
                    onSuccess: {
                        showParentGate = false
                        gameManager.navigate(to: .settings)
                    },
                    onCancel: { showParentGate = false }
                )
                .transition(.opacity)
                .zIndex(70)
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
        .onChange(of: showParentGate || showEvolutionModal) { _, shown in gameManager.isHomeModalPresented = shown }
        .onDisappear { gameManager.isHomeModalPresented = false }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { playgroundOrigin = geo.frame(in: .global).origin }
                    .onChange(of: geo.frame(in: .global).origin) { _, origin in playgroundOrigin = origin }
            }
        )
        .onPreferenceChange(DragonMouthPreferenceKey.self) { pos in
            if pos != .zero {
                dragonMouthPosition = pos
            }
        }
        .sheet(isPresented: $showPowersBook) {
            PowerEncyclopediaView(dragon: activeDragon)
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
            
            Text(isNearMouth ? "Drop to munch!" : "Bring the treat here")
                .font(.clay(13, .heavy))
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
                .font(.clay(16, .heavy))
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
    
    // MARK: - Top Bar

    private var topHUDBar: some View {
        HStack(spacing: 8) {
            StarCounterView(count: gameManager.totalStars)
            ClayPill(systemName: "flame.fill", iconColor: ClayColor.coral,
                     value: "\(gameManager.state.streak.current)", accessibilityLabel: "Care streak")
            Spacer()
            ClayIconButton(systemName: "gearshape.fill", accessibilityLabel: "Settings") {
                showParentGate = true
            }
        }
    }

    // MARK: - Dragon Card

    private var dragonCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(activeDragon.badgedName)
                        .font(.clay(24, .heavy))
                        .foregroundColor(ClayColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 6) {
                        Label(activeDragon.element.rawValue, systemImage: activeDragon.element.iconName)
                            .foregroundColor(ClayColor.inkSoft)
                        Text("Lvl \(stats.level) · \(stats.growthStage.rawValue)")
                            .foregroundColor(ClayColor.inkSoft)
                    }
                    .font(.clay(13, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 4)
                ClayIconButton(systemName: "sparkles", size: 40, tint: ClayColor.accent, badge: availablePowers.count, accessibilityLabel: "Powers") {
                    showPowersBook = true
                }
                ClayIconButton(systemName: "trophy.fill", size: 40, tint: ClayColor.sunShade, badge: unlockedAchievementsCount, accessibilityLabel: "Achievements") {
                    showAchievements = true
                }
            }

            ClayMeter(value: stats.currentLevelProgress * 100, color: ClayColor.accent, height: 8)

            HStack(spacing: 8) {
                vitalMeter(icon: "fork.knife", value: stats.hunger, color: ClayColor.coral)
                vitalMeter(icon: "heart.fill", value: stats.happiness, color: ClayColor.rose)
                vitalMeter(icon: "bolt.fill", value: stats.energy, color: ClayColor.sun)
                vitalMeter(icon: "figure.run", value: stats.fitness, color: ClayColor.sky)
                vitalMeter(icon: "cross.fill", value: stats.health, color: ClayColor.mint)
            }

            statusRow
        }
        .padding(14)
        .claySurface(cornerRadius: 26)
    }

    private var unlockedAchievementsCount: Int {
        gameManager.state.achievements.filter { $0.isUnlocked }.count
    }

    /// Illness, tummy ache and evolution as small clay chips; empty when all is well.
    @ViewBuilder
    private var statusRow: some View {
        let canEvolve = stats.canEvolve && stats.condition == .healthy
        if stats.condition.illness != nil || stats.tummyAcheUntil != nil || canEvolve {
            HStack(spacing: 8) {
                if let illness = stats.condition.illness {
                    Label(illness.displayName, systemImage: "thermometer.medium")
                        .font(.clay(13, .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(ClayColor.coralShade))
                    Button {
                        if !gameManager.useHealingHerb() { gameManager.navigate(to: .foodInventoryShop) }
                    } label: {
                        Label(gameManager.state.itemCount(.healingHerb) > 0 ? "Cure ×\(gameManager.state.itemCount(.healingHerb))" : "Buy herb",
                              systemImage: "leaf.fill")
                            .font(.clay(13, .heavy))
                            .foregroundColor(ClayColor.ink)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                    .buttonStyle(ClayButtonStyle(color: ClayColor.mint, cornerRadius: 14))
                } else if stats.tummyAcheUntil != nil {
                    Label("Tummy ache", systemImage: "face.dashed")
                        .font(.clay(13, .heavy))
                        .foregroundColor(ClayColor.coralShade)
                }
                Spacer(minLength: 0)
                if canEvolve {
                    Button {
                        HapticsService.shared.medium()
                        showEvolutionModal = true
                    } label: {
                        Label("Evolve", systemImage: "arrow.up.circle.fill")
                            .font(.clay(14, .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                    .buttonStyle(ClayButtonStyle(color: ClayColor.accent, cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Den switcher

    /// Arrows beside the dragon when the den holds more than one dragon.
    @ViewBuilder
    private var denSwitcher: some View {
        let den = gameManager.state.denDragons
        if den.count > 1, let index = den.firstIndex(where: { $0.id == activeDragon.id }) {
            HStack {
                ClayIconButton(systemName: "chevron.left", size: 40, accessibilityLabel: "Previous dragon") {
                    gameManager.selectDragon(id: den[(index + den.count - 1) % den.count].id)
                }
                Spacer()
                ClayIconButton(systemName: "chevron.right", size: 40, accessibilityLabel: "Next dragon") {
                    gameManager.selectDragon(id: den[(index + 1) % den.count].id)
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Today

    private var todayCard: some View {
        let quests = gameManager.state.daily.quests
        let done = quests.filter(\.isComplete).count
        return Button {
            HapticsService.shared.light()
            gameManager.navigate(to: .today)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ClayColor.ink)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ClayColor.sun))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Today's quests")
                            .font(.clay(16, .heavy))
                            .foregroundColor(ClayColor.ink)
                        Spacer()
                        Text("\(done)/\(max(quests.count, 1))")
                            .font(.clay(15, .heavy))
                            .foregroundColor(ClayColor.inkSoft)
                    }
                    ClayMeter(value: quests.isEmpty ? 0 : Double(done) / Double(quests.count) * 100, color: ClayColor.mint, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(ClayColor.inkSoft)
            }
            .padding(12)
        }
        .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 22))
    }

    private var sleepOverlay: some View {
        ZStack(alignment: .top) {
            Color(red: 0.12, green: 0.10, blue: 0.30).opacity(0.35)
                .ignoresSafeArea()
            Label("\(activeDragon.name) is sleeping", systemImage: "moon.zzz.fill")
                .font(.clay(16, .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .padding(.top, 300)
        }
        .allowsHitTesting(false)
    }
    
    private var spiritOverlay: some View {
        let status = DragonStatus.describe(stats, now: gameManager.clock.now(), calendar: gameManager.calendar, mode: gameManager.state.careMode)
        let embers = gameManager.state.itemCount(.phoenixEmber)
        return ZStack {
            Color(red: 0.20, green: 0.18, blue: 0.40).opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                DragonView(dragon: activeDragon, mood: .sleepy, size: 130, allowInteractivePetting: false)
                    .opacity(0.45)
                    .colorMultiply(Color(red: 0.8, green: 0.85, blue: 1.0))
                Text("\(activeDragon.name) has become a spirit")
                    .font(.clay(20, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                    .multilineTextAlignment(.center)
                if let status { DragonStatusBadge(status: status) }
                Text("A Phoenix Ember can bring them back. They'll keep their level but lose one growth stage.")
                    .font(.clay(13, .medium))
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
                }
                Button("See all dragons") { gameManager.navigate(to: .dragonCollection) }
                    .font(.clay(15, .bold))
                    .foregroundColor(DragonPalette.softPurple)
            }
            .padding(22)
            .claySurface(cornerRadius: 24)
            .padding(.horizontal, 26)
        }
    }
    
    private func vitalMeter(icon: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            ClayMeter(value: value, color: color, height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(Int(value)) percent")
    }

    // MARK: - Care Dock

    private var careDock: some View {
        HStack(alignment: .top, spacing: 0) {
            dockButton(showFoodTray ? "Close" : "Feed", icon: showFoodTray ? "xmark" : "fork.knife", color: ClayColor.coral,
                       badge: showFoodTray ? 0 : totalFoodCount) {
                showFoodTray.toggle()
            }
            dockButton("Pet", icon: "hand.wave.fill", color: ClayColor.rose, enabled: !isSpirit) {
                gameManager.petActiveDragon()
                setTemporaryMood(.happy, duration: 1.2)
            }
            dockButton("Power", icon: primaryPower.iconName, color: activeDragon.element.themeColor,
                       enabled: stats.energy >= primaryPower.energyCost && !isSpirit && !isAsleep) {
                castElementalPower()
            }
            dockButton(stats.isSleepingEarly ? "Wake" : "Sleep", icon: stats.isSleepingEarly ? "sun.max.fill" : "moon.fill",
                       color: ClayColor.sky, enabled: !isSpirit && (stats.isSleepingEarly || gameManager.canLightsOut)) {
                if stats.isSleepingEarly { gameManager.wakeUp() } else { gameManager.lightsOut() }
            }
            Button {
                HapticsService.shared.medium()
                AudioService.shared.playPop()
                gameManager.navigate(to: .trainingHub)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "play.fill").font(.system(size: 20, weight: .heavy))
                    Text("Train").font(.clay(15, .heavy))
                }
                .foregroundColor(.white)
                .frame(width: 76, height: 66)
            }
            .buttonStyle(ClayButtonStyle(color: ClayColor.accent, cornerRadius: 24))
            .accessibilityLabel("Train")
        }
    }

    private var totalFoodCount: Int {
        gameManager.state.foodInventory.values.reduce(0, +)
    }

    private func dockButton(_ title: String, icon: String, color: Color, badge: Int = 0, enabled: Bool = true,
                            action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            ClayIconButton(systemName: icon, size: 52, tint: color, badge: badge, accessibilityLabel: title, action: action)
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.45)
            Text(title)
                .font(.clay(12, .heavy))
                .foregroundColor(ClayColor.ink)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Food Tray

    /// Food to tap (it flies to the dragon) or hold and drag into its mouth.
    private var foodTray: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tap a snack, or hold and drag it to \(activeDragon.name)")
                    .font(.clay(13, .bold))
                    .foregroundColor(ClayColor.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Button("Shop") { gameManager.navigate(to: .foodInventoryShop) }
                    .font(.clay(14, .heavy))
                    .foregroundColor(ClayColor.accent)
            }
            .padding(.horizontal, 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FoodType.allCases) { food in
                        foodChip(food: food)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .claySurface(cornerRadius: 28)
        .padding(.horizontal, 10)
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
                        .font(.clay(10, .heavy))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(food.primaryColor))
                        .offset(x: 2, y: -2)
                }
            }
            
            Text(food.displayName)
                .font(.clay(11, .bold))
                .foregroundColor(DragonPalette.textDark)
                .lineLimit(1)
            
            if isFavorite && activeDragon.stats.favoriteFoodDiscovered {
                Label("Fav", systemImage: "heart.fill")
                    .font(.clay(10, .heavy))
                    .foregroundColor(ClayColor.rose)
            }
        }
        .frame(width: 76, height: 86)
        .padding(.vertical, 6)
        .claySurface(cornerRadius: 18, elevation: 0.7)
        .contentShape(Rectangle())
        .opacity(count > 0 ? 1.0 : 0.5)
        // UIKit recognizers so a quick swipe still scrolls the strip; the drag starts only after a hold.
        .overlay(
            HoldDragTapView(
                onTap: { location in
                    guard count > 0 && !isEatingSequenceRunning && !isDraggingFood else { return }
                    launchFlyingFood(food: food, from: toPlayground(location))
                },
                onDragChanged: { location in
                    guard count > 0 && !isEatingSequenceRunning else { return }
                    foodDragChanged(food: food, to: toPlayground(location))
                },
                onDragEnded: { location in
                    foodDragEnded(at: toPlayground(location))
                }
            )
        )
    }
    
    /// Converts a window location into the playground's coordinate space.
    private func toPlayground(_ global: CGPoint) -> CGPoint {
        CGPoint(x: global.x - playgroundOrigin.x, y: global.y - playgroundOrigin.y)
    }
    
    private func foodDragChanged(food: FoodType, to location: CGPoint) {
        if draggedFood == nil {
            draggedFood = food
            isDraggingFood = true
            HapticsService.shared.light()
        }
        dragCurrentPosition = location
        
        // Trailing stardust
        dragStardustTrail.append(location)
        if dragStardustTrail.count > 6 {
            dragStardustTrail.removeFirst()
        }
        
        let dist = hypot(location.x - dragonMouthPosition.x, location.y - dragonMouthPosition.y)
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
    
    private func foodDragEnded(at location: CGPoint) {
        guard isDraggingFood, let food = draggedFood else { return }
        let dist = hypot(location.x - dragonMouthPosition.x, location.y - dragonMouthPosition.y)
        if dist < 170 {
            startFeedingSequence(food: food, from: location)
            return
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
