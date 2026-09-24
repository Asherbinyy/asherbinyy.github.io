# 2026-09-24-02 — The owner's review of the work-of-art branch, then merge

**Agent:** Claude / Opus 5.5
**Milestone:** Re-innovation, full ownership
**Started from:** `cf17fa7` (feat/work-of-art)

## Goal

The owner's localhost review: four annotated screenshots, an Anubis scan, the Mokaf Figma file, a Snunu screen recording, and "remove the yap" from the game. Then merge and push.

## What changed

- **Intro:** Anubis (the recumbent jackal of Tutankhamun's shrine, owner-supplied `ah-2.stl`, 1.38M → 22.5k triangles) on the right pedestal in black stone; Ra-Horakhty is no longer loaded.
- **Skills:** titles in two lines at their natural widths (the owner asked not to box them to one size); pressing the open title closes it; a swipeable single row on a phone.
- **Stops:** a timeline — years above a line, a marker that says what each stop was (cap, briefcase, laptop), names below; scrolls sideways on a phone. The meaningless cartouche pill is gone.
- **Career cards:** the first sentence of each story only.
- **Phone:** hero figures as one compact card of three rows; Email and WhatsApp side by side; profiles as icon-only tiles (named by tooltip and screen reader); the booking card is a title and a calendar.
- **Booking:** a calendar mark replaces the shadow clock the owner read as a scale.
- **About:** the Courtyard door shows the game climbing by itself (a practice run with the vectors' autopilot, only while visible, still under reduced motion) beside the words and interests; the contact panel has a falcon carrying a letter between two seals on its right.
- **Game copy:** no level count in the legend or the win screen.
- **Mokaf:** three screens cropped from the owner's Figma via its public embed. **Snunu:** four frames from the owner's Drive recording, plus a gallery link to the recording.

## Files touched

- `web/intro/{intro.js,models/anubis.kmsh,models/LICENSE.md}`
- `lib/core/widgets/skill_groups.dart`, `lib/features/station/presentation/widgets/{career_stops,career_sequence,hero_content}.dart`
- `lib/features/about/presentation/{about_screen,widgets/courtyard_door,widgets/contact_links}.dart`; created `widgets/live_climb.dart`, `widgets/falcon_courier.dart`
- `lib/app/theme/tokens.dart`, `lib/app/l10n/app_{en,ar}.arb`, `assets/content/apps.json`, `pubspec.yaml`, `assets/media/apps/{mokaf,snunu}/`
- `docs/14-PROVENANCE.md`, tests as below

## Decisions made

- Skill titles: natural widths split into two `Wrap` lines, after the owner rejected equal fixed widths.
- Icon-only profile tiles on a phone; LinkedIn keeps the generic link mark (no brand mark in the icon set).
- The live climb reuses the generator's autopilot rather than a canned animation, so it is the real game.
- Removed tokens: `skillTitleWidth`, `bookingClockSize`, `bookingClockSweep`. Added: `stopItemWidth`, `stopNodeSize`, `stopNodeLift`, `compactStatFigure`, `contactCompactDirect`, `contactCompactTile`, `bookingIconSize`, `courier*`, `doorClimb*`, `liveClimbRestart`.

## Tests

- Added: "pressing the open title again closes it".
- Goldens: the Journey selected-stop golden regenerated after review (app names under the map follow the content).
- Full suite: pass, 845 passing, 0 failing. Worker: 328 passing.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — 355 files, 0 changed
fvm flutter analyze                        pass — No issues found
fvm flutter test --coverage                pass — 845 passed, 0 failed
fvm flutter build web --wasm               pass — Built build/web
cd worker && node --test test/*.test.js    pass — 328 passed
```

Browser: Home and About at 1440×900 and 390×844, and the intro.

## Known issues left open

- **Anubis author and licence** still to be named by the owner (see `web/intro/models/LICENSE.md`).
- The intermittent `Exception` on /about in the headless browser, most likely a relay request refused from localhost; not reproduced on demand.
- Services list is English on the Arabic site (content schema).

## Next

Watch the deploy of `main`, then play a ranked climb on sherbini.uk to confirm the v3 Worker verifies it.
