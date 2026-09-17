# 2026-09-16-04 — A leaderboard that checks the climb instead of believing it

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `aa65525`

## Goal

The board itself, on top of the frozen physics from `2026-09-16-03`: endpoints,
storage, the participant flow and the screen. `26-GAME-LEADERBOARD-CONTRACT.md`
end to end.

## The measurement that decided the architecture

Server-side replay is pure CPU, so the first thing to do was time it rather than
guess: **331k ticks a second**, which is ~50ms for a two-minute climb and ~350ms
at the fifteen-minute ceiling, on a developer laptop. A Worker isolate is
slower.

Cloudflare's documented limit is **10ms of CPU per request on the Workers Free
plan**, against 5 minutes on Paid. Ten milliseconds buys about twelve seconds of
gameplay. There is no run-length cap that makes single-shot verification fit on
the free plan — the feature the owner asked for could not be built the obvious
way at any setting.

That is a decision about money, not engineering, so it went to the owner with
four options. He chose to stay on the free plan and verify in the background.

**So a run is replayed about five hundred ticks at a time**, each chunk in its
own Durable Object alarm with a fresh budget, and a submission answers `202
pending` until the last chunk lands. The board settles a few seconds after you
land instead of instantly. The climber is held to exactly the same standard,
and both suites require chunked and single-pass replay to reach the same metre
on every vector in the fixture — at chunk sizes of 1, 7, 13, 512 and 997, because
a chunking bug that only shows at one size is the kind that ships.

A 26% speed-up came free while checking this: the per-tick ledge sort only has to
run on a tick that actually recycled a ledge, which is a few hundred of a hundred
and fifteen thousand. Same array either way; the vectors still agree bit for bit.

## What the design refuses to do

**The client never reports a score.** It sends the seed it was given and the
keys that were pressed. The height is whatever the server reaches replaying
them. `metres` on the results screen is what that screen prints, and the board
never sees it.

**The server picks the shaft.** A client choosing its own seed could grind
offline for an easy one, so a run begins with a signed challenge carrying seed,
physics version, expiry and the player it was issued to. A tape is only ever
replayed against a seed inside a signature, and a challenge issued to one
participant cannot be submitted by another.

**A player is a value their own browser made.** 128 random bits, stored only as
its SHA-256, never derived from the device, the browser or the network — a value
that was would be a fingerprint, which is the one thing this must not be. No
name, no email, no account, no IP. It identifies a browser rather than a person
and **the board says so on itself**, next to the line saying every height was
replayed on the server. Both are load-bearing claims and neither belongs in a
tooltip.

**Nothing is stored before an explicit choice.** A visitor who plays and looks at
the board stores nothing and sends no player key. Declining without being
remembered stores nothing either, and actively clears any earlier answer.

**Nothing is kept that does not need keeping.** The board holds ten entries. A
climb that is real but outside the ten is discarded in the same operation that
judged it. A run being verified holds its tape for as long as the check takes
and its verdict for ten minutes, then the object deletes itself. No score
history, no rejected-submission log, no replay archive.

## Ranking, said once

`rankInto` is a pure function, so the rules are testable without a Durable
Object, a network or a clock. Higher first; a tie to whoever was accepted first;
and the player hash breaks the tie in the tie, because a comparator that can
return 0 for two different entries leaves their order to whatever sort the
runtime ships. One player holds one place and only ever improves it — a good run
does not get to push its own author down a row.

The whole read-modify-write is inside `blockConcurrencyWhile`. Input gating
would very likely have covered it, since every await between read and write is a
storage call, and "very likely" is the wrong standard for the operation that
decides whether somebody's climb counted — one `await fetch()` added in the
middle later would break it in silence. **The test fake deliberately provides no
gating**, so the eleven-entries race is testing this code rather than testing
Cloudflare.

## What the second implementation caught, again

Two bugs found by things other than reading the code.

`ByteData.getUint64` is signed in Dart, so every negative double in the vector
fixture had been written with a minus sign in front of it — and the Dart tests
passed, because the generator and the test shared the one broken helper. The
JavaScript side found it on a scarab ledge's drift. (That one is written up in
`2026-09-16-03`; it belongs here too as the reason for writing it twice.)

And the reply to one climb's submission could clear a challenge fetched for the
*next* run, after which the next climb would quietly stop counting with nothing
on screen to say so. Found by asking what happens when two unawaited futures
touch the same field.

## Asked at the end of a climb, not the start of one

Three things were originally at the top of `_start` and all three were wrong
there.

Asking before the first run is asking whether somebody wants to be on a
scoreboard for a game they have not played. Asking without checking the board
exists meant that on the site as deployed today — relay configured, leaderboard
not — every visitor would have been offered a place on a board that is not
there, and then shown "the board is not answering" under their score. And
fetching the challenge in front of the Play button put a six-second network
timeout between a visitor and a game.

All three now happen while the results are on screen. Until the Worker has the
bindings, the climb is exactly the game it was.

## Four states, four sentences

The board distinguishes loading, empty, unreachable and populated, because an
empty board is a real answer meaning nobody has climbed yet — and collapsing it
with "unreachable", which is the usual shortcut, tells a visitor whose wifi
dropped that they are the first person ever to play.

The results line does the same: checking, verified and ranked, verified and
outside the ten, verified but not your own best, could not be verified, and *on
this device only*. One hopeful line for all of them is how a local score ends up
looking like a rank.

## Files touched

New: `worker/src/game/{board,verifier,leaderboard}.js`,
`worker/test/leaderboard.test.js`,
`lib/features/courtyard/game/domain/leaderboard.dart`,
`lib/features/courtyard/game/data/leaderboard_client.dart`,
`lib/features/courtyard/game/presentation/leaderboard_controller.dart`,
`lib/features/courtyard/game/presentation/widgets/{leaderboard_panel,join_prompt}.dart`,
`test/unit/features/ascent/leaderboard_test.dart`,
`test/widget/ascent/leaderboard_ui_test.dart`.

Modified: `worker/src/{index,game/ascent}.js`, `worker/README.md`,
`ascent_stage.dart`, `preference_store.dart` (+`remove`), both `.arb` files
(25 strings, English and Arabic).

## Tests

- **749 Flutter tests** (was 721) and **99 Worker tests** (was 80).
- Browser evidence, because this rewrote the game loop and reading the code has
  twice agreed with passing tests and been wrong on this project: Play then six
  taps of space took the climb 0 m → 3 m, airborne, shaft scrolling under the
  camera, one canvas at 2240×1505 for a 1280×860 view — `devicePixelRatio` still
  capped at 1.75 — and nothing thrown.

```
fvm dart format --set-exit-if-changed .   pass, 314 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 749 tests
node --test worker/test/*.test.js          pass, 99 tests
fvm flutter build web --wasm               pass, 51.2s
```

## What the owner has to do

Nothing works until the Worker has two Durable Object bindings, a migration and
one secret. The exact config and the reasoning are in `worker/README.md`. Until
then the Worker answers `503 Leaderboard is not configured`, the client treats
that as absent, and the game is unchanged.

## Known issues left open

- **Replay proves a score is reachable, not that a human reached it.** A
  scripted input stream replays exactly like a played one — the vector
  generator's own bot reaches 362m, almost certainly better than any person
  will. That is the honest ceiling of this design. It is not currently said on
  the page, and probably should be if the board ever attracts a cheat.
- **Not deployed and therefore not proved end to end.** Everything is tested
  against fakes, including the Durable Objects. The first real deployment is the
  first time an alarm actually fires.
- **The chunk size is chosen with room rather than tuned.** `Date.now()` does
  not advance during computation in a Worker — a timing-attack mitigation —
  so a chunk cannot measure itself, and 512 is a guess with a wide margin.
- **Nickname handling is not moderation** and does not pretend to be. It removes
  what breaks a page: control characters, bidi overrides, invisibles, links.
  A board of ten entries is small enough for the owner to read.
- **The board's Worker code will need a branch decision.** The full Worker lives
  on `phase/reinnovation-admin`, which has never merged; `main` carries a
  smaller one. `worker/src/game/` is additive to both.
- The preview adapter, HTML publication parity and A5 are untouched.
