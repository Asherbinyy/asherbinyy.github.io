# 2026-09-06-10 — Milestone 3, and the owner's four changes

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 3
**Started from:** 1f47d8f

## Goal
Pick up Codex's handoff, which had deployed the Milestone 2 Worker but written
no Milestone 3 code. Complete 3.1 through 3.4, and carry out the four changes
the owner asked for: remove the consent UI, remove `/how-it-was-built`, make
the résumé follow light and dark, and redesign the projects and writing links
as visual, interactive sections.

## What the handoff actually contained
`phase/3-edge` and `fix/analytics-worker-release` held the same two
documentation commits and neither was pushed. The Worker was deployed and
verified. No Milestone 3 source existed.

## Decisions put to the owner first
Three of the four requests were not safe to interpret:

- **The consent teardown.** Removing the prompt without removing what it
  consents to would be the dark pattern `06-ANALYTICS-AND-PRIVACY.md` warns
  about. The owner chose to stop collecting and keep the code dormant.
- **`/how-it-was-built`.** The owner chose to remove the whole page.
- **The Linktree URL.** Codex reported finding it by web search but committed
  nothing, so it did not exist in the repository. An agent-discovered URL for a
  real person's profile is exactly what `AGENTS.md` §3 forbids inventing, so
  the owner supplied `https://linktr.ee/ahmedElsherbini`, which was verified to
  resolve before use.

## What changed

**Collection stops, and the site says so.** The release build supplies no
`ANALYTICS_ENDPOINT`, so there is no sender, no client, and nothing recorded or
written to a device. `analyticsIsCollectingProvider` is the single switch: the
banner does not render, and `/privacy` states plainly that the site collects
nothing and offers no controls.

**`/how-it-was-built` is gone** — route, screen, generator, CI step, strings,
links and tests. `AnalyticsClient.permits` went back to private with the
readout that measured it.

**The résumé and brief follow the reader's theme**, and that work exposed a
defect: `generate_static.dart` still carried the pre-correction palette, so the
two indexable pages were below AA.

**`/work` and `/writing` are visual grids.** `/about` gained a contact section,
which it had lacked entirely.

**Milestone 3.** Campaign capture gated on collection; every measurable
performance budget measured; the accessibility audit written; one easter egg.

## Files touched
- `lib/core/analytics/analytics_providers.dart` — modified — the collecting switch.
- `lib/features/privacy/**` — modified — banner gate and the collects-nothing notice.
- `lib/features/colophon/**`, `tool/generate_build_facts.dart`, `assets/build_facts.json` — deleted.
- `tool/generate_static.dart` — modified — both palettes, per-scheme theme-color, Linktree.
- `tool/fonts.sh` — modified — the Arabic subset ranges.
- `assets/fonts/IBMPlexSansArabic-*-subset.ttf` — modified — 543KB to 303KB.
- `lib/features/work/presentation/widgets/work_card.dart` — created; `ledger_row.dart` — deleted.
- `lib/features/writing/presentation/widgets/article_card.dart` — created; `article_row.dart` — deleted.
- `lib/features/about/presentation/widgets/contact_links.dart` — created.
- `lib/features/station/presentation/widgets/cq_response.dart` — created — the egg.
- `lib/app/chrome/app_nav.dart` — modified — the missing semantic label.
- `lib/app/router.dart` — modified — campaign capture gated.
- `lib/content/models/profile.dart`, `assets/content/profile.json` — modified — Linktree.
- `test/widget/accessibility_test.dart`, `test/unit/performance/budget_test.dart`, `test/widget/station/cq_response_test.dart` — created.
- `docs/{02,11}` and `.github/workflows/ci.yml` — modified.

## Decisions made

**The card grid answers the spec's objection rather than overruling it.**
`02-SCREEN-SPECS.md` argued for a ledger on two grounds: cards would be "twelve
identical rounded rectangles", and they would bury the store links. The artwork
is `StationCard`, seeded per application, so no two match; the store links stay
separately focusable rather than folded into a card-wide tap target. The doc now
records the change and keeps the original reasoning, because it still
constrains the design.

**No decorative hover on a card body.** The design system says motion answers
actions. A card that lights up while offering nothing to press answers nothing,
so the interaction lives on the links, which are real actions with focus rings.

**Campaign capture is gated, not removed.** `/r/:campaign` writes the slug to
`sessionStorage`, and `/privacy` now promises nothing is written to the device.
The redirect still works so a printed or emailed link never 404s.

**The egg uses a global key handler, not a focused listener.** A
`KeyboardListener` only hears keys while focused, and making it focusable would
put the egg in the tab order — intrusive, which is the one thing roadmap 3.4
forbids. It returns false from every event so no keystroke meant for the page
is swallowed, and its height is reserved so an answer reflows nothing.

**The font budget was not met, and was not quietly widened.** 556KB against
480KB. The two options — three Arabic weights or the documented figure — are a
typography decision, recorded as issue 3.12 rather than taken here.

## Defects found and fixed
- **The primary navigation announced nothing to screen readers.** `AppNav` set
  `link: true` with no label while wrapping its visible text in
  `ExcludeSemantics`. Found by the first accessibility run.
- **`/cv` and `/brief` shipped the pre-correction palette**, `--text-muted` at
  3.53:1 — below AA on the two indexable pages.
- **`/r/:campaign` wrote to `sessionStorage`** while `/privacy` claimed nothing
  was written to the device.

## Tests
- Added: 17 accessibility, 7 easter egg, 4 performance budget, 6 static theme
  and palette, 4 dormant-build privacy.
- Modified: the privacy suite now pumps a collecting build, so the dormant
  machinery cannot rot; work and writing tests follow the card rename.
- Full suite: pass, 562 passing / 0 failing. Worker: 26 passing / 0 failing.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (242 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test                           pass (562 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- **3.12** — fonts 556KB against a 480KB budget, needing the owner's call.
- **Frame costs for the trace and map remain unmeasured** in a real browser
  profile. Widget tests cannot measure them; this is the one part of roadmap
  3.2 that could not be completed here.
- **Nothing in this milestone has been seen in a browser**, including the
  Arabic subsets. Goldens render without fonts, so they cannot catch a missing
  glyph — an Arabic visual check matters more than usual after this change.
- **The real-phone check remains unperformed** across all releases.
- The content and asset gaps in §1 are unchanged.

## Next
An Arabic visual check after the font resubsetting, then the phone check, then
merge `phase/3-edge` and tag `v1.0.0`.
