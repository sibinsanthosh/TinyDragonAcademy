# Daily Habit (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Care Mode, daily quests, care streak with Streak Shield, dragon wishes and shiny hatches.

**Architecture:** A new pure `DailyRules` module (quests, wishes, streak) driven by `PlayerAction`s that `GameManager` records; `LifeSimulator` and `NotificationPlanner` take a `CareMode`. All rules tested with `TestTime.utc` and seeded RNG, then wired into SwiftUI screens.

**Tech Stack:** Swift 5 mode, SwiftUI, XCTest (existing target).

**Spec:** `docs/superpowers/specs/2026-10-27-daily-habit-design.md`

## Global Constraints

- All numbers from spec §3–§7 live as constants in `DailyRules` / `LifeRules`.
- Game day starts at 07:00 (`LifeRules.wakeHour`).
- New persisted fields decode with `decodeIfPresent` defaults; old saves keep loading.
- Seeds must be stable across launches (FNV-1a over UTF-8, never `hashValue`).
- Commit identity: `-c user.name="Sibin Santhosh" -c user.email="sibaatta@gmail.com"`, trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Test command: the existing `xcodebuild test … -only-testing:"Tiny Dragon AcademyTests/<Suite>"`.

## Review Focus

1. **Multi-day absence across a streak:** shields consumed one per missed day, streak reset once shields run out, rewards not double-granted. Test: `DailyRulesTests.test_rollover_gapUsesShieldsThenResets`.
2. **Illness during offline catch-up credited to the right day.** Test: `GameManagerDailyTests.test_illnessDuringAbsence_creditedToItsDay`.
3. **Gentle dragon never dies, even over 7 days of neglect.** Test: `LifeSimulatorTests.test_gentle_neverDies`.
4. **Quest list stable for the whole day** (re-opening the app doesn't reroll). Test: `DailyRulesTests.test_quests_stableForSameDay`.
5. **All-clear and milestone rewards granted exactly once.** Tests: `test_allClear_rewardedOnce`, `test_milestone_rewardedOnce`.

---

### Task 1: Models & game day
**Files:** Create `Models/DailyModels.swift`; modify `Models/ProgressionModel.swift`, `Models/DragonModel.swift`, `Models/LifeModels.swift` (Memorial, LifeRules). Test `DailyModelTests.swift`.
**Produces:** `CareMode`, `GameDay.id(for:calendar:)`, `GameDay.daysBetween(_:_:calendar:)`, `QuestKind`, `DailyQuest`, `WishKind`, `DragonWish`, `DailyState`, `StreakDayResult`, `StreakDay`, `StreakState`, `PlayerAction`, `StableHash.fnv1a(_:)`; `AppProgressState.careMode/daily/streak`; `DragonModel.isShiny`, `badgedName`; `Memorial.isShiny`; `LifeRules.gentleHealthFloor = 10`.
- [ ] Tests: game day before/after 07:00, daysBetween across month end, legacy decode defaults, round-trip of new fields, FNV-1a known value.
- [ ] Implement, run, commit "Add daily-habit data model".

### Task 2: Gentle mode rules
**Files:** `Life/LifeSimulator.swift`, `Views/Den/DragonStatusBadge.swift`, `Notifications/NotificationPlanner.swift`. Tests in `LifeSimulatorTests`, `DragonStatusTests`, `NotificationPlannerTests`.
**Produces:** `advance(..., mode: CareMode = .classic)`, `predict(..., mode:)`; `DragonStatus.describe(_:now:calendar:mode:)`; planner reads `state.careMode`, `body(for:name:mode:)`.
- [ ] Tests: `test_gentle_neverDies` (7 days neglect → health 10, healthy or ill, never spirit), deep-sleep badge, gentle planner has no died/lastChance, ≤3 per game day, gentle copy.
- [ ] Implement, run, commit.

### Task 3: Quests & wishes
**Files:** `Life/DailyRules.swift`; tests `DailyRulesTests.swift`.
**Produces:** `QuestContext`, `DailyRules.quests(for:mode:context:)`, `DailyRules.wish(for:dayId:)`, `DailyRules.record(_:daily:) -> DailyOutcome { completedQuests, allClearedNow, grantedWishDragonIds }`, constants (`questReward = 5`, `allClearStars = 10`, wish rewards).
- [ ] Tests: 3 distinct quests, stable for same day, context filtering (no warm without egg, no score in Gentle), progress/complete once, allClear once, wish deterministic, wish granted by matching action only, pet wish needs 3, caredToday set by feed/train only.
- [ ] Implement, run, commit.

### Task 4: Streak rollover
**Files:** `Life/DailyRules.swift`; tests in `DailyRulesTests`.
**Produces:** `DailyRules.rollover(streak:previous:toDayId:calendar:) -> [StreakReward]`, `StreakReward { stars(Int), shield, egg(EggTier) }`.
- [ ] Tests: counted day increments, illness day breaks, gap uses shields then resets, shield cap 2, milestones 3/7/14/30/60 once, recent capped at 14, same-day no-op.
- [ ] Implement, run, commit.

### Task 5: Shiny
**Files:** `Life/EggHatcher.swift`, `Models/ShinyPalette.swift`, `Life/DenRules.swift` (expire resets), `ViewModels/GameManager+Life.swift` (crackEgg, XP). Tests in `EggHatcherTests`, `DenRulesTests`, `GameManagerDailyTests`.
- [ ] Tests: rollShiny threshold with FixedRNG, palette exists for every element, expire keeps memorial shiny and resets colors, crackEgg with forced shiny sets flag/colors, +10% XP on feed.
- [ ] Implement, run, commit.

### Task 6: GameManager integration
**Files:** `ViewModels/GameManager+Daily.swift`, `ViewModels/GameManager+Life.swift`, `ViewModels/GameManager.swift`. Tests `GameManagerDailyTests.swift`.
**Produces:** `refreshDay()`, `record(_:)`, `@Published toast`, `setCareMode(_:)`, `completeOnboarding(starterDragonName:careMode:)`, illness-day attribution via `LifeSimulator.advanceTimed`.
- [ ] Tests: rollover on new day gives fresh quests; feeding records quest + caredToday; wish grant applies rewards; streak milestone reward applied; illness credited to its day; gentle mode passes to simulator; toast set on quest complete.
- [ ] Implement, run, commit.

### Task 7: Screens
**Files:** `Views/Today/TodayView.swift`, main menu, Playground wish bubble, onboarding step, Settings picker, HatchRevealView, Den/Collection badges, DragonView sparkle, ContentView toast + route.
- [ ] Build, run all tests, simulator screenshots of Today, onboarding step, wish bubble, shiny reveal; commit.

### Task 8: Final review & fixes
- [ ] Fresh reviewer over the phase-1 range; fix Critical/Important with tests; commit.
