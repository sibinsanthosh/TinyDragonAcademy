//
//  ShapeMagicGameView.swift
//  Tiny Dragon Academy
//
//  Game B: Shape Magic.
//  Children match geometric and magical shapes to their glowing outlines on a spell tablet.
//

import SwiftUI

enum MagicShapeType: String, CaseIterable, Identifiable {
    case circle = "Circle"
    case square = "Square"
    case triangle = "Triangle"
    case star = "Star"
    case heart = "Heart"
    case diamond = "Diamond"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .circle: return DragonPalette.skyBlue
        case .square: return DragonPalette.mintGreen
        case .triangle: return DragonPalette.buttercup
        case .star: return DragonPalette.softPurple
        case .heart: return DragonPalette.coral
        case .diamond: return DragonPalette.lavender
        }
    }
}

struct ShapeMagicGameView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var round: Int = 1
    @State private var currentShapes: [MagicShapeType] = []
    @State private var matchedShapes: Set<MagicShapeType> = []
    @State private var selectedShape: MagicShapeType? = nil
    @State private var showVictory: Bool = false
    
    var body: some View {
        ZStack {
            DragonPalette.skyGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                headerView
                
                // Instructions
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20))
                        .foregroundColor(DragonPalette.softPurple)
                    Text("Place each magical shape in its outline!")
                        .font(.clay(17, .bold))
                        .foregroundColor(DragonPalette.textDark)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.9)))
                
                Spacer()
                
                // Magical Runestone Tablet (Outlines)
                spellTabletView
                
                Spacer()
                
                // Bottom Tray of Available Shapes
                shapesTrayView
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
            
            Text("Round \(round) of 3")
                .font(.clay(16, .bold))
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.85)))
            
            Spacer()
            
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Spell Tablet
    
    private var spellTabletView: some View {
        VStack(spacing: 16) {
            Text("Spell Tablet")
                .font(.clay(16, .bold))
                .foregroundColor(DragonPalette.textMuted)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)], spacing: 16) {
                ForEach(currentShapes) { shape in
                    tabletSlot(for: shape)
                }
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(DragonPalette.softPurple.opacity(0.4), lineWidth: 3)
                )
                .shadow(color: DragonPalette.softShadow, radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 12)
    }
    
    private func tabletSlot(for shape: MagicShapeType) -> some View {
        let isMatched = matchedShapes.contains(shape)
        
        return Button(action: {
            if let selected = selectedShape {
                tryMatch(shape: selected, target: shape)
            }
        }) {
            ZStack {
                // Outline border slot
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isMatched ? shape.color : Color(red: 0.75, green: 0.75, blue: 0.85),
                        style: StrokeStyle(lineWidth: 3, dash: isMatched ? [] : [6, 4])
                    )
                    .frame(width: 80, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isMatched ? shape.color.opacity(0.2) : Color.white.opacity(0.4))
                    )
                
                // Shape inside
                if isMatched {
                    shapeGraphic(for: shape, size: 52, color: shape.color)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Dim gray silhouette outline
                    shapeGraphic(for: shape, size: 50, color: Color(red: 0.78, green: 0.78, blue: 0.85))
                        .opacity(0.6)
                }
            }
        }
    }
    
    // MARK: - Available Shapes Tray
    
    private var shapesTrayView: some View {
        VStack(spacing: 10) {
            Text("Tap a shape, then tap its outline:")
                .font(.clay(14, .medium))
                .foregroundColor(DragonPalette.textMuted)
            
            HStack(spacing: 14) {
                ForEach(currentShapes.filter { !matchedShapes.contains($0) }) { shape in
                    let isSelected = (selectedShape == shape)
                    
                    Button(action: {
                        HapticsService.shared.selection()
                        AudioService.shared.playPop()
                        selectedShape = shape
                    }) {
                        ZStack {
                            Circle()
                                .fill(shape.color)
                                .frame(width: 66, height: 66)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: isSelected ? 4 : 2)
                                )
                                .shadow(color: shape.color.opacity(0.4), radius: isSelected ? 8 : 4)
                            
                            shapeGraphic(for: shape, size: 36, color: .white)
                        }
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSelected)
                    }
                }
            }
            .frame(height: 75)
        }
    }
    
    @ViewBuilder
    private func shapeGraphic(for shape: MagicShapeType, size: CGFloat, color: Color) -> some View {
        switch shape {
        case .circle:
            Circle().fill(color).frame(width: size, height: size)
        case .square:
            RoundedRectangle(cornerRadius: 10).fill(color).frame(width: size, height: size)
        case .triangle:
            Image(systemName: "triangle.fill").font(.system(size: size * 0.85)).foregroundStyle(color)
        case .star:
            StarShape().fill(color).frame(width: size, height: size)
        case .heart:
            HeartShape().fill(color).frame(width: size, height: size)
        case .diamond:
            Image(systemName: "suit.diamond.fill").font(.system(size: size * 0.85)).foregroundStyle(color)
        }
    }
    
    private func tryMatch(shape: MagicShapeType, target: MagicShapeType) {
        if shape == target {
            // SUCCESS
            HapticsService.shared.success()
            AudioService.shared.playChime(frequency: 880.0)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                matchedShapes.insert(shape)
                selectedShape = nil
            }
            
            // Check round complete
            if matchedShapes.count == currentShapes.count {
                if round < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        round += 1
                        setupRound()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        gameManager.awardStars(3, forGame: .shapeMagic)
                        AudioService.shared.playVictoryFanfare()
                        showVictory = true
                    }
                }
            }
        } else {
            // Gentle wrong hint
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
        matchedShapes = []
        selectedShape = nil
        
        let pool = MagicShapeType.allCases
        let count = min(pool.count, round + 2) // Round 1: 3 shapes, Round 2: 4 shapes, Round 3: 5 shapes
        currentShapes = Array(pool.prefix(count)).shuffled()
    }
}
