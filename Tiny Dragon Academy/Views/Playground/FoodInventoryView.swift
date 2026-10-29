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
        ZStack {
            ClayBackdrop()

            VStack(spacing: 10) {
                if closeRoute != nil {
                    ScreenTopBar(title: "Shop")
                } else {
                    sheetHeader
                }

                ScrollView {
                    VStack(spacing: 14) {
                        favoriteHint

                        sectionTitle("Treats", icon: "fork.knife")
                        ForEach(FoodType.allCases) { food in
                            foodCard(food)
                        }

                        sectionTitle("Care", icon: "cross.case.fill")
                        ForEach(CareItem.allCases, id: \.self) { item in
                            shopRow(
                                icon: item.iconName,
                                color: item == .healingHerb ? ClayColor.mint : ClayColor.coral,
                                title: item.rawValue,
                                subtitle: item == .healingHerb ? "Cures Hunger Fever or Sluggish Scales" : "Revives a spirit within 48 hours",
                                owned: "×\(gameManager.state.itemCount(item))",
                                price: item.price
                            ) { _ = gameManager.purchaseCareItem(item) }
                        }

                        sectionTitle("Mystery eggs", icon: "oval.portrait.fill")
                        ForEach(EggTier.allCases.filter { $0.shopPrice != nil }, id: \.self) { tier in
                            shopRow(
                                icon: "oval.portrait.fill",
                                color: tier.shellColor,
                                title: tier.displayName,
                                subtitle: "Hatches in \(Int(tier.hatchDuration / 3600))h",
                                owned: nil,
                                price: tier.shopPrice ?? 0
                            ) { _ = gameManager.purchaseEgg(tier) }
                        }

                        if gameManager.state.incubatorCapacity < DenRules.maxIncubatorSlots || gameManager.nextDenSlotPrice != nil {
                            sectionTitle("Upgrades", icon: "arrow.up.circle.fill")
                        }
                        if gameManager.state.incubatorCapacity < DenRules.maxIncubatorSlots {
                            shopRow(icon: "flame.fill", color: ClayColor.coral, title: "Second incubator",
                                    subtitle: "Warm two eggs at once", owned: nil, price: DenRules.incubatorSlotPrice) {
                                _ = gameManager.purchaseIncubatorSlot()
                            }
                        }
                        if let price = gameManager.nextDenSlotPrice {
                            shopRow(icon: "house.fill", color: ClayColor.accent, title: "Den spot \(gameManager.state.denCapacity + 1)",
                                    subtitle: "Care for one more dragon", owned: nil, price: price) {
                                _ = gameManager.purchaseDenSlot()
                            }
                        }

                        if closeRoute != nil {
                            sectionTitle("Style", icon: "paintbrush.fill")
                            HStack(spacing: 12) {
                                styleTile("Dress-Up", icon: "tshirt.fill", color: ClayColor.rose) { gameManager.navigate(to: .dragonDressUp) }
                                styleTile("Island", icon: "leaf.fill", color: ClayColor.mint) { gameManager.navigate(to: .islandBuilder) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    /// Sheet form (opened from Home): a title and a close button.
    private var sheetHeader: some View {
        HStack {
            Text("Shop")
                .font(.clay(24, .heavy))
                .foregroundColor(ClayColor.ink)
            Spacer()
            StarCounterView(count: gameManager.totalStars)
            ClayIconButton(systemName: "xmark", accessibilityLabel: "Close") { dismiss() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var favoriteHint: some View {
        Label(activeDragon.stats.favoriteFoodDiscovered
              ? "\(activeDragon.name) loves \(activeDragon.favoriteFoodType.displayName): 2× XP"
              : "Find \(activeDragon.name)'s favorite treat for 2× XP",
              systemImage: "heart.fill")
            .font(.clay(14, .bold))
            .foregroundColor(ClayColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(ClayColor.rose.opacity(0.15)))
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.clay(20, .heavy))
            .foregroundColor(ClayColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func priceButton(_ price: Int, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.light()
            AudioService.shared.playPop()
            action()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.system(size: 12, weight: .bold))
                Text("\(price)").font(.clay(15, .heavy))
            }
            .foregroundColor(ClayColor.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(ClayButtonStyle(color: ClayColor.sun, cornerRadius: 16))
        .disabled(gameManager.totalStars < price)
    }

    private func iconBadge(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(Circle().fill(color.shadow(.inner(color: Color.black.opacity(0.15), radius: 0, x: 0, y: -4))))
    }

    private func styleTile(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            HapticsService.shared.medium()
            action()
        } label: {
            VStack(spacing: 8) {
                iconBadge(icon, color: color)
                Text(title)
                    .font(.clay(16, .heavy))
                    .foregroundColor(ClayColor.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(ClaySecondaryButtonStyle(cornerRadius: 24))
    }

    private func shopRow(icon: String, color: Color, title: String, subtitle: String, owned: String?, price: Int,
                         action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.clay(16, .heavy))
                        .foregroundColor(ClayColor.ink)
                    if let owned {
                        Text(owned)
                            .font(.clay(13, .heavy))
                            .foregroundColor(ClayColor.inkSoft)
                    }
                }
                Text(subtitle)
                    .font(.clay(13, .bold))
                    .foregroundColor(ClayColor.inkSoft)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            priceButton(price, action: action)
        }
        .padding(12)
        .claySurface(cornerRadius: 22)
    }

    private func foodCard(_ food: FoodType) -> some View {
        let count = gameManager.state.foodInventory[food.rawValue] ?? 0
        let isFavorite = food == activeDragon.favoriteFoodType && activeDragon.stats.favoriteFoodDiscovered
        return HStack(spacing: 12) {
            iconBadge(food.icon, color: food.primaryColor)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(food.displayName)
                        .font(.clay(16, .heavy))
                        .foregroundColor(ClayColor.ink)
                    Text("×\(count)")
                        .font(.clay(13, .heavy))
                        .foregroundColor(ClayColor.inkSoft)
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ClayColor.rose)
                            .accessibilityLabel("Favorite")
                    }
                }
                HStack(spacing: 8) {
                    Label("\(Int(food.hungerRestored))", systemImage: "fork.knife")
                    Label("\(Int(food.energyRestored))", systemImage: "bolt.fill")
                    Label("\(food.baseXP) XP", systemImage: "sparkles")
                }
                .font(.clay(12, .heavy))
                .foregroundColor(ClayColor.inkSoft)
            }
            Spacer(minLength: 4)
            priceButton(food.purchaseStarCost) {
                _ = gameManager.purchaseFood(food: food, count: 1)
            }
        }
        .padding(12)
        .claySurface(cornerRadius: 22)
    }
}
