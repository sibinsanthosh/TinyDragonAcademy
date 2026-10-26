//
//  ContentView.swift
//  Tiny Dragon Academy
//
//  Root coordinator navigating between Onboarding, Main Menu, Mini Games,
//  Collection, Dress-Up, Island Builder, and Settings.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.scenePhase) private var scenePhase
    
    private let lifeTicker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            switch gameManager.currentRoute {
            case .onboarding:
                HatchIntroView()
                    .transition(.opacity)
            case .mainMenu:
                MainMenuView()
                    .transition(.opacity)
            case .miniGamesHub:
                MiniGamesHubView()
                    .transition(.opacity)
            case .miniGame(let gameType):
                switch gameType {
                case .colorGarden:
                    ColorGardenGameView()
                        .transition(.opacity)
                case .shapeMagic:
                    ShapeMagicGameView()
                        .transition(.opacity)
                case .countStars:
                    CountStarsGameView()
                        .transition(.opacity)
                case .dragonPuzzle:
                    DragonPuzzleGameView()
                        .transition(.opacity)
                }
            case .dragonCollection:
                DragonCollectionView()
                    .transition(.opacity)
            case .dragonDressUp:
                DragonDressUpView()
                    .transition(.opacity)
            case .islandBuilder:
                IslandBuilderView()
                    .transition(.opacity)
            case .settings:
                SettingsView()
                    .transition(.opacity)
            case .dragonPlayground:
                DragonPlaygroundView()
                    .transition(.opacity)
            case .powerEncyclopedia:
                PowerEncyclopediaView(dragon: gameManager.activeDragon)
                    .transition(.opacity)
            case .foodInventoryShop:
                FoodInventoryView()
                    .transition(.opacity)
            case .achievementsList:
                AchievementsView()
                    .transition(.opacity)
            case .trainingGame(let game):
                switch game {
                case .dragonDash:
                    DragonDashView()
                        .transition(.opacity)
                case .fireTarget:
                    FireTargetView()
                        .transition(.opacity)
                case .skyFlight, .snackCatch:
                    Text("Coming soon")
                }
            case .den, .trainingHub, .incubator, .hallOfLegends:
                Text("Coming soon")
                    .transition(.opacity)
            }
        }
        .onReceive(lifeTicker) { _ in
            guard gameManager.state.hasCompletedOnboarding else { return }
            gameManager.tick()
        }
        .onChange(of: scenePhase) { _, phase in
            guard gameManager.state.hasCompletedOnboarding else { return }
            switch phase {
            case .active: gameManager.catchUp()
            case .background: gameManager.rescheduleNotifications()
            default: break
            }
        }
        .animation(gameManager.state.settings.reduceMotion ? .none : .easeInOut(duration: 0.3), value: gameManager.currentRoute)
    }
}
