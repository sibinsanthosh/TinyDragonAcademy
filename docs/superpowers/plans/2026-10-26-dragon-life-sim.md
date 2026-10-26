# Dragon Life Simulation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Tiny Dragon Academy into a never-ending Tamagotchi-style pet game with real-time needs, illness, death/revive, mystery eggs, a den of active dragons, four arcade training games and predictive local notifications.

**Architecture:** All rules live in pure, UI-free Swift types (`LifeSimulator`, `CareActions`, `EggHatcher`, `DenRules`, `NotificationPlanner`, per-game `…GameState` structs) that are unit-tested with fixed dates, a UTC calendar and seeded RNG. `GameManager` gains a thin integration layer (`GameManager+Life.swift`) that calls them, persists, and reschedules notifications. Views are SwiftUI following the existing route/`ContentView` pattern; training games share a fixed-step `TimelineView` loop.

**Tech Stack:** Swift 5 mode, SwiftUI, iOS 17.6+, UserNotifications, XCTest. Xcode 27, project uses `PBXFileSystemSynchronizedRootGroup` (new files in a synced folder are picked up automatically). Build settings: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so test classes are `@MainActor`.

**Spec:** `docs/superpowers/specs/2026-10-26-dragon-life-sim-design.md`

## Global Constraints

- Deployment target stays iOS 17.6 for app and tests; no new third-party dependencies.
- All life rules and numbers come from spec §2–§5; constants are defined once in `LifeRules` (Task 2) and referenced everywhere else — no duplicated magic numbers.
- Quiet hours: 22:00–07:00 local time (`LifeRules.sleepStartHour = 22`, `LifeRules.wakeHour = 7`).
- Spirit window 48h real time; catch-up cap 7 days; simulation step 60s.
- Prices: Healing Herb 15★, Phoenix Ember 60★, eggs Common 25★ / Uncommon 50★ / Rare 100★, incubator slot 2 150★, den slot 4 200★, den slot 5 400★.
- Every new persisted field decodes with `decodeIfPresent` + default; old saves must load.
- Notification copy is exactly the table in spec §5.2.
- Existing features (learning mini-games, dress-up, island, achievements, powers, daily bonus, parent gate) keep working.
- Commit identity in this repo: pass `-c user.name="Sibin Santhosh" -c user.email="sibaatta@gmail.com"` (no repo identity is configured); end messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

**Test command** (used by every task; `<Suite>` is the XCTest class):

```bash
xcodebuild test -project "Tiny Dragon Academy.xcodeproj" -scheme "Tiny Dragon Academy" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:"Tiny Dragon AcademyTests/<Suite>" 2>&1 | grep -E "error:|Test Case|\*\* TEST"
```

Expected on pass: `** TEST SUCCEEDED **`. Shared test helpers (Task 1) provide `TestTime.utc` (a Gregorian `Calendar` with UTC time zone) and `TestTime.date(day:hour:minute:)` returning 2026-01-0{day} HH:MM UTC.

## Review Focus

1. **Long absence spanning death and spirit expiry** — a player away 5 days must come back to a legend memorial plus a same-species egg, not a live dragon or a crash. Test: `LifeSimulatorTests.test_catchUp_spanningDeathAndExpiry_emitsBothEvents` (Task 3) and `DenRulesTests.test_expireSpirit_createsMemorialAndEgg` (Task 6).
2. **Whole den lost** — if every den dragon expires, the player must still be able to continue (eggs in basket, a valid selected dragon fallback, no soft-lock). Test: `DenRulesTests.test_allDenDragonsExpire_basketHasEggs_activeFallsBack` (Task 6).
3. **Hatching when the tier is exhausted or a fixed-species egg's species is alive again** — must give stars or roll the tier, never a duplicate id. Test: `EggHatcherTests.test_fixedSpeciesAlive_fallsBackToTierRoll` and `test_tierExhausted_givesStars` (Task 5).
4. **DST / time-zone change during catch-up** — quiet-hours detection per step must use the calendar, and a 23h/25h day must not double- or under-count. Test: `LifeSimulatorTests.test_dstTransitionDay_quietHoursStillNineHours` (Task 3).
5. **Early lights-out spanning 07:00 and care while asleep** — dragon must auto-wake at 07:00 and feeding/training while asleep must be refused, not silently consume items/energy. Tests: `LifeSimulatorTests.test_lightsOut_autoWakesAt7` (Task 3), `CareActionsTests.test_feedWhileAsleep_refusedAndNoFoodSpent` (Task 4).

---

### Task 1: Unit test target

**Files:**
- Modify: `Tiny Dragon Academy.xcodeproj/project.pbxproj`
- Create: `Tiny Dragon Academy.xcodeproj/xcshareddata/xcschemes/Tiny Dragon Academy.xcscheme`
- Create: `Tiny Dragon AcademyTests/TestTime.swift`
- Create: `Tiny Dragon AcademyTests/SmokeTests.swift`

**Interfaces:**
- Produces: XCTest target `Tiny Dragon AcademyTests` (hosted by the app; `@testable import Tiny_Dragon_Academy`), `enum TestTime { static let utc: Calendar; static func date(day: Int, hour: Int, minute: Int = 0) -> Date }`.

- [ ] **Step 1:** Add to `project.pbxproj`: a `PBXFileSystemSynchronizedRootGroup` for path `Tiny Dragon AcademyTests` (added to the main group), a `PBXFileReference` for `Tiny Dragon AcademyTests.xctest`, a `PBXNativeTarget` (`productType = "com.apple.product-type.bundle.unit-test"`, Sources/Frameworks/Resources phases, `fileSystemSynchronizedGroups` = the new group), a `PBXContainerItemProxy` + `PBXTargetDependency` on the app target, the target in `PBXProject.targets`, and Debug/Release `XCBuildConfiguration`s with: `TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Tiny Dragon Academy.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Tiny Dragon Academy"`, `BUNDLE_LOADER = "$(TEST_HOST)"`, `PRODUCT_BUNDLE_IDENTIFIER = "sibaatta.com.Tiny-Dragon-AcademyTests"`, `GENERATE_INFOPLIST_FILE = YES`, `IPHONEOS_DEPLOYMENT_TARGET = 17.6`, `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `TARGETED_DEVICE_FAMILY = "1,2"`, `DEVELOPMENT_TEAM = CY8L268S88`, `CODE_SIGN_STYLE = Automatic`. Use new unique 24-hex IDs.
- [ ] **Step 2:** Create the shared scheme with BuildAction for the app, TestAction containing the test target as a `TestableReference`, LaunchAction for the app.
- [ ] **Step 3:** Write `TestTime.swift` (UTC Gregorian calendar; `date(day:hour:minute:)` builds 2026-01-day) and `SmokeTests.test_initialStateHasSparkle` asserting `AppProgressState.initial().dragons.contains { $0.id == "sparkle" }`.
- [ ] **Step 4:** Run test command with `<Suite>` = `SmokeTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `git add -A && git commit -m "Add XCTest unit test target and shared scheme"`.

---

### Task 2: Life data model and save migration

**Files:**
- Create: `Tiny Dragon Academy/Models/LifeModels.swift`
- Create: `Tiny Dragon Academy/Models/EggModels.swift`
- Modify: `Tiny Dragon Academy/Models/DragonGrowthModel.swift` (`DragonStats`, `GrowthStage`)
- Modify: `Tiny Dragon Academy/Models/DragonModel.swift` (`residence`, `isUnlocked`)
- Modify: `Tiny Dragon Academy/Models/ProgressionModel.swift` (`AppProgressState`)
- Test: `Tiny Dragon AcademyTests/LifeModelTests.swift`

**Interfaces:**
- Produces (in `LifeModels.swift`):
  - `enum LifeRules` — static constants: `simulationStep: TimeInterval = 60`, `fullnessDecayPerHour = 12.0`, `energyDecayPerHour = 4.0`, `energySleepGainPerHour = 12.0`, `happinessDecayPerHour = 5.0`, `fitnessDecayPerHour = 4.0`, `healthRegenPerHour = 2.0`, `healthRegenMinFullness = 50.0`, `starvingDrainPerHour = 2.0`, `illDrainPerHour = 1.0`, `lowFitnessDrainPerHour = 0.5`, `hungryThreshold = 30.0`, `lowFitnessThreshold = 20.0`, `needsTrainingThreshold = 30.0`, `healthCriticalThreshold = 25.0`, `hungerFeverMinutes = 120.0`, `sluggishScalesMinutes = 360.0`, `tummyAcheFullness = 95.0`, `tummyAcheDuration: TimeInterval = 3600`, `tummyAcheHappinessPenalty = 10.0`, `spiritWindow: TimeInterval = 172_800`, `spiritLastChance: TimeInterval = 21_600`, `catchUpCap: TimeInterval = 604_800`, `sleepStartHour = 22`, `wakeHour = 7`, `reviveHealth = 50.0`, `reviveFullness = 50.0`, `sluggishCureSessions = 2`, `trainingEnergyCost = 15.0`, `migratedFitness = 70.0`.
  - `enum Illness: String, Codable, CaseIterable { case hungerFever = "Hunger Fever", sluggishScales = "Sluggish Scales" }` with `displayName` (= rawValue).
  - `enum DragonCondition: Codable, Equatable { case healthy, ill(Illness), spirit(diedAt: Date) }` with `var isSpirit: Bool`, `var illness: Illness?`.
  - `enum DragonResidence: String, Codable { case den, sanctuary, undiscovered, legend }`.
  - `enum LifeEvent: Equatable, Hashable { case becameHungry, starving, needsTraining, becameIll(Illness), healthCritical, died, spiritLastChance, spiritExpired, cured, fellAsleep, wokeUp, eggReady, eggCold }` with `var severity: Int` (died 7, spiritLastChance 6, healthCritical 5, becameIll 4, starving 3, becameHungry 2, needsTraining 1, others 0).
  - `enum CareItem: String, Codable, CaseIterable { case healingHerb = "Healing Herb", phoenixEmber = "Phoenix Ember" }` with `price: Int` (15 / 60).
  - `struct Memorial: Codable, Equatable, Identifiable { id: UUID; dragonId: String; name: String; speciesTitle: String; stage: GrowthStage; level: Int; bornAt: Date; diedAt: Date }`.
- Produces (in `EggModels.swift`):
  - `enum EggTier: String, Codable, CaseIterable { case common, uncommon, rare, legendary }` with `speciesIds: [String]` (spec §3.1 table), `hatchDuration: TimeInterval` (2/4/8/12 h), `shopPrice: Int?` (25/50/100/nil), `duplicateStars: Int` (12/25/50/100), `static func tier(forSpecies: String) -> EggTier?`.
  - `struct Egg: Codable, Equatable, Identifiable { id: UUID = UUID(); tier: EggTier; fixedSpeciesId: String? = nil }`.
  - `struct IncubatorSlot: Codable, Equatable { var egg: Egg?; var warmth: Double = 100; var progress: Double = 0 /* 0…1 */; var lastSimulatedAt: Date; var isReady: Bool { egg != nil && progress >= 1 } }`.
- Produces (fields): `DragonStats` + `fitness = 100.0`, `condition: DragonCondition = .healthy`, `fullnessZeroMinutes = 0.0`, `lowFitnessMinutes = 0.0`, `cureSessionsRemaining = 0`, `tummyAcheUntil: Date? = nil`, `isSleepingEarly = false`, `lastSimulatedAt: Date = Date()`, `stagesRewarded: Set<GrowthStage> = [.baby]`, `bornAt: Date = Date()`. `GrowthStage` + `var previousStage: GrowthStage?` and `Hashable`. `DragonModel` + `var residence: DragonResidence`; `isUnlocked` becomes computed `residence == .den || residence == .sanctuary` (the memberwise `init(isUnlocked:)` parameter maps `true → .den`, `false → .undiscovered`). `AppProgressState` + `eggBasket: [Egg] = []`, `incubatorSlots: [IncubatorSlot] = [IncubatorSlot(lastSimulatedAt: Date())]`, `denCapacity = 3`, `itemInventory: [String: Int] = [:]`, `trainingBests: [String: Int] = [:]`, `trainingSessionsCompleted = 0`, `hallOfLegends: [Memorial] = []`, `remindersEnabled = true`, `hasSeenReminderPrimer = false`; computed `denDragons: [DragonModel]`, `incubatorCapacity: Int { incubatorSlots.count }`.

- [ ] **Step 1: Write failing tests** in `LifeModelTests`:

```swift
func test_dragonStats_decodesLegacyJSONWithoutNewFields() throws {
    let legacy = #"{"hunger":50,"happiness":60,"energy":70,"health":100,"experience":0,"level":1,"growthStage":"Baby Dragon","ageInDays":1,"totalFeedings":0,"favoriteFoodDiscovered":false,"lastCareTimestamp":0,"lastFeedingTimestamp":0,"unlockedPowerIds":["fire_1"]}"#
    let stats = try JSONDecoder().decode(DragonStats.self, from: Data(legacy.utf8))
    XCTAssertEqual(stats.hunger, 50); XCTAssertEqual(stats.condition, .healthy); XCTAssertEqual(stats.fitness, 100)
}
func test_dragonCondition_roundTripsSpirit() throws {
    let c = DragonCondition.spirit(diedAt: TestTime.date(day: 5, hour: 10))
    XCTAssertEqual(try JSONDecoder().decode(DragonCondition.self, from: JSONEncoder().encode(c)), c)
}
func test_legacySave_migratesOwnedDragonsIntoDen_selectedFirst_capThree() throws
    // Build a legacy AppProgressState JSON (encode AppProgressState.initial(), strip new keys
    // "eggBasket","incubatorSlots","denCapacity","itemInventory","trainingBests",
    // "trainingSessionsCompleted","hallOfLegends","remindersEnabled","hasSeenReminderPrimer",
    // and each dragon's "residence"; set "isUnlocked": true for sparkle, ember, frosty, volt;
    // selectedDragonId = "volt").
    // Assert: den ids == ["volt","sparkle","ember"] in that order; frosty == .sanctuary;
    // nova == .undiscovered; eggBasket == 1 egg with tier .common; every owned dragon has
    // fitness 70, health 100, condition .healthy.
func test_newState_roundTripsAllNewFields() throws
    // Set eggBasket, itemInventory["Phoenix Ember"]=2, trainingBests["Dragon Dash"]=500,
    // hallOfLegends 1 memorial; encode → decode → XCTAssertEqual(decoded, original).
func test_eggTier_speciesTable() {
    XCTAssertEqual(EggTier.common.speciesIds, ["ember","splash","sprout","terra"])
    XCTAssertEqual(EggTier.legendary.speciesIds, ["twinkle","rainbow"])
    XCTAssertNil(EggTier.legendary.shopPrice); XCTAssertEqual(EggTier.rare.hatchDuration, 8 * 3600)
    XCTAssertEqual(EggTier.tier(forSpecies: "nova"), .rare); XCTAssertNil(EggTier.tier(forSpecies: "sparkle"))
}
```

- [ ] **Step 2:** Run with `<Suite>` = `LifeModelTests`. Expected: compile FAIL (types missing).
- [ ] **Step 3:** Implement the interfaces above. `DragonStats` needs an explicit `CodingKeys` + `init(from:)` using `decodeIfPresent` for every field (synthesized Codable would reject legacy saves), and keeps a memberwise-style default `init()`. Migration lives in `AppProgressState.init(from:)`: when the `eggBasket` key is absent, run `static func migrateLegacy(_ state: inout AppProgressState, now: Date)` that assigns residences (selected first, then remaining owned in array order, up to `denCapacity`), resets owned stats (`fitness = LifeRules.migratedFitness`, `health = 100`, `.healthy`, `lastSimulatedAt = now`, `bornAt = now`) and appends `Egg(tier: .common)`. `DragonModel.init(from:)`: `residence = decodeIfPresent ?? (legacy isUnlocked ? .den : .undiscovered)`; encode `residence` instead of `isUnlocked`. Default dragons: sparkle `.den`, others `.undiscovered`.
- [ ] **Step 4:** Run `LifeModelTests` and `SmokeTests`. Expected: `** TEST SUCCEEDED **`. Also build the app (`xcodebuild build …`) — fix compile errors at existing `isUnlocked = true` assignments in `GameManager.swift` (lines ~154, ~168) by assigning `residence = .den`.
- [ ] **Step 5:** Commit: `"Add life simulation data model and legacy save migration"`.

---

### Task 3: LifeSimulator — dragon advance

**Files:**
- Create: `Tiny Dragon Academy/Life/LifeSimulator.swift`
- Test: `Tiny Dragon AcademyTests/LifeSimulatorTests.swift`

**Interfaces:**
- Consumes: `DragonStats`, `LifeRules`, `LifeEvent`, `DragonCondition` (Task 2).
- Produces: `enum LifeSimulator { static func isAsleep(_ stats: DragonStats, at: Date, calendar: Calendar) -> Bool; static func isQuietHours(_ date: Date, calendar: Calendar) -> Bool; static func advance(_ stats: DragonStats, from: Date, to: Date, calendar: Calendar) -> (DragonStats, [LifeEvent]) }`. `advance` sets `lastSimulatedAt = to` on return. Events are emitted once on threshold *crossing* (e.g. `becameHungry` when fullness goes from ≥30 to <30).

- [ ] **Step 1: Write failing tests** (`stats` helper: all meters 100, fitness 100, health 100, healthy):

```swift
func test_sixAwakeHours_fullnessDropsTo28_andEmitsHungry()      // 08:00→14:00 day 5: hunger == 28 (±0.01), events contains .becameHungry
func test_awakeRates_energyHappinessFitness()                    // 08:00→10:00: energy 92, happiness 90, fitness 92
func test_quietHours_freezeAllButEnergy()                        // energy 40, hunger 50, 22:00 day5→07:00 day6: hunger 50, happiness/fitness unchanged, energy 100 (40+12*9 capped)
func test_hungerFever_afterTwoHoursAtZero()                      // hunger 24 at 08:00 → reaches 0 at 10:00; at 11:59 condition .healthy; at 12:00 condition == .ill(.hungerFever); events contains .starving and .becameIll(.hungerFever)
func test_sluggishScales_afterSixHoursBelowTwenty()             // fitness 19, hunger 100 at 08:00 → 14:00 condition == .ill(.sluggishScales)
func test_onlyOneIllnessAtATime()                                 // hunger 0 & fitness 0 at 08:00 → 16:00: condition is .ill(.hungerFever) (triggers first), no second becameIll
func test_healthDrain_stacks()                                    // hunger 0, fitness 10, condition .ill(.hungerFever), health 100, 08:00→10:00: health == 93 (100 - 2*(2+1+0.5))
func test_healthRegen_onlyWhenFedAndWell()                         // health 80, hunger 100: 08:00→09:00 health 82; same with condition ill → no regen (and -1)
func test_neglectedFromFull_diesBetween48And72Hours()             // start day5 07:00 full; advance in one call to day9 07:00; condition is .spirit(diedAt: d) with d - start in 48h...72h; events contains .died exactly once; .healthCritical before .died
func test_spirit_doesNotDecay_andExpiresAfter48h()               // condition .spirit(diedAt: day5 10:00); advance to day7 09:59 → no .spiritExpired; to day7 10:00 → .spiritExpired; meters unchanged
func test_spiritLastChance_at6hLeft()                               // diedAt day5 10:00; advance to day7 04:00 → events contains .spiritLastChance
func test_tummyAche_wearsOffEvenAsleep()                            // tummyAcheUntil = day5 22:30; advance 22:00→23:00 → tummyAcheUntil == nil
func test_lightsOut_autoWakesAt7()                                    // isSleepingEarly = true at 20:00 day5; advance to day6 08:00 → isSleepingEarly == false, events contains .wokeUp; hunger frozen 20:00→07:00 then −12 for 07:00→08:00
func test_catchUp_cappedAtSevenDays()                                 // XCTAssertEqual(LifeSimulator.effectiveStart(from: t, to: t + 10 days), t + 3 days); advance(from: t, to: t + 10 days) == advance(from: t + 3 days, to: t + 10 days) for the same starting stats
func test_backwardsClock_noChange()                                    // to < from → stats identical except lastSimulatedAt == to, events empty
func test_catchUp_spanningDeathAndExpiry_emitsBothEvents()            // full dragon, day5 07:00 → day12 07:00: events contains .died then .spiritExpired (in order)
func test_dstTransitionDay_quietHoursStillNineHours()                 // calendar with TimeZone "America/New_York", 2026-03-08 (DST start): count minutes where isQuietHours from 2026-03-08 12:00 local to 2026-03-09 12:00 local == 9*60
```

- [ ] **Step 2:** Run `<Suite>` = `LifeSimulatorTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement. Step in `LifeRules.simulationStep` increments from `effectiveStart(from:to:) = max(from, to - catchUpCap)` (expose as `static func effectiveStart(from: Date, to: Date) -> Date`; the 7-day test asserts on it). Per step: expire tummy ache; if spirit → only check last-chance/expiry; wake (`isSleepingEarly = false`) when local hour == `wakeHour` at a step boundary crossing; if asleep → energy += gain only; else apply decays, update `fullnessZeroMinutes`/`lowFitnessMinutes` (reset to 0 when condition clears), trigger illness if healthy, apply drain/regen, die at health ≤ 0 (`condition = .spirit(diedAt: stepTime)`). Clamp all meters 0…100. Performance: a 7-day catch-up is ≤10 080 steps per dragon — acceptable.
- [ ] **Step 4:** Run `LifeSimulatorTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `"Add LifeSimulator dragon advance with sleep, illness and death"`.

---

### Task 4: CareActions — feeding, medicine, revive, sleep, training rewards

**Files:**
- Create: `Tiny Dragon Academy/Life/CareActions.swift`
- Test: `Tiny Dragon AcademyTests/CareActionsTests.swift`

**Interfaces:**
- Consumes: `LifeSimulator.isAsleep`, `LifeRules`, `GrowthStage.previousStage` (Tasks 2–3).
- Produces:
  - `enum FeedOutcome: Equatable { case fed, tummyAche, refusedAsleep, refusedSpirit }`
  - `struct TrainingReward: Equatable { let fitness: Double; let xp: Int; let stars: Int }`
  - `enum CareActions`:
    - `static func feed(_ stats: inout DragonStats, food: FoodType, isFavorite: Bool, now: Date, calendar: Calendar) -> FeedOutcome` — on `.fed`/`.tummyAche` applies the food's existing `hungerRestored`/`happinessRestored`(×2 if favorite)/`energyRestored`; tummy ache when hunger > 95 *before* feeding: sets `tummyAcheUntil = now + 1h`, happiness −10 (no restore). XP is handled by `GameManager` (Task 9).
    - `static func useHealingHerb(_ stats: inout DragonStats) -> Bool` — true only when `.ill`; sets `.healthy`, resets illness minute counters and `cureSessionsRemaining = 0`.
    - `static func revive(_ stats: inout DragonStats) -> Bool` — only when spirit; health 50, hunger 50, `.healthy`, counters reset, `growthStage = previousStage ?? .baby`, `level` kept, `isSleepingEarly = false`.
    - `static func lightsOut(_ stats: inout DragonStats)` / `static func wakeUp(_ stats: inout DragonStats)`.
    - `static func canTrain(_ stats: DragonStats, now: Date, calendar: Calendar) -> Bool` — false when asleep, spirit, or energy < 15.
    - `static func trainingReward(normalizedScore s: Double, isIll: Bool) -> TrainingReward` — fitness `25 + 15s`, xp `10 + 30s` rounded (halved, rounded down, when ill), stars `1 + round(4s)`; `s` clamped 0…1.
    - `static func applyCountedSession(_ stats: inout DragonStats, reward: TrainingReward) -> Bool` — adds fitness; if `.ill(.sluggishScales)`: on first counted session while ill set `cureSessionsRemaining = 2` before decrementing; cure at 0. Returns true if cured.

- [ ] **Step 1: Write failing tests:**

```swift
func test_feed_restoresFoodValues()                  // hunger 50 + frostApples → 72; outcome .fed
func test_feed_overfull_givesTummyAche()             // hunger 96 → outcome .tummyAche; happiness −10; tummyAcheUntil == now+3600
func test_feedWhileAsleep_refusedAndNoFoodSpent()    // now = day5 23:00 → .refusedAsleep; stats unchanged
func test_feedSpirit_refused()
func test_herb_curesIllness_onlyWhenIll()            // healthy → false; .ill(.hungerFever) → true and .healthy
func test_revive_dropsOneStage_keepsLevel()          // spirit, adolescent, level 12 → young, level 12, health 50, hunger 50
func test_revive_babyStaysBaby()
func test_revive_notSpirit_returnsFalse()
func test_trainingReward_scaling()                   // s=0 → (25,10,1); s=1 → (40,40,5); s=0.5 ill → (32.5,12,3)
func test_sluggishScales_curedAfterTwoCountedSessions() // first call → false, second → true and .healthy
func test_canTrain_rules()                           // energy 14 → false; asleep → false; ill with energy 50 at 12:00 → true
```

- [ ] **Step 2:** Run `CareActionsTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement `CareActions` per the interfaces.
- [ ] **Step 4:** Run `CareActionsTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `"Add CareActions for feeding, medicine, revive, sleep and training rewards"`.

---

### Task 5: Incubator simulation and egg hatching

**Files:**
- Create: `Tiny Dragon Academy/Life/EggHatcher.swift`
- Create: `Tiny Dragon Academy/Life/SeededRNG.swift`
- Modify: `Tiny Dragon Academy/Life/LifeSimulator.swift` (add incubator advance)
- Test: `Tiny Dragon AcademyTests/EggHatcherTests.swift`

**Interfaces:**
- Produces:
  - `struct SeededRNG: RandomNumberGenerator { init(seed: UInt64) }` (SplitMix64) — reused by training games.
  - `LifeSimulator.advance(_ slot: IncubatorSlot, from: Date, to: Date) -> (IncubatorSlot, [LifeEvent])` — warmth −10/h (floor 0), progress += dt / `tier.hatchDuration` × (warmth ≥ 50 ? 1 : 0.5), capped 1; emits `.eggCold` on crossing below 50 and `.eggReady` on reaching 1. Not paused by quiet hours. Empty slot only updates `lastSimulatedAt`.
  - `enum HatchOutcome: Equatable { case dragon(id: String), stars(Int) }`
  - `enum EggHatcher { static func warm(_ slot: inout IncubatorSlot); static func roll(_ egg: Egg, dragons: [DragonModel], rng: inout some RandomNumberGenerator) -> HatchOutcome }` — warm adds 10 (cap 100). Roll: if `fixedSpeciesId` set and that dragon's residence is `.undiscovered`/`.legend` → that id; otherwise uniform among the tier's species with those residences; none → `.stars(tier.duplicateStars)`.

- [ ] **Step 1: Write failing tests:**

```swift
func test_commonEgg_warm_hatchesInTwoHours_emitsReady()     // warmth kept ≥50 by advancing in 1h chunks and warming 1× per hour; ready at 2h
func test_coldEgg_hatchesAtHalfSpeed()                       // warmth 0, common: after 2h progress == 0.5
func test_warmthDecay_emitsColdOnce()                        // warmth 100 → after 6h warmth 40, events contains .eggCold once
func test_warm_capsAt100()
func test_roll_onlyPicksUndiscoveredOrLegend()               // ember .den, splash .legend, sprout .undiscovered, terra .sanctuary; 50 rolls with SeededRNG(seed: 1) ⊆ {splash, sprout}
func test_fixedSpecies_hatchesThatSpecies()
func test_fixedSpeciesAlive_fallsBackToTierRoll()            // fixed "ember" but ember .den → result in available common species
func test_tierExhausted_givesStars()                         // all common species .den → .stars(12)
```

- [ ] **Step 2:** Run `EggHatcherTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement per interfaces.
- [ ] **Step 4:** Run `EggHatcherTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `"Add incubator simulation and mystery egg hatching"`.

---

### Task 6: Den and sanctuary rules

**Files:**
- Create: `Tiny Dragon Academy/Life/DenRules.swift`
- Test: `Tiny Dragon AcademyTests/DenRulesTests.swift`

**Interfaces:**
- Consumes: `AppProgressState`, `DragonResidence`, `Memorial`, `Egg` (Task 2).
- Produces: `enum DenRules`:
  - `static let denSlotPrices: [Int: Int] = [4: 200, 5: 400]`, `static let maxDenCapacity = 5`, `static let incubatorSlotPrice = 150`, `static let maxIncubatorSlots = 2`.
  - `static func moveToSanctuary(_ id: String, state: inout AppProgressState) -> Bool` — only den + `.healthy`.
  - `static func moveToDen(_ id: String, state: inout AppProgressState, now: Date) -> Bool` — only sanctuary + free slot; sets `lastSimulatedAt = now`.
  - `static func placeHatched(_ id: String, name: String, state: inout AppProgressState, now: Date)` — den if free else sanctuary; fresh `DragonStats.defaultStats(for:)` with `bornAt/lastSimulatedAt = now`.
  - `static func expireSpirit(_ id: String, state: inout AppProgressState, now: Date)` — append `Memorial`, residence `.legend`, append `Egg(tier: EggTier.tier(forSpecies: id) ?? .common, fixedSpeciesId: id)`, reset that dragon's stats to defaults and name to its default name.
  - `static func ensureActiveInDen(_ state: inout AppProgressState)` — if selected is not in den, select first den dragon (keep selection unchanged if the den is empty).

- [ ] **Step 1: Write failing tests:**

```swift
func test_moveToSanctuary_onlyWhenHealthy()        // ill → false; spirit → false; healthy → true
func test_moveToDen_respectsCapacity_resetsClock()
func test_placeHatched_fullDen_goesToSanctuary()
func test_expireSpirit_createsMemorialAndEgg()     // memorial fields copied; residence .legend; basket last egg fixedSpeciesId == id, tier from table
func test_allDenDragonsExpire_basketHasEggs_activeFallsBack() // den: sparkle(selected), ember; expire both → basket has 2 eggs; ensureActiveInDen leaves selection valid (no crash); denDragons empty
func test_ensureActiveInDen_picksFirstDenDragon()
```

- [ ] **Step 2:** Run `DenRulesTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement. Sparkle has no tier: its returned egg uses `.common` with `fixedSpeciesId: "sparkle"` (roll honours fixed species regardless of tier).
- [ ] **Step 4:** Run `DenRulesTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `"Add den and sanctuary rules with spirit expiry"`.

---

### Task 7: Threshold prediction and NotificationPlanner

**Files:**
- Modify: `Tiny Dragon Academy/Life/LifeSimulator.swift`
- Create: `Tiny Dragon Academy/Notifications/NotificationPlanner.swift`
- Test: `Tiny Dragon AcademyTests/NotificationPlannerTests.swift`

**Interfaces:**
- Produces:
  - `LifeSimulator.predict(_ stats: DragonStats, from: Date, horizon: TimeInterval, calendar: Calendar) -> [(event: LifeEvent, at: Date)]` — runs `advance` step by step and records the first time each notifiable event fires (`becameHungry, starving, needsTraining, becameIll, healthCritical, died, spiritLastChance`). `needsTraining` = fitness crossing below `needsTrainingThreshold` (add the emission to `advance`).
  - `LifeSimulator.predict(_ slot: IncubatorSlot, from: Date, horizon: TimeInterval) -> [(event: LifeEvent, at: Date)]` (`eggCold`, `eggReady`).
  - `struct PlannedNotification: Equatable { let id: String; let title: String; let body: String; let fireDate: Date; let dragonId: String? }`
  - `enum NotificationPlanner { static let horizon: TimeInterval = 72 * 3600; static func plan(state: AppProgressState, now: Date, calendar: Calendar) -> [PlannedNotification]; static func body(for: LifeEvent, name: String) -> String }`. Title is the dragon name (or "Incubator" for eggs). Ids: `"\(dragonId).\(event)"` / `"egg\(slotIndex).\(event)"`.

- [ ] **Step 1: Write failing tests:**

```swift
func test_hungry_predictedAtFiftyMinutes()                // den dragon hunger 40 at day5 08:00 → a notification with body "Sparkle is hungry! 🍖" at 08:50
func test_copyMatchesSpec()                                // body(for:.died,"Ember") == "Ember has become a spirit 👻 You have 48h to revive them." … one assert per §5.2 row
func test_quietHours_shiftTo7am()                          // egg ready predicted 23:30 → fireDate next day 07:00
func test_eventsWithin30Min_collapseToMostSevere()         // hunger 30.5 & fitness 30.5 at 08:00 → only the hungry notification in that window
func test_minimumTwoHoursBetweenNotificationsPerDragon()
func test_sanctuaryAndUndiscovered_notPlanned()
func test_remindersDisabled_planIsEmpty()
```

- [ ] **Step 2:** Run `NotificationPlannerTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement. Throttle per source (dragon id / egg slot): sort predicted events by time; shift quiet-hour dates to the next 07:00; walk the list keeping an event only if ≥2h after the last kept one, except that an event within 30 min of the last kept one replaces it when more severe.
- [ ] **Step 4:** Run `NotificationPlannerTests` and `LifeSimulatorTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `"Add threshold prediction and notification planner"`.

---

### Task 8: GameManager life integration

**Files:**
- Create: `Tiny Dragon Academy/ViewModels/GameManager+Life.swift`
- Create: `Tiny Dragon Academy/Life/GameClock.swift`
- Create: `Tiny Dragon Academy/Notifications/NotificationService.swift`
- Modify: `Tiny Dragon Academy/ViewModels/GameManager.swift` (init, `feedActiveDragon`, `evolveActiveDragon`, `hatchDragon` removal, `petActiveDragon`, `AppRoute`, debug routes)
- Modify: `Tiny Dragon Academy/Services/TimeProgressionService.swift` (keep only daily bonus; remove hunger/energy logic and `CareSummary` stat fields)
- Modify: `Tiny Dragon Academy/ContentView.swift` (30s timer, `scenePhase`)
- Modify: `Tiny Dragon Academy/Tiny_Dragon_AcademyApp.swift` (notification delegate)
- Modify: `Tiny Dragon Academy/Tests/GameLogicTests.swift` (update smoke tests for removed APIs)
- Test: `Tiny Dragon AcademyTests/GameManagerLifeTests.swift`

**Interfaces:**
- Consumes: Tasks 2–7.
- Produces:
  - `struct GameClock { var timeScale: Double; let origin: Date; func now(real: Date = Date()) -> Date }` — `origin + (real - origin) * timeScale`; `static func fromLaunchArguments(_ args: [String]) -> GameClock` reading DEBUG `-timeScale N` (default 1).
  - `GameManager.init(persistence: PersistenceService = .shared, clock: GameClock = .fromLaunchArguments(ProcessInfo.processInfo.arguments), notifications: NotificationScheduling = NotificationService.shared)`.
  - `protocol NotificationScheduling { func schedule(_ plan: [PlannedNotification]); func requestAuthorization() async -> Bool; func authorizationDenied() async -> Bool }`; `NotificationService` implements it with `UNUserNotificationCenter` (removes all pending, then adds `UNCalendarNotificationTrigger`s; `userInfo["dragonId"]`).
  - `@Published var awayReport: [String: [LifeEvent]]` (dragonId/"incubator" → events), replacing `offlineCareSummary`; `@Published var dailyBonus: (stars: Int, food: FoodType?)?`.
  - `func tick()` — advances every den dragon and incubator slot from their `lastSimulatedAt` to `clock.now()`, handles `.spiritExpired` via `DenRules.expireSpirit`, calls `ensureActiveInDen`, saves, reschedules. `func catchUp()` = `tick()` that also fills `awayReport` when anything happened.
  - Care: `feedActiveDragon(food:)` now returns `(gainedXP: Int, isFavorite: Bool, leveledUp: Bool, outcome: FeedOutcome)`; XP halved while ill; no food spent on refusal. `evolveActiveDragon()` refuses while ill or spirit; on reaching a stage not in `stagesRewarded` appends the egg tier from spec §3.3 to `eggBasket`. `useHealingHerb() -> Bool`, `reviveActiveDragon() -> Bool`, `lightsOut()`, `wakeUp()` — each consumes items from `itemInventory` where relevant.
  - Shop: `purchaseCareItem(_ item: CareItem) -> Bool`, `purchaseEgg(_ tier: EggTier) -> Bool`, `purchaseIncubatorSlot() -> Bool`, `purchaseDenSlot() -> Bool`.
  - Eggs: `placeEgg(_ eggId: UUID, slot: Int) -> Bool`, `warmEgg(slot: Int)`, `crackEgg(slot: Int) -> HatchOutcome?` (only when ready; on `.dragon` caller then calls `nameHatched(id:name:)` which uses `DenRules.placeHatched`).
  - Den: `moveToSanctuary(_:) -> Bool`, `moveToDen(_:) -> Bool`.
  - New `AppRoute` cases: `den`, `trainingHub`, `incubator`, `hallOfLegends` (ContentView shows a placeholder `Text` for each until Task 14/15); DEBUG `-route` values `den`, `trainingHub`, `incubator`, `hallOfLegends`. Task 9 adds `trainingGame(TrainingGameType)` and the four game routes.
  - `PersistenceService` gains `init(fileURL: URL)` (the shared instance keeps the Documents path) so tests use a temp file.
  - `func handleNotificationTap(dragonId: String)` — select if in den, navigate to `.dragonPlayground`.

- [ ] **Step 1: Write failing tests** (GameManager with a temp-directory `PersistenceService(fileURL:)` initializer — add that initializer — a `GameClock` with a fixed origin and timeScale 1, and a `SpyScheduler: NotificationScheduling` recording plans):

```swift
func test_tick_advancesDenOnly_notSanctuary()
func test_tick_expiredSpirit_movesToLegendAndAddsEgg()
func test_feed_illHalvesXP_andRefusalSpendsNoFood()
func test_reachingYoung_grantsCommonEggOnce()         // evolve → basket +1 common; revive (drops to baby) and evolve again → no second egg
func test_revive_consumesEmber_failsWithoutEmber()
func test_tick_reschedulesNotifications()             // spy received a non-empty plan
func test_purchaseDenSlot_pricesAndCap()               // 200 then 400 then false at capacity 5
```

- [ ] **Step 2:** Run `GameManagerLifeTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement. Remove `hatchDragon(id:)` (eggs replace it) and the star-unlock UI call in `DragonCollectionView` (temporarily disable the button; Task 15 replaces it). In `ContentView` add `.onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in gameManager.tick() }` and `.onChange(of: scenePhase)` → `.active`: `catchUp()`, `.background`: reschedule. Register a `UNUserNotificationCenterDelegate` in the app that calls `handleNotificationTap`.
- [ ] **Step 4:** Run all suites (omit `-only-testing`). Expected: `** TEST SUCCEEDED **`; app builds.
- [ ] **Step 5:** Commit: `"Integrate life simulation, eggs, shop and notifications into GameManager"`.

---

### Task 9: Training engine and session rules

**Files:**
- Create: `Tiny Dragon Academy/Training/TrainingGameType.swift`
- Create: `Tiny Dragon Academy/Training/TrainingSessionRules.swift`
- Create: `Tiny Dragon Academy/Training/GameLoop.swift`
- Modify: `Tiny Dragon Academy/ViewModels/GameManager+Life.swift` (start/finish training)
- Test: `Tiny Dragon AcademyTests/TrainingSessionRulesTests.swift`

**Interfaces:**
- Produces:
  - `enum TrainingGameType: String, CaseIterable, Codable, Identifiable { case dragonDash = "Dragon Dash", fireTarget = "Fire Target", skyFlight = "Sky Flight", snackCatch = "Catch the Snacks" }` with `subtitle`, `iconName`, `trainsLabel` ("Stamina"/"Aim"/"Agility"/"Reflexes"), `isTimed` (fireTarget, snackCatch), `roundDuration: Double?` (45 / 60), `minimumCountedScore: Int?` (dash 200, sky 5), `scoreForFullMarks: Double` (dash 2000, fire 30, sky 40, snacks 40).
  - `enum TrainingSessionRules { static func counts(_ game: TrainingGameType, duration: Double, score: Int, completedRound: Bool) -> Bool; static func normalizedScore(_ game: TrainingGameType, score: Int) -> Double; static let emberDropChance = 0.03; static let sessionsPerEgg = 10; static let maxSnacksPerRound = 5 }`.
  - `struct GameLoop<Content: View>: View { init(isRunning: Bool, step: @escaping (Double) -> Void, @ViewBuilder content: () -> Content) }` — fixed `dt = 1/60`, accumulator, max 5 steps per frame, does nothing when `!isRunning`.
  - `struct TrainingResult: Equatable { let counted: Bool; let reward: TrainingReward?; let isNewBest: Bool; let droppedEmber: Bool; let earnedEgg: Bool; let snacksAdded: [FoodType]; let cured: Bool }`
  - `GameManager.startTraining(_ game: TrainingGameType) -> Bool` (uses `CareActions.canTrain`, deducts 15 energy) and `finishTraining(_ game: TrainingGameType, score: Int, duration: Double, completedRound: Bool, caughtSnacks: [FoodType] = [], rng: inout some RandomNumberGenerator) -> TrainingResult`.

- [ ] **Step 1: Write failing tests:**

```swift
func test_counts_untimedNeedsTwentySecondsOrMinScore()   // dash: (10s, 150) false; (25s, 0) true; (5s, 200) true
func test_counts_timedCountsWhenRoundCompleted()          // fire: (45, 0, completed) true; (10, 3, not completed) false
func test_normalizedScore_clamped()                        // dash 1000 → 0.5; dash 9999 → 1; sky 0 → 0
func test_finishTraining_counted_appliesRewardAndCounter()  // GameManager: fitness up, stars up, sessions +1
func test_tenthSession_grantsCommonEgg()
func test_newBest_emberDrop_usesRNG()                       // RNG stub returning value < 0.03 → droppedEmber true and itemInventory ember +1
func test_snacks_cappedAtFive()
func test_startTraining_refusedWhenAsleepOrLowEnergy_noEnergySpent()
```

- [ ] **Step 2:** Run `TrainingSessionRulesTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement; add `AppRoute.trainingGame(TrainingGameType)` (placeholder view until Tasks 10–13) and DEBUG `-route` values `dragonDash`, `fireTarget`, `skyFlight`, `snackCatch`.
- [ ] **Step 4:** Run `TrainingSessionRulesTests`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit: `"Add training engine, session rules and rewards"`.

---

### Task 10: Dragon Dash

**Files:**
- Create: `Tiny Dragon Academy/Training/Games/DashGameState.swift`
- Create: `Tiny Dragon Academy/Views/Training/DragonDashView.swift`
- Create: `Tiny Dragon Academy/Views/Training/TrainingResultCard.swift` (shared by all four games)
- Test: `Tiny Dragon AcademyTests/DashGameStateTests.swift`

**Interfaces:**
- Produces: `struct DashGameState { init(seed: UInt64); var elapsed: Double; var score: Int; var isOver: Bool; var dragonY: Double /* 0 = ground, up positive */; var obstacles: [DashObstacle]; mutating func step(dt: Double, input: DashInput) }`, `struct DashInput { var jumpPressed: Bool; var jumpHeld: Bool }`, `struct DashObstacle { enum Kind { case rock, cactus, bat }; var kind: Kind; var x: Double; var width: Double; var height: Double; var y: Double }`. World units: dragon at x = 0.2, world width 1.0 (normalized), base speed 0.5/s, ×1.05 every 10s. Score = distance travelled × 100 (integer).
- `TrainingResultCard(game:, score:, result: TrainingResult, onDone:)`.

- [ ] **Step 1: Write failing tests:**

```swift
func test_jump_onlyFromGround_andLandsAgain()
func test_holdJump_goesHigherThanTap()
func test_speedIncreasesFivePercentEveryTenSeconds()   // speed at 20s == base * 1.05^2
func test_collision_endsRun()                           // place a rock at dragon x, step → isOver
func test_batAtHeadHeight_avoidedByStayingOnGround()
func test_sameSeed_sameObstacleSequence()
```

- [ ] **Step 2:** Run `DashGameStateTests`. Expected: compile FAIL.
- [ ] **Step 3:** Implement the state, then `DragonDashView`: pre-game card (energy cost, best), `GameLoop` rendering ground, obstacles (SF Symbols / shapes), `DragonView` of the active dragon scaled small at the dragon position; tap/press gesture → input; on `isOver` call `finishTraining` and show `TrainingResultCard`.
- [ ] **Step 4:** Run `DashGameStateTests`; launch app with `-route dragonDash` in the simulator, play once, screenshot. Expected: tests pass; dragon jumps, run ends on hit, result card shows rewards.
- [ ] **Step 5:** Commit: `"Add Dragon Dash runner training game"`.

---

### Task 11: Fire Target

**Files:**
- Create: `Tiny Dragon Academy/Training/Games/FireTargetGameState.swift`
- Create: `Tiny Dragon Academy/Views/Training/FireTargetView.swift`
- Test: `Tiny Dragon AcademyTests/FireTargetGameStateTests.swift`

**Interfaces:**
- Produces: `struct FireTargetGameState { init(seed: UInt64); var timeRemaining: Double /* starts 45 */; var score: Int; var combo: Int; var targets: [FireTarget]; var fireballs: [Fireball]; var isOver: Bool; mutating func step(dt: Double, input: FireInput); static func trajectory(origin: CGPoint, pull: CGVector, steps: Int) -> [CGPoint] }`, `struct FireInput { var release: CGVector? /* pull vector when the drag is released */ }`, `struct FireTarget { enum Kind { case dummy, balloon, shield }; var kind; var position: CGPoint; var hitsRemaining: Int; var velocity: CGVector }`. Launch velocity = −pull × 3.0, gravity 1.2 units/s². Target mix by time elapsed: 0–15s dummies, 15–30s balloons, 30–45s shields (2 hits). Points per destroyed target = 1 × combo multiplier (combo increments on hit, resets on a fireball leaving the screen).

- [ ] **Step 1: Write failing tests:**

```swift
func test_roundEndsAt45Seconds()
func test_fireball_followsTrajectoryPreview()       // fireball position after n steps ≈ trajectory(…)[n]
func test_shieldNeedsTwoHits()
func test_comboMultiplier_increasesAndResetsOnMiss()
func test_targetMix_changesOverTime()                // spawns at t=5 are dummies, t=35 shields
```

- [ ] **Step 2:** Run. Expected: compile FAIL.
- [ ] **Step 3:** Implement state and view (drag gesture from dragon draws dotted trajectory; fireball uses `activeDragon.element.themeColor`).
- [ ] **Step 4:** Run tests; launch `-route fireTarget`, play, screenshot. Expected: pass; aiming and hits work.
- [ ] **Step 5:** Commit: `"Add Fire Target aiming training game"`.

---

### Task 12: Sky Flight

**Files:**
- Create: `Tiny Dragon Academy/Training/Games/SkyFlightGameState.swift`
- Create: `Tiny Dragon Academy/Views/Training/SkyFlightView.swift`
- Test: `Tiny Dragon AcademyTests/SkyFlightGameStateTests.swift`

**Interfaces:**
- Produces: `struct SkyFlightGameState { init(seed: UInt64); var dragonY: Double; var velocityY: Double; var pillars: [CloudPillar]; var gems: [CGPoint]; var score: Int; var isOver: Bool; mutating func step(dt: Double, input: FlapInput) }`, `struct FlapInput { var flap: Bool }`, `struct CloudPillar { var x: Double; var gapCenter: Double; var gapHeight: Double; var passed: Bool }`. Gravity −1.8/s², flap sets velocityY = +0.7, scroll 0.35/s, gap height starts 0.38 and shrinks 0.01 per pillar to a floor of 0.24. +1 per pillar passed, +2 per gem. Leaving the top/bottom or touching a pillar ends the run.

- [ ] **Step 1: Write failing tests:**

```swift
func test_gravityPullsDown_flapPushesUp()
func test_passingPillar_scoresOnce()
func test_gapShrinks_toFloor()
func test_hitPillarOrGround_endsRun()
func test_gemPickup_addsTwo()
```

- [ ] **Step 2:** Run. Expected: compile FAIL.
- [ ] **Step 3:** Implement state and view.
- [ ] **Step 4:** Run tests; launch `-route skyFlight`, play, screenshot. Expected: pass.
- [ ] **Step 5:** Commit: `"Add Sky Flight agility training game"`.

---

### Task 13: Catch the Snacks

**Files:**
- Create: `Tiny Dragon Academy/Training/Games/SnackCatchGameState.swift`
- Create: `Tiny Dragon Academy/Views/Training/SnackCatchView.swift`
- Test: `Tiny Dragon AcademyTests/SnackCatchGameStateTests.swift`

**Interfaces:**
- Produces: `struct SnackCatchGameState { init(seed: UInt64); var timeRemaining: Double /* 60 */; var lives: Int /* 3 */; var dragonX: Double; var items: [FallingItem]; var score: Int; var caught: [FoodType]; var isOver: Bool; mutating func step(dt: Double, input: CatchInput) }`, `struct CatchInput { var targetX: Double? }` (dragon moves toward targetX at max 1.5 units/s), `struct FallingItem { enum Kind { case food(FoodType), storm }; var kind; var x: Double; var y: Double; var speed: Double }`. Catch radius 0.08; food +1 score and appended to `caught`; storm −1 life; ends at 0 lives or 0 time. The view passes `caught` to `finishTraining`, which keeps the first 5.

- [ ] **Step 1: Write failing tests:**

```swift
func test_catchFood_addsScoreAndCaught()
func test_storm_costsLife_threeStormsEnd()
func test_roundEndsAt60Seconds()
func test_dragonMoveSpeedCapped()
```

- [ ] **Step 2:** Run. Expected: compile FAIL.
- [ ] **Step 3:** Implement state and view (food icons use `FoodType.icon`/`primaryColor`).
- [ ] **Step 4:** Run tests; launch `-route snackCatch`, play, screenshot. Expected: pass.
- [ ] **Step 5:** Commit: `"Add Catch the Snacks reflex training game"`.

---

### Task 14: Training Hub, Den, Incubator and main menu

**Files:**
- Create: `Tiny Dragon Academy/Views/Training/TrainingHubView.swift`
- Create: `Tiny Dragon Academy/Views/Den/DenView.swift`
- Create: `Tiny Dragon Academy/Views/Den/DragonMetersView.swift` (five meters, reused by Playground)
- Create: `Tiny Dragon Academy/Views/Incubator/IncubatorView.swift`
- Create: `Tiny Dragon Academy/Views/Incubator/HatchRevealView.swift`
- Modify: `Tiny Dragon Academy/Views/Home/MainMenuView.swift`
- Modify: `Tiny Dragon Academy/Views/MiniGames/MiniGamesHubView.swift` (title "Learning Games")
- Modify: `Tiny Dragon Academy/ContentView.swift` (route cases)

**Interfaces:**
- Consumes: `GameManager` APIs from Tasks 8–9.
- Produces: `DragonMetersView(stats: DragonStats, compact: Bool)`; status badge helper `DragonStatusBadge(stats:now:)` returning "Hungry" (hunger < 30), "Sick: {illness}", "Asleep", "Spirit {hh:mm left}", or nothing.

- [ ] **Step 1:** Implement `TrainingHubView` (four cards: icon, name, trains label, personal best, "15 ⚡", disabled with reason when `!canTrain`), `DenView` (slot cards per spec §6, empty slot → "Hatch an egg" to incubator, buy-slot button using `purchaseDenSlot`, denied-reminders banner), `IncubatorView` (slots with warmth bar + progress ring, tap = `warmEgg`, "Ready!" → `crackEgg` → `HatchRevealView` with name field → `nameHatched`; Egg Basket list with Place buttons; buy slot 2), main menu primary tiles Den / Train / Incubator.
- [ ] **Step 2:** Build and run all tests. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 3:** In the simulator launch with `-route den`, `-route trainingHub`, `-route incubator`, `-route mainMenu`; screenshot each. Expected: screens render with real state; warming an egg raises warmth; with `-timeScale 3600` an egg reaches Ready within seconds and can be hatched and named.
- [ ] **Step 4:** Commit: `"Add Den, Training Hub, Incubator screens and new main menu tiles"`.

---

### Task 15: Playground, Shop, Collection, Hall of Legends, away report, reminders

**Files:**
- Modify: `Tiny Dragon Academy/Views/Playground/DragonPlaygroundView.swift`
- Modify: `Tiny Dragon Academy/Views/Playground/FoodInventoryView.swift` (shop)
- Modify: `Tiny Dragon Academy/Views/Dragons/DragonCollectionView.swift`
- Modify: `Tiny Dragon Academy/Views/Settings/SettingsView.swift`
- Create: `Tiny Dragon Academy/Views/Legends/HallOfLegendsView.swift`
- Create: `Tiny Dragon Academy/Views/Away/AwayReportSheet.swift`
- Create: `Tiny Dragon Academy/Views/Reminders/ReminderPrimerView.swift`

**Interfaces:**
- Consumes: `GameManager` APIs (Task 8), `DragonMetersView`, `DragonStatusBadge` (Task 14), `NotificationPlanner.body(for:name:)` for event wording in the away report.

- [ ] **Step 1:** Playground: `DragonMetersView`; illness badge + "Cure (Healing Herb ×n)"; Lights out / Wake up; night overlay when asleep; spirit state (dragon at 0.4 opacity with a ghost tint, countdown, "Revive (Phoenix Ember ×n)" and "Buy Ember 60★"); feeding, powers and evolution disabled with a one-line reason when refused (use `FeedOutcome`).
- [ ] **Step 2:** Shop: a "Care" section (Herb, Ember), an "Eggs" section (three tiers), and an "Upgrades" section (incubator slot 2, den slots 4–5) with prices from Global Constraints.
- [ ] **Step 3:** Collection: tabs Den / Sanctuary / Hall of Legends / Undiscovered; move buttons call `moveToSanctuary`/`moveToDen` and show why a move was refused; remove the old star-unlock sheet. `HallOfLegendsView` lists memorials (name, species, stage, level, lived dates).
- [ ] **Step 4:** `AwayReportSheet` presented from `ContentView` when `awayReport` is non-empty (plus `dailyBonus`); `ReminderPrimerView` shown once after the first hatch or, for migrated saves, on first launch (`hasSeenReminderPrimer`), then calls `requestAuthorization`; Settings gets a "Care reminders" toggle bound to `remindersEnabled` (rescheduling on change).
- [ ] **Step 5:** Run all tests and build. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 6:** Commit: `"Extend Playground, Shop and Collection; add Hall of Legends, away report and reminders"`.

---

### Task 16: End-to-end verification

**Files:**
- Modify: `Tiny Dragon Academy/Tests/GameLogicTests.swift` (only if smoke tests fail)

- [ ] **Step 1:** Run the full test suite. Expected: `** TEST SUCCEEDED **`, and the DEBUG launch smoke suite prints `✅ [SMOKE TEST] All feature tests passed successfully.`
- [ ] **Step 2:** Install a pre-update save: build `main` (stash this branch's build), launch once, unlock Ember via the old flow, quit; then install this branch. Expected: den shows Sparkle + Ember, basket has the welcome Common egg, reminder primer appears.
- [ ] **Step 3:** Launch with `-timeScale 3600` (1s = 1h) and do nothing for ~90s. Expected: hungry → starving → Hunger Fever → spirit; the away/hub screens reflect each stage; revive with a purchased Ember drops one stage. Then let a spirit expire: Hall of Legends entry + same-species egg.
- [ ] **Step 4:** Notifications: allow reminders, background the app with `-timeScale 60`, confirm a hungry notification arrives and tapping it opens that dragon's Playground.
- [ ] **Step 5:** Play each training game once. Expected: rewards apply, personal bests saved, Catch the Snacks adds ≤5 foods.
- [ ] **Step 6:** Commit any fixes: `"Fix issues found in end-to-end verification"`.
