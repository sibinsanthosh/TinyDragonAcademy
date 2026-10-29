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
            case .mainMenu, .dragonPlayground:
                // Home: the den dragon front and centre, or the hatch-an-egg welcome
                Group {
                    if gameManager.hasActiveDenDragon {
                        DragonPlaygroundView()
                    } else {
                        MainMenuView()
                    }
                }
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
            case .powerEncyclopedia:
                PowerEncyclopediaView(dragon: gameManager.activeDragon)
                    .transition(.opacity)
            case .foodInventoryShop:
                FoodInventoryView(closeRoute: .mainMenu)
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
                case .skyFlight:
                    SkyFlightView()
                        .transition(.opacity)
                case .snackCatch:
                    SnackCatchView()
                        .transition(.opacity)
                }
            case .today:
                TodayView()
                    .transition(.opacity)
            case .den:
                DenView()
                    .transition(.opacity)
            case .trainingHub:
                TrainingHubView()
                    .transition(.opacity)
            case .incubator:
                IncubatorView()
                    .transition(.opacity)
            case .hallOfLegends:
                HallOfLegendsView()
                    .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if AppTab.forRoute(gameManager.currentRoute) != nil {
                ClayTabBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if gameManager.currentRoute != .onboarding {
                if gameManager.shouldShowReminderPrimer {
                    ReminderPrimerView()
                } else if AwayReportSheet.hasContent(gameManager) {
                    AwayReportSheet()
                }
            }
        }
        // Celebrations sit above every sheet and play one after another
        .overlay(alignment: .top) {
            if let toast = gameManager.toasts.first {
                Text(toast)
                    .font(.clay(15, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white).shadow(color: DragonPalette.popShadow, radius: 10, y: 4))
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(toast + "\(gameManager.toasts.count)")
                    .task(id: toast + "\(gameManager.toasts.count)") {
                        try? await Task.sleep(nanoseconds: 2_600_000_000)
                        withAnimation { if gameManager.toasts.first == toast { gameManager.toasts.removeFirst() } }
                    }
                    .onTapGesture { withAnimation { if !gameManager.toasts.isEmpty { gameManager.toasts.removeFirst() } } }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gameManager.toasts)
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
