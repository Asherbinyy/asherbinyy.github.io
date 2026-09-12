# 2026-09-12-03 — AR-1 to AR-9 from Codex's merge review

**Agent:** Claude / Opus 5
**Milestone:** 6 (legacy template slot); actual work is **Re-innovation R3**
**Started from:** `fd5139a`, on `phase/reinnovation-admin`
**Previous worklog:** `2026-09-12-02-claude-admin-preview-release.md`

## Goal

Codex reviewed `fd5139a` and found nine defects the 229 passing tests did not.
Fix all nine, add regressions that would have caught them, and correct the
documentation claims the review called stale or contradictory.

Four of the nine were races. None of them were visible from the test suite,
and three needed a browser holding a write open to reproduce at all.

## What changed

### AR-1 · Concurrent publication lost content and history

KV has no compare-and-set and no transaction, and a mutex in the Worker is
worthless because there is no single Worker — requests land in whichever
isolate the edge picked. So content mutations now go through a `ContentStore`
**Durable Object**: one instance across the network, serialised execution, and
the whole read-check-write inside `blockConcurrencyWhile` with the commit in a
single `storage.transaction`.

The binding is **commented out in `wrangler.toml`**, with the two things to
confirm before enabling it and the migration note. Enabling it moves where the
owner's published content lives, which is his decision. Without it the Worker
behaves exactly as before, `atomic` is false, and the panel says so in the
editing bar rather than implying a protection it has not got.

### AR-2 · Password throttling ran after the expensive part

The limit is now checked **before** any derivation. The deployment secret is
tried first — a constant-time comparison of a 48-character random value, with
nothing to protect from repetition — then the limit, then the password. So a
blocked attempt derives nothing and a correct password is refused while the
limit holds, which is what a throttle is. The owner is not locked out because
the recovery credential is the way in, and getting in clears the count.
Attempt counting moved into the same object, so two guesses arriving together
cannot both read the same number.

### AR-3 · A delayed upload wrote into whichever document was open later

Anything that finishes later now captures where it started: the document, the
path, and the stable identifier of every list entry the path passes through.
On completion the anchor is resolved against the current draft — so an upload
follows its entry when the list is reordered, and reports itself rather than
guessing when the entry has been removed. Publishing acknowledges the exact
snapshot it submitted, so typing during an in-flight publish leaves the page
dirty instead of marking unsaved work as saved. Review, rollback, withdrawal,
history and the media picker were audited for the same dependence.

### AR-4 · Refreshing heads silently rebased dirty drafts

A document and the revision it is are one fact, so they are fetched together
now, through a new authenticated `GET /v1/admin/content/{file}`. (That also
fixes something latent: the panel had been reading content through the
origin-gated public route, which refuses a same-origin request from the panel
itself.) A head refresh no longer writes a revision onto a dirty entry — it
reloads a clean page, and reports divergence on a dirty one. The bar says
someone else has published; the next save conflicts; the draft survives.

### AR-5 · Rollback and withdrawal ignored stale revisions

Both are writes and both now carry the same precondition as publish, enforced
inside the object, with the panel sending its captured revision and showing the
conflict sheet rather than discarding the draft.

### AR-6 · Preview validation belonged to an earlier draft

Every edit bumps a generation. A validation result is stored with the exact
draft it validated and the generation it belongs to, and the preview is sent
**that snapshot**, only while the generation still matches. Emptying a required
field and switching language inside the debounce now shows "Checking this
draft before showing it..." and sends nothing.

### AR-7 · Snapshot reference checks trusted caller-supplied identifiers

`buildSnapshot` takes no hints at all any more. Cross-references are derived
from the documents in the release.

### AR-8 · Truncated M4A threw instead of returning an error

Version-specific lengths are checked against both the file and the enclosing
atom before any read, and a truncated MPEG-4 is refused rather than stored with
an unknown duration — unlike MP3 and Ogg, an MPEG-4 always states its length,
so not finding one means the container is broken. Both sniffers are also
wrapped, because parsing a stranger's upload is exactly where an unexpected
shape becomes a 500.

### AR-9 · Active sessions did not follow the promised idle expiry

Using a session pushes the idle clock back, bounded by the absolute limit, and
only once the remaining window has fallen below half — one write per afternoon
rather than one per request.

### Documentation

`INTEGRATION.md` §1 said no fields had been added and then listed four; §3.2
still described the old outline; §3.3 asked for a decision §3.0 said was
answered. §1 and §3.2–3.3 are rewritten and §3.0 is gone. "Nothing on the admin
side" is replaced with a table of what is actually open. The preview status now
says everywhere that what is proved is the admin half against a test double,
not end-to-end rendering. The theme finding is marked as compatibility, not a
rename proposal. The snapshot comments no longer read as Astro-specific.

The digest pin was hashing the owner's live bundle, so ordinary content edits
would have broken it. It now pins a frozen synthetic set, checks against a
second implementation of the canonical form written from the specification, and
compares directly against `site/src/lib/content.mjs` where that is checked out.

## Files touched

- `worker/src/store.js` — created — the Durable Object and the two backends.
- `worker/src/index.js` — modified — every mutation through the store; the throttle order; the editor read endpoint; idle renewal; media bounds; the listing.
- `worker/contracts/snapshot.js` — modified — references derived from the release; renderer-neutral wording.
- `worker/contracts/validate.js` — modified — unchanged by this review, carried through.
- `worker/contracts/appearance.js` — modified — the theme note is a compatibility finding.
- `worker/contracts/INTEGRATION.md` — modified — the contradictions.
- `worker/src/admin/client-state.js` — modified — anchors, generations, paired document and revision.
- `worker/src/admin/client-publish.js` — modified — exact submitted snapshots; head refresh; preconditions.
- `worker/src/admin/client-preview.js` — modified — the exact-draft gate.
- `worker/src/admin/client-fields.js`, `client-app.js`, `markup.js` — modified — anchored uploads, divergence, withdrawal precondition.
- `worker/dev/durable-double.js` — created — the object double, shared by tests and harness.
- `worker/dev/serve.js` — modified — runs on the transactional path; delay hooks.
- `worker/dev/verify-review-fixes.js` — created — 18 browser checks for AR-3, AR-4 and AR-6.
- `worker/dev/verify-a4.js` — modified — the corrected throttle policy.
- `worker/test/store.test.js` — created — 16 tests.
- `worker/test/admin-media.test.js`, `admin-auth.test.js`, `snapshot.test.js` — modified — 20 further tests.
- `wrangler.toml` — modified — the binding and migration, commented, with what to confirm first.
- `worker/README.md`, `docs/15-ADMIN-AND-MEDIA.md` — modified — the corrections above.

## Decisions made

**Durable Object rather than D1.** Both give transactions. The object also
gives serialised execution, which is what the read-check-write actually needs,
and it can be doubled faithfully in a test without a SQLite dependency. D1
would have needed `node:sqlite`, which is Node 22 and would have split the test
runtime.

**The binding is off.** Turning it on migrates live content. The review said no
production migration during this fix, and the honest alternative to a silent
downgrade is a panel that says which mode it is in.

**A blocked correct password is refused.** That is the throttle working. The
escape hatch is the recovery credential, which is why it is checked first and
not throttled.

**A truncated MPEG-4 is a 400, not a stored file with unknown length.** MP3 and
Ogg genuinely do not state their duration; MPEG-4 always does, so failing to
read one means the file is broken.

**Anchors use the entry's own `id`.** A path is positional, which is not an
address once a list can be reordered.

## Tests

- Added: 16 in `store.test.js` (concurrency, preconditions, injected write
  failure, throttle-before-derivation, atomic attempt counting, the editor read
  endpoint), 6 for idle renewal, 6 for truncated media, 4 for snapshot
  references, 3 for the digest pin. Worker suite **262 passing, 0 failing**
  (was 229).
- Added: `verify-review-fixes.js`, 18 browser checks — delayed upload across
  navigation, across reorder, across removal; the invalid draft held back
  inside the debounce; a dirty draft surviving reauthentication and conflicting
  on save.
- One test in `store.test.js` deliberately reproduces the defect against the
  key/value path, so the concurrency tests are known to discriminate rather
  than passing by construction.
- Modified: `verify-a4.js`, which asserted the old throttle policy.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 262 tests
a1 27/27  a2 21/21  a3 18/18  a3-preview 15/15  a4 19/19  a6 18/18
review-fixes 18/18                         136 browser checks
```

Two regressions were caught by rerunning the older scenarios rather than by the
new ones: moving content into the object left `GET /v1/admin/content` still
listing the KV prefix, so the panel was told nothing had ever been published;
and removing the now-dead key helpers took `revisionHead` with them.

## Known issues left open

Unchanged from the previous session, and all of it still true:

- **Live preview is not done.** The protocol is verified against a test double.
- **HTML publication is not done.** Nothing serves a release file; CI
  triggering, artifact delivery, failure recovery and release rollback are
  unwritten.
- **A5 is not started.**
- **The four accepted fields have no renderer.**
- **Concurrency protection is not enabled in production**, by design.
- **No real-device or screen-reader check has ever run.**

New, from this session:

- The Durable Object has been exercised against a faithful double, not against
  the Cloudflare runtime. Plan availability and cost need confirming, and the
  existing KV content needs copying in, before the binding is switched on.
- The PBKDF2 iteration count is still bounded by the free plan's processor
  budget.

## Next

Codex re-reviews this branch and integrates it with the public work.
