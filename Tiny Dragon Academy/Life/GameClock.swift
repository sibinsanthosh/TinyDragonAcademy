//
//  GameClock.swift
//  Tiny Dragon Academy
//
//  Source of "now" for the life simulation. DEBUG builds accept
//  `-timeScale N` so N game seconds pass per real second when testing.
//

import Foundation

struct GameClock {
    var timeScale: Double
    let origin: Date
    /// Extra game time added on top of the scaled clock (used by tests).
    var offset: TimeInterval = 0

    init(timeScale: Double = 1, origin: Date = Date()) {
        self.timeScale = timeScale
        self.origin = origin
    }

    func now(real: Date = Date()) -> Date {
        origin.addingTimeInterval(real.timeIntervalSince(origin) * timeScale + offset)
    }

    /// Converts a game-time date to the real date it will occur on (for scheduling notifications).
    func realDate(forGame game: Date) -> Date {
        guard timeScale > 0 else { return game }
        return origin.addingTimeInterval((game.timeIntervalSince(origin) - offset) / timeScale)
    }

    static func fromLaunchArguments(_ args: [String]) -> GameClock {
        var clock = GameClock()
        #if DEBUG
        if let i = args.firstIndex(of: "-timeScale"), i + 1 < args.count, let scale = Double(args[i + 1]), scale > 0 {
            clock.timeScale = scale
        }
        // Shifts game time, e.g. to play at "noon" while it's night outside.
        if let i = args.firstIndex(of: "-timeOffsetHours"), i + 1 < args.count, let hours = Double(args[i + 1]) {
            clock.offset = hours * 3600
        }
        #endif
        return clock
    }
}
