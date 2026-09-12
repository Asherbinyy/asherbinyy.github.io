# 2026-09-12-04 — ARR-1 to ARR-3 from Codex's re-review

**Agent:** Claude / Opus 5
**Milestone:** 6 (legacy template slot); actual work is **Re-innovation R3**
**Started from:** `afc8969`, on `phase/reinnovation-admin`
**Previous worklog:** `2026-09-12-03-claude-admin-review-fixes.md`

## Goal

Codex re-reviewed `afc8969` and found three more races that the 262 passing
tests did not cover. All three were places where I had made the individual
storage calls safe without making the *decision* atomic. Fix them, prove the
fixes with deterministic regressions, and correct the documentation now that
the separate frontend has been rejected and removed.

## What changed

### ARR-1 · Concurrent guesses bypassed admission

Serialising `read`, then deriving, then `record` does not make admission
atomic: thirty guesses arriving together all read the same count, all passed
the check, and all thirty derived a key. Codex measured exactly that — thirty
derivations, thirty 401s, no 429.

There is now a single **check-and-reserve**: the slot is taken and the limit
tested in one indivisible step inside the object, before any derivation. The
reservation is kept whatever happens next — failure, success, or a request that
dies half way. Holding one costs an attempt from the hour's allowance, which is
the conservative direction; releasing it would hand a burst its bypass back.

Recovery stays separate and unthrottled: a constant-time comparison of a
48-character random value, with nothing to protect from repetition.

### ARR-2 · A delayed renewal could revive a logged-out session

Renewal read from KV and wrote back separately, so a logout landing between the
two was undone by the write that followed it. Codex reproduced it: log out,
release the held renewal, and the revoked token authenticates again.

The whole session lifecycle — create, use, renew, end, end-all — now lives in
the object, where those operations cannot interleave. A use that runs first
extends and is then deleted; a use that runs after finds nothing. There is no
ordering in which a revoked session comes back. The password verifier moved
there too, so a change and the invalidation it triggers are one ordered pair.

**On the fallback store, renewal is switched off entirely.** Read-then-write
renewal cannot be made safe there, and a stale renewal that resurrects a
revoked session is worse than a session that expires twelve hours after it was
created rather than after twelve idle hours.

### ARR-3 · Reads that had to agree were still two reads

An HTTP envelope around two separate reads is still two separate reads. The
editor read is now one store operation returning the document and its head
together; so is the public read, so the `x-content-revision` header cannot
describe a different revision from the body it is attached to; and the release
capture takes all five overrides in one operation, reporting the revision each
was at, so a digest cannot describe a state of the site that never existed.

### The rejected frontend

`site/` is gone, so the digest test no longer imports it. The canonical form is
now pinned by literal expected strings written from the specification, plus the
frozen synthetic document set. The specification is the contract; when the
Flutter generator implements it, compare it against those same vectors.
`INTEGRATION.md` and the admin documentation say Flutter is the only
interactive UI, and no longer mention Astro.

### Saying what the fallback is

Codex asked that KV fallback not be described as protected. `INTEGRATION.md`,
`docs/15` and `worker/README.md` now each state that a deployment today runs
unprotected, what specifically is unsafe, and that a combined release cannot
claim concurrency protection while it does. `worker/README.md` gained the
migration and rollback procedure.

## Files touched

- `worker/src/store.js` — modified — check-and-reserve, the session lifecycle, the password record, `readWithHead`, `capture`; the fallback's deliberate no-renewal.
- `worker/src/index.js` — modified — admission before derivation; sessions and password through the store; single-operation reads for the editor, the public GET and the release capture.
- `worker/contracts/snapshot.js` — modified — the specification is the contract; no reference to the removed frontend.
- `worker/contracts/INTEGRATION.md` — modified — Flutter-only, preview status, and an explicit unsafe-fallback statement.
- `worker/dev/durable-double.js` — modified — read and write hooks, so an interleaving can be made deterministic.
- `worker/test/store.test.js` — modified — 11 further tests.
- `worker/test/admin-auth.test.js` — modified — renewal tests moved onto the transactional store; the fallback's no-renewal asserted.
- `worker/test/snapshot.test.js` — modified — literal canonical-form vectors.
- `worker/README.md`, `docs/15-ADMIN-AND-MEDIA.md` — modified — fallback status, migration and rollback.

## Decisions made

**A reservation is kept, not released.** A request that dies mid-attempt leaves
its slot taken. That costs the owner one attempt from an hour's allowance and
closes the bypass; releasing it on failure would reopen exactly the burst
window ARR-1 describes.

**A blocked correct password stays blocked.** The escape hatch is recovery,
which is why it is checked first and not throttled.

**The fallback does not renew.** Correctness beats the convenience. It is
better to expire a session early than to bring a revoked one back.

**The password verifier moved into the object.** It is read on every sign-in
and written by the change that invalidates every session; those two belong in
the same serialised place. There is no production password to migrate — the
feature has never been deployed.

## Tests

- Added 11 in `store.test.js`: the burst asserting **one derivation** rather
  than a final counter value; reservation kept on failure; recovery unthrottled;
  a renewal held open across a logout; a renewal arriving after a logout; a
  renewal across a password change; editor and public reads never pairing a
  revision with another revision's document; a release capture matching its
  reported revisions.
- Two of those are discrimination tests: the two-call read shape *does* mismatch
  under a deterministic interleave, and the same interleave against the single
  operation does not. The suite can tell the difference.
- `admin-auth.test.js`: renewal tests moved to the transactional store, plus one
  asserting the fallback deliberately does not renew.
- Worker suite: **pass, 270 passing, 0 failing** (was 262).

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 270 tests
a1 27/27  a2 21/21  a3 18/18  a3-preview 15/15  a4 19/19  a6 18/18
review-fixes 18/18                         136 browser checks
```

Codex's own reproduction script, run against this branch, now reports
`derivations: 1, {401: 1, 429: 29}` for ARR-1 and a consistent
`{revision: 1, label: 'Walking'}` for ARR-3 — and its assertions, which were
written to confirm the defects, fail. Its ARR-2 section hooks `CONTENT.put` for
`session:` keys and no longer fires at all, because sessions are not in KV any
more; the equivalent race is covered by `store.test.js` hooking the object's
storage instead.

## Known issues left open

- **The binding is still not enabled**, so a deployment today runs on the
  unsafe fallback: concurrent publishes can lose a revision and sessions do not
  renew. Documented in three places, reported by the API as `atomic: false`,
  and shown in the editing bar. A combined release must not claim concurrency
  protection while it is running this way.
- **The object has been exercised against a faithful double**, plus Codex's
  local workerd run of the content-write path. Plan availability, cost and
  migration safety are still unverified, and the migration is a manual copy.
- **Live preview, HTML publication, A5 and the four accepted field consumers**
  remain open and belong to Codex.
- **No real-device or screen-reader check has ever run.**
- The PBKDF2 iteration count is still bounded by the free plan's processor
  budget.

## Next

Codex re-reviews and integrates on a non-production branch.
