# Dragon Skills & Signature Talents — Design

**Date:** 2026-10-29
**Branch:** `feature/dragon-life-sim`
**Status:** Approved in chat (skills part 1, talents part 2)

## Why

All 15 dragons play identically. They differ only in looks, element animation in the
playground, favorite food and a personality line. Training cards say "Trains Aim" but no
skill exists. Egg rarity changes nothing about play. Players (kids and adults) should feel a
difference the moment they switch dragons, and training should visibly grow something.

## Goals

1. Every dragon has four real skills with its own strengths and a weakness.
2. Skills grow from training and make the matching game a little easier.
3. Every species has one signature talent that visibly changes its best game.
4. Rarer dragons start stronger.
5. Rewards and quests stay balanced: talents that inflate scores don't speed up rewards.

Non-goals: care-need differences per species, talents that work in every game, talent
upgrades by growth stage, power changes in the playground.

## 1. Skills

| Skill | Game | Effect per star above 1★ (`s = stars − 1`, 0…4) |
|---|---|---|
| Stamina | Dragon Dash | jump velocity × √(1 + 0.04·s) → jump height +4% per star |
| Aim | Fire Target | target hit radius × (1 + 0.10·s) |
| Agility | Sky Flight | every gap height × (1 + 0.06·s) |
| Reflexes | Catch the Snacks | catch half-width × (1 + 0.10·s) |

At 1★ every game behaves exactly as it does today.

### Starting stars

Each species' talent skill is its highest (ties allowed). Totals by egg tier: common 8,
uncommon 9, rare 10, legendary 11. Sparkle (starter, no egg tier) counts as common.

| Dragon | Tier | Stamina | Aim | Agility | Reflexes |
|---|---|---|---|---|---|
| Sparkle | starter | 2 | 2 | 3 | 1 |
| Ember | common | 2 | 3 | 1 | 2 |
| Splash | common | 1 | 2 | 3 | 2 |
| Sprout | common | 3 | 1 | 2 | 2 |
| Terra | common | 3 | 2 | 1 | 2 |
| Frosty | uncommon | 1 | 3 | 2 | 3 |
| Volt | uncommon | 2 | 3 | 1 | 3 |
| Zephyr | uncommon | 1 | 2 | 3 | 3 |
| Flora | uncommon | 3 | 1 | 2 | 3 |
| Nova | rare | 2 | 4 | 3 | 1 |
| Sunny | rare | 4 | 1 | 3 | 2 |
| Bubble | rare | 3 | 1 | 2 | 4 |
| Berry | rare | 2 | 1 | 3 | 4 |
| Twinkle | legendary | 3 | 1 | 4 | 3 |
| Rainbow | legendary | 3 | 3 | 1 | 4 |

### Growth

- A **counted** training session earns skill points in that game's skill:
  `1 + round(2 × normalizedScore)` → 1…3 points. Uncounted sessions earn nothing.
- Points are cumulative per skill. Stars earned above the species base use cumulative
  thresholds **10, 30, 65, 115** (that is 10, 20, 35, 50 points per star).
- `stars = min(5, base + earnedStars)`. Points keep counting at 5★ but do nothing more.
- Shown on the progress bar: points toward the next star.

### Persistence & lifecycle

- `DragonStats.skillPoints: [String: Int]` keyed by skill raw value, decoded with
  `decodeIfPresent` → `[:]`. Old saves get the species base stars automatically.
- Revive keeps skills (stats object is kept). Hatching and a spirit expiring create fresh
  `DragonStats`, so a new life starts from the species base.

## 2. Signature talents

Each talent works only in its own game and is active from hatching.

| Dragon | Talent | Game | Rule |
|---|---|---|---|
| Ember | Splash Blast | Fire Target | on a hit, every other target within 0.15 of the impact also takes a hit |
| Volt | Chain Bolt | Fire Target | on a hit, the nearest other target (any distance) also takes a hit |
| Frosty | Frozen Field | Fire Target | all target movement (balloon rise, shield patrol) at 0.5× speed |
| Nova | Laser Shot | Fire Target | fireballs ignore gravity (straight line to the aim point, same flight time) and pierce: a ball hits each target at most once and keeps flying |
| Terra | Rock Hide | Dragon Dash | the first collision of a run removes that obstacle instead of ending the run |
| Sprout | Leaf Glide | Dragon Dash | held-jump float lasts 0.55 s (from 0.3) with held gravity 1.0 (from 1.3) |
| Sunny | Sunrise Sprint | Dragon Dash | shown score = distance × 125 (from × 100) |
| Zephyr | Tailwind | Sky Flight | gravity × 0.8 |
| Splash | Bubble Shield | Sky Flight | the first pillar hit bounces the dragon (velocity = flap velocity) and that pillar can no longer hit; floor/ceiling still end the run |
| Twinkle | Moon Float | Sky Flight | scroll speed × 0.85 |
| Sparkle | Star Magnet | Sky Flight | gem pickup radius × 2 |
| Bubble | Wave Guard | Catch the Snacks | the first storm caught costs no life |
| Berry | Sweet Tooth | Catch the Snacks | each snack is worth 2 shown points |
| Flora | Blossom Drift | Catch the Snacks | snacks (not storms) fall at 0.8× speed |
| Rainbow | Rainbow Luck | Catch the Snacks | storm chance × 0.5 |

Chain/splash hits follow normal hit rules: a destroyed target scores the current combo;
each extra hit raises the combo by one like a normal hit.

### Feedback

- Event talents (Splash Blast, Chain Bolt, Laser pierce, Rock Hide, Bubble Shield, Wave
  Guard) increment a `talentTriggers` counter on the game state; the view shows a short
  "✨ Rock Hide!" pop each time it changes.
- During a run with an active talent, the HUD shows a small "✨ <Talent>" badge.

## 3. Fair scoring

Games report two scores:
- `score` — what the player sees (includes Sweet Tooth / Sunrise Sprint).
- `baseScore` — the score without talent bonuses.

`finishTraining` uses `baseScore` for: whether the session counts, normalized reward,
skill points and the daily score quest. `score` is used for the shown result and
`trainingBests`. Skill effects and non-score talents are deliberately allowed to raise
`baseScore`; that is the reward for training and collecting dragons.

## 4. Screens

- **Training start card:** "<Name>'s Aim ★★★☆☆" replaces "Trains Aim". If the dragon's
  talent is for this game: "✨ Talent: Splash Blast — <short rule>". Otherwise:
  "<Name>'s talent shines in <Game>".
- **Results card:** "+3 Aim points"; when a star is gained: "Aim grew to ★★★★!".
- **Training hub:** each game card shows the active dragon's star count for its skill;
  the talent game is marked with ✨.
- **My Dragons:** each row shows a compact four-skill strip and the talent name; an info
  button opens a sheet with stars, progress bars and the talent description.

## 5. Architecture

- `Models/DragonSkills.swift` (pure): `DragonSkill` (4 cases, `game`, `title`, `icon`),
  `DragonTalent` (15 cases, `title`, `summary`, `game`), `SpeciesTraits` table
  (`baseStars`, `talent` per species id), `SkillProgress` (stars, points to next) and
  `SkillRules.points(forNormalizedScore:)`.
- `Training/DragonPlayStyle.swift` (pure): `DragonPlayStyle { stars: [DragonSkill: Int];
  talent: DragonTalent? }` with `.neutral` and `stars(for:)`; built from a dragon.
- Each game state gets `init(seed:, style: DragonPlayStyle = .neutral)` and keeps its
  current behavior under `.neutral`. Derived values live on the instance
  (e.g. `targetRadius`), so existing static constants stay as the 1★ baseline.
- `GameManager.finishTraining` gains `baseScore` and returns `skillGain` in
  `TrainingResult`.

## 6. Testing

- Pure tests: base table totals per tier and talent skill is highest; star thresholds;
  points formula; decoding old saves.
- One test per skill effect at 1★ vs 5★, and one per talent rule (15).
- Neutral style leaves every existing game test unchanged.
- GameManager: counted session grows the right skill; uncounted doesn't; `baseScore`
  drives quest/reward while `score` drives best; revive keeps and re-hatch resets skills.
- Simulator: start cards, a talent pop, My Dragons sheet.
