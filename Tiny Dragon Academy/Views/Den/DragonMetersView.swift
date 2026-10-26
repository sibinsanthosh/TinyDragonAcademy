//
//  DragonMetersView.swift
//  Tiny Dragon Academy
//
//  The five life meters: fullness, energy, happiness, fitness, health.
//

import SwiftUI

struct DragonMetersView: View {
    let stats: DragonStats
    var compact: Bool = false

    private var meters: [(label: String, icon: String, value: Double, color: Color)] {
        [
            ("Fullness", "fork.knife", stats.hunger, DragonPalette.coral),
            ("Energy", "bolt.fill", stats.energy, Color(red: 0.95, green: 0.75, blue: 0.2)),
            ("Happiness", "heart.fill", stats.happiness, DragonPalette.rosyPink),
            ("Fitness", "figure.run", stats.fitness, DragonPalette.skyBlue),
            ("Health", "cross.fill", stats.health, Color(red: 0.35, green: 0.78, blue: 0.55))
        ]
    }

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            ForEach(meters, id: \.label) { meter in
                HStack(spacing: 6) {
                    Image(systemName: meter.icon)
                        .font(.system(size: compact ? 10 : 13, weight: .bold))
                        .foregroundColor(meter.color)
                        .frame(width: compact ? 14 : 18)
                    if !compact {
                        Text(meter.label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                            .frame(width: 76, alignment: .leading)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.08))
                            Capsule()
                                .fill(meter.value < 30 ? DragonPalette.coral : meter.color)
                                .frame(width: geo.size.width * max(0, min(1, meter.value / 100)))
                        }
                    }
                    .frame(height: compact ? 6 : 10)
                    if !compact {
                        Text("\(Int(meter.value.rounded()))")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textMuted)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(meter.label) \(Int(meter.value.rounded())) percent")
            }
        }
    }
}
