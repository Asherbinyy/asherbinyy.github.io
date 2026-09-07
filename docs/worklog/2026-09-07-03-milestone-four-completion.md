# 2026-09-07-03 — Milestone 4 completed

**Agent:** Claude Opus 5 (Claude Code)
**Milestone:** 4
**Started from:** `ddd8e0d` — article covers relayed through this origin

## Goal

Finish milestone 4: the remaining content work, the map's two reported defects,
the CV, the screenshot pipeline, and the release paperwork. The owner answered
the outstanding provenance questions at the start of the session and asked for
the milestone to be run to completion without further check-ins.

## What changed

**Off duty (4.4).** `interests.json`, a model, a parser rule, a provider, and a
grid on `/about`. Six interests in the owner's words with the two specifics he
named. Every tile is legible without interacting with it and the tiles are
deliberately **not** focusable: there is nowhere for one to go, so putting six
stops in the tab order ahead of the contact links would cost a keyboard user
something in exchange for an emphasis they cannot see.

**Coursework as evidence.** `EducationModule` gained an optional `Evidence`.
Two modules carry one — the Power BI dashboard at 94 and the research poster at
80 — as thumbnails that open full size. Both were supplied and cleared by the
owner. **The poster is cropped**: the original carries his name and student
number in a header band, and a matriculation number has no reason to be on a
public page.

**The journey (4.3).** Content half shipped in the previous session; this one
did the two defects the owner reported. The chronology scrubber was six dots,
each drawing its own rail segment inside its own column, so the line never
joined up and nothing said the control could be dragged. It now has a
continuous rail, names the stop it has selected, and is flanked by step
controls — which is the part that makes it operable without a viewer having to
guess. The transmission panel filled with `surfaceRaised`, which is near-white
on papyrus; it fills with `surface` now and carries a short gold rule.

**The CV (4.12).** The PDF is committed, `profile.cvFile` is set, and the
hero's second action reads *Download the CV*. The fallback to the static HTML
page stays: that page is the indexable surface and does not stop existing
because a PDF sits beside it.

**Screenshots (4.13).** `ShippedApp.screenshot`, rendered through the existing
three-stage resolve with the procedural card as the fallback, plus a README in
`assets/media/apps/` covering the convention, the sizes and what not to publish.

**The claim audit (4.1).** `provenance_test.dart` walks the content, extracts
every figure a reader would take as a claim, and fails if it has no row in
`14-PROVENANCE.md`. It guards seven: `25+`, `16+`, `15,000+`, `50%`, `30%`,
`20%`, `4+`. It asserts a figure is accounted for, not that the accounting is
honest — no test can do the second — but it prevents the exact failure that
started this milestone.

## Files touched

- `assets/content/interests.json` — created — the owner's interests
- `assets/content/{education,apps,profile}.json` — modified — evidence, screenshot field, cvFile
- `assets/media/{rt-poster,bdia-dashboard}.jpg`, `assets/docs/…cv.pdf` — created
- `assets/media/apps/README.md` — created — the screenshot convention
- `lib/content/models/{interests,education,apps}.dart` — created/modified
- `lib/content/{content_parser,content_repository,asset_content}.dart` — modified
- `lib/features/about/presentation/widgets/{interests_grid,education_table}.dart` — created/modified
- `lib/features/signal/presentation/widgets/{chronology_scrubber,transmission_panel}.dart` — modified
- `lib/features/work/presentation/widgets/ledger_row.dart` — modified — screenshots
- `lib/features/station/presentation/widgets/cv_button.dart` — modified — download
- `lib/core/widgets/loading/station_card.dart` — modified — overflow fix
- `test/…` — six files modified, `provenance_test.dart` created
- `docs/{11-OPEN-ISSUES,14-PROVENANCE}.md`, `CHANGELOG.md` — modified

## Decisions made

**Guardy ships as an application, not a map stop.** The owner described the
work but not his engagement dates. An application entry needs no dates; a stop
on the map needs a range to sort and label it. Inventing one — even a plausible
one anchored to the store's release date — is what `AGENTS.md` §3 forbids, so
the feature was shaped around the gap. Germany appears in the ledger and in the
countries claim, and not on the atlas. Recorded as open issue 0c.1.

**The journey opens at a university, not a birth.** The owner withdrew Saudi
Arabia and gave Mansoura. Rather than ask for a birth year, the two study stops
already in `education.json` carry it: Mansoura University 2015 and Salford
2026. The map gained an origin and a present **without a single new claim**.

**Malboos lost its featured slot to Guardy.** The parser caps featured entries
at six. Malboos is the only one with no role description — a bare name and a
link, and the weakest row in a six-row recruiter view. An editorial call an
agent made, flagged as 0c.2, reversible with one flag.

**Interests are not focusable.** Recorded above; the accessibility reasoning is
the whole justification and a future agent will otherwise "fix" it by adding
focus.

**Tests derive from content, not from copies of it.** Continued from the
previous session and extended. Eight more assertions that had hard-coded counts
now read `assets/content/`.

## Tests

- Added: 12 — interests (3), evidence (2), scrubber (3), station-card overflow sweep (1), provenance (2), Arabic coverage (1 group)
- Modified: hero CTA label, scrubber selection point
- Full suite: **pass, 583 passing, 0 failing**
- Worker suite: **pass, 34 passing**
- Coverage delta: not measured

## Verification run

```
fvm dart format --set-exit-if-changed .   pass
fvm flutter analyze                        pass — no issues
fvm flutter test                           pass — 583/583
fvm flutter build web --wasm               pass
```

## Known issues left open

- **`/v1/cover` is not deployed**, so `/writing` still draws procedural marks. `npx wrangler deploy` from `worker/`. Issue 0b.12.
- **The Arabic has not had a native read.** Written by an agent under the owner's explicit waiver; `docs/AR-REVIEW.md` is the review surface.
- **`02-SCREEN-SPECS.md` and `07-CONTENT-SCHEMA.md` still describe the ground station.** Neither documents the interests grid, the evidence thumbnails, the redesigned scrubber, the screenshot field or `/ascent`. Deferred through the whole milestone; they should be rewritten as part of milestone 5, when the screens they describe are being rebuilt anyway.
- **`assets/media/apps/` is empty.** The pipeline works; no screenshots exist.
- **Easy Go is still absent.** The owner's live-store-links rule excludes a pub.dev package by accident rather than by intent. Issue 0b.11.
- **The real-phone check has still never been performed.** It has gated every merge to `main` since milestone 1 and remains the one gate a machine cannot run.
- Frame cost for the trace and map has still never been measured in a browser profile.

## Next

**The real-phone check, then merge and tag `v0.3.0`.** Everything in this
milestone is verified in widget tests and a wasm build; none of it has been
seen on a real device, and this milestone changed the palette, the layout of
two screens and the whole Arabic channel.

After that, milestone 5 — and its first task should be rewriting
`02-SCREEN-SPECS.md` and `07-CONTENT-SCHEMA.md`, because they are now three
milestones stale and are two of the four documents `AGENTS.md` §1 tells a new
agent to read first.
