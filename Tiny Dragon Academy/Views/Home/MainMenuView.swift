//
//  MainMenuView.swift
//  Tiny Dragon Academy
//
//  Main hub view featuring an animated floating dragon island, companion dragon,
//  star display, parental-gated settings, and navigation cards to all games.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var showParentGate: Bool = false
    @State private var companionMood: DragonMood = .idle
    @State private var islandBobOffset: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background Sky
            DragonPalette.skyGradient
                .ignoresSafeArea()
            
            FloatingParticlesView(particleCount: 16, themeColor: DragonPalette.softPurple)
            
            VStack(spacing: 0) {
                // Top Header: Star Counter & Settings
                topHeaderView
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                
                Spacer(minLength: 8)
                
                // Central Animated Floating Island & Companion Dragon
                centralIslandView
                    .frame(maxHeight: 280)
                
                Spacer(minLength: 12)
                
                // Navigation Hub Buttons (Play, My Dragons, Dress-Up, Island)
                navigationGrid
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            
            // Parent Gate Modal
            if showParentGate {
                ParentGateView(
                    onSuccess: {
                        showParentGate = false
                        gameManager.navigate(to: .settings)
                    },
                    onCancel: {
                        showParentGate = false
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                islandBobOffset = -12.0
            }
        }
    }
    
    // MARK: - Top Header
    
    private var topHeaderView: some View {
        HStack {
            // Star Counter
            StarCounterView(count: gameManager.totalStars, isInteractive: true) {
                HapticsService.shared.light()
            }
            
            Spacer()
            
            // Settings Button with Grown-up Lock Icon
            Button(action: {
                HapticsService.shared.medium()
                AudioService.shared.playPop()
                showParentGate = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                }
                .foregroundColor(DragonPalette.textDark)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: DragonPalette.softShadow, radius: 5, x: 0, y: 3)
                )
            }
            .accessibilityLabel("Settings (Grown-ups only)")
        }
    }
    
    // MARK: - Central Island & Companion Dragon
    
    private var centralIslandView: some View {
        ZStack {
            // Floating Island Base
            ZStack {
                // Island Soil / Rock
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.75, green: 0.60, blue: 0.48), Color(red: 0.58, green: 0.44, blue: 0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 320, height: 110)
                    .offset(y: 65)
                
                // Lush Grass Island Top
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [DragonPalette.mintGreen, Color(red: 0.58, green: 0.88, blue: 0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 310, height: 95)
                    .overlay(
                        Ellipse().stroke(Color.white.opacity(0.8), lineWidth: 3)
                    )
                    .offset(y: 40)
                
                // Mini Scenery: Mushroom house & Blossom tree
                MushroomHouseView(size: 50)
                    .offset(x: -105, y: 15)
                
                BlossomTreeView(size: 55)
                    .offset(x: 105, y: 10)
            }
            
            // Active Baby Dragon Companion!
            VStack(spacing: 6) {
                DragonView(
                    dragon: gameManager.activeDragon,
                    mood: companionMood,
                    size: 170,
                    allowInteractivePetting: false
                )
                .onTapGesture {
                    HapticsService.shared.medium()
                    AudioService.shared.playPop()
                    gameManager.navigate(to: .dragonPlayground)
                }
                
                // Interactive Raise & Feed Pill
                Button(action: {
                    HapticsService.shared.medium()
                    AudioService.shared.playPop()
                    gameManager.navigate(to: .dragonPlayground)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13))
                            .foregroundColor(DragonPalette.coral)
                        Text("\(gameManager.activeDragon.name) • Lvl \(gameManager.activeDragon.stats.level) \(gameManager.activeDragon.stats.growthStage.rawValue)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(DragonPalette.coral)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: DragonPalette.softShadow, radius: 5, x: 0, y: 3)
                    )
                }
            }
            .offset(y: -15)
        }
        .offset(y: islandBobOffset)
    }
    
    // MARK: - Navigation Hub Buttons
    
    private var navigationGrid: some View {
        VStack(spacing: 14) {
            // Main Big Play Button
            Button(action: {
                HapticsService.shared.medium()
                AudioService.shared.playPop()
                gameManager.navigate(to: .miniGamesHub)
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 34, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Play Games")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                        Text("4 fun dragon adventures!")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .opacity(0.9)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 26))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient(
                                colors: [DragonPalette.coral, DragonPalette.rosyPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(Color.white.opacity(0.6), lineWidth: 3)
                        )
                        .shadow(color: DragonPalette.coral.opacity(0.4), radius: 8, x: 0, y: 5)
                )
            }
            
            // 3 Sub-features: My Dragons, Dress Up, Island
            HStack(spacing: 12) {
                menuTile(
                    title: "My Dragons",
                    icon: "heart.circle.fill",
                    color: DragonPalette.softPurple
                ) {
                    gameManager.navigate(to: .dragonCollection)
                }
                
                menuTile(
                    title: "Dress-Up",
                    icon: "sparkles.rectangle.stack.fill",
                    color: DragonPalette.buttercup,
                    textColor: DragonPalette.textDark
                ) {
                    gameManager.navigate(to: .dragonDressUp)
                }
                
                menuTile(
                    title: "My Island",
                    icon: "leaf.circle.fill",
                    color: DragonPalette.mintGreen,
                    textColor: DragonPalette.textDark
                ) {
                    gameManager.navigate(to: .islandBuilder)
                }
            }
        }
    }
    
    private func menuTile(
        title: String,
        icon: String,
        color: Color,
        textColor: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.7), lineWidth: 2.5)
                    )
                    .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 4)
            )
        }
    }
}
