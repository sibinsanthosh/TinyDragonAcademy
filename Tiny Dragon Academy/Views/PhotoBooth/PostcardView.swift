//
//  PostcardView.swift
//  Tiny Dragon Academy
//
//  The 360×450 postcard the photo booth exports at 3× (1080×1350).
//

import SwiftUI

struct PostcardView: View {
    static let size = CGSize(width: 360, height: 450)

    let dragon: DragonModel
    let frame: PostcardFrame
    let pose: PostcardPose
    /// The player's island colours instead of the frame's own scene.
    var islandBackground: LinearGradient? = nil

    private var content: PostcardContent { PostcardContent(dragon: dragon) }

    var body: some View {
        ZStack {
            background
            decorations

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack {
                    ClayPlatform(top: Color.white.opacity(0.85), side: frame.accent.opacity(0.55), width: 230)
                        .offset(y: 92)
                    DragonView(dragon: dragon, mood: pose.mood, size: 210, allowInteractivePetting: false)
                }
                .frame(height: 250)
                label
            }
            .padding(18)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(Color.white, lineWidth: 8))
    }

    @ViewBuilder
    private var background: some View {
        if let islandBackground {
            islandBackground
        } else {
            LinearGradient(colors: frame.colors, startPoint: .top, endPoint: .bottom)
        }
    }

    private var decorations: some View {
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.12, 0.08, 18), (0.86, 0.12, 24), (0.08, 0.42, 14),
                                                    (0.92, 0.38, 16), (0.2, 0.62, 12), (0.84, 0.6, 20)]
        return GeometryReader { geo in
            ForEach(0..<spots.count, id: \.self) { i in
                Image(systemName: frame.decoration)
                    .font(.system(size: spots[i].2, weight: .bold))
                    .foregroundColor(frame.isDark ? ClayColor.sun : Color.white.opacity(0.9))
                    .position(x: geo.size.width * spots[i].0, y: geo.size.height * spots[i].1)
            }
        }
    }

    private var label: some View {
        VStack(spacing: 6) {
            Text(content.title)
                .font(.clay(30, .heavy))
                .foregroundColor(ClayColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(content.subtitle)
                .font(.clay(15, .bold))
                .foregroundColor(ClayColor.inkSoft)
            HStack(spacing: 8) {
                if let talent = content.talentTitle {
                    Label(talent, systemImage: "sparkles")
                        .font(.clay(13, .heavy))
                        .foregroundColor(ClayColor.ink)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(frame.accent.opacity(0.18)))
                }
                HStack(spacing: 4) {
                    Image(systemName: content.bestSkill.iconName)
                    Text("\(content.bestSkill.title) \(SkillStars.text(content.bestSkillStars))")
                }
                .font(.clay(13, .heavy))
                .foregroundColor(ClayColor.ink)
            }
            Text("Tiny Dragon Academy")
                .font(.clay(11, .bold))
                .foregroundColor(ClayColor.inkSoft.opacity(0.8))
                .padding(.top, 2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .claySurface(cornerRadius: 26)
    }
}
