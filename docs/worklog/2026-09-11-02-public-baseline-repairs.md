# 2026-09-11-02 — Parallel checkout and public baseline repairs

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** 6cfb1f1

## Goal
Prepare Claude's isolated admin checkout and continue the public app concurrently. Repair the confirmed Journey viewport/selection defects and sitemap route drift while the public-rendering decision remains pending.

## What changed
- Created `/Users/sherbini/Flutter Projects/nocturne-admin` on `phase/reinnovation-admin`, starting at the shared audit/handoff commit `6cfb1f1`. The owner confirmed Claude was working on admin when this session continued on 2026-09-12; Codex did not launch or inspect his process.
- Switched the original checkout to `phase/reinnovation-app`. No changes were made to Claude's working files or to Worker source.
- Published the measured chrome content height through `ContentViewport`. Journey gives the heading/timeline their natural height and allocates the remaining space to its map. Very short windows retain scrolling instead of clipping controls.
- Browser inspection found a left-aligned bounded map and wrapped phone year labels. Centered the map, reduced compact page padding using existing spacing tokens and showed full boundary/selected years in the compact timeline.
- Added a localized, keyboard-accessible Close button for inline details. Narrow pointer windows now open the existing dialog; touch uses the existing sheet. Wide touch windows no longer render an additional inline panel behind the sheet.
- Derived sitemap entries from the public route enum and actual project IDs. Removed retired `/signal` and `/privacy` entries and omitted untrustworthy build-clock `lastmod` values. No public route path changed.
- Added viewport and interaction regressions and replaced the stale sitemap spelling assertions with a route/content inventory check. Updated the five Journey visual baselines for the intentional geometry/Close changes.

## Files touched
- `lib/core/platform/platform_scope.dart` — modified — inherited measured content viewport.
- `lib/app/chrome/chrome_scaffold.dart` — modified — supply the visible content height before scrolling.
- `lib/app/theme/tokens.dart` — modified — add `journeyMinContentHeight`; existing token values unchanged.
- `lib/features/signal/presentation/signal_screen.dart` — modified — bounded map/timeline layout and complete selection surfaces.
- `lib/features/signal/presentation/widgets/transmission_panel.dart` — modified — optional localized inline Close action.
- `lib/features/signal/presentation/widgets/chronology_scrubber.dart` — modified — compact boundary/selected-year labels without squeezing all dates into phone columns.
- `tool/generate_static.dart` — modified — current route/project sitemap, no invented modification dates.
- `test/widget/signal/signal_test.dart` — modified — six viewport sizes, horizontal map centering, compact single-line year labels, close/restore, narrow pointer details and short-landscape reachability.
- `test/unit/tool/generate_static_test.dart` — modified — exact public route/project inventory and timestamp rule.
- `test/golden/goldens/signal_*.png` — modified — five intentional Journey snapshots.
- `README.md` — modified — link the separate ownership handoff and contract.
- `CHANGELOG.md` — modified — identify local public repairs separately from historical deployments.
- `docs/11-OPEN-ISSUES.md` — modified — record partial local repairs without closing R1/R4.
- `docs/19-FLUTTER-ENHANCEMENT-PLAN.md` — modified — expose the first app increment and remaining milestone scope.
- `docs/worklog/2026-09-11-02-public-baseline-repairs.md` — created — this record.
- `docs/audits/2026-09-12/README.md` and five Journey PNGs — created — final local-browser evidence, including selected/closed states and two phone sizes.

## Decisions made
- User explicitly requested all admin work be assigned to Claude while Codex continues the app. Prepared an actual separate checkout and a manual launch prompt; did not impersonate Claude with another agent or claim he was running.
- Legacy milestone template slot remains 6; actual work is an initial R1/R4 repair increment, not either completed milestone.
- No package, framework, SDK, palette or existing token value changed. `journeyMinContentHeight = 320` is a new fallback minimum for short-window scrolling; text scaling increases the reservation.
- Measured the actual content viewport rather than estimating browser/nav heights. Map and timeline stay in one layout; long detail content scrolls inside its bounded panel.
- Retained the current central platform convention: narrow pointer details are a dialog, touch details are a sheet. The wide pointer panel uses the existing reduced-motion-aware width animation.
- An absent sitemap modification timestamp is more accurate than stamping all pages with build time. Shared revision timestamps remain an R1 integration task.
- Render migration, navigation merge and final game input remain pending. No owner facts, translations, analytics behavior, production credentials or deployments changed.

## Tests
- Added: ten Journey behavior/geometry tests (six viewport sizes, compact year labels, inline close, narrow pointer selection, short landscape).
- Modified: sitemap inventory/date tests and five Journey goldens.
- Full suite: pass, 676 Flutter passing, 0 failing after final browser-driven corrections. Worker source unchanged; the audit's separate 70-test baseline remains applicable, not a new run in this increment.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 676 tests
fvm flutter build web --wasm               pass, build/web generated (491.4s)
```

Targeted Journey/sitemap run passed 74 tests before the additional short-landscape regression. Initial golden comparison failed all five intentional changed layouts; inspected the output before regenerating, then the five updated goldens passed. Initial analysis reported three import/type/style issues, corrected before the final run. No tests were skipped or deleted. Local documentation links and `git diff --check` pass.

After browser inspection, all 29 Journey tests passed and the five goldens were regenerated/reviewed for centering. The first compact-map test incorrectly required full width even when text height constrained the map; corrected it to the actual invariants (centered map, complete single-line boundary years). The first build passed in 584.2s with the existing icon-font warning. A browser automation selector did not find Flutter's generated Close semantics; use the inspected visible control to verify the browser action and retain the separate widget accessibility/interaction checks. The local preview server maps `/journey` to the app for development; its HTTP 200 does not resolve or verify production SEO-1.

Final build inspected in local Chrome at 1440×900, 1366×768, 390×844, 320×568 and 844×390: no reported runtime exceptions or horizontal document overflow. Viewed the final desktop, selected/closed and small-phone captures. Pointer/keyboard selection with motion enabled opened the right panel; clicking the visible Close control restored the original layout. The final screenshots and limitations are recorded in `docs/audits/2026-09-12/README.md`.

## Known issues left open
- These changes are local. Production deep-link 404 responses, semantic HTML, route metadata, Arabic indexing and content-release parity remain open in R1.
- R4's materials, richer timeline, supplied birth stop/photo and full responsive redesign are not delivered by this repair. Loading-state art and the underlying map artwork remain the old implementation.
- Full immersive Egyptian visual system, intro, game, Work/About and media improvements remain on the roadmap.
- Real iOS/Android device verification remains unperformed. Browser captures are local desktop/phone emulation, not physical-device proof.
- Existing icon-font build warning remains. No new analytics or production writes were used for verification.
- Claude's checkout does not inherit ignored FVM/build/generated artifacts; its README includes setup commands. The owner reports admin work is now active; no admin completion or integration is certified by this app session.

## Next
Claude continues admin in his checkout. Codex resolves the public-rendering choice for R1 and prepares the R2 Home/entrance visual proof before extending the design section by section.
