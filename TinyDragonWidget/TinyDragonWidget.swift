//
//  TinyDragonWidget.swift
//  Tiny Dragon Widget
//
//  Home-screen (small, medium) and lock-screen (circular, inline) widgets
//  showing the active dragon, its mood and its meters. Reads the timeline
//  the app writes to the shared App Group.
//

import SwiftUI
import WidgetKit

struct DragonEntry: TimelineEntry {
    let date: Date
    let dragon: WidgetSnapshot.Entry
}

struct DragonProvider: TimelineProvider {
    static let sample = WidgetSnapshot.Entry(date: Date(), name: "Sparkle", colors: ["#D0C7F5", "#FFEAA7", "#FFF9E6"],
                                             stageTitle: "Baby Dragon", mood: .happy, hunger: 80, energy: 70, health: 95)

    func placeholder(in context: Context) -> DragonEntry {
        DragonEntry(date: Date(), dragon: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DragonEntry) -> Void) {
        let now = Date()
        let entry = WidgetStore.read()?.entry(at: now) ?? Self.sample
        completion(DragonEntry(date: now, dragon: entry))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DragonEntry>) -> Void) {
        let now = Date()
        guard let snapshot = WidgetStore.read(), let current = snapshot.entry(at: now) else {
            let empty = WidgetSnapshot.Entry(date: now, name: "", colors: [], stageTitle: "", mood: .empty,
                                             hunger: 0, energy: 0, health: 0)
            completion(Timeline(entries: [DragonEntry(date: now, dragon: empty)], policy: .after(now.addingTimeInterval(3600))))
            return
        }
        // The current state now, then each future projection at its own time,
        // then a "missing you" entry once the projections run out
        var entries = [DragonEntry(date: now, dragon: current)]
        entries += snapshot.entries.filter { $0.date > now }.map { DragonEntry(date: $0.date, dragon: $0) }
        if let last = snapshot.entries.last {
            let staleAt = last.date.addingTimeInterval(WidgetSnapshot.staleAfter + 1)
            if staleAt > now, let stale = snapshot.entry(at: staleAt), stale.mood == .stale {
                entries.append(DragonEntry(date: staleAt, dragon: stale))
            }
        }
        let refresh = snapshot.entries.last.map { max($0.date, now.addingTimeInterval(1800)) } ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

struct TinyDragonWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TinyDragonWidget", provider: DragonProvider()) { entry in
            DragonWidgetView(entry: entry)
        }
        .configurationDisplayName("My Dragon")
        .description("See how your dragon is doing at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}

@main
struct TinyDragonWidgetBundle: WidgetBundle {
    var body: some Widget {
        TinyDragonWidget()
    }
}

// MARK: - Views

struct DragonWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DragonEntry

    private var dragon: WidgetSnapshot.Entry { entry.dragon }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryInline:
            Text(dragon.mood == .empty ? "Tiny Dragon · Hatch an egg" : "\(dragon.name) · \(dragon.mood.title)")
        case .systemMedium:
            medium
        default:
            small
        }
    }

    private var background: some View {
        LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.89), Color(red: 0.84, green: 0.93, blue: 1.0)],
                       startPoint: .top, endPoint: .bottom)
    }

    private var small: some View {
        VStack(spacing: 6) {
            WidgetDragonFace(colors: dragon.colors, mood: dragon.mood)
                .frame(width: 74, height: 74)
            Text(dragon.mood == .empty ? "Tiny Dragon" : dragon.name)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(WidgetInk.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(dragon.mood.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(WidgetInk.moodColor(dragon.mood))
        }
        .containerBackground(for: .widget) { background }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                WidgetDragonFace(colors: dragon.colors, mood: dragon.mood)
                    .frame(width: 86, height: 86)
                Text(dragon.mood.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetInk.moodColor(dragon.mood))
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(dragon.mood == .empty ? "Tiny Dragon" : dragon.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(WidgetInk.ink)
                    .lineLimit(1)
                if dragon.mood == .empty {
                    Text("Your den is empty. Hatch an egg to meet a new dragon.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(WidgetInk.inkSoft)
                } else {
                    meter("fork.knife", dragon.hunger, Color(red: 1.0, green: 0.54, blue: 0.36))
                    meter("bolt.fill", dragon.energy, Color(red: 0.94, green: 0.64, blue: 0.10))
                    meter("cross.fill", dragon.health, Color(red: 0.25, green: 0.66, blue: 0.40))
                    Text(hint)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(WidgetInk.inkSoft)
                        .lineLimit(1)
                }
            }
        }
        .containerBackground(for: .widget) { background }
    }

    private var hint: String {
        switch dragon.mood {
        case .hungry: return "Feed me, please!"
        case .sick: return "I need some care"
        case .spirit: return "Come back for me"
        case .stale: return "Open the app to check on me"
        case .asleep: return "Shh… see you at 7"
        case .tired: return "Time for a rest"
        default: return "\(dragon.stageTitle)"
        }
    }

    private func meter(_ icon: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
                .frame(width: 14)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.85))
                    Capsule().fill(color).frame(width: max(8, geo.size.width * min(max(value, 0), 100) / 100))
                }
            }
            .frame(height: 8)
        }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Gauge(value: min(max(dragon.hunger, 0), 100), in: 0...100) {
                Image(systemName: "fork.knife")
            } currentValueLabel: {
                Image(systemName: dragon.mood == .asleep ? "moon.zzz.fill" : "flame.fill")
            }
            .gaugeStyle(.accessoryCircular)
        }
        .widgetAccentable()
        .containerBackground(for: .widget) { Color.clear }
    }
}

/// A simple drawn clay dragon head in the dragon's own colours.
struct WidgetDragonFace: View {
    let colors: [String]
    let mood: WidgetMood

    private var primary: Color { Color(widgetHex: colors.first ?? "#D0C7F5") }
    private var accent: Color { Color(widgetHex: colors.count > 1 ? colors[1] : "#FFEAA7") }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Little horns
                HStack(spacing: s * 0.34) {
                    Capsule().fill(accent).frame(width: s * 0.11, height: s * 0.26).rotationEffect(.degrees(-18))
                    Capsule().fill(accent).frame(width: s * 0.11, height: s * 0.26).rotationEffect(.degrees(18))
                }
                .offset(y: -s * 0.36)
                Circle()
                    .fill(RadialGradient(colors: [Color.white.opacity(0.55), primary], center: UnitPoint(x: 0.35, y: 0.25),
                                         startRadius: 0, endRadius: s * 0.6))
                    .background(Circle().fill(primary))
                    .frame(width: s * 0.82, height: s * 0.82)
                    .offset(y: s * 0.04)
                eyes(s)
                    .offset(y: -s * 0.02)
                Circle().fill(Color.pink.opacity(0.35)).frame(width: s * 0.14).offset(x: -s * 0.24, y: s * 0.12)
                Circle().fill(Color.pink.opacity(0.35)).frame(width: s * 0.14).offset(x: s * 0.24, y: s * 0.12)
                mouth(s).offset(y: s * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(mood == .spirit ? 0.5 : 1)
            .saturation(mood == .empty ? 0 : 1)
        }
    }

    @ViewBuilder
    private func eyes(_ s: CGFloat) -> some View {
        HStack(spacing: s * 0.2) {
            ForEach(0..<2, id: \.self) { _ in
                if mood == .asleep || mood == .tired {
                    Capsule().fill(WidgetInk.ink).frame(width: s * 0.13, height: s * 0.035)
                } else {
                    Circle().fill(WidgetInk.ink).frame(width: s * 0.12)
                        .overlay(Circle().fill(Color.white).frame(width: s * 0.04).offset(x: s * 0.02, y: -s * 0.02))
                }
            }
        }
    }

    private func mouth(_ s: CGFloat) -> some View {
        Path { p in
            let w = s * 0.16
            p.move(to: CGPoint(x: 0, y: 0))
            p.addQuadCurve(to: CGPoint(x: w, y: 0),
                           control: CGPoint(x: w / 2, y: mood == .happy ? s * 0.08 : (mood == .hungry || mood == .sick ? -s * 0.05 : s * 0.02)))
        }
        .stroke(WidgetInk.ink, style: StrokeStyle(lineWidth: max(1.5, s * 0.03), lineCap: .round))
        .frame(width: s * 0.16, height: s * 0.08)
    }
}

enum WidgetInk {
    static let ink = Color(red: 0.29, green: 0.21, blue: 0.34)
    static let inkSoft = Color(red: 0.54, green: 0.45, blue: 0.60)

    static func moodColor(_ mood: WidgetMood) -> Color {
        switch mood {
        case .happy: return Color(red: 0.25, green: 0.66, blue: 0.40)
        case .hungry, .sick, .spirit, .stale: return Color(red: 0.90, green: 0.38, blue: 0.24)
        case .tired, .asleep: return Color(red: 0.42, green: 0.31, blue: 0.88)
        case .empty: return inkSoft
        }
    }
}

extension Color {
    init(widgetHex hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = Int(s, radix: 16) ?? 0xD0C7F5
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}
