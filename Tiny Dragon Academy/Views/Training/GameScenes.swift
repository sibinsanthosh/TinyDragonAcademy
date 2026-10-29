//
//  GameScenes.swift
//  Tiny Dragon Academy
//
//  Clay backdrops for the four training games and the pill HUD they share.
//

import SwiftUI

/// Timer, score and extras as clay pills across the top of a game.
struct ClayGameHUD: View {
    var seconds: Int? = nil
    let score: String
    var scoreIcon: String = "star.fill"
    var trailing: (icon: String, text: String, color: Color)? = nil
    var lives: Int? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let seconds {
                ClayPill(systemName: "timer", iconColor: seconds <= 5 ? ClayColor.coralShade : ClayColor.sky,
                         value: "\(seconds)s", accessibilityLabel: "Time left")
            }
            Spacer(minLength: 0)
            ClayPill(systemName: scoreIcon, iconColor: ClayColor.sun, value: score, accessibilityLabel: "Score")
            Spacer(minLength: 0)
            if let lives {
                HStack(spacing: 2) {
                    ForEach(0..<SnackCatchGameState.startingLives, id: \.self) { i in
                        Image(systemName: i < lives ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ClayColor.rose)
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .claySurface(cornerRadius: 17, elevation: 0.7)
                .accessibilityLabel("\(lives) lives left")
            } else if let trailing {
                ClayPill(systemName: trailing.icon, iconColor: trailing.color, value: trailing.text)
            } else if seconds != nil {
                Color.clear.frame(width: 60, height: 34)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }
}

/// Dragon Dash: two layers of rolling hills and a grassy ground strip.
struct DashScene: View {
    let size: CGSize
    let groundY: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            gameSky
            SkyDecor(size: size)
            ClayHills(color: ClayColor.blobSky, bumps: 3)
                .frame(width: size.width, height: 150)
                .offset(y: groundY - 130)
            ClayHills(color: Color(red: 0.72, green: 0.92, blue: 0.74), bumps: 5)
                .frame(width: size.width, height: 90)
                .offset(y: groundY - 70)
            ground(width: size.width, height: size.height - groundY + 120)
                .offset(y: groundY)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// Fire Target: a meadow with a soft hill line behind the dragon.
struct MeadowScene: View {
    let size: CGSize
    let groundY: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            gameSky
            SkyDecor(size: size)
            ClayHills(color: Color(red: 0.72, green: 0.92, blue: 0.74), bumps: 3)
                .frame(width: size.width, height: 80)
                .offset(y: groundY - 55)
            ground(width: size.width, height: size.height - groundY + 120)
                .offset(y: groundY)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// Sky Flight: open sky with a few soft background clouds.
struct SkyScene: View {
    let size: CGSize

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.75, green: 0.89, blue: 1.0), Color(red: 0.93, green: 0.90, blue: 1.0)],
                           startPoint: .top, endPoint: .bottom)
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: size.width * [0.32, 0.22, 0.28, 0.2][i], height: 26)
                    .position(x: size.width * [0.2, 0.75, 0.55, 0.12][i], y: size.height * [0.2, 0.35, 0.68, 0.85][i])
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

/// Catch the Snacks: a checked picnic blanket along the bottom.
struct PicnicScene: View {
    let size: CGSize

    var body: some View {
        let blanket: CGFloat = 70
        ZStack(alignment: .bottom) {
            gameSky
            SkyDecor(size: size)
            HStack(spacing: 0) {
                ForEach(0..<12, id: \.self) { i in
                    VStack(spacing: 0) {
                        Rectangle().fill(i.isMultiple(of: 2) ? ClayColor.rose.opacity(0.7) : Color.white)
                        Rectangle().fill(i.isMultiple(of: 2) ? Color.white : ClayColor.rose.opacity(0.7))
                    }
                }
            }
            .frame(width: size.width, height: blanket)
            .overlay(alignment: .top) { Rectangle().fill(ClayColor.rose).frame(height: 6) }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

/// Soft sky behind every game, so the menu backdrop doesn't show through.
private var gameSky: some View {
    GameSky().padding(.bottom, -120)
}

/// A clay sun and a few puffy clouds for the open sky.
struct SkyDecor: View {
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(ClayColor.sun.shadow(.inner(color: ClayColor.sunShade, radius: 0, x: 0, y: -6)))
                .frame(width: 64, height: 64)
                .shadow(color: ClayColor.sun.opacity(0.5), radius: 18)
                .position(x: size.width * 0.82, y: size.height * 0.2)
            puff(width: size.width * 0.3).position(x: size.width * 0.22, y: size.height * 0.24)
            puff(width: size.width * 0.22).position(x: size.width * 0.6, y: size.height * 0.36)
            puff(width: size.width * 0.26).position(x: size.width * 0.3, y: size.height * 0.48)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func puff(width: CGFloat) -> some View {
        HStack(spacing: -width * 0.25) {
            Circle().frame(width: width * 0.42)
            Circle().frame(width: width * 0.58).offset(y: -width * 0.08)
            Circle().frame(width: width * 0.42)
        }
        .foregroundColor(Color.white.opacity(0.85))
    }
}

/// The game sky colour, also painted behind the game header so there's no seam.
struct GameSky: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.80, green: 0.91, blue: 1.0), Color(red: 0.99, green: 0.89, blue: 0.93)],
                       startPoint: .top, endPoint: .bottom)
    }
}

/// A grass strip with a darker lip, shared by the ground-based scenes.
private func ground(width: CGFloat, height: CGFloat) -> some View {
    Rectangle()
        .fill(Color(red: 0.55, green: 0.85, blue: 0.58))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(red: 0.40, green: 0.75, blue: 0.46)).frame(height: 8)
        }
        .frame(width: width, height: max(0, height))
}
