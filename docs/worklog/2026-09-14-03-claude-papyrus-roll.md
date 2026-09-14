# 2026-09-14-03 — Papyrus, on the two cards that asked for it

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `84ec67d`

## Goal

The papyrus interaction, which the handoff records as still unimplemented:
the two home figures roll closed on a click and open again when the pointer
leaves or on a second click. Only those two.

## What changed

The two figures are drawn on papyrus now — the same `PapyrusPainter` the
Journey atlas is drawn on, so it is the site's existing material rather than a
new one, and it stays inside the four-pigment rule by using `surfaceRaised`
with fibre and a torn edge instead of introducing a cream.

**The roll.** Click and the bottom edge lifts and winds upward: the sheet
shortens, the cylinder travels up the card, and the writing goes with the sheet
it is written on. Three things do the convincing. The cylinder thickens as it
winds, on a square root, because the first turn adds most of the thickness and
the tenth adds almost none. It is lit from above, with a dark underside and a
band a third of the way down, because without a gradient a cylinder reads as a
flat bar. And a short shadow above it bends the flat part into the roll rather
than letting the two meet at a corner.

**Pointer exit reopens it.** Not a flourish — a card rolled shut hides the
control that would reopen it, so leaving it is the way back. Touch has no
pointer to leave, so there the second tap is the whole story.

**Both cards are now the same size**, which was a separate complaint: one grew
to its text and the other did not. A sheet is a sheet, and a roll needs a known
height to wind into anyway.

## Files touched

- `lib/core/painting/papyrus_roll_painter.dart` — created — the cylinder, its shading and the bend.
- `lib/core/painting/papyrus_painter.dart` — modified — the reed count is a parameter now.
- `lib/features/station/presentation/widgets/papyrus_stat_panel.dart` — created — the card and its states.
- `lib/features/station/presentation/widgets/hero_content.dart` — modified — the first two figures get it.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — the roll hint.
- `test/widget/station/papyrus_roll_test.dart` — created — six behaviours.
- `test/widget/station/station_test.dart` — modified — counts both treatments.
- `test/golden/goldens/hero_stats_dark_en.png` — modified — reviewed before accepting.

## Decisions made

**The reed count is a parameter.** The sheet painter was written for the atlas,
where 34 fibres across a wide panel read as a weave. At 200px the same count
reads as millimetre graph paper, which is the opposite of the material. The
card asks for 13 by 8.

**Reduced motion still rolls, instantly.** The open/closed state is
information. Removing the interaction would leave the card with nothing to do,
which is not what the preference asks for.

**Only the first two.** Written as a named constant on `HeroContent` rather
than a bare 2 at the call site, so the reason survives. A third figure, if the
owner adds one, gets the ordinary panel — and the golden shows exactly that.

## Tests

- Added six in `papyrus_roll_test.dart`: starts flat; a click closes it; a
  second click opens it; the pointer leaving opens it; reduced motion rolls
  without travel; the figure is announced with its label.
- Full suite: **pass, 699 passing, 0 failing.**

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 699 tests
fvm flutter build web --wasm               pass, build/web generated
```

Driven in Chrome at 1440x900: clicked, sampled mid-roll, and confirmed the
pointer leaving reopens it. Frames in `docs/audits/2026-09-14/papyrus-roll/`.

Two real defects were caught by doing this rather than by reading it. The first
version painted the cylinder over a sheet that was still full height, so it read
as a bar lying on a card rather than as a roll; the sheet had to be clipped to
the same exposed region as its contents. The second was the fixed height: Arabic
sets taller and wraps the label to two lines, so a height that fitted English
overflowed the Arabic card by eight pixels. The label is `Flexible` now as well
as the card being sized for the taller of the two.

## Known issues left open

- The cylinder at full roll reads a little flat; more contrast between its lit
  band and its underside would help.
- The right-hand third of the hero is still the five ornament rows the owner
  said he did not like. Untouched so far.
- Home still prints skills as three grey sentences, unlike About.
- The career column is still a column, not the grid the owner asked for, and
  still runs oldest-first rather than most-recent-first.
- Everything else from the handoff: real Flutter preview, HTML release parity,
  content renderers, A5, both halves of the leaderboard, football, game, intro.

## Next

The rest of Home: skills, the career grid and its order, then the right-hand
column.
