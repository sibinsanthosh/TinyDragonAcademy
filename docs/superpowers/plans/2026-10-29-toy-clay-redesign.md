# Toy Clay Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every screen onto a Toy Clay design system with tab navigation, a dragon-first Home and drawn game art.

**Architecture:** Tokens and Baloo 2 font in `Theme/`; reusable clay components in `Components/Clay/`; a pure `AppTab` model drives a floating tab bar from `ContentView`; existing screens are restyled in place, shared pieces (`KidButton`, `kidCard`, `ScreenTopBar`, `StarCounterView`, `DragonPalette`) are upgraded so untouched code shifts too.

**Tech Stack:** SwiftUI, CoreText font registration, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-29-toy-clay-redesign-design.md`

## Global Constraints

- iOS 17.6; no new dependencies; Baloo 2 bundled with `OFL.txt`.
- Game logic and saved data unchanged; all existing tests stay green.
- Text on white uses ink or inkSoft only; no pastel text on white.
- Reduce motion (system or `state.settings.reduceMotion`) turns animations into fades.

## Review Focus

1. Tab bar must not cover game controls, sheets or the food tray.
2. Every route still reachable (Today, Powers, Achievements, Dress-Up, Island, Legends, Den, Settings).
3. Small screens (iPhone SE) must not clip Home or the start/results cards.
4. Font fallback works if registration fails (no invisible text).
5. Parent gate still guards Settings.

---

### Wave 1

**Task 1 — Theme and font.** Add `Resources/Fonts/Baloo2.ttf` + `OFL.txt`; `Theme/ClayTheme.swift` with `FontRegistry.registerBundledFonts()` (called from the app init), `Font.clay(_:_:)`, `ClayColor` tokens; re-point `DragonPalette`; replace all `.system(size:…, design: .rounded)` with `.clay(…)`. Test: `FontRegistryTests.test_baloo2_isRegistered`.

**Task 2 — Clay components.** `ClayBackdrop`, `.claySurface`, `ClayButtonStyle`, `ClayPill`, `ClayIconButton`, `ClayMeter`, `ClaySheet`, `ClayToast`; `KidButton`, `kidCard`, `StarCounterView`, `ScreenTopBar` rebuilt on them; every `skyGradient` background becomes `ClayBackdrop`.

**Task 3 — Navigation.** `Models/AppTab.swift` (pure) + `AppTabTests`; `ClayTabBar` overlaid in `ContentView` for tab routes; `.dragonPlayground` aliases Home; top bar hides back on tab roots.

**Task 4 — Home.** Restyle `DragonPlaygroundView` into Home (pills, dragon card, den switcher, Today card, care dock, Train button); empty-den Home; `MainMenuView` retired from routing.

### Wave 2

**Task 5 — Clay art kit.** `Components/Clay/ClayArt.swift`: target, balloon, shield dummy, burst, gem, storm cloud, rock, cactus, bat, food token.

**Task 6 — Games.** Clay HUD, scenes and art in the four games; start card and results card rebuilt with count-up, staggered rows and confetti (`ConfettiView`).

### Wave 3

**Task 7 — Tab screens and sheets.** Train hub + Learn row; Eggs (incubator, hatch reveal); Dragons (collection, skills sheet, legends, den); Today; Shop (+ Dress-Up and Island entries); Settings; away report, reminder primer, toasts.

### Wave 4

**Task 8 — Remaining screens.** Onboarding, learning games and victory modal, Dress-Up, Island, Powers, Achievements, Evolution, parent gate.

### Finish

Full test suite; simulator screenshot pass (iPhone 17 + SE) of every tab and game; whole-branch review; fixes; push.
