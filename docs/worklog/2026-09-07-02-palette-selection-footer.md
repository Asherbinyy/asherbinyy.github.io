# 2026-09-07-02 — Tasks 4.10, 4.8 and 4.9

**Agent:** Claude Opus 5 (Claude Code)
**Milestone:** 4
**Started from:** `bef4bc9` — the milestone-4 planning commit

## Goal

Ship the three milestone-4 tasks that needed nothing from the owner: the new
palettes, selectable text, and the footer coordinate removal. Then resolve as
many provenance questions as could be answered without him.

## What changed

**4.10 — the Kemet and Deshret palettes.** Both shipped, with `faience` and
`faienceDim` added as the interaction pigment. Kemet's base moved from
`#05070A` to `#121826` — 4.4× the relative luminance, which is the owner's "too
dark" answered with a measurement rather than a feeling.

`contrast_test.dart` gained rows for both faience roles and a regression test
asserting Kemet sits off pure black. The 36 golden failures were all
colour-driven; regenerated and reviewed by eye in both themes.

**4.8 — selectable text.** `SelectionArea` wraps the content column. It
excludes the header, rail and footer deliberately, so a drag that begins on a
control does not become a text drag. Three tests hold the boundary in both
directions.

**4.9 — the footer coordinate.** Removed, along with `_latitudeOf` and the
`coordinate` parameter. Nothing replaced it.

**Provenance work.** Four owner decisions recorded, and a store-link sweep run
against the iTunes lookup API: **all eight live iOS links in `apps.json` still
resolve**, no rot since milestone 1. **Guardy's listing is verified** — Guardy
GmbH, Navigation, first released 2024-07-17, now v3.0.1, which is consistent
with the owner's account of building v1 as a freelancer.

The owner's rule for the sixteen LinkedIn projects is **live store links only**.
A search found no live App Store listing for Meswak, Spix, Moawda, Kafu, Weze,
Jumper or Absher, so the rule excludes most of them on its own.

## Files touched

- `lib/app/theme/tokens.dart` — modified — both palettes replaced
- `lib/app/theme/theme_tokens.dart` — modified — `faience`/`faienceDim` through the constructor, fields, `copyWith` and `lerp`
- `lib/app/chrome/app_footer.dart` — modified — coordinate parameter and readout removed
- `lib/app/chrome/chrome_scaffold.dart` — modified — `_Footer` no longer reads career; `SelectionArea` added; three imports dropped
- `test/unit/app/theme/contrast_test.dart` — modified — faience rows, off-black regression test, theme names
- `test/unit/app/theme/theme_test.dart` — modified — value guards updated to the new palettes
- `test/widget/chrome/chrome_test.dart` — modified — three selection tests
- `test/widget/station/station_test.dart` — modified — coordinate test inverted
- `test/golden/goldens/*.png` — modified — 36 regenerated
- `docs/11-OPEN-ISSUES.md`, `docs/14-PROVENANCE.md` — modified — five items closed, verification recorded

## Decisions made

**The palette shipped in milestone 4 rather than 5.** Colour is cheap and
high-value; form is expensive. Sequencing them apart fixes a live complaint now
and means milestone 5 never repaints anything twice.

**`SelectionArea` wraps the content column, not the frame.** Selection over the
chrome would let control drags become text drags, and no chrome text is worth
copying.

**The coordinate test was inverted, not deleted.** `AGENTS.md` §4 forbids
deleting a failing test to get a green run. The behaviour was deliberately
removed, so the test now asserts its absence and carries the reason — a removed
feature with no test is one a future agent reinstates.

**Nothing replaced the coordinate.** The footer is one 48px row; the honest
response to a flourish that was not working is removal, not substitution.

**"Manchester" was left in the footer.** The owner's objection named the city as
well as the latitude, but a footer location is ordinary and true, and removing
it would be acting on an inference about what he meant. Flagged in
`11-OPEN-ISSUES.md` 0b.7 for him to settle.

## Tests

- Added: 3 (`text selection` group in `chrome_test.dart`), 1 (`Kemet sits off pure black`), 2 faience contrast roles across both themes
- Modified: `theme_test.dart` value guards; `station_test.dart` footer test inverted
- Full suite: **pass, 559 passing, 0 failing** (was 556 before the new tests)
- Coverage delta: not measured

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — 241 files, 0 changed
fvm flutter analyze                        pass — no issues
fvm flutter test                           pass — 559/559
fvm flutter build web --wasm               pass — built build/web
```

The build still emits the Material/Cupertino icon-font warning, which is the
long-standing cosmetic issue 3.7 and not new.

## Known issues left open

- **The goldens were reviewed on a machine without the bundled fonts loaded**, so text renders as blocks in them. Colour and geometry were verifiable; type was not. The real check is the phone check, still never performed.
- **The palette has not been seen in a browser**, only in widget-test rasters. Gold coverage is specified at under 8% of any viewport and that has not been measured on a real page.
- `docs/02-SCREEN-SPECS.md` and `docs/07-CONTENT-SCHEMA.md` still describe the ground station. Unchanged from the planning session.
- Eleven items remain open in `14-PROVENANCE.md` §3, and they block most of the remaining milestone-4 tasks.

## Next

**Task 4.2 — Guardy into `apps.json` and `career.json`**, because it is the one
content addition whose external facts are now verified, and because it is what
makes the "six countries" claim in 4.1 true rather than an overstatement.

It still needs the owner's engagement dates and what he built (§3.1). Without
them the entry can carry the app, the market and the store link, but not a role
line — and inventing one is exactly what `AGENTS.md` §3 forbids.
