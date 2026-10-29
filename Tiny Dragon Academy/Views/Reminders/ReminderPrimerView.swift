//
//  ReminderPrimerView.swift
//  Tiny Dragon Academy
//
//  Explains why care reminders matter before showing the system prompt.
//

import SwiftUI

struct ReminderPrimerView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 44))
                    .foregroundColor(DragonPalette.coral)
                Text("Never miss feeding time")
                    .font(.clay(22, .heavy))
                    .foregroundColor(DragonPalette.textDark)
                    .multilineTextAlignment(.center)
                Text(gameManager.state.careMode == .gentle
                     ? "Your dragons get hungry, want to play, and get sleepy when they're left alone. A few gentle reminders a day tell you when they'd love a visit. We stay quiet from 10pm to 7am."
                     : "Your dragons get hungry, need training, and can fall sick — or even become spirits — if they're left alone too long. Reminders tell you when they need you. We stay quiet from 10pm to 7am.")
                    .font(.clay(14, .medium))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                KidButton(title: "Turn on reminders", icon: "bell.fill", backgroundColor: ClayColor.accent) {
                    Task { await gameManager.enableReminders() }
                }
                Button("Not now") { gameManager.markReminderPrimerSeen() }
                    .font(.clay(15, .bold))
                    .foregroundColor(DragonPalette.textMuted)
            }
            .padding(24)
            .claySurface(cornerRadius: 24)
            .padding(.horizontal, 28)
        }
    }
}
