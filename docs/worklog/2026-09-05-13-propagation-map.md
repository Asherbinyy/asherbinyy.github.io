# 2026-09-05-13 — The propagation map

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** c9cc777

## Goal
Implement task 1.8, the propagation map, and close the two trace issues left
open by the previous session.

## What changed

### Issues fixed
- **The trace idle now pauses off-screen.** Section 5 allows exactly one
  infinite loop on the site and requires it to pause when off-screen; it was
  ticking whenever the station route was mounted. Scrolling past the career
  sequence now costs nothing at all, rather than a cheap painter early-return.
- **Frame cost has a structural guard.** A profile build is still the real
  measurement, but two tests now assert what actually holds the 4ms budget: a
  page ten times longer does not cost ten times more to paint, and one full
  viewport paint stays well inside a frame.
- **The stale "five countries" in the docs is fixed.** `07-CONTENT-SCHEMA.md`,
  `00-PROJECT-BRIEF.md` and `02-SCREEN-SPECS.md` still claimed five after the
  owner corrected the content to six, which risked a future agent reverting it.

### The map
- Added `core/painting/great_circle.dart`: spherical interpolation, so an arc
  is the shortest real path rather than a straight line on a flat projection.
- Added `core/painting/map_painter.dart`: graticule, arcs drawn in
  chronological sequence, station nodes, selection pulse, and hit testing.
- Added the signal feature: `signal_screen.dart`, `propagation_map.dart`,
  `transmission_panel.dart` and `chronology_scrubber.dart`.
- Added six ARB keys in both channels and seven tokens.

## Files touched
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — pause.
- `docs/{00,02,07}-*.md` — modified — six countries.
- `lib/core/painting/great_circle.dart` — created — spherical interpolation.
- `lib/core/painting/map_painter.dart` — created — the map surface.
- `lib/features/signal/presentation/signal_screen.dart` — created.
- `lib/features/signal/presentation/widgets/propagation_map.dart` — created.
- `lib/features/signal/presentation/widgets/transmission_panel.dart` — created.
- `lib/features/signal/presentation/widgets/chronology_scrubber.dart` — created.
- `lib/app/router.dart` — modified — route the signal screen.
- `lib/app/theme/{tokens,token_values}.dart` — modified — map tokens.
- `lib/app/l10n/app_{en,ar}.arb` — modified — six keys.
- `test/support/station_harness.dart` — modified — an initial route.
- `test/unit/core/painting/great_circle_test.dart` — created — 8 tests.
- `test/unit/core/painting/map_painter_test.dart` — created — 10 tests.
- `test/unit/core/painting/trace_painter_test.dart` — modified — cost guards.
- `test/widget/signal/signal_test.dart` — created — 12 tests.
- `test/golden/signal_test.dart` + 5 baselines — created.
- `docs/worklog/2026-09-05-13-propagation-map.md` — created — this handoff.

## Decisions made

**The surface is a graticule, not coastlines.** The screen spec asks for
landmasses as hairline outlines. The repository carries no coastline dataset,
and `03-ARCHITECTURE.md` rules out a map SDK — which is what keeps the privacy
claim honest. A graticule is the truthful instrument reading of an
equirectangular projection; an invented outline would not be. Recorded as an
open item: a small simplified coastline dataset would satisfy the spec, and it
is the owner's call whether to add one.

**Arcs are great circles, not straight lines.** Manchester to Toronto bows
north on a flat projection, and drawing it straight would depict a different
journey. The interpolation is spherical and tested against the real station
coordinates, including that the arc is symmetric travelled either way and never
doubles back.

**The antimeridian is handled explicitly.** A path crossing it would otherwise
draw a line straight back across the whole map, which is the classic flat-map
artefact. The painter starts a new subpath instead.

**Evri renders as a minor node.** The content schema says it should be present
and factual, not featured. A role with no trace weight and no applications gets
a smaller node and no emphasis, which is the same judgement the trace makes.

**Selection is a `ValueNotifier`, not a provider.** Nothing outside the screen
needs to know which station is open, and the standards ban `setState`.

**The scrubber's scale is `ExcludeSemantics`.** A test caught the six year
marks merging into the slider's accessible name, so a screen reader would have
announced "Career chronology 2021 2023 2023 2024 2025 2025" as the control's
title. The slider's value carries the selection; the marks are the visual scale.

## Tests
- Added: 30 — 8 great circle, 10 map painter, 12 the map in the app — plus 2
  trace cost guards and 5 golden cases.
- Modified: `widget_test.dart` for the new route; the trace painter suite for
  the cost guards. None deleted, none skipped.
- Full suite: pass, 347 passing plus 36 goldens, 0 failing.
- Coverage delta: 93.69% to 93.20% (2822/3028 lines). The dip is map widget
  code whose interaction paths the goldens cover visually rather than by line.

## Verification run
```
fvm dart format --set-exit-if-changed .       pass (0 changed)
fvm flutter analyze --fatal-infos              pass (no issues found)
fvm flutter test --coverage --exclude-tags golden  pass (347 passing)
fvm flutter test --tags golden                 pass (36 passing)
fvm flutter build web --wasm                   pass (built build/web)
```

## Known issues left open
- **No coastlines.** As above; needs a dataset decision from the owner.
- **The map does not pan or zoom.** Section 7's matrix lists pinch zoom and drag
  pan on touch, scroll zoom and drag pan on pointer. Selection, keyboard
  navigation and the scrubber are in; the viewport transform is not, and with
  six stations on one screen it is not yet load-bearing.
- **Stations cluster in the northern middle of the world map**, because that is
  where they are. It reads honestly but leaves the map sparse; cropping to the
  stations' bounding box would be denser and is a design call for the owner.
- Trace frame cost is still unmeasured in a profile build.
- `profile.json` still carries no `stats` block, so the hero shows no panels.
- Forty-six agent-authored Arabic interface strings want an owner read.
- Nothing has been checked on a real phone browser, which `05-TESTING.md`
  requires before any merge to `main`.

## Next
Task 1.9, the work ledger. `apps.json` is already typed and validated, the
station card already renders for applications with no screenshot, and the
remaining work is the ledger rows, the hover preview and verifying every store
link resolves.
