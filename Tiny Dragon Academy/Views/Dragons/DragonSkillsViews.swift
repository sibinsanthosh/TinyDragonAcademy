//
//  DragonSkillsViews.swift
//  Tiny Dragon Academy
//
//  How a dragon's skills and talent are shown: star strings, the compact
//  strip on My Dragons rows, and the detail sheet.
//

import SwiftUI

enum SkillStars {
    /// "★★★☆☆" for 3 of 5.
    static func text(_ stars: Int) -> String {
        let filled = min(SkillRules.maxStars, max(0, stars))
        return String(repeating: "★", count: filled) + String(repeating: "☆", count: SkillRules.maxStars - filled)
    }
}

/// Four skills with their star counts, plus the talent name; tapping opens the details.
struct DragonSkillsStrip: View {
    let dragon: DragonModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                // Two rows of two so the strip fits next to the row's action button
                ForEach([[DragonSkill.stamina, .aim], [.agility, .reflexes]], id: \.self) { pair in
                    HStack(spacing: 10) {
                        ForEach(pair) { skill in
                            HStack(spacing: 3) {
                                Image(systemName: skill.iconName).foregroundColor(skill.game.themeColor)
                                Text("\(dragon.skillStars(skill))★").foregroundColor(DragonPalette.textDark)
                            }
                            .fixedSize()
                        }
                    }
                }
                .font(.clay(11, .heavy))
                HStack(spacing: 4) {
                    if let talent = dragon.talent {
                        Label(talent.title, systemImage: "sparkles")
                    }
                    Image(systemName: "info.circle.fill").foregroundColor(DragonPalette.softPurple)
                }
                .font(.clay(11, .bold))
                .foregroundColor(DragonPalette.textMuted)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(dragon.name)'s skills")
    }
}

struct DragonSkillsSheet: View {
    let dragon: DragonModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DragonView(dragon: dragon, mood: .happy, size: 110, allowInteractivePetting: false)
                Text("\(dragon.badgedName)'s Skills")
                    .font(.clay(24, .heavy))
                    .foregroundColor(DragonPalette.textDark)

                ForEach(DragonSkill.allCases) { skill in
                    skillRow(skill)
                }

                if let talent = dragon.talent {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles").foregroundColor(talent.game.themeColor)
                            Text("Talent: \(talent.title)").foregroundColor(DragonPalette.textDark)
                        }
                        .font(.clay(17, .heavy))
                        Text(talent.summary)
                            .font(.clay(15, .semibold))
                            .foregroundColor(DragonPalette.textDark)
                        Text("Works in \(talent.game.rawValue).")
                            .font(.clay(13, .bold))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(talent.game.themeColor.opacity(0.12)))
                }

                Text("Train in a game to grow its skill. Higher stars make that game easier.")
                    .font(.clay(13, .semibold))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)

                KidButton(title: "Done", icon: "checkmark", backgroundColor: DragonPalette.softPurple) { dismiss() }
            }
            .padding(24)
        }
        .background(ClayBackdrop())
    }

    private func skillRow(_ skill: DragonSkill) -> some View {
        let progress = dragon.skillProgress(skill)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(skill.title, systemImage: skill.iconName)
                    .font(.clay(16, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                Spacer()
                Text(SkillStars.text(progress.stars))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DragonPalette.starGold)
            }
            if let needed = progress.needed {
                ProgressView(value: Double(progress.into), total: Double(needed))
                    .tint(skill.game.themeColor)
                Text("\(progress.into) / \(needed) points to the next star • \(skill.game.rawValue)")
                    .font(.clay(12, .bold))
                    .foregroundColor(DragonPalette.textMuted)
            } else {
                Text("Max stars! • \(skill.game.rawValue)")
                    .font(.clay(12, .bold))
                    .foregroundColor(DragonPalette.textMuted)
            }
        }
        .padding(14)
        .claySurface(cornerRadius: 16)
    }
}
