//
//  GameVictoryModal.swift
//  Tiny Dragon Academy
//
//  Celebratory victory modal shown after completing a mini-game.
//  Awards stars, plays fanfare, and allows replaying or returning to menu.
//

import SwiftUI

struct GameVictoryModal: View {
    let starsEarned: Int
    let onPlayAgain: () -> Void
    let onBackToMenu: () -> Void
    
    @State private var starScale1: CGFloat = 0.1
    @State private var starScale2: CGFloat = 0.1
    @State private var starScale3: CGFloat = 0.1
    @State private var modalScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Cheering Dragon Icon
                ZStack {
                    Circle()
                        .fill(DragonPalette.buttercup.opacity(0.3))
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(DragonPalette.buttercup)
                }
                
                VStack(spacing: 6) {
                    Text("Magical Job!")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    
                    Text("You earned 3 shiny dragon stars!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(DragonPalette.textMuted)
                }
                
                // 3 Bouncing Stars
                HStack(spacing: 16) {
                    starItem(scale: starScale1)
                    starItem(scale: starScale2)
                    starItem(scale: starScale3)
                }
                .padding(.vertical, 8)
                
                // Action Buttons
                VStack(spacing: 12) {
                    KidButton(
                        title: "Play Again!",
                        icon: "arrow.clockwise",
                        backgroundColor: DragonPalette.softPurple,
                        minWidth: 220
                    ) {
                        onPlayAgain()
                    }
                    
                    Button(action: onBackToMenu) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                            Text("Back to Island")
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.99, green: 0.98, blue: 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: DragonPalette.popShadow, radius: 20)
            )
            .padding(.horizontal, 30)
            .scaleEffect(modalScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                modalScale = 1.0
            }
            
            // Cascading stars pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    starScale1 = 1.0
                }
                HapticsService.shared.medium()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    starScale2 = 1.0
                }
                HapticsService.shared.medium()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    starScale3 = 1.0
                }
                HapticsService.shared.success()
            }
        }
    }
    
    private func starItem(scale: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: 38))
            .foregroundStyle(
                LinearGradient(
                    colors: [DragonPalette.buttercup, Color.yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.yellow.opacity(0.6), radius: 6)
            .scaleEffect(scale)
    }
}
