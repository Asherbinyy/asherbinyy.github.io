# 2026-09-05-12 — The telemetry trace

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 195260f

## Goal
Implement task 1.7: the telemetry trace, the site's signature element, plus the
career sequence it travels over.

## What changed
- Added `features/trace/domain/trace_geometry.dart`: duration, amplitude,
  density, coherence, state resolution, burst layout and sampling, all as pure
  functions. The roadmap requires the amplitude maths to be unit-tested and this
  is the part a reader cannot check by looking.
- Added `core/painting/trace_painter.dart`: one painted path, sampling only the
  visible window and early-returning when the trace is off-screen.
- Added `features/trace/presentation/telemetry_trace.dart`: a single `Ticker`
  driving the idle carrier, scroll velocity read per frame, coherence and state
  published without rebuilding the page.
- Added `features/trace/presentation/station_trace.dart`, which keeps the
  content lookup out of the trace widget so the maths and painter can be tested
  with no repository near them.
- Added `features/station/presentation/widgets/career_sequence.dart` and put it
  under the hero. Section 6 runs the trace from the hero to the end of the
  career sequence, so the sequence has to exist for the trace to mean anything.
- Added a `backgroundBuilder` slot to `ChromeScaffold`, given the page scroll
  controller. The trace sits behind the scrolling column rather than inside it,
  because a painter inside a viewport cannot know what is visible.
- Added six tokens and tuned three of them after looking at the render.

## Files touched
- `lib/features/trace/domain/trace_geometry.dart` — created — the maths.
- `lib/core/painting/trace_painter.dart` — created — the painter.
- `lib/features/trace/presentation/telemetry_trace.dart` — created — the widget.
- `lib/features/trace/presentation/station_trace.dart` — created — content wiring.
- `lib/features/station/presentation/widgets/career_sequence.dart` — created.
- `lib/features/station/presentation/station_screen.dart` — modified — career.
- `lib/app/chrome/chrome_scaffold.dart` — modified — background slot.
- `lib/app/router.dart` — modified — the trace on the station route.
- `lib/app/theme/{tokens,token_values}.dart` — modified — trace tokens.
- `test/support/pump.dart` — created — bounded pumps, see below.
- `test/support/{chrome,station}_harness.dart` — modified — use them.
- `test/unit/features/trace/trace_geometry_test.dart` — created — 30 tests.
- `test/unit/core/painting/trace_painter_test.dart` — created — 7 tests.
- `test/widget/trace/trace_test.dart` — created — 7 tests.
- Six test suites — modified — `pumpAndSettle` replaced, see below.
- `docs/worklog/2026-09-05-12-telemetry-trace.md` — created — this handoff.

## Decisions made

**Bursts are confined to the trace below the hero.** A widget test caught the
page loading already in `lock`: bursts were spread evenly over the whole trace,
so the first one sat under the hero and the site opened locked onto a role
nobody could see. Section 6 anchors each role to where it appears in the career
sequence, which starts a screen down, and `withinRange` now does that.

**`pumpAndSettle` cannot be used once the trace is mounted.** It idles at 0.2Hz
for the life of the page — which section 5 explicitly permits as the one
allowed infinite loop — so the tree never reaches quiescence. `pumpFrames`
advances a bounded number of frames instead. Six suites were updated; none were
deleted or skipped, and none of their assertions changed.

**Cycles are specified per screen, not per trace.** A fixed count over the whole
trace turns into a slow decorative sine on a long page, which is what the first
render was. The painter scales the count by how many viewports the trace spans,
so the frequency reads the same whatever the page's length.

**The burst width is much narrower than the mark's.** They share
`CarrierWave.burstEnvelope`, but the mark spans one 32px box and the trace spans
pages. At the mark's width every burst overlapped every other and the rest
amplitude was never visible — the first render was one continuous swell.

**An explicit `traceWeight` in the content wins over the derived duration.** The
schema documents it as the burst amplitude and the owner set it deliberately on
one role. Duration supplies the rest, per section 6.

**A short role keeps an amplitude floor.** Evri is the case the content schema
calls out: present and factual, not featured. Without a floor it would vanish
into the carrier rather than sit quietly in the sequence.

**Noise is deterministic.** The degraded waveform is seeded from position, so
the same scroll position always jitters the same way — which is what lets a
test assert anything at all about the scanning state.

**Burst labels carry only what the content states.** Five of the six roles have
no company, and those fall back to their city rather than to an invented
employer. The screen spec's example shows an application count; `career.json`
records application ids for one role only, so no count is shown rather than a
zero that would read as a claim.

## Tests
- Added: 44 — 30 covering the geometry, 7 the painter, 7 the trace in the app.
- Modified: six suites, for the pump change only. None deleted, none skipped.
  All goldens regenerated: the trace now runs behind the station.
- Full suite: pass, 346 passing, 0 failing.
- Coverage delta: 93.66% to 93.69% (2422/2585 lines).

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test --coverage                pass (346 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- **Frame cost is unmeasured.** Section 6 budgets 4ms and the painter is built
  for it — one path, visible window only, correct `shouldRepaint` — but that is
  an argument, not a measurement. It needs a profile build and DevTools.
- **The trace does not pause when off-screen.** Section 5 requires the idle to
  pause off-screen; today it ticks whenever the station route is mounted. It is
  cheap while the painter early-returns, but the ticker still runs.
- **The lock label is positioned, not laid out against the career entry.**
  Bursts are spaced evenly below the hero rather than measured against where
  each role actually renders, so a label can sit slightly off its entry on
  unusual viewport sizes.
- The career sequence is deliberately plain. It exists to anchor the trace, and
  five of six roles have no copy to show beyond dates and location.
- `profile.json` still carries no `stats` block, so the hero shows no panels.
- `docs/07-CONTENT-SCHEMA.md` and `docs/00-PROJECT-BRIEF.md` still say "five
  countries" while the content says six.
- Nothing has been checked on a real phone browser, which `05-TESTING.md`
  requires before any merge to `main`.

## Next
Task 1.8, the propagation map. `projection.dart` is already built and tested
against the real station coordinates, and the career content is already wired,
so the remaining work is the painter, the arcs and the transmission panels.
