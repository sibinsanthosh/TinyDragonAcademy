# Dragon Skills & Talents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every dragon four growing skills and one signature talent that change how the training games play.

**Architecture:** Pure model (`DragonSkills.swift`) holds species tables and growth rules; a `DragonPlayStyle` value is passed into each game state's initializer, which derives its tuning from it and keeps today's behavior under `.neutral`. `GameManager.finishTraining` awards skill points from the talent-free `baseScore`.

**Tech Stack:** Swift 5 / SwiftUI, XCTest, iOS 17.6+.

**Spec:** `docs/superpowers/specs/2026-10-29-dragon-skills-design.md`

## Global Constraints

- iOS 17.6 deployment target; Swift 5 mode with default MainActor isolation (tests are `@MainActor`).
- `.neutral` play style must leave every existing game test passing unchanged.
- Old saves must decode: `skillPoints` via `decodeIfPresent` → `[:]`.
- Test command: `xcodebuild test -scheme "Tiny Dragon Academy" -destination 'id=<sim>' -collect-test-diagnostics never`.

## Review Focus

1. Pierce (Laser Shot) must not hit the same target twice with one ball, and must not loop forever on a target it sits inside.
2. Chain Bolt / Splash Blast destroying several targets in one frame must not crash on index removal.
3. Rock Hide / Bubble Shield / Wave Guard trigger once per run only.
4. Quests and rewards must read `baseScore`; bests read `score`.
5. A 5★ skill must not make a game unloseable (e.g. Agility gap never exceeds the play area).

---

### Task 1: Skills model and growth

**Files:** Create `Tiny Dragon Academy/Models/DragonSkills.swift`; modify `Models/DragonGrowthModel.swift` (`skillPoints`); test `Tiny Dragon AcademyTests/DragonSkillsTests.swift`.

**Produces:**
- `enum DragonSkill: String, Codable, CaseIterable { stamina, aim, agility, reflexes }` with `game: TrainingGameType`, `title`, `iconName`, `static func forGame(_:) -> DragonSkill`.
- `enum DragonTalent: String, CaseIterable` (15) with `title`, `summary`, `game`.
- `enum SpeciesTraits { static func baseStars(_ id: String) -> [DragonSkill: Int]; static func talent(_ id: String) -> DragonTalent? }`.
- `enum SkillRules { static let thresholds = [10, 30, 65, 115]; static let maxStars = 5; static func points(forNormalizedScore:) -> Int; static func stars(base:points:) -> Int; static func progress(base:points:) -> (stars: Int, into: Int, needed: Int?) }`.
- `extension DragonModel { func skillStars(_:) -> Int; var talent: DragonTalent? }`.
- `DragonStats.skillPoints: [String: Int]`.

Tests: totals per tier (8/9/10/11, Sparkle 8); talent skill is max; thresholds (0→base, 9→base, 10→base+1, 115→base+4 capped 5); points 0→1, 0.5→2, 1→3; legacy stats JSON decodes `skillPoints == [:]`; round trip.

### Task 2: Play style + Fire Target

**Files:** Create `Training/DragonPlayStyle.swift`; modify `Training/Games/FireTargetGameState.swift`; tests in `FireTargetGameStateTests.swift`.

**Produces:** `struct DragonPlayStyle { var stars: [DragonSkill: Int]; var talent: DragonTalent?; static let neutral; init(dragon:); func stars(_:) -> Int; func boost(_:) -> Double /* stars−1 */; func has(_:) -> Bool }`. Fire Target: `init(seed:style:)`, instance `hitRadius`, `talentTriggers`, `baseScore`, `FireTarget.id: UUID`, `Fireball.hitIds`, static `trajectory(origin:aim:steps:straight:)`.

Tests: Aim 5★ hit radius = 1.4× base; Splash hits a near target, not a far one; Chain hits nearest other; Frozen halves balloon rise; Laser path is straight and pierces two targets in line, hitting each once; neutral unchanged.

### Task 3: Dragon Dash

`init(seed:style:)`, instance `jumpVelocity`, `maxHoldTime`, `heldGravity`; `score` (shown) and `baseScore`; `talentTriggers`.
Tests: 5★ jump apex ≈ 1.16× 1★; Rock Hide survives first collision only; Leaf Glide floats longer; Sunrise score = 1.25× baseScore.

### Task 4: Sky Flight

`init(seed:style:)`, instance `gravity`, `scrollSpeed`, `gemRadius`, gap multiplier; Bubble Shield; `talentTriggers`.
Tests: 5★ gap = 1.24× (clamped < 0.9); Tailwind falls slower; Bubble Shield bounces once; Moon Float scrolls slower; Star Magnet picks a gem from 2× distance.

### Task 5: Catch the Snacks

`init(seed:style:)`, instance `catchHalfWidth`, `stormChance`; `baseScore`; Wave Guard; Blossom speeds.
Tests: 5★ catch width 1.4×; Wave Guard once; Sweet Tooth score = 2× baseScore; Blossom snack speed 0.8×, storms unchanged; Rainbow storm rate ≈ half over many spawns.

### Task 6: Rewards plumbing

`TrainingSessionSummary.baseScore`; `finishTraining(_:score:baseScore:…)`; `TrainingResult.skillGain: SkillGain?` (`skill`, `points`, `starsBefore`, `starsAfter`).
Tests: counted session adds points to the right skill on the active dragon; uncounted adds none; quest/reward use baseScore; best uses score; revive keeps points; placeHatched resets.

### Task 7: Screens

Start card skill line + talent line; result card gain rows; hub star counts and ✨; My Dragons strip + `DragonSkillsSheet`; in-game talent badge and pop (shared `TalentPopOverlay` in the shell or each view). Verified in the simulator.
