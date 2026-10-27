//
//  ShinyPalette.swift
//  Tiny Dragon Academy
//
//  Rare alternate colors for shiny hatches, one set per element.
//

import Foundation

enum ShinyPalette {
    static func colors(for element: DragonElement) -> (primary: String, secondary: String, belly: String) {
        switch element {
        case .stars: return ("#2E2A6B", "#FFD86B", "#C9C2FF")
        case .fire: return ("#3A3F8F", "#FF6B9A", "#FFE1EC")
        case .water: return ("#FF9F6B", "#FFE08A", "#FFF4E0")
        case .nature: return ("#C77DFF", "#7CF2B4", "#F5E8FF")
        case .ice: return ("#FFB3D9", "#B8F2FF", "#FFF0F8")
        case .lightning: return ("#1F2A44", "#FFE45C", "#9FB4FF")
        case .laser: return ("#FF5CA8", "#5CF2FF", "#FFE3F1")
        case .earth: return ("#E2B66A", "#7A5CFF", "#FFF3D6")
        case .wind: return ("#FFC97A", "#B98CFF", "#FFF6E6")
        case .sun: return ("#6B4CFF", "#FFB84D", "#E9E2FF")
        case .flower: return ("#5CC9A7", "#FFE66B", "#E6FFF6")
        case .ocean: return ("#FF7A7A", "#FFD1A6", "#FFF0EB")
        case .moon: return ("#E8E2C8", "#7FD8FF", "#FFFDF2")
        case .sweet: return ("#6BC6FF", "#B7FF8A", "#EAF7FF")
        case .rainbow: return ("#FFFFFF", "#FFD6F5", "#F2FBFF")
        }
    }
}
