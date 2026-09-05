# 2026-09-05-08 — Loading and placeholder primitives

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 0b70874

## Goal
Review the preceding agents' work, then implement task 1.4b: the shared sweep,
skeletons, the carrier loader, the three-stage image resolve, the procedural
station card, and the empty state — built before any screen consumes them.

## Review of the preceding work
Re-ran the four commands against `0b70874` before changing anything rather than
trusting the reports. All green: 79 files formatted, no analyzer issues, 126
tests passing. Worklogs 05, 06 and 07 agree with each other and with the code.

Five defects found in task 1.4 that were not recorded anywhere. None are in
1.4b's scope; they are listed under Known issues below with a proposed owner.

## What changed
- Added `core/painting/carrier_wave.dart`: the single curve function behind the
  trace, the loader and the mark. `sample` is the travelling carrier,
  `burstEnvelope` the Gaussian window, `burst` the two composed. Section 12
  requires the mark to be a frame lifted from this function rather than drawn
  independently, so task 1.6b now has something to sample and task 1.7 extends
  it with coherence and noise instead of writing a second curve.
- Added `core/painting/projection.dart`: equirectangular lat/lon to canvas,
  unit-tested against the real station coordinates in `career.json`. Section 11
  states the station card reuses this; task 1.8 now inherits it already tested.
- Added `core/painting/station_seed.dart`: FNV-1a plus xorshift32, every step
  masked to 32 bits so the VM and the web build produce identical cards.
- Added `core/painting/carrier_painter.dart`, `corner_ticks_painter.dart` and
  `station_card_painter.dart`. All three early-return on an empty canvas and
  implement `shouldRepaint` field by field.
- Added `core/widgets/instrument_panel.dart`: the hairline edge and corner ticks
  from section 4. The widget reserves the tick offset on all four sides so the
  marks cannot clip and a panel's outer size already includes them.
- Added the loading primitives under `core/widgets/loading/`: `SweepScope`,
  `SweepShimmer`, `SkeletonPanel`, `SkeletonText`, `CarrierLoader`,
  `CarrierEmptyState`, `StationCard`, `ThreeStageImage`.
- Added `TypographyTokens` as a second `ThemeExtension` plus a `context.type`
  accessor, and registered it in `ThemeFactory`.
- Added an optional `country` to `ShippedApp`, and `content/app_origin.dart` to
  resolve where an application was built.
- Added `content/work_domain_label.dart`: an exhaustive switch from `WorkDomain`
  to ARB copy.
- Added ten ARB keys in both English and Arabic — the first copy either channel
  has carried.
- Added five tokens: `carrierRestCycles`, `carrierRestAmplitude`,
  `carrierBurstWidth`, `stationNodeMin`, `stationNodeMax`.

## Files touched
- `lib/core/painting/carrier_wave.dart` — created — the one waveform function.
- `lib/core/painting/carrier_painter.dart` — created — the loader miniature.
- `lib/core/painting/corner_ticks_painter.dart` — created — the panel signature.
- `lib/core/painting/projection.dart` — created — lat/lon to canvas.
- `lib/core/painting/station_seed.dart` — created — deterministic card layout.
- `lib/core/painting/station_card_painter.dart` — created — the constellation.
- `lib/core/widgets/instrument_panel.dart` — created — hairline edge and ticks.
- `lib/core/widgets/loading/sweep_scope.dart` — created — the one shared sweep.
- `lib/core/widgets/loading/sweep_shimmer.dart` — created — the scan band.
- `lib/core/widgets/loading/skeleton_panel.dart` — created — empty instrument.
- `lib/core/widgets/loading/skeleton_text.dart` — created — hairline text rules.
- `lib/core/widgets/loading/carrier_loader.dart` — created — the no-spinner loader.
- `lib/core/widgets/loading/carrier_empty_state.dart` — created — carrier at rest.
- `lib/core/widgets/loading/station_card.dart` — created — procedural card.
- `lib/core/widgets/loading/three_stage_image.dart` — created — image resolve.
- `lib/content/app_origin.dart` — created — resolves an application's country.
- `lib/content/work_domain_label.dart` — created — localised domain names.
- `lib/app/theme/tokens.dart` — modified — five new named values.
- `lib/app/theme/token_values.dart` — modified — mirror the five new values.
- `lib/app/theme/typography.dart` — modified — `TypographyTokens`, `context.type`.
- `lib/app/theme/theme_factory.dart` — modified — register the typography extension.
- `lib/content/models/apps.dart` — modified — optional `country`.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — ten interface keys.
- `test/support/loading_harness.dart` — created — real themes and delegates.
- `test/unit/core/painting/*_test.dart` — created — five painting suites.
- `test/unit/content/{app_origin,work_domain_label}_test.dart` — created.
- `test/widget/loading/{sweep,loading_primitives}_test.dart` — created.
- `test/golden/loading_primitives_test.dart` + 12 baselines — created.
- `docs/worklog/2026-09-05-08-loading-primitives.md` — created — this handoff.

## Decisions made

**Arabic interface copy was written; Arabic content was not.** AGENTS.md section
3 forbids fabricating the owner's Arabic — job titles, summaries, positioning.
It does not sensibly extend to interface chrome such as "Loading", which makes
no claim about anyone, and standards section 13 requires every string to come
from ARB from the first line of UI code. The owner asked for both channels live
from the start. The ten keys added are interface chrome only, written by this
agent and listed under Known issues for review. No content Arabic was touched.

**The station card takes strings, not content models.** Section 11 describes a
card showing name, domain and country, but `core/` sitting below `content/`
would invert the dependency direction. `StationCard` takes resolved strings and
optional coordinates; `content/app_origin.dart` and `content/work_domain_label.
dart` do the resolving. The work grid wires them in task 1.9.

**Country resolution, in the owner's requested order of editability.** An
explicit `country` on an application wins; otherwise the career role whose
`appIds` lists the application supplies both the country and real coordinates.
Adding `"country": "SA"` to any record in `apps.json` is now enough — no code
change. Only 4 of 11 applications resolve today (az-courses, enjoy, snunu,
mostaqbaly, all via CI Company in EG); the other 7 render without a country
line rather than with an invented one. The storefront in a store URL is
deliberately not consulted: `apps.apple.com/sa/` says where an app is listed,
not where the work happened, and using it would put a claim on the site the
owner never made.

**There is always exactly one beacon node.** With coordinates it sits at the
projected position; without, it marks the first seeded node. An abstract
constellation with one highlighted node claims no location, so this stays
truthful while keeping section 11's "a single `--beacon` node" literal.

**`projection.dart` and `carrier_wave.dart` were built now, not in 1.7 and 1.8.**
Section 11 names both as dependencies of this task. Building them here means
the trace, the map and the mark extend one function each rather than
reconciling three; section 12 warns specifically against the mark drifting from
the trace's curve.

**`TypographyTokens` was added to reach the telemetry styles.** Section 11 puts
the station card's domain and country in `telemetry-s`. Material's `TextTheme`
has no slot for it, and the scale depends on viewport width, so a widget could
only rebuild it by reading `MediaQuery.size` — which standards section 16 bans.
Putting the already-constructed scale on the theme resolves both. Its `lerp`
snaps at the midpoint because the scale is discrete, and theme animation is
already zero in this app.

**`SweepScope` exposes a nullable animation.** Null means either no scope above
or reduced motion. Every primitive then renders static instead of throwing, so
one can be used standalone in a test or a golden without ceremony, and the
reduced-motion path is the same code path as the no-scope path.

**No `setState` anywhere.** `SweepScope` and `CarrierLoader` read the reduced-
motion preference in `build`, which registers the dependency and rebuilds on
change; `didChangeDependencies` only syncs the controller. Standards section 16
bans `setState` outright and this keeps to it without a provider for what is
purely local animation plumbing.

**`CarrierPainter.burstCentre` is nullable, and the empty state passes null.**
The first golden showed a burst parked half off the start edge on the at-rest
carrier, which misreports a signal that is not there. Null now means the
baseline carrier of section 6; the loader passes the phase so its burst travels.

**Skeleton geometry is derived, never hard-coded.** `SkeletonText` takes the
real `TextStyle` and computes line boxes from it. The first RTL golden run
caught this: Arabic raises line height by 0.15 per section 3, so a fixed-height
panel overflowed by 4px. That is precisely the layout shift the quality floor
forbids, and it is now the documented usage in the golden fixture.

**No new packages.** The sweep is a `ShaderMask` over a `LinearGradient`, as
section 11 requires; the `shimmer` package was not added.

## Tests
- Added: 90 across eleven files — carrier maths (11), projection (8), station
  seed (7), carrier painter (5), corner ticks (4), station card painter (10),
  app origin (6), domain labels (4), sweep behaviour (7), primitive behaviour
  (16), and 12 golden cases (3 fixtures across both themes and both directions).
- Modified: none of the prior tests.
- Full suite: pass, 216 passing, 0 failing.
- Coverage delta: 91.26% to 92.95% (1265/1361 lines). These are line
  measurements, not branch coverage.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (107 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test --coverage                pass (216 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open

**Defects found in task 1.4, not fixed here (scope).**
1. `web/icons/` holds `Icon-192.png` and `Icon-512.png` with a capital I, while
   `web/index.html` and `tool/generate_static.dart` reference lowercase
   `icons/icon-512.png`. GitHub Pages is case-sensitive, so every Open Graph
   image, Twitter card image and the apple-touch-icon 404s. Section 12 mandates
   the lowercase names. Owner: task 1.6b.
2. `web/manifest.json` is the untouched Flutter scaffold — `background_color`
   and `theme_color` are both `#0175C2`, a second chroma shipped in breach of
   section 2, and the description reads "A new Flutter project." Owner: 1.6b.
3. `tool/generate_static.dart` writes sitemap entries with trailing slashes
   (`/signal/`, `/work/`, `/about/`, `/writing/`, `/privacy/`). `AppRoute`
   declares them without, so go_router resolves those five to `errorBuilder`.
   Five of the eight advertised URLs land on the error route.
4. `_esc` uses `HtmlEscapeMode.element`, which does not escape `"`, but its
   output is interpolated into `content="…"` in nine meta tags. `_escAttr`
   exists and is correct; it is simply not used there. Latent, not triggered by
   the current content.
5. `test/unit/tool/generate_static_test.dart` shells out to a bare `dart`, so
   it may run under a different SDK than the pin. `Platform.resolvedExecutable`
   is the fix and works in CI, which has no FVM.

**This task.**
- The ten Arabic interface strings are agent-authored and want an owner read.
- Seven of eleven applications have no resolvable country, so their cards show
  the domain alone. Adding `country` to `apps.json` is all that is needed.
- `ThreeStageImage` accepts inline placeholder bytes but nothing extracts them:
  the repository has no images at all. The build-time 20x25 WebP extraction from
  section 11 is deferred until real screenshots exist, and the widget falls back
  to the panel surface, which is still the right dimensions so nothing shifts.
- Empty-state copy is per screen and lives with the screen that needs it;
  `CarrierEmptyState` takes the line as a parameter and invents nothing.
- Frame cost was not measured. Section 6's 4ms budget is task 1.7's gate and
  needs a profile build, not a widget test.
- Font budget, stock icon warnings and the Alchemist incompatibility are
  unchanged from worklogs 04 and 05.

## Next
Fix defects 4 and 5 above — both are small, and 4 is an escaping bug worth
closing before more meta tags are added. Then task 1.5, global chrome, which is
the first task that consumes these primitives and will prove the panel language
and the shared sweep against real layout.
