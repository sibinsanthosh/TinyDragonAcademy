//
//  CountStarsGameView.swift
//  Tiny Dragon Academy
//
//  Game C: Count the Stars.
//  Children count glowing stars and magical fireflies with 1-to-1 visual counting aids,
//  progressive numbers 1-10, and multiple choice keypad.
//

import SwiftUI

struct CountableStar: Identifiable {
    let id = UUID()
    var countOrder: Int? = nil // Assigned when tapped for 1-to-1 correspondence
    let xNormalized: CGFloat
    let yNormalized: CGFloat
}

struct CountStarsGameView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var round: Int = 1
    @State private var targetCount: Int = 3
    @State private var stars: [CountableStar] = []
    @State private var numberOptions: [Int] = []
    @State private var currentCounted: Int = 0
    @State private var showVictory: Bool = false
    
    var body: some View {
        ZStack {
            DragonPalette.nightGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                headerView
                
                // Instructions
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(DragonPalette.buttercup)
                    Text("Count the stars! Tap them to count:")
                        .font(.clay(17, .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .claySurface(cornerRadius: 100, elevation: 0.7)
                
                // Starry Sky Field (Play area)
                GeometryReader { geo in
                    ZStack {
                        // Background moon
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 55))
                            .foregroundStyle(DragonPalette.buttercup.opacity(0.3))
                            .position(x: geo.size.width * 0.85, y: 40)
                        
                        // Stars to count
                        ForEach(stars) { star in
                            starView(star: star, in: geo.size)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                    )
                }
                .frame(maxHeight: 280)
                .padding(.horizontal, 12)
                
                // Number Choices Pad
                numberChoicesView
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            
            if showVictory {
                GameVictoryModal(
                    starsEarned: 3,
                    onPlayAgain: {
                        startNewGame()
                    },
                    onBackToMenu: {
                        gameManager.navigate(to: .trainingHub)
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
            ClayIconButton(systemName: "chevron.left", accessibilityLabel: "Back") {
                gameManager.navigate(to: .trainingHub)
            }
            
            Spacer()
            
            Text("Round \(round) of 3")
                .font(.clay(16, .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .claySurface(cornerRadius: 100, elevation: 0.7)
            
            Spacer()
            
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Star View
    
    private func starView(star: CountableStar, in size: CGSize) -> some View {
        let posX = star.xNormalized * size.width
        let posY = star.yNormalized * size.height
        let isCounted = (star.countOrder != nil)
        
        return Button(action: {
            tapStar(star)
        }) {
            ZStack {
                // Star glow
                Circle()
                    .fill(isCounted ? DragonPalette.buttercup.opacity(0.6) : Color.white.opacity(0.2))
                    .frame(width: 58, height: 58)
                
                // Star graphic
                StarShape()
                    .fill(isCounted ? DragonPalette.buttercup : Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: isCounted ? DragonPalette.buttercup : Color.clear, radius: 8)
                
                // Number badge
                if let order = star.countOrder {
                    Text("\(order)")
                        .font(.clay(18, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                        .transition(.scale)
                }
            }
        }
        .position(x: posX, y: posY)
        .scaleEffect(isCounted ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isCounted)
    }
    
    // MARK: - Number Choices
    
    private var numberChoicesView: some View {
        VStack(spacing: 10) {
            Text("How many stars did you find?")
                .font(.clay(16, .bold))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 16) {
                ForEach(numberOptions, id: \.self) { num in
                    Button(action: {
                        checkAnswer(num)
                    }) {
                        Text("\(num)")
                            .font(.clay(32, .heavy))
                            .foregroundColor(DragonPalette.textDark)
                            .frame(minWidth: 70, minHeight: 68)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(DragonPalette.buttercup)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(color: DragonPalette.buttercup.opacity(0.4), radius: 6, x: 0, y: 4)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Game Logic
    
    private func tapStar(_ star: CountableStar) {
        guard let idx = stars.firstIndex(where: { $0.id == star.id }) else { return }
        
        if stars[idx].countOrder == nil {
            currentCounted += 1
            stars[idx].countOrder = currentCounted
            
            HapticsService.shared.light()
            // Ascending pitch for counting: 523.25 * (1 + 0.1 * step)
            let pitch = 523.25 * (1.0 + Double(currentCounted) * 0.08)
            AudioService.shared.playChime(frequency: pitch)
        }
    }
    
    private func checkAnswer(_ choice: Int) {
        if choice == targetCount {
            // SUCCESS
            HapticsService.shared.success()
            AudioService.shared.playChime(frequency: 1046.50)
            
            if round < 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    round += 1
                    setupRound()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    gameManager.awardStars(3, forGame: .countStars)
                    AudioService.shared.playVictoryFanfare()
                    showVictory = true
                }
            }
        } else {
            HapticsService.shared.light()
            AudioService.shared.playEncouragement()
        }
    }
    
    private func startNewGame() {
        round = 1
        showVictory = false
        setupRound()
    }
    
    private func setupRound() {
        currentCounted = 0
        
        // Progressive difficulty: Round 1: 2-4, Round 2: 4-6, Round 3: 6-9
        switch round {
        case 1:
            targetCount = Int.random(in: 2...4)
        case 2:
            targetCount = Int.random(in: 4...6)
        default:
            targetCount = Int.random(in: 6...9)
        }
        
        // Generate pseudo-random positions well-spaced in normalized coords
        var generated: [CountableStar] = []
        let margin: CGFloat = 0.15
        
        for _ in 0..<targetCount {
            var posX: CGFloat = 0
            var posY: CGFloat = 0
            var tooClose = true
            var attempts = 0
            
            while tooClose && attempts < 20 {
                posX = CGFloat.random(in: margin...(1.0 - margin))
                posY = CGFloat.random(in: margin...(1.0 - margin))
                tooClose = generated.contains(where: {
                    hypot($0.xNormalized - posX, $0.yNormalized - posY) < 0.22
                })
                attempts += 1
            }
            generated.append(CountableStar(xNormalized: posX, yNormalized: posY))
        }
        stars = generated
        
        // Generate 3 choices including the correct answer
        var choices = Set<Int>()
        choices.insert(targetCount)
        while choices.count < 3 {
            let offset = Int.random(in: -2...2)
            let wrong = targetCount + offset
            if wrong > 0 && wrong != targetCount && wrong <= 10 {
                choices.insert(wrong)
            }
        }
        numberOptions = Array(choices).sorted()
    }
}
