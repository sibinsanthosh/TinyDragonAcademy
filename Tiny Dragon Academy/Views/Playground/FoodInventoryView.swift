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
    /// When shown as a full screen route (not a sheet), Done navigates here.
    var closeRoute: AppRoute? = nil
    
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
                        
                        sectionTitle("Care", icon: "cross.case.fill")
                        ForEach(CareItem.allCases, id: \.self) { item in
                            shopRow(
                                icon: item.iconName,
                                color: item == .healingHerb ? DragonPalette.mintGreen : DragonPalette.coral,
                                title: item.rawValue,
                                subtitle: item == .healingHerb ? "Cures Hunger Fever or Sluggish Scales." : "Revives a spirit within 48 hours.",
                                owned: "Owned: \(gameManager.state.itemCount(item))",
                                price: item.price
                            ) { _ = gameManager.purchaseCareItem(item) }
                        }
                        
                        sectionTitle("Mystery Eggs", icon: "oval.portrait.fill")
                        ForEach(EggTier.allCases.filter { $0.shopPrice != nil }, id: \.self) { tier in
                            shopRow(
                                icon: "oval.portrait.fill",
                                color: tier.shellColor,
                                title: tier.displayName,
                                subtitle: "Hatches in \(Int(tier.hatchDuration / 3600))h. Goes to your egg basket.",
                                owned: nil,
                                price: tier.shopPrice ?? 0
                            ) { _ = gameManager.purchaseEgg(tier) }
                        }
                        
                        sectionTitle("Upgrades", icon: "arrow.up.circle.fill")
                        if gameManager.state.incubatorCapacity < DenRules.maxIncubatorSlots {
                            shopRow(icon: "flame.fill", color: DragonPalette.peach, title: "Second Incubator",
                                    subtitle: "Warm two eggs at once.", owned: nil, price: DenRules.incubatorSlotPrice) {
                                _ = gameManager.purchaseIncubatorSlot()
                            }
                        }
                        if let price = gameManager.nextDenSlotPrice {
                            shopRow(icon: "house.fill", color: DragonPalette.softPurple, title: "Den Slot \(gameManager.state.denCapacity + 1)",
                                    subtitle: "Care for one more dragon at a time.", owned: nil, price: price) {
                                _ = gameManager.purchaseDenSlot()
                            }
                        }
                        
                        sectionTitle("Treats", icon: "fork.knife")
                        // Food Items Grid
                        ForEach(FoodType.allCases) { food in
                            foodCard(food)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dragon Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let closeRoute {
                            gameManager.navigate(to: closeRoute)
                        } else {
                            dismiss()
                        }
                    }
                    .font(.clay(16, .bold))
                    .foregroundColor(DragonPalette.textDark)
                }
            }
        }
    }
    
    private var topBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Treat Pantry")
                    .font(.clay(18, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                
                Text(activeDragon.stats.favoriteFoodDiscovered ? "Favorite: \(activeDragon.favoriteFoodType.displayName) (2x Bonus!)" : "Tip: Discover \(activeDragon.name)'s favorite treat for 2x XP!")
                    .font(.clay(13, .medium))
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
    
    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.clay(18, .heavy))
            .foregroundColor(DragonPalette.textDark)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
    
    private func shopRow(icon: String, color: Color, title: String, subtitle: String, owned: String?, price: Int,
                         action: @escaping () -> Void) -> some View {
        let canAfford = gameManager.totalStars >= price
        return HStack(spacing: 14) {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: icon).font(.system(size: 24)).foregroundColor(color))
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.clay(16, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    Spacer()
                    if let owned {
                        Text(owned)
                            .font(.clay(13, .bold))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                }
                Text(subtitle)
                    .font(.clay(12, .medium))
                    .foregroundColor(DragonPalette.textMuted)
            }
            Button(action: action) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(DragonPalette.buttercup)
                    Text("\(price)").font(.clay(13, .heavy)).foregroundColor(DragonPalette.textDark)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Capsule().fill(canAfford ? DragonPalette.cream : Color.gray.opacity(0.15)))
            }
            .disabled(!canAfford)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.95)))
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
                        .font(.clay(16, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    
                    if isFavorite && activeDragon.stats.favoriteFoodDiscovered {
                        Text("❤️ Fav")
                            .font(.clay(10, .heavy))
                            .foregroundColor(DragonPalette.rosyPink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DragonPalette.rosyPink.opacity(0.2)))
                    }
                    
                    Spacer()
                    
                    Text("In Stock: \(count)")
                        .font(.clay(13, .bold))
                        .foregroundColor(DragonPalette.textMuted)
                }
                
                Text(food.description)
                    .font(.clay(12, .medium))
                    .foregroundColor(DragonPalette.textMuted)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Text("+\(Int(food.hungerRestored)) Hunger")
                    Text("+\(Int(food.energyRestored)) Energy")
                    Text("+\(food.baseXP) XP")
                }
                .font(.clay(11, .bold))
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
                        .font(.clay(13, .heavy))
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
