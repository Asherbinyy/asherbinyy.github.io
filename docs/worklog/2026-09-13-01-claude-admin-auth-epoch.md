# 2026-09-13-01 — The authentication epoch

**Agent:** Claude / Opus 5
**Milestone:** 6 (legacy template slot); actual work is **Re-innovation R3**
**Started from:** `cb13007`, on `phase/reinnovation-admin`
**Previous worklog:** `2026-09-12-04-claude-admin-rereview-fixes.md`

## Goal

Codex confirmed ARR-1/2/3 fixed and 270 Worker tests passing, and found one
more P1: a login that read the password verifier before a rotation, and
finished after it, still got a session.

## What changed

Deriving a key takes long enough for a rotation to complete underneath it. The
login had verified against a password that no longer opened anything, and
nothing between that verification and the session write checked whether it was
still true.

There is now an **authentication generation**. Rotating the password writes the
verifier, advances the generation and clears every session in **one
transaction**. A login carries the generation it verified against, and the
session is issued only if that is still current — decided inside the store,
not by the caller. A session also carries its generation and is rejected if it
has been superseded.

The deployment secret is not verified against a generation, because rotation
does not change it. Its session takes whatever generation is current at the
moment it is written, inside the same serialised step, so it is either wiped by
a rotation that has not run yet or stamped with the one that has.

## Files touched

- `worker/src/store.js` — modified — the generation, transactional rotation, conditional session issuance, superseded-session rejection; the same shape in the fallback, unsafely.
- `worker/src/index.js` — modified — login carries its verified generation; rotation is one call; issuance is conditional.
- `worker/test/store.test.js` — modified — 8 further tests.
- `worker/README.md` — modified — what the generation is for.

## Decisions made

**Rotation is one operation, not a write followed by an invalidation.** The
previous pair could half-apply: a new verifier with old sessions alive, or the
reverse. There is a test injecting a failure on the generation write and
asserting the old password, the old sessions and the old generation all
survive intact.

**Two simultaneous rotations both apply, and the loser is told.** Both are
authorised by the deployment secret, so both write; the generation advances
once each; exactly one password ends up working; and whichever caller was
superseded gets a 401 with `reason: 'password-rotated'` rather than a session
that would not authenticate. Rare, but it should not be silently wrong.

**The refusal message had to work in two places.** It is reached from a sign-in
and from a password change, so it reads "The password changed while this was in
progress. Sign in again." rather than naming either.

## Tests

- Added 8 in `store.test.js`: a login held open across a rotation is refused;
  it leaves no session behind; the new password works immediately; a session
  from before a rotation stops authenticating; a session stamped with a
  superseded generation is refused; two racing rotations leave one password and
  advance the generation once each; an interrupted rotation changes nothing;
  the deployment secret is unaffected by a rotation in flight.
- Worker suite: **pass, 278 passing, 0 failing** (was 270).

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 278 tests
a1 27/27  a2 21/21  a3 18/18  a3-preview 15/15  a4 19/19  a6 18/18
review-fixes 18/18                         136 browser checks
```

Codex's reproduction script, run against this branch, returns **401** where it
asserted 200 — the old-password login is refused after rotation, so its
defect assertion fails, which is the intended outcome.

One of my own assertions was wrong twice before it was right: I expected both
racing rotations to return 200, and then expected the generation to be 2 when
setting the fixture password had already advanced it to 1. Both were my
expectations rather than the contract; the behaviour was correct in each case.

## Known issues left open

Unchanged, and all still true:

- **The binding is not enabled**, so a deployment today runs on the unsafe
  fallback. The generation is checked there too, but nothing makes it atomic —
  it narrows the window rather than closing it.
- **Live preview, HTML publication, A5 and the four field consumers** are open
  and belong to Codex.
- **The leaderboard** in `docs/26-GAME-LEADERBOARD-CONTRACT.md` is my next
  piece of work and is not started.
- **No real-device or screen-reader check has ever run.**

## Next

The Worker half of the leaderboard contract: the endpoint shapes, the seeded
replay, and the ten-entry transactional ranking.
