//
//  AchievementsView.swift
//  Tiny Dragon Academy
//
//  Track raising milestones: feeding, evolution, powers, and care achievements.
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    var achievements: [DragonAchievement] {
        gameManager.state.achievements
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DragonPalette.skyGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(achievements) { ach in
                            achievementRow(ach)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dragon Milestones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.clay(16, .bold))
                    .foregroundColor(DragonPalette.textDark)
                }
            }
        }
    }
    
    private func achievementRow(_ ach: DragonAchievement) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(ach.isUnlocked ? DragonPalette.buttercup.opacity(0.25) : Color.black.opacity(0.06))
                    .frame(width: 48, height: 48)
                
                Image(systemName: ach.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(ach.isUnlocked ? DragonPalette.coral : DragonPalette.textMuted)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(ach.title)
                    .font(.clay(16, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                
                Text(ach.subtitle)
                    .font(.clay(12, .medium))
                    .foregroundColor(DragonPalette.textMuted)
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                        Capsule()
                            .fill(DragonPalette.coral)
                            .frame(width: geo.size.width * ach.progressFraction)
                    }
                }
                .frame(height: 5)
            }
            
            // Star Reward
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(DragonPalette.buttercup)
                Text("+\(ach.rewardStars)")
                    .font(.clay(14, .heavy))
                    .foregroundColor(DragonPalette.textDark)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ach.isUnlocked ? DragonPalette.cream : Color.gray.opacity(0.12))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
    }
}
