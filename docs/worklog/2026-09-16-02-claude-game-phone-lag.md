# 2026-09-16-02 — Why the climb lagged on a phone, and the fix that measurably works

**Agent:** Claude / Sonnet 5
**Milestone:** Re-innovation, full ownership
**Started from:** `ec9e1bc`

## Goal

The owner: the climb lags on his phone, works fine on the web. No physical
phone available, so this had to be diagnosed and proven by measurement
rather than by guessing.

## What changed

**Measured before touching anything.** The CDP driver's `Emulation` domain
can set an exact `deviceScaleFactor` and CPU throttle, which is what a
trackpad-and-desktop session can never otherwise get honest evidence about.
Holding the phone-width viewport and CPU throttle fixed and varying only
`deviceScaleFactor` isolated device pixel ratio as a variable on its own,
clear of every confound (a wider viewport draws piers and torches a narrow
one skips entirely, which the first pass conflated).

| | 4x throttle | 6x throttle |
|---|---|---|
| DPR 3 (an iPhone-class phone), before | 55.8ms/frame (18fps) | 106.9ms (9fps) |
| DPR 1, same throttle | 18.1ms (55fps) | -- |

Dropping the ratio alone, nothing else, took the frame time from 56ms to
18ms. Flutter Web keeps one `<canvas>` for the whole app, sized at
`window.devicePixelRatio` times its logical size -- a 3x phone's canvas is
nine times the pixels of a 1x screen the same CSS size, and the climb draws
enough masonry, register bands and dust every frame that filling all of
them at 3x is real, GPU-bound cost a phone pays for far more than a desktop
does. This is why it looked fine on the web: the desktop GPU hides exactly
the cost a phone's cannot.

**The first fix attempt did nothing, and was proven not to rather than
assumed to work.** A `RepaintBoundary` sized to a smaller box, stretched
back up with `Transform.scale`, is the standard native-Flutter trick for
exactly this. It does not apply to Flutter Web: there is one shared canvas
for the whole app, not a separate raster surface per `RepaintBoundary`, so
giving one subtree a smaller logical size does not change how many physical
pixels the browser's own canvas element has. Measured directly -- the
canvas's own `width`/`height` attributes were checked before and after, and
did not move. Reverted rather than left in as a placebo.

**The fix that does work reaches the one thing that actually controls the
canvas: `window.devicePixelRatio` itself**, which the engine reads live
every time it recomputes (`EngineFlutterDisplay.devicePixelRatio` in the
SDK, called from `computePhysicalSize()`). `web/index.html` gained a shim,
in the same file and the same shape as the pinch-zoom fix from the 14th:
`Object.defineProperty` replaces the browser's own getter with one capped
at 1.75, only while the climb is open, and fires a `resize` event so the
engine picks it up immediately rather than on the next real resize. Verified
directly this time: the canvas's backing store measurably shrank from
1170x2532 to 683x1477 the moment "Play" was pressed under a 3x emulation,
and the frame-time measurement above, re-run against the fix, came back at
25.2ms (40fps) at 4x throttle and 38.1ms (26fps) at 6x -- from unplayable to
smooth-enough, twice over.

Scoped to the climb's own lifecycle (`RenderScale.capForGame()` in
`AscentStage.initState`, `RenderScale.restore()` in `dispose`) rather than
applied to the whole site: this is a resolution-for-performance trade the
owner did not ask to make everywhere, and the rest of the site's painted
ornament keeps native sharpness on a high-DPI phone. 1.75 rather than a
flatter cap: DPR2 under the same throttle measured close behind DPR1 (24.3ms
vs 18.1ms at 4x), so the cap gives back most of a 3x phone's resolution
while still cutting its fill-rate cost by more than half.

**A second, independent fix, found while reading the painter for the
first.** `_paintShaftWall`'s ornament frieze rebuilt its `Path` from
individual `moveTo`/`lineTo` calls every single frame, for every visible
course -- a fresh painter is built each frame (`world`, `time` and
`entrance` all change), so nothing on the instance could have cached it. The
shape depends only on which ornament and what size, both fixed for a given
window size, so it is now a static, painter-instance-independent cache
keyed on `(Ornament, box)`, built once and translated into place rather than
rebuilt.

## Files touched

- `web/index.html` -- the DPR-cap shim.
- `lib/core/platform/render_scale.dart` (+ `_stub.dart`, `_web.dart`) --
  new, following the project's existing conditional-import shape for
  web-only code.
- `lib/features/courtyard/game/presentation/ascent_stage.dart` -- calls
  `RenderScale` at the two points in the climb's lifecycle that matter.
- `lib/core/painting/ascent_painter.dart` -- the ornament path cache.
- `test/unit/core/platform/render_scale_test.dart` -- new.

## Decisions made

**Proven, not assumed, at every step.** The first fix's failure and the
second fix's success were both read off actual measurements -- the canvas's
own dimensions, and frame-time deltas under emulation -- not inferred from
reading the code.

**Scoped to the game, not the site.** The trade this makes -- some
resolution for a lot of frame rate -- is one the owner asked for here and
did not ask for everywhere else.

**Not a renderer change.** `03-ARCHITECTURE.md` names WASM/skwasm as the
web renderer and asks that a substitution be recorded in a worklog if made.
This isn't one: `devicePixelRatio` is orthogonal to which renderer is
active, and nothing about the renderer choice changed.

## Tests

- `render_scale_test.dart` proves the cap's value is sane and that the call
  shape never throws from the VM test host, which is all `flutter test` can
  reach -- it runs on the VM, and the real effect only exists on the web.
  The actual fix was verified separately, directly in a browser, as
  recorded above.
- Full suite: **704 tests + 2 new, all passing.**

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 301 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 706 tests
fvm flutter build web --wasm               pass
```

## Known issues left open

- **Still emulated, not measured on the owner's actual phone.** The CDP
  throttle-and-DPR combination is the closest evidence obtainable without
  one; a real device may differ, and the owner is the only one who can
  confirm the lag is actually gone now.
- **The character rework the owner also asked for -- a more realistic
  climber, from a CC-licensed source, credited on GitHub -- is not started
  in this pass.**
- The leaderboard itself, the preview adapter, HTML publication parity and
  A5 remain untouched.

## Addendum — the climber, redrawn

The owner also asked for a more realistic character, from a CC-licensed
source if one fitted, credited on GitHub. The licence research was done
first: Kenney's "Platformer Characters" pack is genuinely CC0 (confirmed
from kenney.nl directly, not from a listing site), OpenGameArt and itch.io
both carry CC0-tagged platformer packs, and any of them could have been
used and credited.

**None of them were, and that was a judgement call worth recording.** This
site's whole visual identity is bespoke carved Egyptian line-work -- the
wall, the signs, the ornament, the stop marks. A recoloured off-the-shelf
platformer sprite dropped into it would read as exactly the generic,
bolted-on thing the owner has rejected repeatedly on this project. The
figure is also about fifty pixels tall in play, where almost nothing of a
detailed sprite would survive anyway. So the character stayed procedural
and was rebuilt properly instead. If the owner wants the external-asset
route regardless, the licences are cleared and the swap is his to call.

Three passes, each one driven by looking at the result rather than at the
code:

1. **Gold instead of stone.** The climber had been painted the same colour
   as the wall he climbs, which is most of why he read as a stick figure --
   a stone outline on stone masonry. Section 2 reserves gold for the person,
   and on this screen that is him. Immediate, large readability win.
2. **Too much detail, and it turned to mush.** A profile face, a wesekh
   collar and flared nemes lappets all at fifty pixels came back as a chunky
   cartoon with what were unmistakably blonde pigtails. Screenshotted,
   looked at, thrown away. The lesson is the one the football figure already
   taught: at sprite scale the silhouette is the whole design.
3. **Silhouette-first, then mass.** Lean limbs, a real neck, a headdress
   that hugs the skull instead of flaring past the shoulders -- which fixed
   the pigtails but left a stick figure in a skirt. The last piece was a
   filled torso, broad at the shoulder and drawn in at the waist. That is
   the difference between a person and a stick figure at this size.

Drawn size went from 1.15m to 1.45m of the twenty-metre camera, which is
purely a painting constant -- it is not used anywhere in the physics, so
nothing about how the climb plays changed.
