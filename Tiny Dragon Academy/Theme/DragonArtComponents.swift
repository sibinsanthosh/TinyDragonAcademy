//
//  DragonArtComponents.swift
//  Tiny Dragon Academy
//
//  Original custom SwiftUI vector shapes and illustrations for dragon anatomy,
//  magical eggs, island scenery, and accessories.
//

import SwiftUI

// MARK: - Custom Vector Shapes

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct DragonWingShape: Shape {
    var isFairy: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h * 0.75))
        
        if isFairy {
            // Upper fairy petal
            path.addCurve(
                to: CGPoint(x: w, y: h * 0.15),
                control1: CGPoint(x: w * 0.1, y: 0),
                control2: CGPoint(x: w * 0.7, y: 0)
            )
            path.addCurve(
                to: CGPoint(x: w * 0.35, y: h * 0.55),
                control1: CGPoint(x: w * 0.95, y: h * 0.4),
                control2: CGPoint(x: w * 0.6, y: h * 0.5)
            )
            // Lower fairy petal
            path.addCurve(
                to: CGPoint(x: w * 0.85, y: h * 0.9),
                control1: CGPoint(x: w * 0.5, y: h * 0.65),
                control2: CGPoint(x: w * 0.8, y: h * 0.75)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: h * 0.85),
                control1: CGPoint(x: w * 0.5, y: h),
                control2: CGPoint(x: w * 0.15, y: h * 0.95)
            )
        } else {
            // Classic scalloped dragon wing
            path.addCurve(
                to: CGPoint(x: w, y: h * 0.1),
                control1: CGPoint(x: w * 0.15, y: 0),
                control2: CGPoint(x: w * 0.65, y: 0)
            )
            // Scallop 1
            path.addCurve(
                to: CGPoint(x: w * 0.65, y: h * 0.55),
                control1: CGPoint(x: w * 0.9, y: h * 0.35),
                control2: CGPoint(x: w * 0.78, y: h * 0.45)
            )
            // Scallop 2
            path.addCurve(
                to: CGPoint(x: w * 0.3, y: h * 0.85),
                control1: CGPoint(x: w * 0.55, y: h * 0.75),
                control2: CGPoint(x: w * 0.42, y: h * 0.8)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: h * 0.75),
                control1: CGPoint(x: w * 0.15, y: h * 0.9),
                control2: CGPoint(x: 0, y: h * 0.85)
            )
        }
        
        path.closeSubpath()
        return path
    }
}

struct DragonHornShape: Shape {
    var isCurved: Bool = true
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h))
        if isCurved {
            path.addCurve(
                to: CGPoint(x: w * 0.7, y: 0),
                control1: CGPoint(x: w * 0.1, y: h * 0.4),
                control2: CGPoint(x: w * 0.35, y: h * 0.1)
            )
            path.addCurve(
                to: CGPoint(x: w, y: h),
                control1: CGPoint(x: w * 0.95, y: h * 0.3),
                control2: CGPoint(x: w * 0.85, y: h * 0.7)
            )
        } else {
            // Straight/nubby horn
            path.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: 0, y: h * 0.2))
            path.addQuadCurve(to: CGPoint(x: w, y: h), control: CGPoint(x: w, y: h * 0.2))
        }
        path.closeSubpath()
        return path
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.85))
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.35),
            control1: CGPoint(x: w * 0.15, y: h * 0.65),
            control2: CGPoint(x: 0, y: h * 0.5)
        )
        path.addArc(
            center: CGPoint(x: w * 0.25, y: h * 0.25),
            radius: w * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: w * 0.75, y: h * 0.25),
            radius: w * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.85),
            control1: CGPoint(x: w, y: h * 0.5),
            control2: CGPoint(x: w * 0.85, y: h * 0.65)
        )
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    var points: Int = 5
    var smoothness: CGFloat = 0.45
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        
        let angleStep = (CGFloat.pi * 2) / CGFloat(points * 2)
        var currentAngle = -CGFloat.pi / 2
        
        path.move(to: CGPoint(
            x: center.x + outerRadius * cos(currentAngle),
            y: center.y + outerRadius * sin(currentAngle)
        ))
        
        for i in 1..<(points * 2) {
            currentAngle += angleStep
            let radius = (i % 2 == 1) ? innerRadius : outerRadius
            path.addLine(to: CGPoint(
                x: center.x + radius * cos(currentAngle),
                y: center.y + radius * sin(currentAngle)
            ))
        }
        
        path.closeSubpath()
        return path
    }
}

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.65),
            control1: CGPoint(x: w * 0.9, y: 0),
            control2: CGPoint(x: w, y: h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w, y: h * 0.92),
            control2: CGPoint(x: w * 0.8, y: h)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.65),
            control1: CGPoint(x: w * 0.2, y: h),
            control2: CGPoint(x: 0, y: h * 0.92)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: 0, y: h * 0.35),
            control2: CGPoint(x: w * 0.1, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Dragon Scenery & Decorative Illustrations

struct MushroomHouseView: View {
    var size: CGFloat = 80
    
    var body: some View {
        VStack(spacing: -size * 0.15) {
            // Cap
            ZStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.50, blue: 0.55))
                    .frame(width: size, height: size * 0.6)
                
                // Polka dots
                HStack(spacing: size * 0.18) {
                    Circle().fill(Color.white.opacity(0.85)).frame(width: size * 0.15, height: size * 0.15)
                    Circle().fill(Color.white.opacity(0.85)).frame(width: size * 0.22, height: size * 0.22)
                    Circle().fill(Color.white.opacity(0.85)).frame(width: size * 0.15, height: size * 0.15)
                }
                .offset(y: -size * 0.05)
            }
            .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 3)
            
            // Stem & Door
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(Color(red: 0.99, green: 0.96, blue: 0.88))
                    .frame(width: size * 0.55, height: size * 0.55)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .stroke(Color(red: 0.90, green: 0.85, blue: 0.75), lineWidth: 1.5)
                    )
                
                // Tiny door
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(Color(red: 0.75, green: 0.55, blue: 0.40))
                    .frame(width: size * 0.2, height: size * 0.28)
                    .offset(y: size * 0.12)
                
                // Tiny circular window
                Circle()
                    .fill(DragonPalette.buttercup)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .offset(y: -size * 0.1)
            }
        }
    }
}

struct BlossomTreeView: View {
    var size: CGFloat = 80
    
    var body: some View {
        VStack(spacing: -size * 0.1) {
            // Foliage puffs
            ZStack {
                Circle()
                    .fill(DragonPalette.rosyPink.opacity(0.9))
                    .frame(width: size * 0.75, height: size * 0.75)
                
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.90))
                    .frame(width: size * 0.6, height: size * 0.6)
                    .offset(x: -size * 0.18, y: -size * 0.05)
                
                Circle()
                    .fill(DragonPalette.rosyPink)
                    .frame(width: size * 0.55, height: size * 0.55)
                    .offset(x: size * 0.2, y: -size * 0.08)
                
                // Blossom sparkles
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.18))
                    .foregroundStyle(DragonPalette.buttercup)
                    .offset(x: -size * 0.1, y: size * 0.1)
            }
            .shadow(color: DragonPalette.softShadow, radius: 5, x: 0, y: 3)
            
            // Trunk
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.65, green: 0.45, blue: 0.32))
                .frame(width: size * 0.22, height: size * 0.45)
        }
    }
}

struct CozyPondView: View {
    var size: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Water ellipse
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [DragonPalette.skyBlue, Color(red: 0.45, green: 0.75, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.6)
                .overlay(
                    Ellipse().stroke(Color.white.opacity(0.8), lineWidth: 2.5)
                )
                .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
            
            // Lilypad
            Circle()
                .fill(DragonPalette.mintGreen)
                .frame(width: size * 0.28, height: size * 0.28)
                .offset(x: -size * 0.2, y: size * 0.05)
                .overlay(
                    Circle()
                        .fill(DragonPalette.rosyPink)
                        .frame(width: size * 0.12, height: size * 0.12)
                        .offset(x: -size * 0.2, y: size * 0.05)
                )
            
            // Gentle ripples
            Ellipse()
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                .frame(width: size * 0.5, height: size * 0.25)
                .offset(x: size * 0.15, y: -size * 0.05)
        }
    }
}
