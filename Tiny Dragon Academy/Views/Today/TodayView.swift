//
//  TodayView.swift
//  Tiny Dragon Academy
//
//  The daily habit at a glance: care streak, today's quests, and each dragon's wish.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            ClayBackdrop()

            VStack(spacing: 12) {
                ScreenTopBar(title: "Today", backTo: .mainMenu)

                ScrollView {
                    VStack(spacing: 16) {
                        streakCard
                        questsCard
                        wishesCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear { gameManager.tick() }
    }

    // MARK: - Streak

    private var streakCard: some View {
        let streak = gameManager.state.streak
        return VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(ClayColor.coral.shadow(.inner(color: ClayColor.coralShade, radius: 0, x: 0, y: -5))))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.current)-day care streak")
                        .font(.clay(22, .heavy))
                        .foregroundColor(DragonPalette.textDark)
                    Text("Best \(streak.best) · feed or train, keep everyone healthy")
                        .font(.clay(13, .medium))
                        .foregroundColor(DragonPalette.textMuted)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(lastSevenDays, id: \.label) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(day.color)
                            .frame(width: 26, height: 26)
                            .overlay(Image(systemName: day.icon).font(.system(size: 11, weight: .bold)).foregroundColor(.white))
                        Text(day.label)
                            .font(.clay(11, .bold))
                            .foregroundColor(DragonPalette.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 6) {
                ForEach(0..<DailyRules.maxShields, id: \.self) { i in
                    Image(systemName: i < streak.shields ? "shield.fill" : "shield")
                        .foregroundColor(i < streak.shields ? ClayColor.skyShade : ClayColor.inkSoft.opacity(0.4))
                }
                Text(streak.shields == 1 ? "1 Streak Shield — covers one missed day" : "\(streak.shields) Streak Shields — earned at 7 days")
                    .font(.clay(12, .bold))
                    .foregroundColor(DragonPalette.textMuted)
                Spacer()
            }
        }
        .padding(16)
        .claySurface(cornerRadius: 22)
    }

    private struct DayDot {
        let label: String
        let color: Color
        let icon: String
    }

    /// Six judged days plus today, oldest first.
    private var lastSevenDays: [DayDot] {
        let past = gameManager.state.streak.recent.suffix(6).map { day -> DayDot in
            switch day.result {
            case .counted: return DayDot(label: shortLabel(day.dayId), color: DragonPalette.coral, icon: "flame.fill")
            case .shielded: return DayDot(label: shortLabel(day.dayId), color: DragonPalette.skyBlue, icon: "shield.fill")
            case .missed: return DayDot(label: shortLabel(day.dayId), color: DragonPalette.textMuted.opacity(0.35), icon: "xmark")
            }
        }
        let daily = gameManager.state.daily
        let todayDot: DayDot
        if daily.illnessToday {
            todayDot = DayDot(label: "Today", color: DragonPalette.textMuted.opacity(0.35), icon: "thermometer.medium")
        } else if daily.caredToday {
            todayDot = DayDot(label: "Today", color: DragonPalette.coral, icon: "flame.fill")
        } else {
            todayDot = DayDot(label: "Today", color: DragonPalette.buttercup, icon: "hourglass")
        }
        return past + [todayDot]
    }

    private func shortLabel(_ dayId: String) -> String {
        String(dayId.suffix(2))
    }

    // MARK: - Quests

    private var questsCard: some View {
        let daily = gameManager.state.daily
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's quests", systemImage: "checklist")
                    .font(.clay(18, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                Spacer()
                Text("\(gameManager.todayQuestsDone)/\(daily.quests.count)")
                    .font(.clay(15, .heavy))
                    .foregroundColor(ClayColor.coralShade)
            }
            if daily.quests.isEmpty {
                Text("Quests appear after your first dragon hatches.")
                    .font(.clay(14, .medium))
                    .foregroundColor(DragonPalette.textMuted)
            }
            ForEach(Array(daily.quests.enumerated()), id: \.offset) { _, quest in
                HStack(spacing: 12) {
                    Image(systemName: quest.isComplete ? "checkmark.circle.fill" : quest.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(quest.isComplete ? ClayColor.mintShade : ClayColor.accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quest.title)
                            .font(.clay(15, .bold))
                            .foregroundColor(DragonPalette.textDark)
                            .strikethrough(quest.isComplete)
                        ClayMeter(value: Double(min(quest.progress, quest.target)) / Double(max(quest.target, 1)) * 100,
                                  color: quest.isComplete ? ClayColor.mint : ClayColor.coral, height: 9)
                    }
                    Text("+\(DailyRules.questReward)★")
                        .font(.clay(13, .heavy))
                        .foregroundColor(DragonPalette.textMuted)
                }
            }
            Text(daily.allClearRewarded ? "All done today. New quests at 7am."
                                        : "Finish all three for +\(DailyRules.allClearStars)★ and a Healing Herb.")
                .font(.clay(13, .bold))
                .foregroundColor(DragonPalette.textMuted)
        }
        .padding(16)
        .claySurface(cornerRadius: 22)
    }

    // MARK: - Wishes

    private var wishesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Dragon wishes", systemImage: "sparkles")
                .font(.clay(18, .heavy))
                .foregroundColor(DragonPalette.textDark)
            if gameManager.state.denDragons.isEmpty {
                Text("No dragons in the den yet.")
                    .font(.clay(14, .medium))
                    .foregroundColor(DragonPalette.textMuted)
            }
            ForEach(gameManager.state.denDragons) { dragon in
                if let wish = gameManager.state.daily.wishes[dragon.id] {
                    Button {
                        gameManager.selectDragon(id: dragon.id)
                        gameManager.navigate(to: .dragonPlayground)
                    } label: {
                        HStack(spacing: 12) {
                            DragonView(dragon: dragon, mood: wish.granted ? .happy : .idle, size: 52, allowInteractivePetting: false)
                                .frame(width: 56, height: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dragon.badgedName)
                                    .font(.clay(15, .heavy))
                                    .foregroundColor(DragonPalette.textDark)
                                Text(wish.granted ? "Wish granted" : wish.title)
                                    .font(.clay(13, .medium))
                                    .foregroundColor(DragonPalette.textMuted)
                            }
                            Spacer()
                            Image(systemName: wish.granted ? "checkmark.seal.fill" : wish.iconName)
                                .font(.system(size: 20))
                                .foregroundColor(wish.granted ? ClayColor.mintShade : ClayColor.coral)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .claySurface(cornerRadius: 22)
    }
}
