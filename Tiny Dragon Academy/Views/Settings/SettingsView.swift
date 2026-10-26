//
//  SettingsView.swift
//  Tiny Dragon Academy
//
//  Parent-gated settings screen with audio controls, accessibility toggles,
//  COPPA child privacy assurance, and safe data reset.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameManager: GameManager
    
    @State private var showResetConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            DragonPalette.skyGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: {
                        HapticsService.shared.medium()
                        AudioService.shared.playPop()
                        gameManager.navigate(to: .mainMenu)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 26))
                            Text("Back")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(DragonPalette.textDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.9)))
                    }
                    
                    Spacer()
                    
                    Text("Parent Zone")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(DragonPalette.textDark)
                    
                    Spacer()
                    
                    // Empty spacer to balance header
                    Spacer().frame(width: 70)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                ScrollView {
                    VStack(spacing: 18) {
                        // Audio Section
                        settingsCard(title: "Audio & Music", icon: "speaker.wave.2.fill") {
                            Toggle("Sound Effects", isOn: Binding(
                                get: { gameManager.state.settings.isSoundEnabled },
                                set: { gameManager.updateSettings(sound: $0) }
                            ))
                            .tint(DragonPalette.softPurple)
                            
                            Toggle("Ambient Lullaby Music", isOn: Binding(
                                get: { gameManager.state.settings.isMusicEnabled },
                                set: { gameManager.updateSettings(music: $0) }
                            ))
                            .tint(DragonPalette.softPurple)
                        }
                        
                        // Care Reminders Section
                        settingsCard(title: "Care Reminders", icon: "bell.badge.fill") {
                            Toggle("Remind me when dragons need care", isOn: Binding(
                                get: { gameManager.state.remindersEnabled },
                                set: { gameManager.setRemindersEnabled($0) }
                            ))
                            .tint(DragonPalette.coral)
                        }
                        
                        // Accessibility Section
                        settingsCard(title: "Accessibility", icon: "figure.walk.circle.fill") {
                            Toggle("Reduce Motion", isOn: Binding(
                                get: { gameManager.state.settings.reduceMotion },
                                set: { gameManager.updateSettings(reduceMotion: $0) }
                            ))
                            .tint(DragonPalette.mintGreen)
                            
                            Toggle("High Contrast Visual Hints", isOn: Binding(
                                get: { gameManager.state.settings.highContrastHints },
                                set: { gameManager.updateSettings(highContrast: $0) }
                            ))
                            .tint(DragonPalette.mintGreen)
                        }
                        
                        // Child Safety & Privacy Assurance Card
                        safetyPledgeCard
                        
                        // Reset Data Section
                        resetDataCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
            
            // Reset Confirmation Modal
            if showResetConfirmation {
                resetConfirmationModal
            }
        }
    }
    
    // MARK: - Reusable Settings Card
    
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DragonPalette.softPurple)
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
            }
            
            Divider()
            
            content()
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(DragonPalette.textDark)
        }
        .padding(18)
        .kidCard()
    }
    
    // MARK: - Privacy Pledge Card
    
    private var safetyPledgeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DragonPalette.mintGreen)
                Text("Child Safety & Privacy")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                privacyBullet(icon: "airplane", text: "Works 100% offline (no internet needed)")
                privacyBullet(icon: "xmark.circle.fill", text: "Zero advertisements or sponsored content")
                privacyBullet(icon: "eye.slash.fill", text: "Zero tracking, analytics, or data collection")
                privacyBullet(icon: "cart.badge.minus", text: "No in-app purchases or subscriptions")
                privacyBullet(icon: "lock.fill", text: "Settings protected behind grown-up gate")
            }
        }
        .padding(18)
        .kidCard()
    }
    
    private func privacyBullet(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(DragonPalette.softPurple)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(DragonPalette.textMuted)
        }
    }
    
    // MARK: - Reset Data Card
    
    private var resetDataCard: some View {
        VStack(spacing: 10) {
            Button(action: {
                showResetConfirmation = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Reset All Saved Progress")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(DragonPalette.coral)
                .padding(.vertical, 8)
            }
            
            Text("Erases unlocked dragons, island layout, and star balance.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(DragonPalette.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .kidCard(borderColor: DragonPalette.coral.opacity(0.3))
    }
    
    private var resetConfirmationModal: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(DragonPalette.coral)
                
                Text("Reset Everything?")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                
                Text("This will restore the app to its fresh install state and hatch your first egg again.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 14) {
                    Button("Cancel") {
                        showResetConfirmation = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DragonPalette.textDark)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.white))
                    
                    Button("Yes, Reset") {
                        showResetConfirmation = false
                        gameManager.resetAllProgress()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(DragonPalette.coral))
                }
            }
            .padding(26)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.white))
            .padding(.horizontal, 30)
        }
    }
}
