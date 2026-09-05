# 2026-09-05-10 — Hero and acquisition sequence

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 53c11b3

## Goal
Implement task 1.6: the acquisition sequence and the settled hero, wiring the
content layer into the app for the first time.

## Owner decisions taken before starting
Three content questions were put to the owner, because none of the hero's
numbers exists as data and `AGENTS.md` section 3 forbids inventing them.

1. **Countries.** `profile.json` said "five countries" while `career.json`
   lists six (EG, CA, SA, AM, QA, GB), matching `00-PROJECT-BRIEF.md` section 3.
   The hero would have claimed five directly above a map drawing six. Owner
   chose six and authorised the edit.
2. **Stat panels.** Owner chose an optional `stats` block in `profile.json`.
   Model support is in; the panels render from it and are omitted when absent,
   so nothing is invented and nothing blocks. The values are still needed.
3. **The CV call to action.** `cvFile` is null. Owner asked for a
   recommendation; the button reads "Read the CV" and opens `/cv`, the static
   page that already exists. Section 9 requires a CTA to name its outcome, so
   it cannot say "Download" while navigating.

## What changed
- Edited `assets/content/{profile,fallback}.json` and `web/index.html`:
  "five countries" to "six countries", per the decision above. `/cv` and
  `/brief` pick this up automatically since the generator reads the same JSON.
- Added `ProfileStat` to the profile model, and `stats` to `Profile`.
- Added `content/asset_content.dart`: the injected `assetReader`, the
  repository, and the `profile` and `career` providers. `main.dart` installs
  `rootBundle.loadString`. This is the first time content reaches the app.
- Added `core/painting/grain_painter.dart` and painted it behind the whole
  frame. Section 2's 3% static grain, tiled, never animated.
- Added `core/widgets/beacon_button.dart` and `core/widgets/telemetry_value.dart`.
- Added `core/platform/static_route.dart` with a stub/web pair, so `/cv` leaves
  the Flutter app rather than being resolved client-side to its empty reserved
  placeholder.
- Added the station feature: `station_screen.dart`, `acquisition_sequence.dart`,
  `hero_content.dart`, `stat_panel.dart`, and the in-memory
  `acquisition_controller.dart`.
- Wired the footer's coordinate readout, deferred from task 1.5. "The current
  station" is the career role with no end date — a rule the content states
  rather than one inferred from it.
- Added `NocturneTypography.measureFor`, replacing a bang operator and a magic
  divisor in the hero with the documented 68-character cap.
- Added five ARB keys in both channels, and six tokens.

## Files touched
- `assets/content/profile.json`, `fallback.json` — modified — six countries.
- `web/index.html` — modified — the same, in three meta tags.
- `lib/content/models/profile.dart` — modified — `ProfileStat` and `stats`.
- `lib/content/asset_content.dart` — created — content reaches the app.
- `lib/core/painting/grain_painter.dart` — created — the static grain.
- `lib/core/widgets/beacon_button.dart` — created — the site's CTA.
- `lib/core/widgets/telemetry_value.dart` — created — mono readings.
- `lib/core/platform/static_route{,_stub,_web}.dart` — created — leave the app.
- `lib/features/station/domain/acquisition_controller.dart` — created.
- `lib/features/station/presentation/station_screen.dart` — created.
- `lib/features/station/presentation/widgets/acquisition_sequence.dart` — created.
- `lib/features/station/presentation/widgets/hero_content.dart` — created.
- `lib/features/station/presentation/widgets/stat_panel.dart` — created.
- `lib/app/router.dart` — modified — the station screen and the sequence.
- `lib/app/chrome/chrome_scaffold.dart` — modified — grain, footer coordinate.
- `lib/app/theme/{tokens,token_values,typography}.dart` — modified.
- `lib/main.dart` — modified — install the bundle reader.
- `lib/app/l10n/app_{en,ar}.arb` — modified — five keys.
- `build.yaml` — modified — generate the two new controllers.
- `test/support/{content_readers,station_harness}.dart` — created.
- `test/support/chrome_harness.dart` — modified — install content.
- `test/widget/station/station_test.dart` — created — 16 tests.
- `test/golden/station_test.dart` + 6 baselines — created.
- `test/golden/locale_placeholder_test.dart` — modified — see below.
- `test/{widget_test,widget/*}.dart` — modified — re-anchored, see below.
- `docs/worklog/2026-09-05-10-hero-and-acquisition.md` — created.

## Decisions made

**The sequence wraps the whole frame, not the hero.** Its fourth beat draws the
rail, header and footer in from their edges, so it has to sit above the chrome.
An earlier draft put it inside the station screen, where its `StackFit.expand`
hit the scroll view's unbounded height and threw — the tests caught it.

**"Once per session" is held in memory, not in storage.** The sequence is not a
preference the viewer chose, so writing it to the device would be a storage
write nobody asked for. A hard reload therefore replays it. Recorded as a known
divergence rather than quietly extending the storage the owner approved for
preferences.

**Beats three and four are one fade, not two directional draws.** The spec has
the chrome drawing in from its edges. Differentiating it would mean the
sequence reaching into the header, rail and footer internals, coupling two
things that are otherwise independent. Flagged as a polish item; the settled
state, the timing, the skip and the reduced-motion path all match the spec.

**A fallback profile renders as a hero, not an error.** `ContentFallback` still
carries the owner's real name, positioning and contact, so treating it as a
failure would be wrong. Only `ContentUnavailable` — both the content and its
bundled fallback unparseable — shows the carrier at rest and a direction.

**Test harnesses read the real bundled JSON.** A fixture would drift from the
owner's content; reading `assets/content/` means a change that breaks a screen
fails here rather than in a browser. Content loading is real asynchronous I/O
that the test clock does not advance, so the harnesses warm the providers
inside `runAsync` before pumping — otherwise the skeleton's sweep never settles
and `pumpAndSettle` times out.

**Existing tests were re-anchored, none deleted or skipped.** Four suites looked
up `PlaceholderScreen` to get a context; the station route now renders a real
screen, so they anchor on `ChromeScaffold`, which every framed route has.
`locale_placeholder_test.dart` was repointed at `/about`, a route whose body is
still a reserved placeholder, so it keeps distinct meaning now that the chrome
and hero have their own goldens.

## Tests
- Added: 22 — 16 station behaviour tests and 6 golden cases.
- Modified: five suites, as recorded above. None deleted, none skipped.
- Full suite: pass, 281 passing, 0 failing.
- Coverage delta: 93.68% to 93.78% (2066/2203 lines). These are line
  measurements, not branch coverage.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test --coverage                pass (281 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- **`profile.json` still has no `stats` block**, so the hero renders no stat
  panels. The composition is under a golden using a fixture. Owner to supply
  the three values, or edit the file directly — no code change is needed.
- **`docs/07-CONTENT-SCHEMA.md` and `docs/00-PROJECT-BRIEF.md` still say "five
  countries".** Only the content and the HTML shell were changed, since the
  owner authorised a content fix rather than a documentation edit. A later
  agent reading the schema could "correct" `profile.json` back.
- **The owner's phone number is publicly indexable.** `generate_static.dart`
  writes it as a `tel:` link into `/cv` and `/brief`, which exist to be crawled.
  Raised with the owner; no change made, since it alters what the site
  publishes about them.
- The acquisition sequence replays on a hard reload, as recorded above.
- Beats three and four are a single fade, as recorded above.
- The trace baseline the sequence resolves into is the carrier at rest. Task
  1.7 replaces it with the real trace.
- Thirty-five agent-authored Arabic interface strings now want an owner read.
- The three task-1.4 defects owned by 1.6b remain open: the icon-case 404s, the
  scaffold `manifest.json` shipping a second chroma, and the sitemap's
  trailing-slash URLs.
- Chrome and hero have still not been checked on a real phone browser, which
  `05-TESTING.md` requires before any merge to `main`.

## Next
Task 1.6b, the mark and favicon. `MarkPainter` already draws the mark from the
trace curve, so 1.6b is mostly export plus the three open task-1.4 defects,
which live in exactly the files it touches. Task 1.7, the telemetry trace, is
the larger piece and the roadmap allows it more than one session.
