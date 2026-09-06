# 2026-09-05-09 — Global chrome

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 5a59fd0

## Goal
Implement task 1.5: the header, rail and footer, the mark, the three toggles
and their persistence, keyboard traversal, and goldens across breakpoints,
themes and directions.

## Owner decisions taken before starting
Two documented conflicts were put to the owner rather than resolved unilaterally.

1. **Persistence.** The roadmap requires the three toggles to persist, while
   `AGENTS.md` says no storage write may occur before consent and
   `06-ANALYTICS-AND-PRIVACY.md` section 3 says no localStorage at all. Owner
   chose: persist to local storage with no consent gate. The reasoning, which
   is recorded in `preference_store.dart` so a later agent does not "fix" it
   back: section 3 governs analytics identifiers, PECR exempts storage that is
   strictly necessary for a service the user explicitly requested, the ICO
   names user-interface customisation as an example, and
   `03-ARCHITECTURE.md` section 4 already earmarks `shared_preferences` for
   "theme + consent persistence only".
2. **The theme toggle in Milestone 1.** `00-PROJECT-BRIEF.md` section 8 says
   "dark theme only" while task 1.5 requires all three toggles to work. Owner
   chose: the toggle works now against the Daybreak theme task 1.1 already
   built; task 2.2 still refines Daybreak into a genuine second artifact.

## What changed
- Added `app/theme/app_theme.dart` and `app/theme/theme_controller.dart`:
  the chosen artifact and Recruiter Mode, both persisted. `locale_controller`
  gained the same persistence and a `toggle`.
- Added `core/platform/preference_store.dart`: a three-key interface with a
  synchronous read and an asynchronous write, so a preference is applied on the
  first frame and no frame ever waits on storage. `shared_preference_store.dart`
  holds the only `shared_preferences` import in the codebase.
- Added `core/painting/mark_painter.dart`: the mark, sampled from
  `CarrierWave.burstEnvelope`. Section 12 requires the mark to be a frame lifted
  from the trace's curve rather than designed separately, so the header now
  draws the real thing instead of a placeholder, and task 1.6b exports the SVG
  and favicons from the same function.
- Added `core/widgets/focus_ring.dart`: the visible focus indicator the quality
  floor requires, reserving its own space so focus never shifts a layout.
- Added `features/trace/domain/{trace_state,trace_controller}.dart`: the three
  states from the screen spec, resting at standby, so the rail's indicator is
  truthful before the trace exists. Task 1.7 drives it.
- Added `app/chrome/`: `chrome_scaffold`, `app_header`, `app_nav`, `app_rail`,
  `app_footer`, `app_mark`, `chrome_control`.
- Wired chrome into `router.dart` behind `AppRoute.hasGlobalChrome`, and made
  `PlaceholderScreen` a body rather than a `Scaffold`.
- `main.dart` now loads preferences before `runApp` so the app never paints one
  theme and flips to another.
- Added twenty ARB keys in both channels: five route links, the mark's link
  name, six control announcements, three rail indicator words, and the footer.
- Added six tokens: `headerHeight`, `railWidth`, `footerHeight`,
  `railProgressHeight`, `markNativeSize`, `markStroke`, `markHeaderSize`.

## Files touched
- `lib/app/theme/app_theme.dart` — created — the two artifacts as a pure enum.
- `lib/app/theme/theme_controller.dart` — created — theme, Recruiter Mode, store.
- `lib/app/l10n/locale_controller.dart` — modified — persist and toggle.
- `lib/core/platform/preference_store.dart` — created — the storage boundary.
- `lib/core/platform/shared_preference_store.dart` — created — the real store.
- `lib/core/painting/mark_painter.dart` — created — the mark, from the trace curve.
- `lib/core/widgets/focus_ring.dart` — created — visible keyboard focus.
- `lib/features/trace/domain/trace_state.dart` — created — the three states.
- `lib/features/trace/domain/trace_controller.dart` — created — publishes state.
- `lib/app/chrome/chrome_scaffold.dart` — created — the persistent frame.
- `lib/app/chrome/app_header.dart` — created — mark, links, three controls.
- `lib/app/chrome/app_nav.dart` — created — the route links.
- `lib/app/chrome/app_rail.dart` — created — tick scale, section, indicator.
- `lib/app/chrome/app_footer.dart` — created — location, consent, readout.
- `lib/app/chrome/app_mark.dart` — created — the mark as a link to `/`.
- `lib/app/chrome/chrome_control.dart` — created — one header control.
- `lib/app/router.dart` — modified — frame every route but the static two.
- `lib/app/app_route.dart` — modified — `hasGlobalChrome`.
- `lib/app/app.dart` — modified — theme from the controller.
- `lib/main.dart` — modified — load preferences before the first frame.
- `lib/core/widgets/placeholder_screen.dart` — modified — body, not scaffold.
- `lib/app/theme/tokens.dart`, `token_values.dart` — modified — six tokens.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — twenty keys.
- `build.yaml` — modified — generate the two new controllers.
- `test/support/chrome_harness.dart` — created — the four breakpoints.
- `test/unit/app/theme/theme_controller_test.dart` — created — 13 tests.
- `test/widget/chrome/chrome_test.dart` — created — 13 tests.
- `test/golden/chrome_test.dart` + 9 baselines — created.
- `test/widget_test.dart`, `test/widget/app_messenger_test.dart`,
  `test/widget/locale_switching_test.dart`,
  `test/golden/locale_placeholder_test.dart` + 4 baselines — modified, see below.
- `docs/worklog/2026-09-05-09-global-chrome.md` — created — this handoff.

## Decisions made

**The route links get their own row below 1024px.** The screen spec draws the
desktop header and says only that the *rail* collapses. Hiding the links with
it would leave a phone browser with no navigation at all, and phone browsers are
a primary target. A widget test caught this: the links were invisible at 800px.
The row scrolls horizontally rather than wrapping, so its height is fixed and
nothing below it shifts.

**Chrome frames every route except `/cv` and `/brief`.** Those are hand-written
HTML served directly by Pages; their Flutter routes exist only as reserved
paths, and framing them would imply the app owns pages it does not.

**Hover and focus use `WidgetStatesController`, not `setState`.** The standards
ban `setState` outright. An earlier draft reached for
`Element.markNeedsBuild()`, which is the same thing wearing a disguise and
worse for being hidden; the framework's own states controller is the honest
mechanism and disposes cleanly.

**The footer coordinate is deferred to task 1.6.** The screen spec wants the
viewer's coarse location if consented and Manchester otherwise. Consent does not
exist until 1.10, and the fallback reading lives in `career.json`, which nothing
in the app loads yet — content is first wired in 1.6 for the hero. `AppFooter`
takes a nullable coordinate and omits the line rather than hard-coding a number
into a widget, which would put content in code and break the token rule.

**`ChromeScaffold` owns the page scroll.** The trace runs continuously down the
page, so one page-level scroll is the right structure and the rail's tick scale
needs a controller to read. Scroll progress is published through a
`ValueNotifier` so a scroll rebuilds the tick scale alone rather than the whole
page, which would repaint the trace and the map every frame once they exist.

**Four existing tests were updated, none deleted or skipped.** Chrome
legitimately invalidated assumptions they encoded:
- `widget_test.dart` asserted routes render no `Text` at all. Now scoped to the
  placeholder body, plus new assertions that chrome frames the right routes.
- `app_messenger_test.dart` assumed one Tab reaches the message's close button.
  It now tabs until focus lands there, which proves reachability without
  pinning the test to chrome's control count.
- `locale_switching_test.dart` asserted no `Text`; it now asserts the chrome's
  own copy follows the channel, using a string present at every width.
- `locale_placeholder_test.dart` matched an empty `PlaceholderScreen`, which is
  now genuinely empty; retargeted at the app so the golden captures what a
  route actually renders. Its four baselines were regenerated and inspected.

## Tests
- Added: 43 — controllers and storage (13), chrome behaviour (19 across the
  four breakpoints), 9 golden cases (rail present, rail collapsed, Recruiter
  Mode), and 2 new route-framing tests in the existing suite.
- Modified: four suites, as recorded above. None deleted, none skipped.
- Full suite: pass, 259 passing, 0 failing.
- Coverage delta: 92.95% to 93.68% (1735/1852 lines). These are line
  measurements, not branch coverage.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (128 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test --coverage                pass (259 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- The footer's coordinate readout is absent until content is wired in 1.6.
- The twenty Arabic chrome strings are agent-authored interface copy and want an
  owner read, as do the ten from the previous session.
- The rail's tick scale reads real scroll progress, but every route is still an
  empty placeholder, so it has nothing to travel over yet.
- `TraceController` rests at standby and nothing drives it. Task 1.7 owns the
  velocity state machine.
- Recruiter Mode currently changes chrome only — no rail, no route links. Its
  content is task 1.11.
- The three defects from task 1.4 that belong to 1.6b are still open: the
  icon-case 404s, the scaffold `manifest.json` shipping a second chroma, and the
  sitemap's trailing-slash URLs.
- Font budget, stock icon warnings and the Alchemist incompatibility are
  unchanged from worklogs 04 and 05.
- Chrome has not been checked on a real phone browser. `05-TESTING.md` requires
  that before any merge to `main`, and a resized desktop window does not count.

## Next
Task 1.6, the hero and acquisition sequence. It wires the content layer into the
app, which also supplies the footer's coordinate readout, and it is the first
screen with real content for the rail's tick scale to travel over.
