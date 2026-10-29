//
//  DragonPuzzleGameView.swift
//  Tiny Dragon Academy
//
//  Game D: Dragon Puzzle.
//  Children assemble puzzle pieces into a 2x2 grid to reveal an adorable baby dragon.
//  Features magnetic snap, live animations on completion, and celebration fanfare.
//

import SwiftUI

struct PuzzlePiece: Identifiable, Equatable {
    let id: Int // 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
    let row: Int
    let col: Int
}

struct DragonPuzzleGameView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var placedPieces: [Int: Int] = [:] // slotIndex: pieceId
    @State private var selectedPieceId: Int? = nil
    @State private var availablePieces: [Int] = [0, 1, 2, 3].shuffled()
    @State private var isComplete: Bool = false
    @State private var showVictory: Bool = false
    
    private let gridSize = 2
    
    var body: some View {
        ZStack {
            DragonPalette.sunsetGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                headerView
                
                // Instructions
                HStack(spacing: 8) {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DragonPalette.coral)
                    Text(isComplete ? "Hooray! The puzzle is complete!" : "Place the pieces to reveal the dragon!")
                        .font(.clay(16, .bold))
                        .foregroundColor(DragonPalette.textDark)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.9)))
                
                Spacer()
                
                // Puzzle Board (2x2 Frame)
                puzzleBoardView
                    .frame(width: 260, height: 260)
                
                Spacer()
                
                // Bottom Available Pieces Tray
                if !isComplete {
                    piecesTrayView
                        .padding(.bottom, 24)
                } else {
                    KidButton(
                        title: "Great Job!",
                        icon: "sparkles",
                        backgroundColor: DragonPalette.softPurple,
                        minWidth: 200
                    ) {
                        gameManager.awardStars(3, forGame: .dragonPuzzle)
                        showVictory = true
                    }
                    .padding(.bottom, 24)
                }
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
            
            Text("Baby Dragon Puzzle")
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
    
    // MARK: - Puzzle Board
    
    private var puzzleBoardView: some View {
        ZStack {
            // Completed Living Dragon View
            if isComplete {
                DragonView(
                    dragon: gameManager.activeDragon,
                    mood: .celebration,
                    size: 240,
                    allowInteractivePetting: true
                )
                .transition(.scale)
            } else {
                // 2x2 Slot Grid
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        slotView(slotIndex: 0)
                        slotView(slotIndex: 1)
                    }
                    HStack(spacing: 4) {
                        slotView(slotIndex: 2)
                        slotView(slotIndex: 3)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: DragonPalette.softShadow, radius: 10)
                )
            }
        }
    }
    
    private func slotView(slotIndex: Int) -> some View {
        let isOccupied = placedPieces[slotIndex] != nil
        
        return Button(action: {
            if let selected = selectedPieceId {
                tryPlacePiece(pieceId: selected, inSlot: slotIndex)
            }
        }) {
            ZStack {
                // Blank slot outline
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        Color(red: 0.75, green: 0.70, blue: 0.85),
                        style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                    )
                    .frame(width: 115, height: 115)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.5))
                    )
                
                if let pieceId = placedPieces[slotIndex] {
                    // Render Piece quadrant
                    pieceGraphic(pieceId: pieceId, size: 115)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.75, green: 0.70, blue: 0.85).opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Pieces Tray
    
    private var piecesTrayView: some View {
        VStack(spacing: 8) {
            Text("Tap a piece, then tap its slot:")
                .font(.clay(13, .medium))
                .foregroundColor(DragonPalette.textMuted)
            
            HStack(spacing: 12) {
                ForEach(availablePieces, id: \.self) { pieceId in
                    let isSelected = (selectedPieceId == pieceId)
                    
                    Button(action: {
                        HapticsService.shared.selection()
                        AudioService.shared.playPop()
                        selectedPieceId = pieceId
                    }) {
                        pieceGraphic(pieceId: pieceId, size: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DragonPalette.softPurple, lineWidth: isSelected ? 3 : 1)
                            )
                            .scaleEffect(isSelected ? 1.12 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isSelected)
                            .shadow(color: isSelected ? DragonPalette.softPurple.opacity(0.4) : Color.clear, radius: 6)
                    }
                }
            }
            .frame(height: 80)
        }
    }
    
    // MARK: - Quadrant Graphic Generator
    
    private func pieceGraphic(pieceId: Int, size: CGFloat) -> some View {
        // Render stylized segment of the baby dragon
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(DragonPalette.cream)
            
            switch pieceId {
            case 0: // Top-Left: Horn & Eye
                ZStack {
                    DragonHornShape(isCurved: true)
                        .fill(gameManager.activeDragon.secondaryColor)
                        .frame(width: size * 0.35, height: size * 0.45)
                        .offset(x: -size * 0.15, y: -size * 0.15)
                    Circle()
                        .fill(gameManager.activeDragon.primaryColor)
                        .frame(width: size * 0.7, height: size * 0.7)
                        .offset(x: size * 0.1, y: size * 0.1)
                }
            case 1: // Top-Right: Horn & Wing
                ZStack {
                    DragonWingShape(isFairy: false)
                        .fill(gameManager.activeDragon.secondaryColor)
                        .frame(width: size * 0.5, height: size * 0.5)
                        .offset(x: size * 0.15, y: -size * 0.1)
                    Circle()
                        .fill(gameManager.activeDragon.primaryColor)
                        .frame(width: size * 0.7, height: size * 0.7)
                        .offset(x: -size * 0.1, y: size * 0.1)
                }
            case 2: // Bottom-Left: Body & Paw
                ZStack {
                    Ellipse()
                        .fill(gameManager.activeDragon.primaryColor)
                        .frame(width: size * 0.8, height: size * 0.8)
                        .offset(x: size * 0.1, y: -size * 0.1)
                    Circle()
                        .fill(gameManager.activeDragon.secondaryColor)
                        .frame(width: size * 0.3, height: size * 0.25)
                        .offset(x: -size * 0.15, y: size * 0.25)
                }
            case 3: // Bottom-Right: Tail & Wing tip
                ZStack {
                    Ellipse()
                        .fill(gameManager.activeDragon.bellyColor)
                        .frame(width: size * 0.6, height: size * 0.6)
                        .offset(x: -size * 0.15, y: -size * 0.15)
                    HeartShape()
                        .fill(gameManager.activeDragon.secondaryColor)
                        .frame(width: size * 0.35, height: size * 0.35)
                        .offset(x: size * 0.2, y: size * 0.15)
                }
            default:
                EmptyView()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Game Mechanics
    
    private func tryPlacePiece(pieceId: Int, inSlot slotIndex: Int) {
        // Correct slot matching: slotIndex == pieceId
        if slotIndex == pieceId {
            HapticsService.shared.success()
            AudioService.shared.playChime(frequency: 659.25 + Double(slotIndex) * 100)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                placedPieces[slotIndex] = pieceId
                availablePieces.removeAll(where: { $0 == pieceId })
                selectedPieceId = nil
            }
            
            // Check if all 4 pieces are placed
            if placedPieces.count == 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    AudioService.shared.playVictoryFanfare()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        isComplete = true
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
        placedPieces = [:]
        availablePieces = [0, 1, 2, 3].shuffled()
        selectedPieceId = nil
        isComplete = false
        showVictory = false
    }
}
