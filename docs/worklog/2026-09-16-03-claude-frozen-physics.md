# 2026-09-16-03 — The climb, frozen, and proved identical in two languages

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `b25bf44`

## Goal

The leaderboard, which the owner picked from the remaining four. Not the board
itself yet: the thing `26-GAME-LEADERBOARD-CONTRACT.md` says has to exist before
any of it can be written — "freeze a versioned physics/PRNG/fixed-timestep
contract **before** implementing replay", and "a JavaScript port that merely
looks equivalent is not proof of agreement".

A submitted score is worth nothing. The only honest leaderboard entry is a seed
and the keys that were pressed, replayed on a server that reaches the same
height. That requires the two implementations to agree exactly, and nothing
about the game made that possible.

## Three reasons it was impossible before

**The random numbers were Dart's.** `math.Random(seed)` is reproducible in
Dart. Re-deriving its internal generator in JavaScript from the SDK source
would have been a guess wearing a contract's clothes.

**The timestep was whatever the frame took.** `step(dt: ...)` was handed the
real frame duration, clamped at 1/30. A replay would have had to reproduce the
frame boundaries of a machine it has never seen. Worse, it meant the game was
not the same game on every device: at 120fps gravity is integrated twice as
finely as at 60, so the same press carried you a different distance. For a
ranking that is not a rounding difference, it is an unfair one — a phone was
playing a measurably different climb from a desktop.

**The shaft did not depend on its seed.** `AscentWorld.seeded` used the seed for
the first forty ledges, and then the recycler built every later one from
`math.Random(nextLedgeId)` — a fresh generator seeded with the ledge's id. Ledge
four hundred was therefore the same ledge in every run anybody ever played.

## What changed

### `AscentRng` — thirty lines, written twice on purpose

A 32-bit xorshift seeded through a murmur3 finaliser. Every product is split
into 16-bit halves so no intermediate exceeds 2^53, which makes it exact on a
64-bit Dart int, on a JavaScript double, and on whatever either language
compiles to next — not merely on the two backends in use today.

Ledges are derived from `(runSeed, id)` rather than drawn from a stream. A shaft
is now a pure function of its seed, and ledge four hundred depends on how the
run was seeded rather than on how many times the recycler had happened to run.

### A fixed timestep of exactly 1/128 second

128 rather than the usual 120 because **1/128 is exactly representable in
binary64 and 1/120 is not**. A dt that carries no rounding of its own is one
fewer thing that can diverge between two languages summing it seventeen thousand
times.

The frame no longer decides the physics, only how many ticks are due.
`AscentSimulation` keeps the debt and pays it in whole ticks, up to eight per
frame; past that the backlog is written off rather than carried, which is the
difference between a moment of slow motion and a locked-up game. Replay is
unaffected either way, because a run is its ticks and not its wall clock.

This also quietly fixes something nobody reported: the climb is now identical on
a 60Hz phone and a 144Hz monitor.

### A tape, instead of a claimed score

The controls have seven states, and at 128 ticks a second nearly every tick
repeats the one before it. A run is stored as runs of identical input, one
varint each, base64url. A two-minute climb is about 1.9KB.

The decoder refuses a code that steers both ways at once, a run of no ticks, two
adjacent runs of the same code — which is how one climb could be split into
arbitrarily many entries to make the decoder work without making the climb any
longer — a truncated integer, and anything past the fifteen-minute ceiling.

### `worker/src/game/ascent.js`

The same physics in JavaScript, transcribed expression for expression rather
than tidied, because floating-point addition is not associative and a neater
arrangement of the same arithmetic is a different answer.

## The proof

`worker/contracts/fixtures/ascent-vectors.json`, generated from Dart by
`tool/generate_ascent_vectors.dart` and **read by both test suites, written by
neither**. A test that can regenerate what it checks against agrees with itself
and proves nothing.

| | |
|---|---|
| Seeds | 0, 1, 7, 2^31-1, 2^31, 2^32-1, and a real timestamp |
| Shafts | 7 × 40 ledges, every field as a raw IEEE-754 bit pattern |
| Runs | 56, reaching 362m over ~16,800 ticks |
| Agreement | metre, tick and ending, exactly |

Doubles are written as bit patterns, not decimals. A shortest-round-trip decimal
would almost certainly survive JSON intact, and "almost certainly" is not the
standard for something people are ranked on.

### The vectors had to be able to climb

The first seven scripts were blind — hold a key, jump on a rhythm — and none
survived thirty seconds. They agreed across both languages about the opening
bounce and nothing else: no cracked ledge giving way, no scarab drifting
underfoot, no ledge recycled, and never the floor beginning to rise at sixty
metres. Two implementations agreeing about the first three seconds of a
three-minute game is not agreement worth ranking anybody on.

So the generator got a bot that reads the world. It took two tries. The first
re-aimed in mid-air, so the instant the climber rose past the ledge it was
jumping for, that ledge stopped being "above" and it steered away from its own
landing — it never passed 11m. The second waited on each ledge until the next
was overhead, which is worse: a target two ledge-widths sideways is off the end
of the one you are standing on, so it walked off the edge every fifth jump.

What works is what a person does. Jump the moment you land, and line up in the
air. Both suites now assert the vectors reach past 300m, or they fail.

### What the second implementation caught

`bits()` on the Dart side used `ByteData.getUint64`. A Dart int is signed, so a
pattern with the top bit set came back wrapped negative and printed with a minus
in front of it — not a bit pattern at all. **Every negative double in the fixture
was written wrong, and the Dart tests passed, because the generator and the test
shared the one broken helper.** The JavaScript side is what noticed, on the drift
of a scarab ledge.

That is the argument for writing it twice, in one bug.

## Files touched

- `lib/features/courtyard/game/domain/ascent_rng.dart` — added.
- `lib/features/courtyard/game/domain/ascent_contract.dart` — added — version, tick rate, bounds, the input code.
- `lib/features/courtyard/game/domain/ascent_tape.dart` — added.
- `lib/features/courtyard/game/domain/ascent_run.dart` — added — the fixed-timestep driver and `replay`.
- `lib/features/courtyard/game/domain/ascent_world.dart` — modified — seeded ledges, a total sort order, `meta` instead of `flutter/foundation`.
- `lib/features/courtyard/game/presentation/ascent_stage.dart` — modified — drives the simulation, sounds every tick of a late frame.
- `lib/features/courtyard/game/presentation/ascent_controls.dart` — modified — the pad emits the recorded input type.
- `worker/src/game/ascent.js` — added.
- `worker/contracts/fixtures/ascent-vectors.json` — added — generated, not hand-written.
- `tool/generate_ascent_vectors.dart` — added.
- `test/unit/features/ascent/ascent_vectors_test.dart`, `worker/test/ascent.test.js` — added.
- `pubspec.yaml` — modified — `meta`.

## Decisions made

**One physics path, not two.** The fixed timestep is what everyone plays, not a
mode qualifying runs switch into. Two paths is how a board ends up ranking
something nobody played.

**The physics does not import Flutter.** It uses `meta` for one annotation, so
the vector generator is a plain `dart run` with no UI framework near it.

**The game ships no bot.** It exists in the generator and nowhere else.

**A rejected tape is told it was rejected, not which check caught it.** That is
a courtesy owed to honest clients and a hint owed to nobody else.

## Tests

- 721 Flutter tests (was 706) and 80 Worker tests (was 70), all passing.
- CI already runs `node --test worker/test/*.test.js`, so both halves of the
  proof are guarded on every push without a workflow change.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 307 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 721 tests
node --test worker/test/*.test.js          pass, 80 tests
fvm flutter build web --wasm               pass, 42.9s
```

## Known issues left open

- **Replay proves a score is reachable, not that a human reached it.** A
  scripted input stream replays exactly like a played one — the generator's own
  bot reaches 362m, which is almost certainly better than any person will. That
  is the honest ceiling of this design and it should be said plainly on the
  board rather than dressed up as anti-cheat.
- **Nothing is stored or submitted yet.** No endpoint, no nickname, no consent
  prompt, no ranking. Next.
- **The board's Worker code will need a home.** The full Worker lives on
  `phase/reinnovation-admin`, which has never merged; `main` carries a smaller
  one. `worker/src/game/` is additive to both, but the leaderboard's storage
  will have to pick a branch.
- The preview adapter, HTML publication parity and A5 are untouched.
