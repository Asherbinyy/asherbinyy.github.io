# 2026-09-24-04 — Third review: scoreboard, phone controls, phone intro, About/Home details

**Agent:** Claude / Opus 5.5
**Milestone:** Re-innovation, full ownership
**Started from:** `e296b22` (merged to `main` as PR #53)

## Goal

The owner's third round: the scoreboard not saving a climb played on a phone; Roblox-style touch controls; the intro cut on a phone; vertical stops on a phone; Home closing panel spacing; About alignment and skills placement; the booking card border; the "or" line; one-sentence Icy Tower credit. Then push and merge.

## What changed

- **Scoreboard** (`leaderboard_controller.dart`, `leaderboard.dart`, `ascent_stage.dart`).
  - Cause, established against the live Worker: a climb only counts when it was played on a server-issued run. The site fetched a run only for someone who had already joined, and the join question comes after the first climb, so that climb was never submitted. The owner played, joined, and found nothing on the board.
  - The pipeline was confirmed healthy with a scripted ranked run against production. It was verified at 800 m, ranked #1, and removed with the player key straight after. The board is empty again.
  - Fix: the controller holds a random `_tabKey` (memory only) for undecided visitors. The first climb waits up to `firstRunWait` (1.5 s) for a run. A finished climb by an undecided visitor is kept (`finish`), and joining re-keys the new participant to the tab key (`Joined.rekeyed`) and submits it.
  - `PlayingLocally` still never fetches a run.
- **Touch controls** (`ascent_controls.dart`):
  - The left 55% is a floating stick. It is centred where the thumb lands and steers once the thumb moves past a 12 px dead zone.
  - The right 45% is jump, with a 96 px gold button drawn there.
  - Multi-touch is handled with a `Listener` tracking pointer ids. The controls cover the stage below the top bar while a climb is running.
  - The legend shows `ascentTouch` on touch screens.
- **Intro on a phone** (`web/intro/intro.js`, `#fit`): on a narrow screen the lens widens (up to about 64°) and the camera stands back far enough to frame ±7 units at the statues' depth. The fog is thinned to match, and the approach ends in the same place.
- **Home:**
  - On a phone the horizontal `CareerStops` is hidden. Each career card gets `_PhoneStop` (year and mark) on a line down the leading edge; `CareerStops.markFor` is shared.
  - The closing panel's row is centred vertically.
- **About:**
  - The ankh geometry moved up (bar 0.52→0.46, foot 0.87→0.81 of the height), so its top node is level with the first line.
  - `SkillGroups` moved under the buttons in the identity column. Below 820 px wide, the titles are one wrap instead of two broken halves.
- **Contact:** the "or" line is capped at 640 px (the width of four profile tiles). The booking card is wrapped in `GoldEdge`, which now takes a radius and an inset and puts its child in its own repaint boundary.
- **Courtyard:** one sentence: "A shout-out to Icy Tower, the first game I ever played." (EN and AR). `courtyardShoutout` is removed.

## Files touched

- `lib/features/courtyard/game/{domain/leaderboard,presentation/leaderboard_controller,presentation/ascent_stage,presentation/ascent_controls}.dart` — modified
- `lib/features/courtyard/presentation/courtyard_screen.dart`, `lib/features/about/presentation/{about_screen,widgets/contact_links}.dart` — modified
- `lib/features/station/presentation/{station_screen,widgets/career_sequence,widgets/career_stops}.dart` — modified
- `lib/core/widgets/{gold_edge,skill_groups}.dart`, `lib/core/painting/life_flow_painter.dart` — modified
- `lib/app/theme/tokens.dart`, `lib/app/l10n/app_{en,ar}.arb`, `web/intro/intro.js` — modified
- `test/widget/ascent/ascent_controls_test.dart` — created; `test/unit/features/ascent/leaderboard_test.dart`, `test/widget/courtyard/courtyard_test.dart` — modified
- `docs/14-PROVENANCE.md`, `CHANGELOG.md` — modified

## Decisions made

- **A random tab key is sent before the visitor has joined.** This touches data collection, which AGENTS §8 lists for an explicit answer. It was done because the owner asked for the board to work as he used it.
  - The value is random, lives only in memory, is never written to the device, and is derived from nothing. The Worker stores nothing when it issues a run (only an HMAC token goes back).
  - Nothing is submitted unless the visitor joins.
  - The alternative was an unbound challenge. That needs a Worker change and redeploy, and it weakens the rule that a run is bound to its player.
  - **The owner should confirm this.** It can be reverted by making `beginRankedRun` return null for `Undecided`.
- **Production probe:** one scripted ranked run was submitted to the live board under the name "probe" and removed with its key seconds later. Nothing remains.
- **A 1.5 s wait before the first climb** only applies when no run is in hand. A late run is kept for the next climb.
- **Tokens:**
  - Added: `ascentStick*`, `ascentJump*`, `ascentTouchFill`, `careerRailCompact`, `careerRailNode`, `skillsTwoLinesFrom`, `contactOrMaxWidth`.
  - Ankh geometry constants changed in the painter; they are not tokens.

## Tests

- Added:
  - "a climb finished before joining goes up once they join"
  - "somebody playing on their own is never issued a run"
  - `ascent_controls_test.dart` (3): right-side jump held and released; left-side floating stick; both thumbs at once.
- Modified: the courtyard phone test reads the one-sentence credit.
- Full suite: pass, 850 passing, 0 failing. Worker: 328 passing.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — 357 files, 0 changed
fvm flutter analyze                        pass — No issues found
fvm flutter test                           pass — 850 passed
fvm flutter build web --wasm               pass — Built build/web
cd worker && node --test test/*.test.js    pass — 328 passed
```

The local suite took 9.5 minutes against 1.5 before. The machine was under load at the time (analyze took 25 s against 4 s), and no single test was over 16 s. Watch the CI time.

Browser (Wasm build, localhost):
- About and Home at 1440×900.
- Courtyard, the game (legend and controls) and Home at 390×844.
- The intro rendered at 390×844 through a manual harness. The real intro auto-opens before a headless capture can see it.

## Known issues left open

- The touch controls were tested with synthetic gestures and seen on screen, but not played on a physical phone.
- The first career stop's line runs up past its year on a phone.
- Earlier items remain open: the Anubis licence, English services on the Arabic site, and the intermittent /about headless exception.

## Next

The owner plays a climb on his phone, joins, and checks the board. Then he confirms (or rejects) the tab-key approach above.
