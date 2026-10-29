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
    /// The app hasn't been opened since the timeline ran out.
    case stale

    var title: String {
        switch self {
        case .happy: return "Happy"
        case .hungry: return "Hungry!"
        case .tired: return "Sleepy"
        case .sick: return "Feeling sick"
        case .asleep: return "Asleep"
        case .spirit: return "Needs you"
        case .empty: return "Hatch an egg"
        case .stale: return "Missing you"
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

    /// How long past the last projection before the widget stops guessing.
    static let staleAfter: TimeInterval = 3600

    /// The latest entry at or before `date` (the first one if `date` is earlier).
    /// Well past the end of the timeline the dragon is shown as `.stale`.
    func entry(at date: Date) -> Entry? {
        guard let last = entries.last else { return nil }
        if last.mood != .empty, date > last.date.addingTimeInterval(Self.staleAfter) {
            var stale = last
            stale.date = date
            stale.mood = .stale
            return stale
        }
        return entries.last { $0.date <= date } ?? entries.first
    }

    /// Changes when something the widget will show changes (any entry's mood,
    /// stage, or a meter by 10 points), and at least every hour so the
    /// timeline never runs out while the app is in use.
    var signature: String {
        guard let first = entries.first else { return "none" }
        func bucket(_ v: Double) -> Int { Int((v / 10).rounded()) }
        let hour = Int(first.date.timeIntervalSinceReferenceDate / 3600)
        let timeline = entries.map { "\($0.mood.rawValue)\($0.stageTitle)\(bucket($0.hunger)),\(bucket($0.energy)),\(bucket($0.health))" }
        return "\(hour)|\(first.name)|\(first.colors.joined())|" + timeline.joined(separator: ";")
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
