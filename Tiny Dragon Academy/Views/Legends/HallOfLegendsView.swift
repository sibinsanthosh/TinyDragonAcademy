//
//  HallOfLegendsView.swift
//  Tiny Dragon Academy
//
//  Memorials for dragons whose spirits moved on.
//

import SwiftUI

struct HallOfLegendsView: View {
    var body: some View {
        ZStack {
            DragonPalette.nightGradient.ignoresSafeArea()
            VStack(spacing: 12) {
                ScreenTopBar(title: "Hall of Legends", backTo: .dragonCollection)
                ScrollView { HallOfLegendsList().padding(.horizontal, 16) }
            }
        }
    }
}

struct HallOfLegendsList: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        VStack(spacing: 12) {
            if gameManager.state.hallOfLegends.isEmpty {
                Text("No legends yet. Every dragon here is still with you. 💜")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)
            }
            ForEach(gameManager.state.hallOfLegends.reversed()) { memorial in
                HStack(spacing: 12) {
                    if let dragon = gameManager.state.dragons.first(where: { $0.id == memorial.dragonId }) {
                        DragonView(dragon: dragon, mood: .sleepy, size: 60, stageOverride: memorial.stage, allowInteractivePetting: false)
                            .saturation(0.3)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(memorial.name)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(DragonPalette.textDark)
                        Text("\(memorial.speciesTitle) • \(memorial.stage.rawValue) • Lvl \(memorial.level)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(DragonPalette.textMuted)
                        Text("\(memorial.bornAt.formatted(date: .abbreviated, time: .omitted)) – \(memorial.diedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                    Spacer()
                    Image(systemName: "laurel.leading")
                        .font(.system(size: 22))
                        .foregroundColor(DragonPalette.buttercup)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.92)))
            }
        }
    }
}
