//
//  AppTab.swift
//  Tiny Dragon Academy
//
//  The five bottom tabs and which screens belong to each. Screens with no
//  tab (games, settings, sheets) are full-screen and hide the tab bar.
//

import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home, train, eggs, dragons, shop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .train: return "Train"
        case .eggs: return "Eggs"
        case .dragons: return "Dragons"
        case .shop: return "Shop"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .train: return "figure.run"
        case .eggs: return "oval.portrait.fill"
        case .dragons: return "books.vertical.fill"
        case .shop: return "basket.fill"
        }
    }

    /// The screen a tab opens.
    var root: AppRoute {
        switch self {
        case .home: return .mainMenu
        case .train: return .trainingHub
        case .eggs: return .incubator
        case .dragons: return .dragonCollection
        case .shop: return .foodInventoryShop
        }
    }

    static func forRoute(_ route: AppRoute) -> AppTab? {
        switch route {
        case .mainMenu, .dragonPlayground: return .home
        case .trainingHub, .miniGamesHub: return .train
        case .incubator: return .eggs
        case .dragonCollection, .hallOfLegends, .den: return .dragons
        case .foodInventoryShop: return .shop
        default: return nil
        }
    }

    /// Tab roots show the tab bar and no back button.
    static func isRoot(_ route: AppRoute) -> Bool {
        route == .dragonPlayground || allCases.contains { $0.root == route }
    }
}
