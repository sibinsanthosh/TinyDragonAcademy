//
//  WidgetSnapshot.swift
//  Tiny Dragon Academy (shared with Tiny Dragon Widget)
//
//  What the home- and lock-screen widgets show: a short timeline of the
//  active dragon's predicted state, written by the app into the shared
//  App Group and read by the widget.
//

import Foundation

enum WidgetMood: String, Codable, Equatable {
    case happy, hungry, tired, sick, asleep, spirit, empty

    var title: String {
        switch self {
        case .happy: return "Happy"
        case .hungry: return "Hungry!"
        case .tired: return "Sleepy"
        case .sick: return "Feeling sick"
        case .asleep: return "Asleep"
        case .spirit: return "Needs you"
        case .empty: return "Hatch an egg"
        }
    }
}

struct WidgetSnapshot: Codable, Equatable {
    struct Entry: Codable, Equatable {
        var date: Date
        var name: String
        /// Primary, secondary and belly colour hexes.
        var colors: [String]
        var stageTitle: String
        var mood: WidgetMood
        var hunger: Double
        var energy: Double
        var health: Double
    }

    var entries: [Entry]

    /// The latest entry at or before `date` (the first one if `date` is earlier).
    func entry(at date: Date) -> Entry? {
        entries.last { $0.date <= date } ?? entries.first
    }

    /// Changes only when something visible changes: name, mood, or a meter by 10 points.
    var signature: String {
        guard let first = entries.first else { return "none" }
        func bucket(_ v: Double) -> Int { Int((v / 10).rounded()) }
        return "\(first.name)|\(first.mood.rawValue)|\(first.colors.joined())|\(bucket(first.hunger))|\(bucket(first.energy))|\(bucket(first.health))|\(entries.count)"
    }
}

enum WidgetStore {
    static let appGroup = "group.sibaatta.com.Tiny-Dragon-Academy"
    private static let key = "widgetSnapshot"

    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: appGroup)?.set(data, forKey: key)
    }

    static func read() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
