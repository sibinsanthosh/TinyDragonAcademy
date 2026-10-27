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
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                    .multilineTextAlignment(.center)
                Text(gameManager.state.careMode == .gentle
                     ? "Your dragons get hungry, want to play, and get sleepy when they're left alone. A few gentle reminders a day tell you when they'd love a visit. We stay quiet from 10pm to 7am."
                     : "Your dragons get hungry, need training, and can fall sick — or even become spirits — if they're left alone too long. Reminders tell you when they need you. We stay quiet from 10pm to 7am.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                KidButton(title: "Turn on reminders", icon: "bell.fill", backgroundColor: DragonPalette.coral) {
                    Task { await gameManager.enableReminders() }
                }
                Button("Not now") { gameManager.markReminderPrimerSeen() }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
            .padding(.horizontal, 28)
        }
    }
}
