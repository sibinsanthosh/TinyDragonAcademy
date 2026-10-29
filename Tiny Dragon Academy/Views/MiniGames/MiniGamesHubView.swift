//
//  MiniGamesHubView.swift
//  Tiny Dragon Academy
//
//  Selection hub for the 4 educational mini-games with child-friendly illustrated cards.
//

import SwiftUI

struct MiniGamesHubView: View {
    @EnvironmentObject var gameManager: GameManager
    
    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            DragonPalette.meadowGradient
                .ignoresSafeArea()
            
            FloatingParticlesView(particleCount: 10, themeColor: DragonPalette.softPurple)
            
            VStack(spacing: 16) {
                // Top Bar: Back Button, Title, Stars
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
                                .font(.clay(17, .bold))
                        }
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .claySurface(cornerRadius: 100, elevation: 0.7)
                    }
                    
                    Spacer()
                    
                    StarCounterView(count: gameManager.totalStars)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Hub Title
                VStack(spacing: 4) {
                    Text("Learning Games")
                        .font(.clay(30, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    
                    Text("Choose a fun learning adventure!")
                        .font(.clay(15, .medium))
                        .foregroundColor(DragonPalette.textMuted)
                }
                
                // Game Selection Cards
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(MiniGameType.allCases) { game in
                            gameCard(game)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func gameCard(_ game: MiniGameType) -> some View {
        Button(action: {
            HapticsService.shared.medium()
            AudioService.shared.playPop()
            gameManager.navigate(to: .miniGame(game))
        }) {
            VStack(spacing: 12) {
                // Game Icon Badge
                ZStack {
                    Circle()
                        .fill(game.themeColor.opacity(0.25))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: game.iconName)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(game.themeColor)
                }
                
                VStack(spacing: 4) {
                    Text(game.rawValue)
                        .font(.clay(20, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                        .multilineTextAlignment(.center)
                    
                    Text(game.subtitle)
                        .font(.clay(13, .medium))
                        .foregroundColor(DragonPalette.textMuted)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 34)
                }
                
                // Age & Star Reward Pill
                HStack(spacing: 8) {
                    Text(game.ageRecommendation)
                        .font(.clay(11, .bold))
                        .foregroundColor(DragonPalette.softPurple)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(DragonPalette.buttercup)
                        Text("+3")
                            .font(.clay(11, .heavy))
                            .foregroundColor(DragonPalette.textDark)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .claySurface(cornerRadius: 100, elevation: 0.7)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .kidCard(background: Color.white.opacity(0.92))
        }
    }
}
