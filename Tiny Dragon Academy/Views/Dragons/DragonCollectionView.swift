//
//  DragonCollectionView.swift
//  Tiny Dragon Academy
//
//  All your dragons: who lives in the den, who rests in the sanctuary,
//  the Hall of Legends, and species still waiting in mystery eggs.
//

import SwiftUI

struct DragonCollectionView: View {
    @EnvironmentObject var gameManager: GameManager

    private enum Tab: String, CaseIterable {
        case den = "Den"
        case sanctuary = "Sanctuary"
        case legends = "Legends"
        case undiscovered = "Undiscovered"
    }

    @State private var tab: Tab = .den
    @State private var refusal: String?

    var body: some View {
        ZStack {
            DragonPalette.skyGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                ScreenTopBar(title: "My Dragons")

                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                ScrollView {
                    VStack(spacing: 12) {
                        switch tab {
                        case .den:
                            Text("\(gameManager.state.denDragons.count) of \(gameManager.state.denCapacity) den spots used")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DragonPalette.textMuted)
                            ForEach(dragons(in: .den)) { row($0) }
                        case .sanctuary:
                            Text("Sanctuary dragons are frozen in time — no care needed, no danger.")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DragonPalette.textMuted)
                                .multilineTextAlignment(.center)
                            ForEach(dragons(in: .sanctuary)) { row($0) }
                        case .legends:
                            HallOfLegendsList()
                        case .undiscovered:
                            undiscoveredGrid
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .alert("Can't move", isPresented: Binding(get: { refusal != nil }, set: { if !$0 { refusal = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(refusal ?? "")
        }
        .onAppear { gameManager.tick() }
    }

    private func dragons(in residence: DragonResidence) -> [DragonModel] {
        gameManager.state.dragons.filter { $0.residence == residence }
    }

    private func row(_ dragon: DragonModel) -> some View {
        let status = dragon.residence == .den
            ? DragonStatus.describe(dragon.stats, now: gameManager.clock.now(), calendar: gameManager.calendar)
            : nil
        return HStack(spacing: 12) {
            DragonView(dragon: dragon, mood: .idle, size: 64, allowInteractivePetting: false)
                .opacity(dragon.stats.condition.isSpirit ? 0.45 : 1)
                .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(dragon.name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                Text("\(dragon.speciesTitle) • \(dragon.stats.growthStage.rawValue) • Lvl \(dragon.stats.level)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                if let status { DragonStatusBadge(status: status) }
            }
            Spacer()
            if dragon.residence == .den {
                actionButton("Rest", icon: "moon.stars.fill") {
                    if !gameManager.moveToSanctuary(dragon.id) {
                        refusal = "\(dragon.name) must be healthy to rest in the sanctuary."
                    }
                }
            } else {
                actionButton("To den", icon: "house.fill") {
                    if !gameManager.moveToDen(dragon.id) {
                        refusal = "Your den is full. Rest a dragon or buy another den spot."
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.92)))
        .contentShape(Rectangle())
        .onTapGesture {
            guard dragon.residence == .den else { return }
            gameManager.selectDragon(id: dragon.id)
            gameManager.navigate(to: .dragonPlayground)
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticsService.shared.light()
            action()
        }) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(DragonPalette.lavender))
        }
        .buttonStyle(.plain)
    }

    private var undiscoveredGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(dragons(in: .undiscovered)) { dragon in
                VStack(spacing: 6) {
                    DragonView(dragon: dragon, mood: .idle, size: 70, allowInteractivePetting: false)
                        .colorMultiply(.black)
                        .opacity(0.25)
                    Text("???")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    if let tier = EggTier.tier(forSpecies: dragon.id) {
                        Text(tier.displayName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.85)))
            }
        }
    }
}
