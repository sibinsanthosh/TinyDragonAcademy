//
//  PowerEncyclopediaView.swift
//  Tiny Dragon Academy
//
//  Showcase of all 5 elemental powers for the dragon's species,
//  with progression requirements, energy costs, and descriptions.
//

import SwiftUI

struct PowerEncyclopediaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    let dragon: DragonModel
    
    var powers: [ElementalPower] {
        ElementalPowersCatalog.powers(for: dragon.element)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DragonPalette.skyGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Banner
                        headerBanner
                        
                        // 5 Power Cards
                        ForEach(powers) { power in
                            powerCard(power)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Elemental Powers")
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
    
    private var headerBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: dragon.element.iconName)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(Circle().fill(dragon.element.themeColor))
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(dragon.name)'s \(dragon.element.rawValue) Powers")
                    .font(.clay(18, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                
                Text("Powers awaken as your dragon grows from Baby to Ancient!")
                    .font(.clay(13, .medium))
                    .foregroundColor(DragonPalette.textMuted)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    private func powerCard(_ power: ElementalPower) -> some View {
        let isUnlocked = dragon.stats.unlockedPowerIds.contains(power.id)
        
        return HStack(spacing: 14) {
            // Power Icon / Locked Silhouette
            ZStack {
                Circle()
                    .fill(isUnlocked ? dragon.element.themeColor.opacity(0.2) : Color.black.opacity(0.06))
                    .frame(width: 52, height: 52)
                
                if isUnlocked {
                    Image(systemName: power.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(dragon.element.themeColor)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DragonPalette.textMuted)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isUnlocked ? power.name : "Mysterious Power")
                        .font(.clay(16, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    
                    Spacer()
                    
                    // Stage Tag
                    Text(power.stageRequired.rawValue)
                        .font(.clay(11, .bold))
                        .foregroundColor(power.stageRequired.badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(power.stageRequired.badgeColor.opacity(0.18)))
                }
                
                Text(isUnlocked ? power.description : "Requires \(power.stageRequired.rawValue) (Level \(power.levelRequired)) to unlock.")
                    .font(.clay(13, .medium))
                    .foregroundColor(isUnlocked ? DragonPalette.textMuted : DragonPalette.coral)
                    .lineLimit(2)
                
                if isUnlocked {
                    HStack(spacing: 12) {
                        Label("Energy: \(Int(power.energyCost))", systemImage: "bolt.fill")
                        Label("Cooldown: \(Int(power.cooldownSeconds))s", systemImage: "timer")
                    }
                    .font(.clay(11, .semibold))
                    .foregroundColor(DragonPalette.textMuted)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(isUnlocked ? 0.95 : 0.75))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
    }
}
