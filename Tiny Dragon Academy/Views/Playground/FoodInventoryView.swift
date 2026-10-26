//
//  FoodInventoryView.swift
//  Tiny Dragon Academy
//
//  Interactive food pantry & treat shop. Players can inspect nutrition,
//  favorite hints, and purchase treats with earned stars.
//

import SwiftUI

struct FoodInventoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    var activeDragon: DragonModel {
        gameManager.activeDragon
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DragonPalette.skyGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Top Star Balance & Favorite Hint
                        topBanner
                        
                        // Food Items Grid
                        ForEach(FoodType.allCases) { food in
                            foodCard(food)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dragon Food Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                }
            }
        }
    }
    
    private var topBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Treat Pantry")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                
                Text(activeDragon.stats.favoriteFoodDiscovered ? "Favorite: \(activeDragon.favoriteFoodType.displayName) (2x Bonus!)" : "Tip: Discover \(activeDragon.name)'s favorite treat for 2x XP!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.coral)
            }
            
            Spacer()
            
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
    }
    
    private func foodCard(_ food: FoodType) -> some View {
        let count = gameManager.state.foodInventory[food.rawValue] ?? 0
        let isFavorite = (food == activeDragon.favoriteFoodType)
        let canAfford = gameManager.totalStars >= food.purchaseStarCost
        
        return HStack(spacing: 14) {
            // Food Icon
            Circle()
                .fill(food.primaryColor.opacity(0.2))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: food.icon)
                        .font(.system(size: 24))
                        .foregroundColor(food.primaryColor)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(food.displayName)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    
                    if isFavorite && activeDragon.stats.favoriteFoodDiscovered {
                        Text("❤️ Fav")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.rosyPink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DragonPalette.rosyPink.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    Text("In Stock: \(count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(DragonPalette.textMuted)
                }
                
                Text(food.description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text("+\(Int(food.hungerRestored)) Hunger")
                    Text("+\(Int(food.energyRestored)) Energy")
                    Text("+\(food.baseXP) XP")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(food.primaryColor)
            }
            
            // Buy Button
            Button(action: {
                _ = gameManager.purchaseFood(food: food, count: 1)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(DragonPalette.buttercup)
                    Text("\(food.purchaseStarCost)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(canAfford ? DragonPalette.cream : Color.gray.opacity(0.15))
                        .shadow(color: DragonPalette.softShadow, radius: 3, x: 0, y: 1)
                )
            }
            .disabled(!canAfford)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
        )
    }
}
