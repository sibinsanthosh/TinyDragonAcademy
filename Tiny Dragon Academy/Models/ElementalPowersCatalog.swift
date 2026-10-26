//
//  ElementalPowersCatalog.swift
//  Tiny Dragon Academy
//
//  Complete library of Elemental Powers for every dragon species.
//  Each element features 5 progressive powers across Baby, Young,
//  Adolescent, Adult, and Ancient growth stages.
//

import SwiftUI

struct ElementalPowersCatalog {
    static func powers(for element: DragonElement) -> [ElementalPower] {
        switch element {
        case .fire:
            return [
                ElementalPower(
                    id: "fire_1",
                    name: "Warm Embers",
                    element: .fire,
                    stageRequired: .baby,
                    levelRequired: 1,
                    energyCost: 10,
                    cooldownSeconds: 2.0,
                    iconName: "flame",
                    animationStyle: .flameBreath,
                    description: "Puffs a stream of cozy, crackling embers and warm orange sparks."
                ),
                ElementalPower(
                    id: "fire_2",
                    name: "Flame Spark",
                    element: .fire,
                    stageRequired: .young,
                    levelRequired: 5,
                    energyCost: 20,
                    cooldownSeconds: 3.0,
                    iconName: "flame.fill",
                    animationStyle: .flameBreath,
                    description: "Spits energetic bouncy fireballs that light up the dragon playground."
                ),
                ElementalPower(
                    id: "fire_3",
                    name: "Fire Stream",
                    element: .fire,
                    stageRequired: .adolescent,
                    levelRequired: 10,
                    energyCost: 30,
                    cooldownSeconds: 4.0,
                    iconName: "bolt.horizontal.fill",
                    animationStyle: .flameBreath,
                    description: "Releases a sustained, roaring blaze of swirling golden flame."
                ),
                ElementalPower(
                    id: "fire_4",
                    name: "Flame Burst",
                    element: .fire,
                    stageRequired: .adult,
                    levelRequired: 15,
                    energyCost: 45,
                    cooldownSeconds: 5.0,
                    iconName: "sun.max.fill",
                    animationStyle: .flameBreath,
                    description: "Unleashes a majestic sphere of swirling incandescent dragon fire."
                ),
                ElementalPower(
                    id: "fire_5",
                    name: "Inferno Nova",
                    element: .fire,
                    stageRequired: .ancient,
                    levelRequired: 20,
                    energyCost: 60,
                    cooldownSeconds: 7.0,
                    iconName: "sparkles",
                    animationStyle: .flameBreath,
                    description: "Calls down ancient primordial solar flares that blanket the sky in golden warmth."
                )
            ]
            
        case .ice:
            return [
                ElementalPower(
                    id: "ice_1",
                    name: "Frost Puff",
                    element: .ice,
                    stageRequired: .baby,
                    levelRequired: 1,
                    energyCost: 10,
                    cooldownSeconds: 2.0,
                    iconName: "snowflake",
                    animationStyle: .frostBlast,
                    description: "Breathes a gentle cloud of sparkling subzero frost and tiny snowflakes."
                ),
                ElementalPower(
                    id: "ice_2",
                    name: "Ice Shards",
                    element: .ice,
                    stageRequired: .young,
                    levelRequired: 5,
                    energyCost: 20,
                    cooldownSeconds: 3.0,
                    iconName: "diamond.fill",
                    animationStyle: .frostBlast,
                    description: "Shoots crystalline icicles that glitter brightly across the air."
                ),
                ElementalPower(
                    id: "ice_3",
                    name: "Glacial Wave",
                    element: .ice,
                    stageRequired: .adolescent,
                    levelRequired: 10,
                    energyCost: 30,
                    cooldownSeconds: 4.0,
                    iconName: "wind.snow",
                    animationStyle: .frostBlast,
                    description: "Sweeps a freezing cold front that paints frost patterns on the ground."
                ),
                ElementalPower(
                    id: "ice_4",
                    name: "Blizzard Vortex",
                    element: .ice,
                    stageRequired: .adult,
                    levelRequired: 15,
                    energyCost: 45,
                    cooldownSeconds: 5.0,
                    iconName: "tornado",
                    animationStyle: .frostBlast,
                    description: "Creates an icy howling vortex of hail and diamond snow crystals."
                ),
                ElementalPower(
                    id: "ice_5",
                    name: "Absolute Zero Storm",
                    element: .ice,
                    stageRequired: .ancient,
                    levelRequired: 20,
                    energyCost: 60,
                    cooldownSeconds: 7.0,
                    iconName: "snowflake.circle.fill",
                    animationStyle: .frostBlast,
                    description: "Summons an ancient polar aurora tempest that freezes time in icy splendor."
                )
            ]
            
        case .lightning:
            return [
                ElementalPower(
                    id: "lightning_1",
                    name: "Static Spark",
                    element: .lightning,
                    stageRequired: .baby,
                    levelRequired: 1,
                    energyCost: 10,
                    cooldownSeconds: 2.0,
                    iconName: "bolt",
                    animationStyle: .lightningBolt,
                    description: "Crackles little playful electric sparks between its baby dragon horns."
                ),
                ElementalPower(
                    id: "lightning_2",
                    name: "Thunder Bolt",
                    element: .lightning,
                    stageRequired: .young,
                    levelRequired: 5,
                    energyCost: 20,
                    cooldownSeconds: 3.0,
                    iconName: "bolt.fill",
                    animationStyle: .lightningBolt,
                    description: "Shoots sharp electrical bolts that dance with energetic violet light."
                ),
                ElementalPower(
                    id: "lightning_3",
                    name: "Chain Lightning",
                    element: .lightning,
                    stageRequired: .adolescent,
                    levelRequired: 10,
                    energyCost: 30,
                    cooldownSeconds: 4.0,
                    iconName: "bolt.horizontal.circle.fill",
                    animationStyle: .lightningBolt,
                    description: "Unleashes zigzagging arcs of electric blue voltage jumping through the air."
                ),
                ElementalPower(
                    id: "lightning_4",
                    name: "Thunder Strike",
                    element: .lightning,
                    stageRequired: .adult,
                    levelRequired: 15,
                    energyCost: 45,
                    cooldownSeconds: 5.0,
                    iconName: "cloud.bolt.fill",
                    animationStyle: .lightningBolt,
                    description: "Channels a roaring vertical thunderbolt with deep rumbling reverberations."
                ),
                ElementalPower(
                    id: "lightning_5",
                    name: "Plasma Tempest",
                    element: .lightning,
                    stageRequired: .ancient,
                    levelRequired: 20,
                    energyCost: 60,
                    cooldownSeconds: 7.0,
                    iconName: "bolt.shield.fill",
                    animationStyle: .lightningBolt,
                    description: "Commands the skies in a blinding symphony of plasma globes and lightning strikes."
                )
            ]
            
        case .laser:
            return [
                ElementalPower(
                    id: "laser_1",
                    name: "Glow Dot",
                    element: .laser,
                    stageRequired: .baby,
                    levelRequired: 1,
                    energyCost: 10,
                    cooldownSeconds: 2.0,
                    iconName: "circle.circle",
                    animationStyle: .laserBeam,
                    description: "Emits a cute focused neon pointer beam from its forehead gemstone."
                ),
                ElementalPower(
                    id: "laser_2",
                    name: "Pulse Ray",
                    element: .laser,
                    stageRequired: .young,
                    levelRequired: 5,
                    energyCost: 20,
                    cooldownSeconds: 3.0,
                    iconName: "lines.measurement.horizontal",
                    animationStyle: .laserBeam,
                    description: "Fires rapid rhythmic bursts of neon cyan and magenta laser energy."
                ),
                ElementalPower(
                    id: "laser_3",
                    name: "Focus Laser",
                    element: .laser,
                    stageRequired: .adolescent,
                    levelRequired: 10,
                    energyCost: 30,
                    cooldownSeconds: 4.0,
                    iconName: "waveform.path.badge.plus",
                    animationStyle: .laserBeam,
                    description: "Projects a steady, concentrated laser beam that pierces through clouds."
                ),
                ElementalPower(
                    id: "laser_4",
                    name: "Charged Mega Cannon",
                    element: .laser,
                    stageRequired: .adult,
                    levelRequired: 15,
                    energyCost: 45,
                    cooldownSeconds: 5.0,
                    iconName: "rays",
                    animationStyle: .laserBeam,
                    description: "Powers up an immense wide-aperture energy cannon with glowing rings."
                ),
                ElementalPower(
                    id: "laser_5",
                    name: "Prismatic Orbital Ray",
                    element: .laser,
                    stageRequired: .ancient,
                    levelRequired: 20,
                    energyCost: 60,
                    cooldownSeconds: 7.0,
                    iconName: "sun.rain.fill",
                    animationStyle: .laserBeam,
                    description: "Unleashes a majestic multi-chromatic laser array that illuminates the entire sky."
                )
            ]
            
        case .earth:
            return [
                ElementalPower(
                    id: "earth_1",
                    name: "Pebble Toss",
                    element: .earth,
                    stageRequired: .baby,
                    levelRequired: 1,
                    energyCost: 10,
                    cooldownSeconds: 2.0,
                    iconName: "circle.grid.2x1.fill",
                    animationStyle: .earthShockwave,
                    description: "Playfully bounces smooth polished river pebbles with little thumps."
                ),
                ElementalPower(
                    id: "earth_2",
                    name: "Rock Sling",
                    element: .earth,
                    stageRequired: .young,
                    levelRequired: 5,
                    energyCost: 20,
                    cooldownSeconds: 3.0,
                    iconName: "shield.fill",
                    animationStyle: .earthShockwave,
                    description: "Hurls swirling mossy boulders wrapped in emerald earthen energy."
                ),
                ElementalPower(
                    id: "earth_3",
                    name: "Ground Shockwave",
                    element: .earth,
                    stageRequired: .adolescent,
                    levelRequired: 10,
                    energyCost: 30,
                    cooldownSeconds: 4.0,
                    iconName: "waveform.path",
                    animationStyle: .earthShockwave,
                    description: "Slams its dragon paws down to send rippling tremors through the soil."
                ),
                ElementalPower(
                    id: "earth_4",
                    name: "Seismic Tremor",
                    element: .earth,
                    stageRequired: .adult,
                    levelRequired: 15,
                    energyCost: 45,
                    cooldownSeconds: 5.0,
                    iconName: "mountain.2.fill",
                    animationStyle: .earthShockwave,
                    description: "Erupts glowing crystal spires and gemstone monoliths from deep underground."
                ),
                ElementalPower(
                    id: "earth_5",
                    name: "Continental Slam",
                    element: .earth,
                    stageRequired: .ancient,
                    levelRequired: 20,
                    energyCost: 60,
                    cooldownSeconds: 7.0,
                    iconName: "globe.americas.fill",
                    animationStyle: .earthShockwave,
                    description: "Awakens the pulse of the ancient earth, calling meteors and fertile golden blooms."
                )
            ]
            
        default:
            // Generic star / water / nature magic fallback
            return [
                ElementalPower(
                    id: "\(element.rawValue)_1",
                    name: "\(element.rawValue) Whisper",
                    element: element,
                    stageRequired: .baby,
                    levelRequired: 1,
                    energyCost: 10,
                    cooldownSeconds: 2.0,
                    iconName: element.iconName,
                    animationStyle: .starlightBurst,
                    description: "Releases gentle pulses of sparkling \(element.rawValue.lowercased()) magic."
                ),
                ElementalPower(
                    id: "\(element.rawValue)_2",
                    name: "\(element.rawValue) Spark",
                    element: element,
                    stageRequired: .young,
                    levelRequired: 5,
                    energyCost: 20,
                    cooldownSeconds: 3.0,
                    iconName: element.iconName,
                    animationStyle: .starlightBurst,
                    description: "Shoots vibrant orbs of elemental \(element.rawValue.lowercased()) essence."
                ),
                ElementalPower(
                    id: "\(element.rawValue)_3",
                    name: "\(element.rawValue) Wave",
                    element: element,
                    stageRequired: .adolescent,
                    levelRequired: 10,
                    energyCost: 30,
                    cooldownSeconds: 4.0,
                    iconName: element.iconName,
                    animationStyle: .starlightBurst,
                    description: "Sends a sweeping cascade of elemental energy through the meadow."
                ),
                ElementalPower(
                    id: "\(element.rawValue)_4",
                    name: "\(element.rawValue) Radiance",
                    element: element,
                    stageRequired: .adult,
                    levelRequired: 15,
                    energyCost: 45,
                    cooldownSeconds: 5.0,
                    iconName: "sparkles",
                    animationStyle: .starlightBurst,
                    description: "Fills the sky with a glorious sphere of pure elemental mastery."
                ),
                ElementalPower(
                    id: "\(element.rawValue)_5",
                    name: "\(element.rawValue) Genesis",
                    element: element,
                    stageRequired: .ancient,
                    levelRequired: 20,
                    energyCost: 60,
                    cooldownSeconds: 7.0,
                    iconName: "crown.fill",
                    animationStyle: .starlightBurst,
                    description: "Channels the legendary primordial heart of the \(element.rawValue) element."
                )
            ]
        }
    }
}
