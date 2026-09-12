# 2026-09-12-01 — Admin A2 to A6: media, publishing, accounts, the dashboard

**Agent:** Claude / Opus 5
**Milestone:** 6 (legacy template slot); actual work is **Re-innovation R3 and R8, phases A2–A6**
**Started from:** `8f6868e`, on `phase/reinnovation-admin` in the `nocturne-admin` checkout
**Previous worklog:** `2026-09-11-03-claude-admin-a1.md`

## Goal

Finish every admin phase that does not depend on the public app, and leave the
rest blocked in writing rather than half-built. A2 (content and media), A3
(publishing, minus the preview), A4 (accounts) and A6 (analytics home) are
delivered. A5 (customization) is a written proposal and nothing else, for the
reason given below.

## What changed

### A2 — media

A Media section listing everything stored: dimensions, size, a player for
recordings, the reference to copy, and **which pages are pointing at each
file**. Deleting one still in use names where, by name, before it goes.

Image fields can now upload, take something already in the library, or be
cleared. Uploads report real progress and offer to try again — a photograph
from a phone takes long enough that a control with no progress looks broken,
and the answer to a control that looks broken is to press it again.

Recordings got their own endpoint. The image endpoint's whole argument is that
it reads enough of each container to know it is a raster image; widening it to
"or some audio" throws that away. Four formats, each checked on its own bytes,
with the length read from the header where the container states it and reported
as unknown where it does not — never estimated from the byte count.

### A3 — publishing

Every publish is a numbered revision holding its own copy of the document and
the source given for it. A publish declares the revision it was built on. If
the page has moved since, it stops and shows where the two versions disagree,
with both ways out named: throw mine away, or keep mine and review against
theirs. Nothing is chosen automatically, because both wrong choices cost an
afternoon.

The history can put a revision back, as a **new** revision — two documents
sharing a number makes the number useless — and revalidates on the way in,
because a revision that was fine when published can stop being fine when the
schema tightens.

A claim needs a source and the **Worker** now insists (A-F7). It compares
against the published copy, or against nothing; never against a baseline the
caller supplied, which is the point of doing it server-side. The review
endpoint reports the same answer so the panel asks exactly when the Worker will
refuse.

### A4 — accounts

The deployment secret is exchanged once for a session, and that is all the
browser holds. Sessions expire (twelve hours idle, seven days absolute), can be
ended, and are stored under a hash of themselves so a namespace dump yields
nothing replayable. The password is set from inside the panel and stored
stretched with a per-record salt. Changing it ends every other session and
hands a replacement to whoever made the change.

A session ending mid-edit asks for the password over the top of the panel and
leaves every draft where it was.

The hourly lockout no longer takes the owner down with the attacker (A-F9).

### A6 — home

A dashboard over the counters that already exist. Ranges are whole UTC days and
say so.

There is no weekly or monthly unique-visitor figure, and the reason is on the
page rather than left as a gap: the visitor hash is salted with a salt that
rotates at midnight, so the same person on two days is two hashes by design.
The honest multi-day figure is the busiest single day, labelled as that.

An empty dashboard says nothing is being counted, which is a different claim
from nobody having visited, and only the first one is true.

### A5 — not built, on purpose

No themes, no fonts, no page backgrounds, and **no Appearance section in the
panel**. A setting the renderer does not read is a control that appears to
work, and the handoff is explicit that those must not exist. What is delivered
is `worker/contracts/appearance.js`: the proposed shape written against
identifiers that are real, every blocker listed, and tests asserting it stays
out of the editor and that no blocker has been quietly cleared.

## Files touched

- `worker/src/index.js` — modified — audio endpoint and its byte-level sniffer; media listing carries kind and URL; revisions, conflict detection, provenance enforcement, rollback and history; sessions, password, sign-out, corrected lockout; the insights endpoint.
- `worker/src/insights.js` — created — the arithmetic behind the dashboard, kept pure so it is testable without a store.
- `worker/src/admin/client-media.js` — created — the library and the per-field media control.
- `worker/src/admin/client-publish.js` — created — review, publish, conflicts, history, discard.
- `worker/src/admin/client-account.js` — created — sign-in, sign-out, password, re-authentication.
- `worker/src/admin/client-home.js` — created — the dashboard.
- `worker/src/admin/client-state.js` — modified — media state, upload with progress, usage scanning, the busy marker, session handling.
- `worker/src/admin/client-app.js` — modified — non-document views, Home as the landing section, the new bar.
- `worker/src/admin/client-fields.js` — modified — the richer asset control.
- `worker/src/admin/markup.js`, `styles.js`, `worker/src/admin.js` — modified — the re-authentication dialog, new sections, composition.
- `worker/contracts/appearance.js` — created — the A5 proposal, and the naming trap in it.
- `worker/contracts/INTEGRATION.md` — modified — what each remaining phase needs from Codex.
- `worker/test/support.js` — created — the fake store and request builders the admin tests share.
- `worker/test/admin-media.test.js`, `admin-revisions.test.js`, `admin-auth.test.js`, `admin-insights.test.js`, `appearance.test.js` — created — 84 tests.
- `worker/test/index.test.js` — modified — four assertions that encoded old behaviour; see Tests.
- `worker/dev/harness.js` — created — shared sign-in, reporting, byte builders and the deterministic wait.
- `worker/dev/browser.js` — modified — dialog handling, navigation, setup scripts that survive a reload.
- `worker/dev/serve.js` — modified — a counter-seeding route that exists only in the harness.
- `worker/dev/verify-a2.js`, `verify-a3.js`, `verify-a4.js`, `verify-a6.js` — created — 74 browser checks.
- `worker/dev/verify-a1.js` — modified — moved onto the shared harness; publishes through the review sheet now.
- `worker/README.md` — modified — the auth model, the iteration-count trade-off, the lockout change.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — current state, and an honest list of what is left.
- `docs/audits/2026-09-12-admin-a2|a3|a4|a6/*.png` — created — 18 captures.
- `docs/worklog/2026-09-12-01-claude-admin-a2-a6.md` — created — this record.

## Decisions made

**Audio got its own endpoint rather than a flag on the image one.** The image
endpoint is trustworthy precisely because it decodes enough of each container
to know what it is looking at. A `kind=audio` parameter would have made that
guarantee conditional.

**A length the container does not state is reported as unknown.** MP3 needs
every frame header counted and Ogg needs the last page. Estimating from the
byte count would put a wrong number next to a play button, which is worse than
no number.

**Rollback appends.** Rewinding the revision counter would let two different
documents share a number.

**Provenance is enforced against the published copy or against nothing.** The
panel may send what it believes the site is showing, and the review endpoint
uses it for display — but the rule is applied server-side against what the
Worker can actually see. On a first publish it therefore asks for a source for
every figure on the page, and the review endpoint reports that so the panel
asks the same question rather than the two disagreeing at the last moment.

**The deployment secret keeps working after a password is set.** It is the way
back in when the password is forgotten, and it is why a slow or unreachable
password store cannot lock the owner out of his own site.

**50,000 PBKDF2 iterations.** Bounded by the Workers free plan's per-request
processor budget, which a sign-in has to fit inside. Length carries the
strength instead; the panel requires twelve characters, and each hash records
the count it was made with so the number can be raised later without
invalidating the password. Recorded in `worker/README.md` as something to
verify after the first deployment that sets one.

**The correct credential is checked before the rate limit.** The old rule shut
the endpoint for everybody after ten wrong guesses, so anyone who could reach
the Worker could lock the owner out by typing rubbish. Guessing is still
bounded — a wrong credential is what increments — but the owner is not
collateral.

**Home is the landing section.** A "home dashboard" that is not what you land
on is a tab.

**Verification stopped sleeping.** The panel marks itself while a check is in
flight and the scenarios wait for that to clear. A1 had begun failing
intermittently for exactly the reason a fixed sleep always eventually does; a
longer sleep would have hidden it rather than fixed it.

**Assumption, flagged:** A6 shows the busiest single day as the multi-day
unique figure. It is a floor, not a count of people, and the panel says so. If
the owner wants a real weekly unique count, that needs an identifier that
survives midnight — a privacy decision with consent attached, which nothing
here makes.

## Tests

- Added: 84 Worker tests — media and audio (14), revisions and conflicts (19),
  auth (20), insights (19), the appearance proposal (12).
- Modified: four assertions in `index.test.js` that encoded behaviour these
  phases deliberately changed. The lockout test asserted that a correct token
  is refused during a lockout, which is finding A-F9 written down as an
  expectation; the media listing used a whole-shape snapshot that additive
  fields break; the gate test asserted the words on a label. Each now asserts
  the behaviour rather than the old spelling, with the reason in a comment.
  Nothing was skipped or deleted.
- Worker suite: **pass, 200 passing, 0 failing** (was 116 after A1).
- Browser: **pass, 101 of 101 checks** across five scenarios.
- Flutter suite: **pass, 666 passing, 0 failing** — unchanged, as expected from
  Worker-only phases.
- Coverage delta: not measured.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 200 tests
verify-a1 27/27  a2 21/21  a3 18/18  a4 17/17  a6 18/18
```

Three defects were found by the browser runs that the unit tests could not
have: publishing reported "nothing to publish" whenever no override existed
yet, because the server was diffing against an empty store; tap targets on
chips and language tabs were 28–34px on a phone; and the sign-out reload
deadlocked the driver on a native beforeunload prompt. Two more were found by
reading the screenshots rather than by any assertion — the other-language line
rendered as `شخص تجريبي:Arabic` because a whole paragraph was marked RTL, and
the draft outline laid English out right-to-left in Arabic mode, putting full
stops in front of sentences. Both were bidi isolation.

## Known issues left open

Everything remaining is waiting on the public app, and each has a concrete ask
in `worker/contracts/INTEGRATION.md`:

- **The third column is an outline of the draft, not the site** (§3.2).
- **A publish updates what the app reads, not the CV, Brief or metadata.** The
  review sheet says so where the owner is looking. Blocked on R1 (§3.3).
- **A5 is not built**: no themes, fonts or page backgrounds, no Appearance
  section. Proposal and blockers in `worker/contracts/appearance.js` (§3.1).
- **Editable links, project media lists and interest galleries** are proposed
  and unbuilt (§3.4).
- **The owner cannot change his own name recording.** The validated endpoint
  exists; `NamePronunciation` plays a hard-coded path (§3.4).
- **Alt text** exists only where the model already has a caption.
- **Video** remains an external URL with click-to-load.

On this side:

- The PBKDF2 iteration count fits the free plan's processor budget rather than
  current password-hashing advice. Length is the mitigation, and the recovery
  credential means a failure here cannot lock the owner out.
- Verification is headless Chrome 152 at 1440×900, 1100×820 and 390×844
  emulation. Not a physical phone, not Safari or Firefox, and no automated
  screen-reader pass. Labels, roles and focus were checked structurally and by
  keyboard, which is not the same thing.
- `docs/11-OPEN-ISSUES.md`, `docs/19-REINNOVATION-ROADMAP.md` and `CHANGELOG.md`
  were deliberately not edited: the contract gives Codex the central queue.
  ADM-1 to ADM-5 and ADM-7 are addressed by A1–A4 and A6. ADM-6 is not, and is
  blocked.

## Next

Codex answers `worker/contracts/INTEGRATION.md` §3.1–3.4. Until then there is
no admin work left that can be finished honestly: every remaining item is a
control that would do nothing, or a claim about the site that is not true.
