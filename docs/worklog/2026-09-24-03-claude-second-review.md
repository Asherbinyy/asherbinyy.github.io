# 2026-09-24-03 — The owner's second review: intro light, Courtyard, About, phone

**Agent:** Claude / Opus 5.5
**Milestone:** Re-innovation, full ownership
**Started from:** `929aa35` (feat/work-of-art, PR #53)

## Goal

The owner's second round of review (three annotated screenshots and a list): intro, About, Courtyard, career cards, and a phone audit with centred content. Then merge PR #53 and launch.

## What changed

- **Intro** (`web/intro/intro.js`): the gold staves, their floor strike, flash rings and camera shake are gone. A bronze brazier stands at the front of each pedestal on the doorway's side (three legs, gilt bowl, additive flame and core, a canvas-gradient halo, a warm `PointLight`). The flames flicker while the door waits and flare as it opens, which is now the opening's first beat. The basalt is polished a little (colour `0x2a2e38`, roughness 0.4, metalness 0.15) so the light runs along the carving. "Knock to enter" is kept.
- **Career cards** (`career_sequence.dart`): the timeline band is replaced by a duration badge (for example "2 yrs 3 mos", or "Now" for an ongoing role), computed from the role's dates. New l10n `careerNow`, `careerYears`, `careerMonths` (EN and AR plurals).
- **Courtyard** (`courtyard_screen.dart`, new `core/widgets/gold_edge.dart`): the still is replaced by `LiveClimb` (under the words on a phone). A `GoldEdge` runs an arc of gold light round the panel, and is a still gold hairline under reduced motion. New line `courtyardShoutout`. Off duty tiles rise in with a 70 ms stagger (`interests_grid.dart`).
- **About:**
  - `SkillGroups` moved out of the column beside the portrait to full width below it, as on Home.
  - The ankh caption and its string are removed.
  - `CourtyardDoor` is now stateless, with no interest scenes and a smaller climb (240×220) inset 48 from the panel edge.
  - Contact is `Expanded(flex 2)` links plus `Expanded(flex 1)` with the falcon centred and scaled down to fit.
  - The Fiverr tile is removed.
  - The portrait and route buttons are centred on a phone.
- **Phone:**
  - `StationScreen` no longer reserves a trailing strip for the wall. `TelemetryTrace` paints the whole width at `wallPatternOpacity` on every viewport.
  - `wallTorchTouchPeak` 0.85 → 0.3, so the scroll-carried light glows behind the words instead of flaring over them.
  - Services show two to a row on a phone, with the icon and label centred.

## Files touched

- `web/intro/intro.js`, `web/index.html` (comment) — modified
- `lib/core/widgets/gold_edge.dart` — created
- `lib/features/courtyard/presentation/courtyard_screen.dart`, `lib/features/about/presentation/{about_screen,widgets/courtyard_door,widgets/contact_links,widgets/interests_grid,widgets/life_flow}.dart` — modified
- `lib/features/station/presentation/{station_screen,widgets/career_sequence}.dart`, `lib/features/trace/presentation/telemetry_trace.dart`, `lib/features/services/presentation/services_screen.dart` — modified
- `lib/app/theme/tokens.dart`, `lib/app/l10n/app_{en,ar}.arb` — modified
- `test/widget/{trace/trace_test,courtyard/courtyard_test,about/life_flow_test}.dart`, `test/golden/goldens/chrome_compact_*.png` — modified
- `docs/14-PROVENANCE.md`, `CHANGELOG.md` — modified

## Decisions made

- **"The slogan that hitting the floor"** was read as the gold staves striking the ground, which are removed. "Knock to enter" was kept because the owner did not name it. **Assumption:** if the owner meant the title, it is one line in `web/index.html`.
- **Braziers, not spotlights:** the owner suggested "maybe a lamp". A visible source explains the light and uses the gold the scene already has. No fifth hue.
- **The phone wall strip is gone.** It was the cause of "aligns to the left": a 28% trailing strip that the page stopped short of. The wall is now the faint pattern behind the page, as on a desk.
- **Token value changed:** `wallTorchTouchPeak` 0.85 → 0.3 (AGENTS §8 lists token value changes). At 0.85, with the wall behind the words, the lit signs sat under the copy. Changed to meet the owner's explicit "neat on the phone" and recorded here.
- **Fiverr removed from display, not from `profile.json`**, so the owner's data is untouched and the tile can come back with one line.
- **Duration badge:** it counts both the start and end months.
- **Tokens:**
  - Added: `goldEdgeLap`, `interestStagger`, `serviceCardCompactWidth`, `doorClimbInset`.
  - Changed: `doorClimbWidth` 300→240, `doorClimbHeight` 340→220, `doorClimbCompact` 240→200.
  - Removed: `doorPlay`, `doorSceneSize`, `doorLabel`, `careerRegister*`, `traceColumnFractionCompact`.

## Tests

- Modified:
  - "on a phone the wall is behind the whole page, faint" (was "keeps to a narrow strip on a phone").
  - "a phone gets the climb under the words" (was "a phone gets the words and the buttons").
  - "a wide courtyard shows the climb".
  - "carries no caption on the ankh (the owner cut it)" (was "says what the ankh it runs on means").
  All four assertions changed because the owner's requirements changed; none was skipped.
- Goldens: `chrome_compact_{dark,light}_{en,ar}` regenerated after reviewing the diff. The copy now spans the width and the wall is faint behind it.
- Full suite: pass, 845 passing, 0 failing. Worker: 328 passing.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — 356 files, 0 changed
fvm flutter analyze                        pass — No issues found
fvm flutter test                           pass — 845 passed
fvm flutter build web --wasm               pass — Built build/web
cd worker && node --test test/*.test.js    pass — 328 passed
```

Browser (Wasm build, localhost):
- Intro at 1440×900.
- Home, Services, About and Courtyard at 390×844.
- About at 1440×900.

## Known issues left open

- `career_sequence.dart` still threads the career span (`_Span`, `_yearOf`) into `_Card`, where it is no longer used. It is harmless, and was left to keep this diff to the request.
- The Anubis mesh shows faceted light bands under the braziers (decimated normals). It reads as carved stone at intro distance.
- Anubis author and licence are still to be named. Services show in English on the Arabic site. The intermittent /about headless exception is not reproduced.

## Next

Play a ranked climb on sherbini.uk after the deploy to confirm the v3 Worker verifies it, and ask the owner whether "Knock to enter" should stay.
