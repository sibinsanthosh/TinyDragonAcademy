# Dragon Life Simulation — Design Spec

**Date:** 2026-10-26
**Branch:** `feature/dragon-life-sim`
**Status:** Approved design, pending implementation plan

## 1. Goal

Upgrade Tiny Dragon Academy from a gentle, no-punishment kids' app into a never-ending
Tamagotchi-style dragon pet game with real stakes:

- Dragons' needs decay in real time; the player must feed, rest, play with and train them.
- Neglect causes illness; prolonged neglect causes death. Dead dragons can be revived for a
  limited time.
- Arcade training games (runner, aiming, flying, catching) keep dragons fit.
- Mystery eggs are earned, incubated, warmed and hatched to grow a collection.
- Local notifications remind the player when a dragon or egg needs attention.

Existing features (four learning mini-games, dress-up, island builder, achievements, elemental
powers, growth stages, daily bonus, parent gate) are kept.

### Decisions made

| Topic | Decision |
|---|---|
| Stakes | Real death, revivable within a 48h window |
| Pace | Daily rhythm: hungry ~6h, sick ~1 day, dead ~3 days of neglect; sleeps 22:00–07:00 |
| Roster | Den of 3 active dragons (expandable to 5); unlimited frozen sanctuary |
| Eggs | Earned via milestones/training or bought; incubate with real time + warmth |
| Training games | Dragon Dash, Fire Target, Sky Flight, Catch the Snacks |
| Simulation | One pure `LifeSimulator` engine, minute-stepped, used live and for offline catch-up |
| Game rendering | SwiftUI + shared `TimelineView` fixed-step loop; pure testable game-state structs |

## 2. Life & Health Rules

### 2.1 Stats (0–100, per den dragon)

| Stat | Field | Awake rate | Restored by |
|---|---|---|---|
| Fullness | existing `hunger` | −12/h (hungry when < 30, ≈6h from full) | Feeding |
| Energy | existing `energy` | −4/h awake; **+12/h asleep** | Sleep, some foods |
| Happiness | existing `happiness` | −5/h | Petting, play, favorite food |
| Fitness | new `fitness` | −4/h | Counted training session: +25…+40 by score |
| Health | new `health` | +2/h when fullness ≥ 50 and not ill | Care, medicine |

All stats clamp to 0…100.

### 2.2 Sleep

- Quiet hours are 22:00–07:00 local time. During sleep, all stats are frozen except energy
  (+12/h). Health drain and illness timers are also frozen.
- "Lights out" puts the dragon to bed early; it wakes automatically at 07:00 or when the
  player taps "Wake up". While asleep the dragon cannot train or eat.
- Spirit timers and egg incubation are **not** paused by sleep.

### 2.3 Illnesses

At most one illness at a time. While ill: XP gains are halved, evolution is blocked, and
health drains (see 2.4).

| Illness | Trigger | Cure |
|---|---|---|
| Hunger Fever | Fullness at 0 continuously for 2 awake hours | Healing Herb (fullness must then be > 0; feeding still needed) |
| Sluggish Scales | Fitness < 20 continuously for 6 awake hours | Complete 2 counted training sessions, or a Healing Herb |
| Tummy Ache | Feeding while fullness > 95 | Wears off after 1h (any time, awake or asleep); happiness −10 on trigger |

Tummy Ache is a lightweight status (`tummyAcheUntil`) and does not block the other two.
It does not drain health.

### 2.4 Health drain (per awake hour, cumulative)

- Fullness == 0: −2/h
- Ill (Hunger Fever or Sluggish Scales): −1/h
- Fitness < 20: −0.5/h

Health regenerates +2/h only when fullness ≥ 50 and not ill. A fully-fed dragon ignored
completely becomes sick in ≈1 day and dies in ≈3 days including frozen nights.

### 2.5 Death & revive

- When health reaches 0, condition becomes `spirit(diedAt:)`. The spirit window is 48 real
  hours and is not paused by sleep.
- **Revive** consumes one Phoenix Ember (shop 60★, or a 3% drop on a training personal best).
  Result: health 50, fullness 50, illness cleared, level kept, growth stage drops by one
  (baby stays baby). Powers above the new stage remain unlocked but cannot be cast until
  the stage is regained.
- If the window expires: the dragon's residence becomes `legend`; a `Memorial` entry
  (name, species, stage, level, lived-from/died-at) is added to the Hall of Legends; an egg
  of that **same species** is added to the Egg Basket. The species can be hatched again.

### 2.6 Offline catch-up

- The old 24h clamp and 25% hunger floor are removed.
- Catch-up runs the full simulation from `lastSimulatedAt` to now, capped at 7 days.
- Sanctuary dragons are never simulated.
- Clock moved backwards (now < lastSimulatedAt): no simulation; `lastSimulatedAt` is set
  to now.

### 2.7 LifeSimulator

A pure module with no UI or singleton dependencies:

- `advance(_ dragon: DragonStats, from: Date, to: Date, calendar: Calendar) -> (DragonStats, [LifeEvent])`
  steps in 1-minute increments (larger steps permitted internally when nothing can change),
  applying sleep, decay, illness triggers, health drain, death, and tummy-ache expiry.
- `advance(_ egg: IncubatorSlot, from:to:)` for incubation (see 3.3).
- `predictThresholds(...)` returns the future time each notifiable threshold would be reached
  assuming no player action, within a horizon (used by 5.1).
- `LifeEvent`: `becameHungry`, `starving`, `needsTraining`, `becameIll(Illness)`,
  `healthCritical`, `died`, `spiritExpired`, `cured`, `fellAsleep`, `wokeUp`, `eggReady`.
- Time scale for debug (`-timeScale N`) is applied by the caller, not inside the simulator.

## 3. Eggs & Den

### 3.1 Egg tiers

Sparkle remains the onboarding starter.

| Tier | Species (ids) | Hatch time | Shop price |
|---|---|---|---|
| Common | ember, splash, sprout, terra | 2h | 25★ |
| Uncommon | frosty, volt, zephyr, flora | 4h | 50★ |
| Rare | nova, sunny, bubble, berry | 8h | 100★ |
| Legendary | twinkle, rainbow | 12h | not sold |

### 3.2 Mystery eggs

- An egg has a tier and optionally a fixed species (only for eggs returned from an expired
  spirit).
- On hatch, a tier egg rolls uniformly among that tier's species whose residence is
  `undiscovered` or `legend`. If none are available, the player receives stars equal to half
  that tier's shop price (Legendary: 100★) instead of a dragon.
- Randomness uses an injectable RNG for tests.

### 3.3 Earning eggs and incubation

Sources:
- Active dragon reaches a growth stage for the first time: Young → Common, Adolescent →
  Uncommon, Adult → Rare, Ancient → Legendary. (Re-reaching a stage after revive does not
  grant again; tracked per dragon.)
- Every 10 counted training sessions (global counter) → Common egg.
- Shop purchase (Common/Uncommon/Rare).
- Spirit window expiry → same-species egg.

Unplaced eggs live in the **Egg Basket** (unbounded).

Incubator:
- 1 slot initially; 2nd slot purchasable for 150★.
- Each placed egg has `warmth` 0–100 (starts 100), decaying −10/h. Each warm tap: +10.
- Progress speed: 100% when warmth ≥ 50, 50% when below. Eggs never die.
- At 100% progress the egg is **Ready**; the player taps to crack (reusing `EggView`),
  sees the hatched dragon, and names it.

### 3.4 Den & sanctuary

- Den capacity 3; slot 4 costs 200★, slot 5 costs 400★.
- Den dragons are simulated. Sanctuary dragons are frozen and cannot be fed, trained, or
  harmed.
- A dragon may move den → sanctuary only when `condition == healthy` (no illness, not a
  spirit). Moving sanctuary → den requires a free slot and resets `lastSimulatedAt` to now.
- A spirit keeps its den slot until revived or expired.
- A newly hatched dragon goes to the den if a slot is free, otherwise to the sanctuary.
- The active dragon (`selectedDragonId`) must be a den dragon; if the active dragon leaves
  the den, the first remaining den dragon becomes active.

## 4. Training Games

### 4.1 Shared engine

- `GameLoop` view built on `TimelineView(.animation)` drives a fixed 60 Hz step with an
  accumulator (max 5 steps per frame to avoid spiral-of-death after pauses). Pauses when the
  scene is not active.
- Each game is a pure `struct XGameState` with `mutating func step(dt: Double, input: XInput)`
  and seeded RNG; views only render state. The player's dragon is drawn with existing
  `DragonView` in its colors; effects use `element.themeColor`.

### 4.2 Session rules

- Starting costs 15 energy. Not allowed while asleep, as a spirit, or with energy < 15.
  Allowed while ill.
- A session **counts** if it lasted ≥ 20s or reached the game's minimum score. Only counted
  sessions give fitness, decrement Sluggish Scales cure progress, and advance the
  10-session egg counter.
- Rewards by normalized score s ∈ [0,1] (per-game normalization): fitness 25 + 15s,
  XP 10 + 30s (halved while ill), stars 1 + round(4s). New personal best → 3% Phoenix Ember.
- Personal bests stored per game in `trainingBests`.

### 4.3 Games

1. **Dragon Dash** (stamina) — endless runner. Tap = jump, hold = higher jump. Ground
   obstacles (rocks, cacti) and head-height bats. Speed +5% every 10s. One hit ends the run.
   Score = distance. Minimum counted score: 200.
2. **Fire Target** (aim) — 45s round. Drag back from the dragon to aim (dotted trajectory
   preview), release to fire an arcing fireball. Targets: straw dummies → floating balloons
   → moving shields needing 2 hits. Consecutive hits build a combo multiplier.
3. **Sky Flight** (agility) — tap to flap against gravity through cloud-pillar gaps that
   slowly shrink; gems grant bonus points. One hit ends the run. Minimum counted score: 5.
4. **Catch the Snacks** (reflexes) — 60s round, 3 lives. Drag horizontally to catch falling
   `FoodType` items and dodge storm clouds. Up to 5 caught foods per round go to inventory.

Timed games (Fire Target, Catch the Snacks) always count if played to the end.

### 4.4 Training Hub

New screen listing the four games with personal best, energy cost, and the active dragon's
fitness. The existing mini-games remain, relabelled "Learning Games".

## 5. Notifications

### 5.1 Planning

- Local notifications via `UNUserNotificationCenter`; no server.
- Pure `NotificationPlanner.plan(state:now:calendar:) -> [PlannedNotification]` uses
  `LifeSimulator.predictThresholds` over a 72h horizon for each den dragon and incubator
  slot, assuming no player action.
- `NotificationService` removes all pending requests and schedules the plan. Triggered on
  entering background and after any care action (debounced).

### 5.2 Events

| Event | Copy |
|---|---|
| Fullness < 30 | "{name} is hungry! 🍖" |
| Fullness = 0 | "{name} is starving — feed them soon!" |
| Fitness < 30 | "{name} is getting restless. Time for training! 🏃" |
| Becomes ill | "{name} caught {illness} 🤒" |
| Health < 25 | "{name} is very sick! Come quickly ❗" |
| Died | "{name} has become a spirit 👻 You have 48h to revive them." |
| Spirit 6h left | "Last chance to save {name}'s spirit!" |
| Egg ready | "Your egg is hatching! 🥚" |
| Egg warmth < 50 | "Your egg is getting cold — warm it up!" |

### 5.3 Etiquette

- No delivery 22:00–07:00; events in that window move to 07:00.
- At most one notification per dragon per 2h; events within 30 min collapse to the most
  severe (severity order: died > spirit last chance > health critical > ill > starving >
  hungry > needs training).
- Egg notifications are throttled per slot with the same rule.

### 5.4 Permission & routing

- Not requested at first launch. A primer screen is shown after the first hatch (new players)
  or on first launch after update (existing players), then the system prompt.
- Settings gets a "Care reminders" toggle (`remindersEnabled`).
- If authorization is denied, the Den shows a small warning banner.
- Notification `userInfo` carries `dragonId`; tapping selects that dragon (if in the den) and
  routes to the Playground.

## 6. Screens

New `AppRoute` cases: `den`, `trainingHub`, `trainingGame(TrainingGameType)`, `incubator`,
`hallOfLegends` (also reachable as a Collection tab). Reminder primer and "While you were
away" are sheets.

- **Main menu:** primary tiles Den, Train, Incubator; then Learning Games, Shop, Collection,
  Dress-Up, Island, Settings.
- **Den:** card per slot with dragon, five mini meters, status badge (hungry / sick / asleep /
  spirit + countdown); empty slots show "Hatch an egg" or a buy-slot button.
- **Playground (extended):** five meters, illness badge + Cure, Lights out / Wake up, night
  sleep overlay, spirit state (ghostly dragon, countdown, Revive). Feeding/training/evolving
  are disabled when not allowed, with an explanation.
- **Training Hub + 4 game screens** with pre-game card, in-game HUD, results card (score,
  best, rewards).
- **Incubator:** slots with egg, warmth bar, progress ring, tap-to-warm; Egg Basket list with
  "Place" buttons; hatch & name flow.
- **Shop (extended):** Healing Herb 15★, Phoenix Ember 60★, eggs (Common/Uncommon/Rare),
  incubator slot 2, den slots 4–5.
- **Collection (extended):** tabs Den / Sanctuary / Hall of Legends / Undiscovered with
  move-to-den / move-to-sanctuary actions.
- **While you were away:** per-dragon event list from catch-up (replaces `CareSummary` UI);
  daily bonus shown here too.
- **Live ticking:** while active, simulate all den dragons + incubator every 30s; on
  `scenePhase == .active` run catch-up.

## 7. Data Model & Migration

All new fields decode with `decodeIfPresent` and defaults, following the existing pattern.

- `DragonStats` + `fitness`, `health`, `condition: DragonCondition` (`healthy`,
  `ill(Illness)`, `spirit(diedAt: Date)`), `fullnessZeroMinutes` and
  `lowFitnessMinutes` (Doubles: consecutive awake minutes under each trigger condition,
  reset to 0 when the condition clears), `cureSessionsRemaining`,
  `tummyAcheUntil: Date?`, `isSleepingEarly: Bool`, `lastSimulatedAt: Date`,
  `stagesRewarded: Set<GrowthStage>`, `bornAt: Date`.
- `DragonModel` + `residence: DragonResidence` (`den`, `sanctuary`, `undiscovered`,
  `legend`). `isUnlocked` is derived as `residence == .den || residence == .sanctuary` for
  existing views; `hatchCost` is no longer used for unlocking.
- `AppProgressState` + `eggBasket: [Egg]`, `incubatorSlots: [IncubatorSlot]`,
  `denCapacity` (3), `incubatorCapacity` (1), `itemInventory: [String: Int]` (healingHerb,
  phoenixEmber), `trainingBests: [String: Int]`, `trainingSessionsCompleted`,
  `hallOfLegends: [Memorial]`, `remindersEnabled` (true), `hasSeenReminderPrimer` (false).

Migration of existing saves (runs once when `residence` is absent):
- Unlocked dragons → den in order (selected first) up to 3; the rest → sanctuary.
- Locked dragons → `undiscovered`.
- Every owned dragon: fitness 70, health 100, healthy, `lastSimulatedAt = now`.
- One welcome Common egg in the basket. Daily bonus logic unchanged.

## 8. Testing

- Add an XCTest unit test target (`Tiny Dragon AcademyTests`) runnable via
  `xcodebuild test`. Keep the existing DEBUG launch smoke suite.
- Unit tests: LifeSimulator (decay rates, sleep freeze, each illness trigger and cure, health
  drain, death timing ≈3 days, revive, spirit expiry, catch-up cap, backwards clock),
  incubator and egg rolls, den/sanctuary rules, NotificationPlanner (thresholds, quiet hours,
  throttling), each training game's `step` (collision, scoring, counting rules), save
  migration from a pre-update JSON fixture.
- Manual check in the iPhone 17 simulator using DEBUG `-timeScale 60`.

## 9. Out of Scope

Poop/cleaning, iCloud sync, widgets, new sound assets (reuse `AudioService`), multiplayer,
push notifications.
