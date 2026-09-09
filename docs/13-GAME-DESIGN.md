# Game Design — The Ascent

Milestone 6. Route `/ascent`, plus the offline variant on `404.html`.

---

## 1. Why this exists

A portfolio game is usually a liability: it says "I had spare time" rather than
"I can build things". This one has to earn its place, so it is given a job.

**Climbing the obelisk is how you read the CV.**

Every altitude band the player passes unlocks one real fact from the site's own
content — an application shipped, a country worked in, a role held, a mark
earned. The facts are read from the same `assets/content/*.json` the rest of
the site renders, so they cannot drift from it and cannot be invented for the
game. At the summit the player has passed every claim the site makes, in order.

That is the difference between a distraction and the most-shared page on the
site.

**The content is never gated behind reflexes.** Every fact the game unlocks is
also plainly readable elsewhere on the site, and `/ascent` carries a link to
the full list. A recruiter who cannot or will not play a platformer loses
nothing. A game that hides a person's experience behind hand-eye coordination
would be an accessibility failure dressed up as a feature.

---

## 2. The game

**Form.** Vertical endless climber, in the Ice Tower lineage. The player
bounces continuously; the only input is steering left and right; the camera
follows upward; falling below the frame ends the run.

This form is chosen because it is **one axis of input**. It works identically
on a keyboard, a touch screen and a mouse, which no other arcade form does, and
it needs no tutorial.

**Setting.** The interior shaft of an obelisk, climbing toward the pyramidion.

**The shaft is a column, not the frame.** `AscentPainter.shaftOf` centres a
playable column and draws the rock either side of it as masonry. This is the
one structural thing the game gets from Ice Tower and it was missing: with the
whole surface playable, a wide monitor gave the climber a field to wander
across and no sense of being inside anything. The piers grow from zero as the
frame widens, starting above the largest phone, so a phone plays full width and
a desktop plays a column with scenery. Nothing in the piers is collidable.
The walls carry the glyph field from `12-MOTIF-LIBRARY.md` §4, parallaxed.

### Elements

| Element | Behaviour | Motif |
|---|---|---|
| **Stone block** | Static platform | Limestone course |
| **Cracked block** | Breaks after one bounce | Weathered stone |
| **Scarab block** | Drifts horizontally | Motif #7 |
| **Sand shelf** | Bounces lower than stone | — |
| **Ankh** | Collect: one free recovery from a fall | Motif #4 |
| **Gold leaf** | Collect: score | Pigment |
| **Register band** | Every 120m: the climb pauses, a fact resolves on the wall, play resumes | Motif #2 |
| **Pyramidion** | The summit. Reached once every fact is unlocked. | Motif #6 |

**The summit** is the one place the Tutankhamun mask appears on this site
(`12-MOTIF-LIBRARY.md` §1). It is earned, not decorative, and it is the reward
for having read the whole CV the hard way.

### Controls

| Input | Steer | Start / pause |
|---|---|---|
| Keyboard | ← → or A D | Space, Esc to pause |
| Touch | Drag anywhere, or hold left/right half | Tap |
| Mouse | Pointer x-position | Click |

Gestures are handled through the existing platform service. Never branch on
viewport width or user agent — `AGENTS.md` §6.

---

## 3. Sound

The one place on this site that makes noise (`12-MOTIF-LIBRARY.md` §6).

- Six samples, no music bed: bounce, break, collect, ankh, register unlock, fall.
- Short, dry, percussive — struck stone and metal, not orchestral. Anything that sounds like a film trailer is wrong.
- **Fetched at runtime from `assets/audio/`, never bundled into the wasm output.** See §5.
- Total audio budget: **under 120KB** for all six, mono, at a low bitrate. They are 200ms percussive hits; they do not need fidelity.
- Nothing plays before the player starts a run. That is a gesture, which is also what browser autoplay policy requires.
- A mute control is visible at all times and its state persists. Default is **on**, because the player pressed start.
- Licensing: samples must be public domain or CC0, with the source recorded in `14-PROVENANCE.md`. Audio is content, and content on this site has provenance.

---

## 4. Accessibility

A reflex game cannot be made fully accessible, and pretending otherwise is
worse than stating the limit.

- **Full keyboard play**, with visible focus on every control around the canvas.
- **Practice mode**: no falling, no run end. The whole climb is reachable at the player's own pace. Offered on the start screen with equal weight to the standard mode, not buried as an easier option.
- Every unlocked fact is **also** a plain link out to where it lives on the site.
- The canvas carries a label describing what it is and pointing to that list, so a screen-reader user is told what they are skipping rather than meeting an unlabelled canvas.
- Under `prefers-reduced-motion`: parallax off, screen shake off, particles off. Play continues — the game is motion the viewer opted into by pressing start, which is exactly the case the media query is not meant to suppress.
- Pause on window blur, always.

---

## 5. Engineering constraints

**Deferred loading does not work here.** `11-OPEN-ISSUES.md` §3.10 records that
`fvm flutter build web --wasm` emits a single `main.dart.wasm` with no split
parts, so a `deferred` import does not keep the game out of a visitor's
download. Two consequences, both mandatory:

1. **Game code stays small** and depends on nothing new. No game engine package, no physics library. This is one `CustomPainter`, one ticker, and a few hundred lines of collision maths against axis-aligned boxes.
2. **Game assets are fetched over HTTP at runtime**, on entering `/ascent` — audio and any sprite atlas. They are files under `web/`, not entries in `pubspec.yaml`. This is the only mechanism available that actually keeps weight off the first paint.

**Frame budget: 8ms.** Higher than the wall's 4ms and the map's 6ms because it
is the only thing on screen when it runs, and it is the only route allowed to
hold a continuous ticker.

**The loop runs only while `/ascent` is mounted and the tab is visible.** A
ticker left running on another route is a battery bug and a review finding.

**Scores persist in `localStorage`** through the existing
`preference_store.dart`, alongside theme and language. Nothing is transmitted:
no leaderboard, no network call, no identifier. The high score is one integer on
one device.

> Note for milestone 4: the README currently says "Nothing is stored on the
> visitor's device", which is already inaccurate — theme, language and Recruiter
> Mode have persisted since milestone 1. Task 4.1 corrects that sentence. The
> game does not introduce the inconsistency, but it must not inherit it either.

---

## 6. The offline variant

`404.html` already carries the full hand-authored app shell, because GitHub
Pages needs it for SPA deep links (`03-ARCHITECTURE.md` §3). That makes the
Chrome-dinosaur behaviour nearly free: a wrong URL, or a load with no network,
lands on a page that offers the climb instead of an apology.

Constraints: the 404 shell is **hand-written HTML and must stay indexable and
JS-optional**. The offline variant is therefore a small self-contained
`<canvas>` script in `web/`, not the Flutter game — a page that needs the whole
Flutter bundle to tell you the bundle failed to load is a joke at the visitor's
expense. It shares the art direction and nothing else.

---

## 7. Definition of done

- Runs at 60fps on a mid-range Android phone in Chrome, measured in a real profile, not a widget test.
- Full keyboard play; practice mode reaches the summit; every fact links out.
- Facts are read from `assets/content/`, and a test proves the game surfaces no string that is not in the content layer.
- Audio loads at runtime, is mutable, persists that choice, and never plays before a gesture.
- Ticker stops on blur and on route exit — proven by a test, not by inspection.
- Nothing leaves the device.
- The four verification commands pass.
