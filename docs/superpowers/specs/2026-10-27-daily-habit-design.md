# Daily Habit (Phase 1) — Design Spec

**Date:** 2026-10-27
**Branch:** `feature/dragon-life-sim` (continues the life-simulation work)
**Status:** Approved design
**Builds on:** `docs/superpowers/specs/2026-10-26-dragon-life-sim-design.md`

## 1. Goal

Give every day a reason to come back, for kids and adults alike: a care mode that fits the
player, three daily quests, a forgiving care streak, a daily wish from each dragon, and rare
shiny hatches.

### Decisions made

| Topic | Decision |
|---|---|
| Care Mode choice | Picked in onboarding (behind the parent gate); existing saves default to Classic; changeable in Settings (already behind the parent gate) |
| Streak day | Counts when the player fed or trained at least once AND no den dragon fell ill that game day |
| Day boundary | The game day starts at 07:00 local (wake-up), shared by quests, wishes and streak |
| Shiny | 1 in 20 hatches; alternate palette + sparkle aura + ★ badge; +10% XP |
| Rules module | New pure `DailyRules` fed by `PlayerAction`s from `GameManager` |

## 2. Game day

`GameDay.id(for:calendar:)` returns `yyyy-MM-dd` of the date shifted back by `LifeRules.wakeHour`
hours, so 2026-10-28 06:59 belongs to game day `2026-10-27`. `GameDay.daysBetween(_:_:calendar:)`
counts whole game days between two ids.

## 3. Care Mode

`enum CareMode: String, Codable { case gentle, classic }`, stored as `AppProgressState.careMode`.

- **Classic:** today's rules, unchanged.
- **Gentle:** `LifeSimulator` clamps health at `LifeRules.gentleHealthFloor = 10`; a dragon never
  dies. Hunger, illness and the other meters behave as in Classic. A Gentle dragon at the health
  floor shows the status **"Deep sleep — feed me!"**. Feeding still works.
- Switching to Gentle does not touch a dragon that is already a spirit; it prevents new deaths.
- **Reminders in Gentle:** no `died` / `spiritLastChance` notifications, softer copy, at most
  **3 notifications per game day** across all dragons and eggs.

| Event | Gentle copy |
|---|---|
| Hungry | "{name} would love a snack 🍓" |
| Starving | "{name} is very hungry — time to eat!" |
| Needs training | "{name} wants to play! 🏃" |
| Ill | "{name} isn't feeling well 🤒" |
| Health critical | "{name} fell into a deep sleep 💤 — food will wake them" |

## 4. Daily quests

- Three quests per game day, chosen with an RNG seeded from a stable hash (FNV-1a) of the day id,
  from kinds that make sense now:
  - `feed(n)`, `feedFavorite` (only if a den dragon's favorite is discovered), `train(n)`,
    `score(game, x)` (Classic only), `warmEgg(n)` (only if an egg is incubating), `pet(n)`,
    `grantWish`, `learningGame`.
- Gentle uses smaller counts (feed 2 / train 1 / pet 3 / warm 3) than Classic (feed 3 / train 2 /
  pet 5 / warm 5). Score targets: Dash 500, Fire Target 10, Sky Flight 8, Catch the Snacks 10.
- Each quest pays **5★** when completed (automatically). Completing all three pays **10★ and one
  Healing Herb**, once per day.

## 5. Care streak & Streak Shield

`StreakState { current, best, shields, recent: [StreakDay] }` (`recent` keeps the last 14 days with
result `counted | shielded | missed`).

- At day rollover the previous day is judged: counted if `caredToday && !illnessToday`.
- Every game day between the previous day and today that was never opened is a missed day.
- A missed day uses a shield if one is held (streak unchanged, recorded `shielded`), else the
  streak resets to 0 (recorded `missed`).
- Illness is credited to the game day it happened, including during offline catch-up.
- Shields: only from the 7-day milestone; at most 2 held; never sold.
- Milestones when `current` reaches: 3 → 15★; 7 → Streak Shield + 25★; 14 → Uncommon egg;
  30 and every further 30 → Rare egg.

## 6. Dragon wishes

- One wish per den dragon per game day, seeded from the day id + dragon id:
  `eat(food)` (favorite food half the time), `play(game)`, or `pet(3)`.
- Granting: **+15 happiness, +10 XP, +2★**, and counts toward a `grantWish` quest.
- Dragons that join the den mid-day get a wish when first seen.
- Shown as a speech bubble in the Playground and listed on the Today screen.

## 7. Shiny hatches

- `EggHatcher.rollShiny(rng:)` is true with probability **0.05**.
- A shiny dragon gets `ShinyPalette` colors for its element, `isShiny = true`, a sparkle aura in
  `DragonView`, and a ★ next to its name (`DragonModel.badgedName`).
- Shiny dragons earn **+10% XP** (rounded) from feeding and training.
- `Memorial.isShiny` preserves it in the Hall of Legends; expiry resets the species' colors and
  shiny flag for its next hatch. Existing dragons are not shiny.

## 8. Screens

- **Today** (new route `.today`, main-menu tile): streak flame + shields, the three quests with
  progress, last 7 days as dots, each den dragon's wish.
- Main-menu header gets a streak pill (🔥 N).
- Toast banner for quest completions, wishes granted and streak milestones.
- Onboarding: a "Who's raising this dragon?" step choosing Gentle/Classic.
- Settings: Care Mode picker.
- Hatch reveal shows "✨ SHINY! ✨" for shiny hatches.

## 9. Data & migration

New fields decode with `decodeIfPresent`: `careMode` (classic), `daily` (fresh day on first
refresh), `streak` (zeros), `DragonModel.isShiny` (false), `Memorial.isShiny` (false).

## 10. Testing

TDD on pure rules (Gentle floor, game day ids, quest generation/progress, every streak case
including multi-day gaps and shields, wishes, shiny roll), GameManager integration tests, then a
simulator check.

## 11. Out of scope

Analytics counters (moved to phase 2), widget, Live Activity, share cards.
