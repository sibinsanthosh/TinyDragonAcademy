# Photo Booth, Dragon Nest and Widgets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shareable dragon postcard booth, breeding of adult dragons into hybrid eggs, and home/lock-screen widgets.

**Architecture:** Pure rule types (`PostcardContent`, `BreedingRules`, `WidgetSnapshotBuilder`) carry the logic and tests; SwiftUI views stay thin; the widget reads a snapshot timeline the app writes to an App Group.

**Tech Stack:** SwiftUI, ImageRenderer, WidgetKit, App Groups, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-30-booth-nest-widgets-design.md`

## Global Constraints

- iOS 17.6 for app and widget; no new dependencies; old saves decode (all new fields optional).
- Sharing goes through the parent gate; nothing leaves the device otherwise.

## Review Focus

1. A hybrid egg whose both species are alive must give stars, not duplicate a dragon.
2. Resting parents and sick/spirit dragons can't be paired, including by tapping fast twice.
3. The widget must show something sensible with no den dragon and with a stale snapshot.
4. Widget reloads must not fire on every 30s tick.
5. Postcard export must not include the tab bar or controls.

---

### Task 1: Photo booth
`Models/Postcard.swift` (PostcardFrame, PostcardPose, PostcardContent) + tests; `Views/PhotoBooth/PhotoBoothView.swift`, `PostcardView.swift`, `ActivityView.swift`; route `.photoBooth`; camera button on Home; Info.plist key.

### Task 2: Breeding rules and hatching
`Life/BreedingRules.swift`, `Egg.lineage`/computed properties, `DragonStats.lastBredAt`, `ColorHex.blend`, `EggHatcher` hybrid roll, `GameManager.breed` and hybrid hatch finish + tests.

### Task 3: Dragon Nest UI
Nest card on the Eggs tab.

### Task 4: Widget data
`Shared/WidgetSnapshot.swift`, `WidgetSnapshotBuilder` + tests, `WidgetBridge` hooked after save.

### Task 5: Widget extension
Target, entitlements, provider and views; build for the simulator.
