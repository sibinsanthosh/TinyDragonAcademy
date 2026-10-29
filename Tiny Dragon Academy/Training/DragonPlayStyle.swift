//
//  DragonPlayStyle.swift
//  Tiny Dragon Academy
//
//  The active dragon's skill stars and talent, handed to a training game
//  when a run starts. `.neutral` (all 1★, no talent) is the plain game.
//

import Foundation

struct DragonPlayStyle: Equatable {
    var stars: [DragonSkill: Int]
    var talent: DragonTalent?

    static let neutral = DragonPlayStyle()

    init(stars: [DragonSkill: Int] = [:], talent: DragonTalent? = nil) {
        self.stars = stars
        self.talent = talent
    }

    init(dragon: DragonModel) {
        self.init(
            stars: Dictionary(uniqueKeysWithValues: DragonSkill.allCases.map { ($0, dragon.skillStars($0)) }),
            talent: dragon.talent
        )
    }

    func stars(_ skill: DragonSkill) -> Int {
        min(SkillRules.maxStars, max(1, stars[skill] ?? 1))
    }

    /// Stars above 1★ (0…4); each game scales its helper by this.
    func boost(_ skill: DragonSkill) -> Double {
        Double(stars(skill) - 1)
    }

    func has(_ talent: DragonTalent) -> Bool {
        self.talent == talent
    }
}
