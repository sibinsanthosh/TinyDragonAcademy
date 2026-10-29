# Toy Clay UI Redesign — Design

**Date:** 2026-10-29
**Branch:** `feature/dragon-life-sim`
**Status:** Approved in chat (direction G "Toy Clay", parts 1–3), "build all"

## Why

The app reads as generated: one pastel sky gradient and white capsule card recipe on every
screen, the same heavy rounded system font in 234 places, emoji used as game art, a tile-grid
menu, wordy screens and low-contrast pastel text. Goal: a polished mobile-game look that works
for kids and adults.

## Direction: Toy Clay

Soft 3D, toy-like surfaces (Animal Crossing / Toca Boca feel). Reference mockup:
`style-directions-2.html` option G.

### Tokens (`Theme/DragonPalette.swift`, `Theme/ClayTheme.swift`)

| Token | Value | Use |
|---|---|---|
| backdrop | pink `#FFD9E4` → sky `#D7ECFF` vertical, with two soft blobs (`#FFC2D3`, `#C8E9FF`) | every non-game screen (`ClayBackdrop`) |
| surface | `#FFFFFF` | cards, pills, tab bar |
| ink | plum `#4A3557` | primary text |
| inkSoft | `#8A7299` | secondary text (never lighter on white) |
| accent | purple `#8A6CFF`, shade `#6B4FE0` | primary buttons, selected tab |
| sun / coral / mint / sky / rose | `#FFC93C` / `#FF8A5C` / `#5FD08A` / `#4AB8FF` / `#FF6FA0` | meters, game themes, icons |
| shadow | plum at 16% | clay drop shadow |

Existing `DragonPalette` names are re-pointed to these values so untouched screens shift too.
`textDark` = ink, `textMuted` = inkSoft, `skyGradient` = clay backdrop gradient.

### Type

Baloo 2 (variable TTF, SIL OFL, bundled with its licence) registered at launch with
`CTFontManagerRegisterFontsForURL`. `Font.clay(_ size:, _ weight:)` returns Baloo 2 at that
weight, falling back to SF Rounded if registration failed. Every `.system(… design: .rounded)`
call becomes `.clay(…)`.

### Clay components (`Components/Clay/`)

- `ClayBackdrop` — gradient plus blobs, ignores safe area.
- `.claySurface(cornerRadius:)` — white fill, inner bottom shade (inset 5pt, 6% black), soft
  plum shadow (radius 14, y 6). `kidCard` maps to it.
- `ClayButtonStyle(color:, shade:)` — puffy fill, inner bottom shade, top highlight, squish to
  0.94 on press with a light haptic. `KidButton` renders with it.
- `ClayPill` — icon + Baloo number on a clay surface; bumps when the value changes.
- `ClayIconButton` — round clay button with an SF Symbol (back, close, gear, care actions).
- `ClayMeter` — inset white track (inner shadow) with a rounded coloured fill.
- `ClayTabBar` — floating rounded white bar, 5 tabs, selected tab in accent.
- `ClaySheet` container — rounded-top clay panel for sheets/pop-ups.
- `ClayToast` — clay pop-up that bounces in from the top.

### Navigation

`AppTab` (pure): `home, train, eggs, dragons, shop`, each with title and icon.
`AppTab.forRoute(_:)` maps routes to tabs: home ← mainMenu, dragonPlayground, den;
train ← trainingHub, miniGamesHub; eggs ← incubator; dragons ← dragonCollection,
hallOfLegends; shop ← foodInventoryShop. Other routes return nil and are full-screen.
`AppTab.root` is the route a tab opens. The tab bar shows only when the current route has a tab.
On tab-root screens the top bar shows no back button.

### Home

`.mainMenu` and `.dragonPlayground` both show the Home (the playground restyled):
top clay pills (stars, streak) and a gear (Settings, parent-gated as today); the dragon on a
clay platform with name, level, three `ClayMeter`s and the wish bubble; with 2–3 den dragons,
left/right chevrons switch the active dragon; a Today card (quests done of total, progress bar)
opening Today; a care dock of round clay buttons (Feed opens the food tray, Pet, Power, Sleep);
status (sick/cure, tummy ache) as one clay badge; a large purple Train button. Powers book,
achievements and dress-up open from small clay icon buttons on the dragon card. With no den
dragon, Home shows an empty state that sends you to Eggs.
`.den` stays reachable (Dragons tab) and is restyled.

### Games and art

- Clay HUD: white clay strip with timer / score / combo pills and a round close button.
- Per-game clay scenes: Dash hills (two parallax layers), Fire Target meadow, Sky Flight
  clouds, Snack Catch picnic; rounded ground strips.
- Drawn clay art replaces emoji: target board, balloon, shield dummy, burst, gem, storm cloud,
  rock, cactus, bat, food token. Shapes use a light-top / dark-bottom radial fill.
- Start card: clay sheet with dragon, Baloo title, skill stars, talent chip, one Start button.
- Results: score counts up; reward rows pop in one by one; confetti on a new best or a gained
  skill star; Play again (primary) and Done (secondary).

### Other screens

Train tab = training games plus a Learn row (the four learning games). Eggs, Dragons (with
skills sheet, legends), Today, Shop (with Dress-Up and Island entries), Settings, away report,
reminder primer, toasts, onboarding, learning games and their victory modal, Dress-Up,
Island, Powers, Achievements, Evolution: all move onto clay surfaces, Baloo type and clay
buttons; emoji used as art is replaced; long sentences shortened.

### Motion

Spring transitions; squish on every clay button; pills bump on change; confetti on
celebrations. With reduce motion (system or in-app) everything becomes a fade.

## Non-goals

No game-rule changes. No new currencies (the mockup's gems are not added). No dark mode for
now (the app forces its own palette).

## Testing

- All existing logic tests keep passing.
- New tests: `AppTab` mapping and roots; font registration resolves "Baloo 2"; confetti and
  count-up helpers if they hold logic.
- Simulator screenshots of every wave on iPhone 17 and iPhone SE (3rd gen) size.
