//
//  DragonNestCard.swift
//  Tiny Dragon Academy
//
//  Pair two grown dragons on the Eggs tab: pick the parents, see the colour
//  mix their hatchling will lean toward, and lay a hybrid egg.
//

import SwiftUI

struct DragonNestCard: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var parentA: String?
    @State private var parentB: String?
    @State private var laidEgg = false

    private var candidates: [DragonModel] {
        gameManager.state.dragons
            .filter { $0.residence == .den || $0.residence == .sanctuary }
            .sorted { $0.name < $1.name }
    }

    private func dragon(_ id: String?) -> DragonModel? {
        guard let id else { return nil }
        return gameManager.state.dragons.first { $0.id == id }
    }

    private var refusal: BreedingRefusal? {
        guard let a = dragon(parentA), let b = dragon(parentB) else { return nil }
        return BreedingRules.refusal(a, b, stars: gameManager.totalStars, now: gameManager.clock.now())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Dragon Nest", systemImage: "heart.circle.fill")
                    .font(.clay(18, .heavy))
                    .foregroundColor(ClayColor.ink)
                Spacer()
                Text("\(BreedingRules.price)★")
                    .font(.clay(14, .heavy))
                    .foregroundColor(ClayColor.inkSoft)
            }
            Text("Pair two grown dragons for a hybrid egg with a mix of their colours.")
                .font(.clay(13, .bold))
                .foregroundColor(ClayColor.inkSoft)

            HStack(spacing: 10) {
                parentPicker($parentA, other: parentB)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ClayColor.rose)
                parentPicker($parentB, other: parentA)
            }

            if let a = dragon(parentA), let b = dragon(parentB) {
                mixPreview(a, b)
            }

            if laidEgg {
                Label("A hybrid egg is in your basket!", systemImage: "checkmark.seal.fill")
                    .font(.clay(14, .heavy))
                    .foregroundColor(ClayColor.mintShade)
            } else if let refusal {
                Label(refusal.message, systemImage: "info.circle.fill")
                    .font(.clay(13, .bold))
                    .foregroundColor(ClayColor.coralShade)
            }

            KidButton(title: "Pair", icon: "heart.fill", backgroundColor: ClayColor.rose, minWidth: 0, minHeight: 50, fontSize: 17) {
                guard let a = parentA, let b = parentB else { return }
                if gameManager.breed(a, b) == nil {
                    withAnimation { laidEgg = true }
                    parentA = nil
                    parentB = nil
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(parentA == nil || parentB == nil || refusal != nil)
        }
        .padding(16)
        .claySurface(cornerRadius: 22)
    }

    private func parentPicker(_ selection: Binding<String?>, other: String?) -> some View {
        Menu {
            ForEach(candidates.filter { $0.id != other }) { d in
                Button {
                    selection.wrappedValue = d.id
                    laidEgg = false
                } label: {
                    Text(pickerLabel(d))
                }
            }
        } label: {
            VStack(spacing: 4) {
                if let d = dragon(selection.wrappedValue) {
                    DragonView(dragon: d, mood: .happy, size: 56, allowInteractivePetting: false)
                        .frame(width: 60, height: 60)
                    Text(d.name)
                        .font(.clay(14, .heavy))
                        .foregroundColor(ClayColor.ink)
                        .lineLimit(1)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(ClayColor.accent.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Text("Pick a dragon")
                        .font(.clay(13, .heavy))
                        .foregroundColor(ClayColor.inkSoft)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(ClayColor.accent.opacity(0.08)))
        }
    }

    /// "Ember · Adult", plus why it can't pair yet.
    private func pickerLabel(_ d: DragonModel) -> String {
        var label = "\(d.name) · \(d.stats.growthStage.rawValue)"
        if d.stats.growthStage != .adult && d.stats.growthStage != .ancient {
            label += " (too young)"
        } else if let until = BreedingRules.restUntil(d, now: gameManager.clock.now()) {
            let hours = Int(ceil(until.timeIntervalSince(gameManager.clock.now()) / 3600))
            label += hours >= 24 ? " (resting \(hours / 24)d)" : " (resting \(hours)h)"
        } else if d.stats.condition != .healthy {
            label += " (not well)"
        }
        return label
    }

    /// The colours the hatchling will lean toward: a 50/50 mix of both parents.
    private func mixPreview(_ a: DragonModel, _ b: DragonModel) -> some View {
        let pairs = [(a.primaryColorHex, b.primaryColorHex), (a.secondaryColorHex, b.secondaryColorHex), (a.bellyColorHex, b.bellyColorHex)]
        return HStack(spacing: 8) {
            Text("Colour mix")
                .font(.clay(13, .heavy))
                .foregroundColor(ClayColor.inkSoft)
            ForEach(0..<pairs.count, id: \.self) { i in
                Circle()
                    .fill(Color(hex: ColorHex.blend(pairs[i].0, pairs[i].1, t: 0.5)))
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: ClayColor.shadow, radius: 3, y: 2)
            }
            Spacer()
            Label(BreedingRules.bestSkill(a, b).title, systemImage: BreedingRules.bestSkill(a, b).iconName)
                .font(.clay(13, .heavy))
                .foregroundColor(ClayColor.ink)
        }
    }
}
