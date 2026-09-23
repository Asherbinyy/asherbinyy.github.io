# 2026-09-12-02 — The preview channel, the release contract, and the fields Codex accepted

**Agent:** Claude / Opus 5
**Milestone:** 6 (legacy template slot); actual work is **Re-innovation R3**
**Started from:** `e9080cc`, on `phase/reinnovation-admin`
**Previous worklog:** `2026-09-12-01-claude-admin-a2-a6.md`

## Goal

Codex answered the integration request in `docs/23-ADMIN-INTEGRATION-REPLY.md`
and resolved R1. That unblocked almost everything that had been left open, so:
build it. Preview protocol v1, the release/snapshot contract, and the five
content fields the reply accepted.

Also: push the branch. The previous two sessions committed to a separate
worktree and never pushed, so the owner had no way to see any of it.

## What changed

### Preview — the editor's half of protocol v1

The right-hand column is now a real preview frame with the outline behind a
tab, rather than an outline apologising for not being a preview.

Built to the reply's specifics: `componentId` is `"<file>:<path>"`,
`targetOrigin` is the exact configured origin and never `*`, and every arriving
message is checked for origin, source window, channel, version and session
before a field of it is read. A draft is sent only once it validates, per the
contract, and the panel says why when it is holding one back. Selection follows
the editor. Stale `rendered` acknowledgements are dropped. A frame that never
answers is reported as not having answered, not as a blank site.

**Codex's adapter does not exist yet**, so `worker/dev/serve.js` serves a
protocol-v1 stand-in on `http://127.0.0.1:8788` while the panel runs on
`http://localhost:8788`. Same machine, same port, two different origins as far
as the browser is concerned — so both sides' origin checks are doing real work.

### Release — the snapshot and whether the site is serving it

R1 is Astro, semantic HTML, build-and-release, and the builder takes a
`PORTFOLIO_SNAPSHOT` whose revision it recomputes and checks.

`worker/contracts/snapshot.js` produces that artifact, with the canonical JSON
and digest the reply specifies. `POST /v1/admin/release` returns the revision a
build from current content would carry, reads `/release.json`, and reports
`live`, `behind`, `unreleased` or `unreadable`. The dashboard shows it and,
as instructed, will not call anything published to HTML while nothing is
serving a release file — which is today's state and reads as such.

### The fields Codex accepted

`profile.links[]`, `app.media[]`, `interest.gallery[]` and
`profile.nameAudio`, all editable and validated, all marked `consumer:
'pending'` so the editor labels them "not on the site yet". A test asserts
exactly those four carry the mark.

## Files touched

- `worker/contracts/snapshot.js` — created — the artifact, the canonical form and the digest.
- `worker/contracts/content-schema.js` — modified — links, project galleries, interest galleries, the name recording; a shared gallery-entry shape.
- `worker/contracts/validate.js` — modified — conditional rules, so "a picture needs a file and a video needs an address" lives in the schema rather than in code.
- `worker/contracts/INTEGRATION.md` — modified — what was done with each answer, and what is still owed.
- `worker/src/admin/client-preview.js` — created — the editor's half of protocol v1.
- `worker/src/admin/client-home.js` — modified — the release section.
- `worker/src/admin/client-fields.js` — modified — read-only derived values; the domain a link will be matched on.
- `worker/src/admin/client-app.js` — modified — pane tabs, selection on navigation, the language fix below.
- `worker/src/admin/client-state.js`, `markup.js`, `styles.js`, `admin.js` — modified — the frame, the tabs, the preview origin.
- `worker/src/index.js` — modified — `POST /v1/admin/release`, the release file read, `frame-src` in the panel's policy.
- `worker/dev/serve.js` — modified — the protocol-v1 stand-in on the other origin, a `/release.json`, and the out-of-band report the tests read.
- `worker/dev/verify-a3-preview.js` — created — 15 checks over the whole exchange.
- `worker/test/snapshot.test.js` — created — 19 tests, including the pin below.
- `worker/test/content-schema.test.js` — modified — 10 tests for the accepted fields.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — current state.
- `docs/audits/2026-09-12-admin-a3-preview/*.png` — created — 3 captures.

## Decisions made

**The digest is pinned to Codex's own output, not to my reading of the spec.**
`worker/test/snapshot.test.js` asserts `2e6a765a…8019` — the value
`site/src/lib/content.mjs` produces over the five bundled documents, captured by
running it. Two implementations of "canonical JSON" that agree on paper and
differ on a byte would surface as a build failing with a revision mismatch,
which is a bad place to find out. It surfaces here instead.

**A published document beats what the panel supplies.** The panel has to send
the bundled documents because only it can read them, but for anything already
published the Worker uses its own copy. Otherwise the caller could describe a
document the site is already serving.

**A gallery entry has two fields, not one polymorphic one.** Whether `image` or
`url` is required depends on `kind`, which needs a rule across fields. That is
in the schema as data rather than in the validator as code, because the shape
of a document belongs in one place. Exactly one rule type exists; if a second
kind is ever needed, the answer is probably a clearer document.

**The recording's length is read, not typed.** The reply asked for `seconds` to
be derived rather than required, so the field is read-only in the editor and
filled from the upload's own header. A length the owner could disagree with the
recording about is worse than none.

**The preview stand-in lives in the harness, not in the Worker.** It is a test
double. Shipping it would mean the panel could frame something that is not the
site.

## Tests

- Added: 19 in `snapshot.test.js`, 10 in `content-schema.test.js`, and 15
  browser checks in `verify-a3-preview.js`.
- Worker suite: **pass, 229 passing, 0 failing** (was 200).
- Browser: **pass, 116 of 116** across six scenarios.
- Flutter suite: **pass, 666 passing, 0 failing** — unchanged.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 229 tests
a1 27/27  a2 21/21  a3 18/18  a3-preview 15/15  a4 17/17  a6 18/18
```

Two failures in the preview run were worth having. The first was the test's
fault and proved the design: reading `iframe.contentDocument` threw, because
the preview genuinely is a different origin — so the fixture now reports what
it rendered out of band, and there is a check asserting the panel *cannot* read
into the frame. The second was a real bug: switching the language tab
re-rendered the editor but never told the preview, so the panel showed Arabic
while the preview kept showing English. Switching now re-sends the draft.

## Known issues left open

Nothing on the admin side. What remains needs a public consumer:

- Codex's preview adapter. Point `PREVIEW_ORIGIN` at it when it lands.
- A host serving `/release.json`, plus CI triggering and artifact delivery,
  which the reply lists as integration tasks.
- Renderers for `links`, `app.media`, `interest.gallery` and `nameAudio`.
- The A5 allowlist, which the reply says arrives with the R2/R8 renderer.

And unchanged from the last session: the PBKDF2 iteration count is bounded by
the free plan's processor budget; verification is headless Chrome at three
viewport sizes, not a physical phone or a screen reader.

## Next

Nothing is blocked on this side. When Codex's adapter, consumers or allowlist
land, each has a place to plug into and a test that will say whether it fits.
