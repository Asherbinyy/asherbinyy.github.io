# 2026-09-17-01 — A climb with levels, a board you can see, and a wall that lights on a phone

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `b69bc9c`

## Goal

The owner's game notes, in full: the climber's head too small against his body,
the board hidden until after a fall, a join sheet full of things nobody asked,
buttons with no padding, a climb that opens at its own full difficulty and never
changes character, no sense of a clock running out, no reason to go sideways,
and phone controls shaped like a keyboard.

## What changed

**The shaft has levels.** Each hundred metres is a different climb, and they are
introductions rather than difficulty dials — one new thing per level, in the
order that teaches it.

| | |
| --- | --- |
| **I** 0–100m | Dressed stone, ledges nearly half the shaft wide. Nothing gives way, nothing moves. |
| **II** 100–200m | Cracked ledges, which hold for one landing. Narrower. |
| **III** 200–300m | Ledges carried across the shaft by scarabs; a landing has to be aimed where it *will* be. |
| **IV+** 300m+ | All three at once, at the narrowest they get. It stops narrowing here. |

The floor is the separate axis: still for the first fifty metres, then a step
faster every fifty. So a level is two steps of pace rather than one — the owner
asked for harder every fifty and a new level every hundred, and tying both to one
number had made the first fifty metres as hard as the second.

**Gilded ankhs.** Above fifty metres a ledge may carry one, floating 1.3m over it
— which is almost exactly the apex of a jump from the ledge below, so they are
taken on the way past rather than gone out of the way for. Ten seconds of a 1.42×
jump, set rather than stacked. They are physics, replayed on the server like
everything else, because an effect that only existed in the widget would make a
verified height disagree with the one on the screen.

**The board is on the left for the whole climb**, top five, medals on the first
three. A leaderboard you only meet after you have fallen is a scoreboard; one you
can see while climbing is the reason to climb. It reads and never reacts — no
taps, no retry button over a live game — and when the board is unreachable the
rail says nothing at all rather than putting an errand on the playfield. A phone
is the exception: at 390 points the shaft *is* the frame, so it stays on the
results.

**The join sheet asks for a name.** That is the whole sheet now. What went was a
paragraph explaining what a public board is, a note about places belonging to
browsers, and a tick box offering to remember somebody in the middle of asking to
be remembered.

**Danger is visible.** The floor was drawn faithfully, and faithfully is
invisible: it sits below the frame for most of a run, so the thing about to end
the climb gave no warning until it arrived. Now the frame darkens from the edges
in, squared so it is faint for most of its range and unmistakable at the end,
with a pulse that quickens as the gap closes.

**The head is 1.28× its measured proportion**, scaled about the chin by a canvas
transform rather than by retyping twelve coordinates measured against the neck
they sit on. Life proportion reads as a pinhead at fifty pixels.

**Phone controls are a pad, not a keyboard.** Steering under the left thumb,
a fat round jump button under the right, both lifted clear of the bottom edge
where a system gesture starts. It was a row across the frame with a long bar on
one end, reachable by neither thumb without moving the hand holding the phone.

**Buttons have padding.** They always had a `Padding`, and it was wrapped around
the *outside* of the decorated box — so it inset each button from its neighbours
and left every label sitting against its own border. That is what the owner was
pointing at in every screenshot, and adding more of the padding already there
would only have spread them further apart.

**Every fifty metres says something**, rather than throwing up a number in a
ring: the floor beginning to move at fifty, a new shaft at each hundred, plain
acknowledgement in between.

## And three things off the game

**Less air on a desktop.** Home separated its sections by a flat 96 points at
every width, which the owner said left the desktop page too spread out. A gap is
read against the width beside it: the same 96 that separates two sections on a
phone reads as a hole on a 1440 monitor with a measure-capped column in the
middle of it. `PlatformService.sectionGap` now *shrinks* as the frame grows —
64 on a phone, 48 above 1024 — which is the opposite of the usual rule and the
right one here. One golden moved; I compared it against its master before
updating it.

**The wall lights on a phone.** The inscription column's whole conceit is
somebody holding a light up to it, and on a phone nobody is: there is no
pointer, `_onPointer` never fires, and the signs sat at their resting colour for
the entire page. On touch the torch is now held at the middle of the viewport
and the wall moves past it — the same gesture as carrying a lamp along an
inscription, and the only one a phone has. It follows the *scroll* rather than
the finger, because a finger is on the wall for a few hundred milliseconds of a
flick and your thumb is over the thing it lights.

**It was broken twice before it worked, and both times it looked fine.** The
first version measured the wall against its enclosing `Scrollable` — which is
null here, because the wall is a fixed viewport-sized layer with the scroll
offset handed to the *painter* rather than to the layout. It bailed on every
call and lit nothing. The second lit it, and then `_onPointer` — which still
fires on a touch device, because browsers synthesise mouse events from taps —
read `null` for the hand, concluded the light had left the wall, and reversed
the flame that had just come up.

Neither showed in a screenshot. The wall's gilded signs breathe on their own, so
a lit wall and a dark one look much the same until you count the pixels: decoding
both captures and comparing mean warmth over the sign strip is what caught it
(−14.48 with the torch off, −14.48 with it "on"). It now measures −12.33, and the
difference is plain in the picture.

Capped at 0.85 rather than 1.0: on a phone the light never leaves, so it is on
for the whole page, and the strip runs close enough to the copy that a full flame
sits behind the ends of lines. 0.42 was tried first and was indistinguishable
from nothing, for the same reason the broken versions were.

**The career signs light too.** The seated scribe, djed and falcon beside each
career entry get the same treatment from the other direction: on touch they
brighten as they pass the middle of the screen, as a halo under the carving
rather than a brighter carving — raising the sign's own colour and leaving the
relief alone turns it from something cut into stone into a sticker.

## Files touched

- `lib/features/courtyard/game/domain/ascent_world.dart` — modified — level modes, boons, the `danger` reading, `generate` made public as contract surface.
- `lib/features/courtyard/game/domain/ascent_contract.dart` — modified — version 2 and what it means.
- `lib/features/courtyard/game/domain/ascent_run.dart` — modified — `boonsTaken` on the outcome.
- `worker/src/game/ascent.js` — modified — the same, in JavaScript.
- `tool/generate_ascent_vectors.dart` — modified — boons in the shaft vectors, and a new `levels` section.
- `worker/contracts/fixtures/ascent-vectors.json` — regenerated — 56 runs, highest 507m, 108 boons taken.
- `lib/core/painting/ascent_painter.dart` — modified — the ankhs, the danger vignette, the lit climber, the larger head.
- `lib/features/courtyard/game/presentation/ascent_stage.dart` — modified — the rail, the boon sound, the fifty-metre lines.
- `lib/features/courtyard/game/presentation/widgets/leaderboard_panel.dart` — modified — medals, five rows, the quiet rail variant.
- `lib/features/courtyard/game/presentation/widgets/join_prompt.dart` — modified — a name and two buttons.
- `lib/features/courtyard/game/presentation/game_control.dart` — modified — padding inside the border; round touch controls.
- `lib/features/courtyard/game/presentation/ascent_controls.dart` — modified — the pad layout.
- `lib/app/theme/tokens.dart` — modified — `ascentRailWidth`; `ascentRewardStep` 100 → 50.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — three mark lines.
- `test/unit/features/ascent/ascent_vectors_test.dart`, `worker/test/ascent.test.js` — modified — the level vectors and the boon count.
- `test/widget/ascent/leaderboard_ui_test.dart` — modified — medals, the five-row cap, the rail, the stripped sheet.
- `lib/core/platform/platform_service.dart` — modified — `sectionGap`.
- `lib/features/station/presentation/station_screen.dart`, `lib/features/work/presentation/work_screen.dart` — modified — use it.
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — the scroll-carried torch on touch.
- `lib/features/station/presentation/widgets/stop_mark.dart` — modified — the phone-only glow on the career signs.
- `test/golden/goldens/hero_unavailable_dark_en.png` — updated — the tighter section gap, compared against its master first.

## Decisions made

**Version 2 rather than a second board.** Everything above changes what a metre
costs, so every entry earned under version 1 was earned on a different climb.
`AscentContract.version` already documents that runs of different versions are
never ranked against each other; this is that rule being used rather than worked
around. The board starts empty.

**`AscentWorld.generate` is public.** The fixture samples it at eighteen heights
per seed, either side of every boundary the generator keys on. No tape the bot
produces reaches the third or fourth level, so without direct sampling two
hundred metres of shaft would be ground neither implementation had ever been
checked on. `@visibleForTesting` was the obvious annotation and is wrong: the
caller is a `tool/` script, not a test, and this genuinely is contract surface.

**The boon roll is drawn unconditionally**, even below the floor where it cannot
be used. `&&` would short-circuit it there and leave the two implementations
reading the same generator from different positions — a divergence that would
surface as one unexplainable rejected score months later.

**`boonsTaken` is part of the outcome, not a statistic.** If the two sides ever
disagree about whether the climber passed near enough to an ankh, the *height*
only differs once the extra lift has changed a landing — a hundred metres later,
or not at all on the run that happened to be recorded. Counting them makes the
disagreement itself the failure.

**Boons are collected over `live`, before recycling, one per tick.** A ledge is
only recycled once it is twenty-eight metres below the climber, so nothing within
reach is ever in that set; doing it there means one place mutates the ledge list
and the recycler never has to know a boon exists. One per tick because the timer
is set rather than added to, so a second ankh inside the same reach would be spent
for nothing.

**The join sheet's disclosure is by naming, not explaining.** The sheet is titled
with the board, the field is labelled *name on the board*, the button says join
it, and the board itself is behind it with other people's names on it. A test
now asserts the paragraph stays gone, because the next person to feel the sheet
is under-explained will reach for one.

**Two Arabic strings were written by me and want the owner's eye.** `ascentMarkFloor`,
`ascentMarkLevel` and `ascentMarkHeight` are new in both languages. Listed under
known issues rather than buried here.

## Tests

- Added: `every level builds the shaft its mode calls for` and `the samples cover every level and both sides of the boon floor` (both suites); `the first three places are marked, the rest are numbered`; `it stops at five, however many the server sends`; `the rail beside the climb drops everything but the names`; `the rail says nothing at all when the board is away`.
- Modified: `says what becomes public before anything is chosen` → `asks for a name and nothing else`; `a choice not to be remembered stores nothing` → `remembers either answer, so it is only asked once`; the run vectors and the coverage guards now assert `boonsTaken`.
- Full suite: pass — 794 passing, 0 failing (Flutter); 106 passing, 0 failing (Worker).

## Verification run

```
fvm dart format .                          clean
fvm flutter analyze --fatal-infos          No issues found!
fvm flutter test                           794 passing
npm test (worker)                          106 passing
fvm flutter build web --wasm --release     ✓ Built build/web
```

## Known issues left open

- **The three new Arabic strings are mine, not the owner's.** MSA, and they read
  correctly, but nobody who speaks it has approved them.
- **The rail was verified by widget test, not in a browser.** There is no
  leaderboard endpoint on the local build, so `isAvailable` is false and the rail
  correctly draws nothing; what a live board looks like beside a running climb
  has not been seen.
- The boon rate (13% of ledges above fifty metres) and the lift (1.42×) are
  first settings, tuned by arithmetic against the ledge gap rather than by
  playing. They are physics, so changing either is version 3.
- **The Courtyard icon was left alone.** The owner asked for it to be made fun,
  recoloured or animated, and added "or leave it as it is if you think what I am
  doing is too much". There is no icon on the Courtyard destination to change —
  the header nav is text — so rather than guess which mark he meant and redecorate
  something he was not looking at, it is untouched and flagged here.
- **"Phone-only glow on the hieroglyph icons" was read as two things**, because
  there are two sets of hieroglyphs on a phone: the wall signs behind the reading
  column and the carved signs beside each career entry. Both now light. If he
  meant only one, the other comes back out in a line.

## Next

Play it. Everything above is verified correct and none of it is verified *fun* —
the difficulty curve, the boon rate and the lift are the three numbers most
likely to be wrong, and the only way to find out is a few runs.
