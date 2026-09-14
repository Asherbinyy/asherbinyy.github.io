# 2026-09-14-04 — A torch that lights the wall, and an index to the career

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `106c4fd`

## Goal

The owner's three remaining notes on the wall, sent with a light-mode capture:

1. Hovering should turn the signs gold, as if a torch were being carried past,
   and the stone should come back when the pointer leaves.
2. The burst label was drawn on top of the blocks. It belongs in the gap.
3. The bottom-left of Home was empty. He asked for the stops, in a style that
   suits the page, and for a click to scroll to one.

## What changed

**The light is on its own controller.** This is the part that was actually
broken. The fade was being driven from the scroll ticker, which is the wrong
engine for it: that ticker stops whenever the document is off screen and is
switched off entirely under reduced motion, so the strength never left zero and
the wall changed colour only where a rebuild happened to land. The fade now has
its own `AnimationController`, and the trace listens to the pointer beacon
directly instead of reading it during its build — hover is delivered after
layout, so a layer that reads it while building learns about the pointer a
frame late, which is a frame of the animation lost every time the hand arrives.

**Every sign takes the light, not only the gilded ones.** Distance from the
torch, eased so the pool has an edge, times how far the flame has come up.
Gilded blocks keep their own slow breathing underneath, which is what a phone
and an untouched wall still show.

**The flame blob is gone.** Three blurred rings were drawn at the pointer. On
the dark ground they read as a flame; on the light ground they read as a brown
smudge, which is what the owner's capture shows. Carved gold under a moving
light is the effect; a painted glow on top of it was never part of it.

**The pool is eased, not squared.** The first version fell off as the square
of the distance, which put almost all of the light in the last few pixels: a
block a hand's width from the flame barely moved, and the wall read as tinted
rather than lit. A smoothstep holds the middle of the range up and still falls
to nothing at the edge, and the reach went from 260 to 300.

**The wall clips to its own box.** Found while checking the phone capture: a
course beginning just above the viewport is still drawn, a canvas does not clip
itself, and the top of that sign was being painted over the navigation. Not one
of the three notes, but it is the same wall and it was wrong.

**The burst label moved off the wall.** It sat at `x = 0` inside the column,
which put it on top of the blocks. It is pushed entirely past the column's
leading edge now, into the gap between the copy and the stone.

**The stops.** A short index above the career: a thread, a cartouche for each
stop, the year and the name. Clicking one scrolls the page to that entry. It is
drawn as a route rather than a list of links because the site already calls
these stops and already draws them as cartouches on the atlas — a column of
underlined text there would belong to a different site. Both the index and the
sequence are handed the same ordered list, so the third stop cannot scroll to
the fourth entry.

## Files touched

- `lib/core/painting/wall_painter.dart` — modified — the flame removed; `torchStrength`; every sign lerps to gold under the light; the eased falloff; the clip.
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — the beacon listener and the fade controller.
- `lib/app/chrome/pointer_beacon.dart` — modified — `notifierOf`, for a listener that cannot wait for a build.
- `lib/features/trace/presentation/trace_burst_label.dart` — modified — pushed into the gap.
- `lib/features/station/presentation/widgets/career_stops.dart` — added — the index.
- `lib/features/station/presentation/station_screen.dart` — modified — one ordering for both.
- `lib/app/theme/tokens.dart` — modified — `wallTorchFade` replaces the flame's three radii; the stop geometry.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — two strings for the index.
- `test/widget/trace/trace_test.dart` — modified — the torch, and where the label lands.

## Decisions made

**The fade is animated, not switched.** Leaving the column used to cut the gold
out in one frame, which reads as a glitch rather than as a light being carried
away. 260ms each way.

**Long stop names shrink rather than wrap.** A phone's column is 312px and
"University of Salford" is not; the index may shorten a name, it may not push
the row off the screen.

**Reduced motion gets the light without the flame.** On or off, no ramp.

## Tests

- One widget test drives the whole interaction: hover the wall, assert the
  strength is rising but not yet arrived, hold it and assert it is fully lit,
  leave and assert it dies down and reaches zero. It fails against the previous
  arrangement, which is the point — the defect was invisible to every check
  that existed.
- A second measures the label against the wall's own left edge, so "in the gap"
  is a number rather than an opinion. It has to measure the panel: the card is
  moved by a paint-time translation, which the label's own box does not carry,
  and the first version of the test passed the wrong box and failed.
- Full suite: **700 tests, all passing**, after regenerating the goldens.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 292 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 700 tests
fvm flutter build web --wasm               pass, 48.5s, build/web generated
```

The eighteen golden failures were consequences of the two visible changes and
were regenerated after inspecting the diffs: the propagation map's scrubber
shifted because the Home column is taller, which was traced to
`station_screen.dart` by bisecting the working tree rather than assumed.

Browser evidence, 1440x900 and 390x844, both themes: the pool follows the
pointer and the wall returns to stone when it leaves; the light-mode wall has no
smudge; the stops fill the ground the owner marked; the phone navigation is no
longer painted over.

## Known issues left open

- **The headless driver cannot prove a continuous animation**, only its end
  states. The ramp is proven by the widget test, which controls time directly.
  Chrome's frame loop does run there — an instrumented build showed the fade
  reaching 1 between two pointer moves — but nothing in a screenshot shows a
  fade in progress.
- **Three of Chrome's leaked profiles at a time** are left behind by the
  driver's `close()`; six of them took the machine's load average to 31 and made
  a four-minute build take twenty. Killed by profile name. Worth fixing in the
  driver, which is now Codex's.
- The larger backlog from the owner's voice note is untouched: skills and tools
  from the CV, the Work/Writing merge, the contact cards, the papyrus sound,
  the game's rewards and sound library, the thinner stickman, and Brief.
