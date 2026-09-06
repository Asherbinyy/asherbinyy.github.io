# 2026-09-06-07 — Daybreak verified, and seven palette values corrected

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 2
**Started from:** 635ee13

## Goal
Task 2.2 — Daybreak as a second identity, not an inversion, with contrast
verified in both themes.

## What the task turned out to be
Both palettes were already transcribed exactly from `01-DESIGN-SYSTEM.md` §2
by task 1.1, and the second-identity half of the definition of done already
held. What did not exist anywhere in the repository was any contrast
verification at all — no `meetsGuideline(textContrastGuideline)`, no ratio
check, nothing. So "contrast verified in both" had never actually been done,
and performing it honestly failed in **both** themes.

## The failures, before correction

| Theme | Role | Measured | Needed |
|---|---|---|---|
| Nocturne | `--text-muted` — metadata, timestamps | 3.53 | 4.5 |
| Nocturne | `--beacon-dim` — corner ticks | 2.99 | 3.0 |
| Daybreak | **primary CTA label on its own amber fill** | **4.07** | **4.5** |
| Daybreak | `--beacon` as text — burst labels, ledger links | 4.07 | 4.5 |
| Daybreak | `--instrument-mid` — secondary data, axis labels | 3.86 | 4.5 |
| Daybreak | `--text-muted` | 3.29 | 4.5 |
| Daybreak | `--instrument-dim` — gridlines, inactive data | 2.32 | 3.0 |
| Daybreak | `--beacon-dim` | 1.92 | 3.0 |

Two of these mattered more than the rest. The Nocturne `--text-muted` failure
was **live on the published site** — it paints the footer, ledger metadata, the
chronology scrubber, transmission panels and the career sequence. And the
Daybreak CTA failure hit the single most important interactive element in that
theme.

No large-text allowance applies to any of them. WCAG's threshold is 24px, or
18.66px bold; the largest role in this scale carrying a non-primary colour is
`heading` at 22px, and the failing roles are painted at 11px, 13px and 14px.

## What changed
- Added `test/support/wcag.dart` — the WCAG 2.1 ratio around Flutter's own
  `computeLuminance`, the AA thresholds, and a failure message that reports the
  measured ratio and the shortfall rather than "expected true, got false".
- Added `test/unit/app/theme/contrast_test.dart` — 25 tests checking every
  palette role against every surface it is painted on, in both themes, plus
  three asserting the two themes are distinct artifacts rather than inversions.
- Corrected seven token values, each a lightness-only move that left hue and
  saturation alone. Daybreak: `--beacon` `#A8620C`→`#95570B`, `--beacon-dim`
  `#C9A878`→`#A37B41`, `--instrument-mid` `#6B7887`→`#5B6773`,
  `--instrument-dim` `#A79C89`→`#8E806A`, `--text-muted` `#778395`→`#5C6676`.
  Nocturne: `--text-muted` `#57687B`→`#70849A`, `--beacon-dim`
  `#7E5720`→`#875D22`.
- Updated `01-DESIGN-SYSTEM.md` §2 to the corrected values, and added a
  subsection stating that contrast is a constraint on the palette rather than a
  review step, with the CTA's label-on-fill case spelled out.
- Regenerated all 36 golden baselines.

## Files touched
- `test/support/wcag.dart` — created — WCAG ratio, thresholds, and a diagnostic assertion.
- `test/unit/app/theme/contrast_test.dart` — created — the palette contrast suite.
- `lib/app/theme/tokens.dart` — modified — seven corrected palette values.
- `test/unit/app/theme/theme_test.dart` — modified — the seven transcribed values it asserts.
- `docs/01-DESIGN-SYSTEM.md` — modified — §2 values, plus the contrast subsection.
- `docs/11-OPEN-ISSUES.md` — modified — rows 3.8 and 3.9.
- `test/golden/goldens/*.png` — modified — 34 baselines, colour-only.
- `docs/worklog/2026-09-06-07-daybreak-contrast.md` — created.

## Decisions made

**The owner authorised the palette change.** These are design-system values and
`AGENTS.md` §6 makes tokens the design system's to define, so the eight
failures and the computed corrections were put to the owner with the
alternatives — Daybreak only, the two worst only, or record the failures as
accepted non-compliance — and they chose to apply all of them across both
themes.

**Corrections move lightness only.** Each value was solved by walking its HSL
lightness in 1/2000 steps until it cleared its target against every surface it
appears on, keeping hue and saturation fixed. That is what stops an accessibility
fix from quietly becoming a redesign: Daybreak's amber is still the same amber,
just deeper. Daybreak needed five of the seven because dark ink on warm paper
has far less headroom than light ink on near-black.

**The primary CTA is checked as its label on its own fill, not as amber on the
page.** `BeaconButton` fills with `--beacon` and labels in `--void`, so the
page-background ratio would have measured a pair that never appears. The hover
state is checked separately against `--beacon-glow`, which in Daybreak is
*darker* than the rest state rather than brighter — correct for paper, and it
passes at 6.70.

**`--hairline` and `--hairline-strong` are deliberately outside the suite.**
They draw structural rules and panel edges. WCAG 1.4.11 covers visual
information required to identify components and their states, which decorative
edges are not, and where an edge does carry state the focus ring carries it.
Both would fail at 3:1 if included — 1.69 and 2.32 — so this exclusion is
recorded as open issue 3.9 rather than left implicit, and 3.3's audit can
overturn it.

**The 34 changed goldens were reviewed before regenerating.** Diffs ran 0.01%
to 2.06%. An isolated diff showed solid fills at existing element positions with
no doubled edges, which is a colour change; a layout shift would have ghosted.
The Daybreak frames still read as a technical drawing on warm paper, with the
map graticule now legible where it had been near-invisible at 2.32:1.

**The second-identity half needed proving, not building.** Three tests now
assert it: Daybreak's base is warm where an inversion of Nocturne's blue-black
would be cool, both themes raise panels *toward* light rather than mirroring
each other, and Daybreak's amber is darker than Nocturne's rather than reused.
All three passed before any correction, so Daybreak was already a genuine
second artifact — it was only illegible.

## Tests
- Added: 25 in `contrast_test.dart` — 22 palette-role checks across both
  themes, and 3 asserting the themes are distinct artifacts.
- Modified: `theme_test.dart`, for the seven corrected values it transcribes.
- Full suite: pass, 460 passing / 0 failing (424 non-golden, 36 golden).
- Coverage delta: 93.44%, unchanged — the new tests cover token data rather
  than new executable lines.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (202 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test                           pass (460 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
`docs/11-OPEN-ISSUES.md` carries the register. New this session: 3.8, that
`05-TESTING.md`'s tap-target, semantic-label and keyboard-traversal tests are
still unwritten and belong to roadmap 3.3; and 3.9, the deliberate
hairline exclusion above.

The palette correction has not been seen in a browser. The goldens render
without fonts, so they confirm colour but not the finished typographic texture
of Daybreak on a real screen.

## Next
Task 2.3, writing — the Medium feed, cached and failing silently. It needs the
Worker to proxy the RSS, since the browser cannot fetch `medium.com` directly
across origins. `/about` should be folded in with it, per open issue 3.3.
