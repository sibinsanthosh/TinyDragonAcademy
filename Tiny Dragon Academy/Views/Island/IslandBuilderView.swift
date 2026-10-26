//
//  IslandBuilderView.swift
//  Tiny Dragon Academy
//
//  Interactive magical island sandbox builder.
//  Children can place, reposition, remove, and decorate their island with 18+ fantasy items.
//

import SwiftUI

struct IslandBuilderView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var selectedItemToPlace: IslandItemType? = nil
    @State private var selectedPlacedItemId: UUID? = nil
    @State private var activeCategory: IslandItemCategory = .nature
    @State private var isTrashHovered: Bool = false
    
    var body: some View {
        ZStack {
            // Background Theme
            gameManager.state.island.theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // Header: Back, Theme, Reset, Stars
                headerView
                
                // Interactive Island Canvas
                GeometryReader { geo in
                    ZStack {
                        // Floating Island Terrain Base
                        islandTerrainGraphic(in: geo.size)
                        
                        // Active Placed Decorations
                        ForEach(gameManager.state.island.placedItems) { item in
                            placedItemView(item: item, in: geo.size)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleCanvasTap(at: location, in: geo.size)
                    }
                }
                .frame(maxHeight: 340)
                
                // Controls Bar: Selected item banner & Remove action
                selectionStatusBar
                
                // Bottom Category Filter & Item Picker Tray
                categoryPickerStrip
                itemsTray
                    .padding(.bottom, 14)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
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
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.white.opacity(0.9)))
            }
            
            Spacer()
            
            // Theme Picker Menu
            Menu {
                ForEach(IslandBackdrop.allCases, id: \.self) { theme in
                    Button(theme.rawValue) {
                        gameManager.setIslandTheme(theme)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "paintpalette")
                    Text("Theme")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.white.opacity(0.9)))
            }
            
            // Reset Button
            Button(action: {
                HapticsService.shared.light()
                gameManager.resetIsland()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DragonPalette.coral)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.9)))
            }
            
            Spacer()
            
            StarCounterView(count: gameManager.totalStars)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }
    
    // MARK: - Island Graphic Terrain
    
    private func islandTerrainGraphic(in size: CGSize) -> some View {
        ZStack {
            // Earth Base
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.72, green: 0.58, blue: 0.44), Color(red: 0.50, green: 0.38, blue: 0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width * 0.92, height: size.height * 0.75)
                .offset(y: size.height * 0.2)
            
            // Green Pasture Plateau
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [DragonPalette.mintGreen, Color(red: 0.55, green: 0.88, blue: 0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width * 0.88, height: size.height * 0.68)
                .overlay(
                    Ellipse().stroke(Color.white.opacity(0.8), lineWidth: 3)
                )
                .offset(y: size.height * 0.08)
        }
    }
    
    // MARK: - Placed Items
    
    private func placedItemView(item: PlacedItem, in canvasSize: CGSize) -> some View {
        let posX = item.xNormalized * canvasSize.width
        let posY = item.yNormalized * canvasSize.height
        let isSelected = (selectedPlacedItemId == item.id)
        
        return decorationGraphic(for: item.itemType, size: 68)
            .overlay(
                Circle()
                    .stroke(DragonPalette.softPurple, lineWidth: isSelected ? 3 : 0)
                    .scaleEffect(1.2)
            )
            .position(x: posX, y: posY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        selectedPlacedItemId = item.id
                        let normalizedX = value.location.x / canvasSize.width
                        let normalizedY = value.location.y / canvasSize.height
                        gameManager.moveIslandItem(id: item.id, newX: normalizedX, newY: normalizedY)
                    }
                    .onEnded { _ in
                        HapticsService.shared.light()
                        AudioService.shared.playPop()
                    }
            )
            .onTapGesture {
                HapticsService.shared.selection()
                selectedPlacedItemId = item.id
            }
    }
    
    // MARK: - Status & Action Bar
    
    private var selectionStatusBar: some View {
        HStack {
            if let id = selectedPlacedItemId, let item = gameManager.state.island.placedItems.first(where: { $0.id == id }) {
                Text(item.itemType.rawValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                
                Spacer()
                
                Button(action: {
                    HapticsService.shared.medium()
                    AudioService.shared.playPop()
                    gameManager.removeIslandItem(id: id)
                    selectedPlacedItemId = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text("Remove")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(DragonPalette.coral))
                }
            } else if let toPlace = selectedItemToPlace {
                Text("Tap anywhere on the green island to place \(toPlace.rawValue)!")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.softPurple)
            } else {
                Text("Tap an item below to add to your island!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 32)
    }
    
    // MARK: - Category Filter Strip
    
    private var categoryPickerStrip: some View {
        HStack(spacing: 8) {
            ForEach(IslandItemCategory.allCases, id: \.self) { cat in
                let isSelected = (activeCategory == cat)
                Button(action: {
                    HapticsService.shared.selection()
                    AudioService.shared.playPop()
                    activeCategory = cat
                }) {
                    Text(cat.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : DragonPalette.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isSelected ? DragonPalette.softPurple : Color.white.opacity(0.8))
                        )
                }
            }
        }
    }
    
    // MARK: - Items Tray
    
    private var itemsTray: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                let items = IslandItemType.allCases.filter { $0.category == activeCategory }
                ForEach(items, id: \.self) { type in
                    let isSelected = (selectedItemToPlace == type)
                    
                    Button(action: {
                        HapticsService.shared.selection()
                        AudioService.shared.playPop()
                        selectedItemToPlace = (selectedItemToPlace == type) ? nil : type
                        selectedPlacedItemId = nil
                    }) {
                        VStack(spacing: 4) {
                            decorationGraphic(for: type, size: 44)
                            Text(type.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(DragonPalette.textDark)
                                .lineLimit(1)
                        }
                        .frame(width: 74, height: 74)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? DragonPalette.buttercup.opacity(0.5) : Color.white.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(DragonPalette.softPurple, lineWidth: isSelected ? 3 : 0)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 85)
    }
    
    // MARK: - Canvas Tap Placement
    
    private func handleCanvasTap(at point: CGPoint, in size: CGSize) {
        if let type = selectedItemToPlace {
            let normX = max(0.12, min(0.88, point.x / size.width))
            let normY = max(0.18, min(0.78, point.y / size.height))
            
            HapticsService.shared.success()
            AudioService.shared.playChime(frequency: 784.0)
            gameManager.addIslandItem(type: type, x: normX, y: normY)
            selectedItemToPlace = nil
        } else {
            selectedPlacedItemId = nil
        }
    }
    
    // MARK: - Decoration Visual Renderer
    
    @ViewBuilder
    private func decorationGraphic(for item: IslandItemType, size: CGFloat) -> some View {
        switch item {
        case .mushroomCottage:
            MushroomHouseView(size: size)
        case .dragonNest:
            ZStack {
                Ellipse().fill(Color(red: 0.82, green: 0.70, blue: 0.52)).frame(width: size, height: size * 0.45)
                EggShape().fill(DragonPalette.buttercup).frame(width: size * 0.35, height: size * 0.45).offset(y: -size * 0.1)
            }
        case .crystalTower:
            Image(systemName: "building.columns.fill").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.softPurple)
        case .cloudGazebo:
            Image(systemName: "tent.fill").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.skyBlue)
        case .pinkBlossomTree:
            BlossomTreeView(size: size)
        case .magicFruitTree:
            VStack(spacing: -size * 0.1) {
                Circle().fill(DragonPalette.buttercup).frame(width: size * 0.7, height: size * 0.7)
                RoundedRectangle(cornerRadius: 4).fill(Color.brown).frame(width: size * 0.18, height: size * 0.35)
            }
        case .gentlePine:
            Image(systemName: "tree").font(.system(size: size * 0.75)).foregroundStyle(DragonPalette.mintGreen)
        case .fairyWillow:
            Image(systemName: "leaf.fill").font(.system(size: size * 0.75)).foregroundStyle(DragonPalette.lavender)
        case .giantToadstool:
            ZStack {
                Circle().fill(DragonPalette.coral).frame(width: size * 0.7, height: size * 0.45)
                Capsule().fill(Color.white).frame(width: size * 0.22, height: size * 0.4).offset(y: size * 0.2)
            }
        case .rainbowTulips:
            Image(systemName: "camera.macro").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.rosyPink)
        case .glowingLotus:
            Image(systemName: "sparkles").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.buttercup)
        case .crystalCluster:
            Image(systemName: "suit.diamond.fill").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.turquoise)
        case .cozyPond:
            CozyPondView(size: size)
        case .rainbowBridge:
            Image(systemName: "rainbow").font(.system(size: size * 0.75)).foregroundStyle(DragonPalette.softPurple)
        case .starryFountain:
            Image(systemName: "water.waves").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.skyBlue)
        case .dragonSlide:
            Image(systemName: "figure.walk").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.coral)
        case .starrySwing:
            Image(systemName: "star.fill").font(.system(size: size * 0.65)).foregroundStyle(DragonPalette.buttercup)
        case .cloudTrampoline:
            Image(systemName: "cloud.fill").font(.system(size: size * 0.75)).foregroundStyle(DragonPalette.skyBlue.opacity(0.85))
        }
    }
}
