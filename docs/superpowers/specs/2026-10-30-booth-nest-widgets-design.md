# Photo Booth, Dragon Nest (Breeding) and Widgets — Design

**Date:** 2026-10-30
**Branch:** `feature/dragon-life-sim`
**Status:** Approved in chat (photo booth "postcard + share", breeding "two adults, 3-day rest" with
"parent species + mixed look", widgets "home screen + lock screen", no Live Activity)

## 1. Photo booth

- New full-screen route `.photoBooth` (no tab bar), opened from a camera button on Home's dragon card.
- `PostcardFrame`: classic, starry, garden, party (each: background colours and a decoration).
- `PostcardPose`: happy, cheeky, sleepy, power → `DragonMood` happy, celebration, sleepy, castingPower.
- Background toggle: the frame's own scene or the player's island theme colours.
- `PostcardContent(dragon:)` (pure): title (badged name), subtitle ("Lvl N · Stage"), talent title, best
  skill (highest stars, ties in `DragonSkill.allCases` order) with its stars, shiny flag.
- Card: 360×450pt design rendered with `ImageRenderer` at scale 3 → 1080×1350 image.
- Save to Photos: `UIImageWriteToSavedPhotosAlbum`; Info.plist gets `NSPhotoLibraryAddUsageDescription`
  ("Save your dragon postcards to your photos."). Result shown as a toast.
- Share: behind the existing `ParentGateView`; on success presents `UIActivityViewController` with the image.

## 2. Dragon Nest (breeding)

- `BreedingRules` (pure): `price = 50`, `restDays = 3`, `hybridHatchDuration = 6h`.
  - `refusal(_ a:, _ b:, stars:, now:) -> BreedingRefusal?`: same dragon, either not Adult/Ancient, either
    not in den or sanctuary, either a spirit or ill, either resting (`lastBredAt + 3 days > now`),
    not enough stars. `nil` means they can pair.
  - `restUntil(_ dragon) -> Date?`.
  - `makeEgg(_ a, _ b) -> Egg`: tier `.rare`, `lineage = HybridLineage(parentA, parentB)`.
- `Egg.lineage: HybridLineage?` (`parentA`, `parentB` species ids and their colour hexes at pairing time);
  `Egg.hatchDuration` (6h for hybrids, else tier), `Egg.displayName` ("Hybrid egg"), `Egg.shellColor`.
  Every `egg.tier.hatchDuration/displayName/shellColor` use moves to the `Egg` properties.
- `DragonStats.lastBredAt: Date?` (decodeIfPresent); a new life resets it.
- `GameManager.breed(_ a:, _ b:) -> BreedingRefusal?`: spends 50★, stamps both parents, adds the egg to
  the basket, saves.
- Hatching (`EggHatcher.roll`): a hybrid picks parent A or B 50/50; if that species is alive (den or
  sanctuary) it takes the other; if both are alive → `.stars(EggTier.rare.duplicateStars)`.
- After a hybrid hatch (`GameManager.crackEgg`): colours = hatched species' defaults blended 60/40 with the
  other parent's saved colours (`ColorHex.blend(_:_:t:)`, per channel, rounded); skill bonus = 10 points in
  the other parent's best skill (= +1 star from base, capped at 5 by existing rules). Shiny roll still
  applies and wins over the blend.
- UI: "Dragon Nest" card on the Eggs tab — two parent pickers (menus of den + sanctuary dragons with
  their stage), a blended colour preview, the refusal reason in plain words, and a "Pair · 50★" button.

## 3. Widgets

- New widget extension target "Tiny Dragon Widget" (iOS 17.6), embedded in the app; App Group
  `group.sibaatta.com.Tiny-Dragon-Academy` on both targets.
- `Shared/WidgetSnapshot.swift` (compiled into both targets): `WidgetSnapshot { entries: [Entry], updatedAt }`,
  `Entry { date, name, element colour hexes, stageTitle, mood (happy/hungry/sick/asleep/spirit/empty),
  hunger, energy, health }`; `WidgetStore.read()/write()` via the App Group container
  (`UserDefaults(suiteName:)`, key `widgetSnapshot`, JSON).
- App side `WidgetBridge.publish(state:, now:, calendar:)`: builds entries every 30 min for 12 h by running
  `LifeSimulator.advance` on the active den dragon (or one `empty` entry), writes them, and calls
  `WidgetCenter.shared.reloadAllTimelines()` only when the first entry's rounded values changed.
  Called after `save()`.
- `WidgetSnapshotBuilder` (pure, in the app): the projection, mood choice and change detection — tested.
- Widget: `TimelineProvider` returns the stored entries (reload after the last one); views:
  small (face + mood word), medium (face + three clay meters + hint), accessoryCircular (hunger ring +
  dragon glyph), accessoryInline ("Sparkle · Happy"). Tap opens the app (`widgetURL` "tinydragon://home").
  The face is a simple drawn clay dragon head from the snapshot colours.

## Testing

- PostcardContent; BreedingRules (each refusal, rest window); hybrid roll (A/B/both alive); colour blend;
  skill bonus cap; Egg decode without lineage; GameManager.breed (stars, stamps, basket);
  WidgetSnapshotBuilder (entry count/spacing, projection lowers hunger, moods, empty den, change detection).
- Simulator: booth renders and shares; Nest pairs and a hybrid hatches; widget gallery renders.
