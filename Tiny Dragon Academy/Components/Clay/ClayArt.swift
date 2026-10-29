//
//  ClayArt.swift
//  Tiny Dragon Academy
//
//  Drawn clay game art that replaces emoji: targets, balloons, shields,
//  bursts, gems, storm clouds, rocks, cacti, bats, food and backdrops.
//  Every piece is lit from the top-left with a darker underside.
//

import SwiftUI

/// Fill with a soft clay highlight: light top-left fading into the base colour.
private func clayFill(_ base: Color, highlight: Double = 0.55) -> RadialGradient {
    RadialGradient(colors: [Color.white.opacity(highlight), base.opacity(0)], center: UnitPoint(x: 0.35, y: 0.25), startRadius: 0, endRadius: 60)
}

/// A shaded clay blob of any shape.
private struct ClayShape<S: Shape>: View {
    let shape: S
    let color: Color
    var shade: Double = 0.22

    var body: some View {
        shape
            .fill(color.shadow(.inner(color: Color.black.opacity(shade), radius: 1, x: 0, y: -4)))
            .overlay(shape.fill(clayFill(color)))
    }
}

// MARK: - Fire Target

struct ClayTargetBoard: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.62, green: 0.42, blue: 0.28))
                .frame(width: size * 0.12, height: size * 0.55)
                .offset(y: size * 0.42)
            ZStack {
                ClayShape(shape: Circle(), color: ClayColor.coralShade)
                Circle().fill(Color.white).padding(size * 0.14)
                Circle().fill(ClayColor.coral).padding(size * 0.26)
                Circle().fill(Color.white).padding(size * 0.36)
                Circle().fill(ClayColor.coralShade).padding(size * 0.43)
                Circle().fill(clayFill(.white, highlight: 0.5))
            }
            .frame(width: size, height: size)
            .shadow(color: ClayColor.shadow, radius: 4, y: 3)
        }
        .frame(width: size, height: size)
    }
}

struct ClayBalloon: View {
    var size: CGFloat
    var color: Color = ClayColor.rose

    var body: some View {
        VStack(spacing: 0) {
            ClayShape(shape: Ellipse(), color: color)
                .frame(width: size * 0.82, height: size)
            Triangle()
                .fill(color)
                .frame(width: size * 0.16, height: size * 0.1)
            Path { p in
                p.move(to: CGPoint(x: size * 0.05, y: 0))
                p.addQuadCurve(to: CGPoint(x: size * 0.05, y: size * 0.4), control: CGPoint(x: size * 0.16, y: size * 0.2))
            }
            .stroke(ClayColor.inkSoft, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: size * 0.1, height: size * 0.4)
        }
        .shadow(color: ClayColor.shadow, radius: 3, y: 2)
    }
}

struct ClayShieldDummy: View {
    var size: CGFloat
    var hits: Int = 2

    var body: some View {
        ZStack {
            ClayShape(shape: ShieldShape(), color: Color(red: 0.55, green: 0.62, blue: 0.80))
            ShieldShape()
                .stroke(Color(red: 0.95, green: 0.78, blue: 0.30), lineWidth: size * 0.07)
                .padding(size * 0.05)
            Image(systemName: hits > 1 ? "star.fill" : "star.leadinghalf.filled")
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundColor(Color(red: 0.98, green: 0.84, blue: 0.36))
        }
        .frame(width: size * 0.86, height: size)
        .shadow(color: ClayColor.shadow, radius: 4, y: 3)
    }
}

struct ClayBurst: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            BurstShape(points: 10, innerRatio: 0.55).fill(ClayColor.sun)
            BurstShape(points: 10, innerRatio: 0.55).fill(ClayColor.coral).padding(size * 0.2)
            Circle().fill(Color.white.opacity(0.85)).padding(size * 0.38)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Sky Flight

struct ClayGem: View {
    var size: CGFloat
    var color: Color = ClayColor.sky

    var body: some View {
        ZStack {
            GemShape().fill(color)
            GemShape().fill(LinearGradient(colors: [Color.white.opacity(0.7), .clear], startPoint: .topLeading, endPoint: .center))
            Path { p in
                p.move(to: CGPoint(x: size * 0.2, y: size * 0.32))
                p.addLine(to: CGPoint(x: size * 0.8, y: size * 0.32))
                p.move(to: CGPoint(x: size * 0.5, y: size * 0.32))
                p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.95))
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 1.2)
        }
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.5), radius: 5)
    }
}

/// A puffy cloud column for Sky Flight; `capAtBottom` puts the round puffs on the gap side.
struct ClayCloudPillar: View {
    var width: CGFloat
    var height: CGFloat
    var capAtBottom: Bool

    var body: some View {
        ZStack(alignment: capAtBottom ? .bottom : .top) {
            RoundedRectangle(cornerRadius: width * 0.3, style: .continuous)
                .fill(Color.white.shadow(.inner(color: ClayColor.sky.opacity(0.35), radius: 1, x: 0, y: capAtBottom ? -6 : 6)))
            HStack(spacing: -width * 0.3) {
                Circle().fill(Color.white).frame(width: width * 0.62)
                Circle().fill(Color.white).frame(width: width * 0.78)
            }
            .offset(y: capAtBottom ? width * 0.25 : -width * 0.25)
        }
        .frame(width: width, height: max(0, height))
        .shadow(color: ClayColor.sky.opacity(0.35), radius: 6, y: 3)
    }
}

// MARK: - Catch the Snacks

struct ClayStormCloud: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            HStack(spacing: -size * 0.25) {
                Circle().frame(width: size * 0.45)
                Circle().frame(width: size * 0.6).offset(y: -size * 0.1)
                Circle().frame(width: size * 0.45)
            }
            .foregroundColor(Color(red: 0.42, green: 0.40, blue: 0.55))
            .overlay(
                HStack(spacing: -size * 0.25) {
                    Circle().frame(width: size * 0.45)
                    Circle().frame(width: size * 0.6).offset(y: -size * 0.1)
                    Circle().frame(width: size * 0.45)
                }
                .foregroundStyle(clayFill(Color(red: 0.42, green: 0.40, blue: 0.55), highlight: 0.35))
            )
            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.38, weight: .black))
                .foregroundColor(ClayColor.sun)
                .offset(y: size * 0.32)
        }
        .frame(width: size, height: size)
        .shadow(color: ClayColor.shadow, radius: 3, y: 2)
    }
}

/// A round clay coin showing a food's icon.
struct ClayFoodToken: View {
    let food: FoodType
    var size: CGFloat

    var body: some View {
        ZStack {
            ClayShape(shape: Circle(), color: food.primaryColor)
            Image(systemName: food.icon)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.15), radius: 0, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: ClayColor.shadow, radius: 3, y: 2)
    }
}

// MARK: - Dragon Dash

struct ClayRock: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ClayShape(shape: RockShape(), color: Color(red: 0.62, green: 0.58, blue: 0.68))
            .frame(width: width, height: height)
    }
}

struct ClayCactus: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        let green = Color(red: 0.36, green: 0.74, blue: 0.45)
        ZStack(alignment: .bottom) {
            ClayShape(shape: Capsule(), color: green)
                .frame(width: width, height: height)
            ClayShape(shape: Capsule(), color: green)
                .frame(width: width * 0.6, height: height * 0.4)
                .offset(x: -width * 0.7, y: -height * 0.35)
            ClayShape(shape: Capsule(), color: green)
                .frame(width: width * 0.6, height: height * 0.32)
                .offset(x: width * 0.7, y: -height * 0.5)
        }
        .frame(width: width, height: height)
    }
}

struct ClayBat: View {
    var width: CGFloat

    var body: some View {
        let purple = Color(red: 0.45, green: 0.36, blue: 0.62)
        ZStack {
            HStack(spacing: -width * 0.1) {
                WingShape().fill(purple).frame(width: width * 0.45, height: width * 0.36)
                Spacer().frame(width: width * 0.2)
                WingShape().fill(purple).frame(width: width * 0.45, height: width * 0.36).scaleEffect(x: -1)
            }
            ClayShape(shape: Circle(), color: purple).frame(width: width * 0.36)
            HStack(spacing: width * 0.07) {
                Circle().fill(Color.white).frame(width: width * 0.08)
                Circle().fill(Color.white).frame(width: width * 0.08)
            }
            .offset(y: -width * 0.02)
        }
        .frame(width: width, height: width * 0.5)
    }
}

/// Rolling clay hills along the bottom of a game scene.
struct ClayHills: View {
    var color: Color
    var bumps: Int = 4

    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width, h = geo.size.height
                p.move(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: 0, y: h * 0.5))
                let step = w / CGFloat(bumps)
                for i in 0..<bumps {
                    let x0 = CGFloat(i) * step
                    p.addQuadCurve(to: CGPoint(x: x0 + step, y: h * (i % 2 == 0 ? 0.55 : 0.45)),
                                   control: CGPoint(x: x0 + step / 2, y: i % 2 == 0 ? 0 : h * 0.15))
                }
                p.addLine(to: CGPoint(x: w, y: h))
                p.closeSubpath()
            }
            .fill(color)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.15), control: CGPoint(x: rect.maxX * 0.8, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY * 0.75))
            p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.15), control: CGPoint(x: rect.minX, y: rect.maxY * 0.75))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.width * 0.2, y: rect.minY))
        }
    }
}

struct BurstShape: Shape {
    var points: Int
    var innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        return Path { p in
            for i in 0..<(points * 2) {
                let r = i.isMultiple(of: 2) ? outer : inner
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }
}

struct GemShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.08))
            p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY + rect.height * 0.08))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.32))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.32))
            p.closeSubpath()
        }
    }
}

struct RockShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.width * 0.3, y: rect.minY + rect.height * 0.15), control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.3))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.55), control: CGPoint(x: rect.width * 0.8, y: rect.minY - rect.height * 0.1))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.width * 0.5, y: rect.minY - rect.height * 0.2))
            p.addQuadCurve(to: CGPoint(x: rect.width * 0.35, y: rect.maxY * 0.8), control: CGPoint(x: rect.width * 0.1, y: rect.midY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.width * 0.7, y: rect.maxY))
        }
    }
}
