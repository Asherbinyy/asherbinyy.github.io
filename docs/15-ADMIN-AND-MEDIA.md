# Admin and media

Current state: 2026-09-12, after admin phases **A1-A4 and A6**, plus the
preview channel, the release contract and the fields Codex accepted in
[`23-ADMIN-INTEGRATION-REPLY.md`](23-ADMIN-INTEGRATION-REPLY.md). A5 remains
blocked on the renderer allowlist. Audit baseline was `1cfd039`.
Target workflow and acceptance: [R3](19-REINNOVATION-ROADMAP.md#r3--admin-as-an-editing-workspace). Customization and analytics: [R8](19-REINNOVATION-ROADMAP.md#r8--customization-and-analytics).
Phases and ownership: [handoff](21-CLAUDE-ADMIN-HANDOFF.md). Requests to the public app: [`worker/contracts/INTEGRATION.md`](../worker/contracts/INTEGRATION.md).

## What exists

The Worker serves `/admin`, assembled by `worker/src/admin.js` from the modules
in `worker/src/admin/`. The HTML is public and marked noindex; write endpoints
require a separate `ADMIN_TOKEN`. It edits profile, apps, career, education and
interests, and calls itself Sherbini's Portfolio.

Public content reads use `/v1/content/<file>`. Authenticated content
writes/withdrawals use `/v1/admin/content/<file>`. The site tries the published
document, with a timeout and bundled fallback. Image upload/list/remove
endpoints and `/v1/media/<hash>` use the content KV binding.

### The schema

`worker/contracts/content-schema.js` describes all five documents field by
field: type, requiredness, allowed values, and whether a field is a claim about
the owner. It is derived from the Freezed models in `lib/content/models/`, which
are what the app actually parses, and `worker/test/content-schema.test.js`
checks every bundled document against it so drift fails a test rather than
refusing the owner's own content.

The panel is drawn from that schema rather than from a document's existing keys,
which is what makes a field the owner has never filled in editable at all.

`worker/contracts/validate.js` is the one validator, and it runs on the server.
The panel has no copy: it asks `/v1/admin/validate`, so it cannot report
something as publishable that `PUT /v1/admin/content/<file>` would refuse.

### What is delivered

- Sections, editor and a third column at desk widths; one column on a phone,
  with the third column behind a control between the two.
- Long lists are compact rows that open into their own panel, with a breadcrumb
  back. Short lists open in place.
- One draft per document, kept while moving between sections. A section with
  unsaved work is marked in the list, and leaving the page warns.
- English and Arabic are a stacked pair of tabs switching the whole panel. Both
  drafts are kept; the other language is shown under each field; Arabic is
  edited right to left, and neither language forces its direction onto the
  other's text.
- Every control has an associated label, an id, a visible focus ring and a
  keyboard path. Tap targets are at least 44px on a phone.
- Publishing is refused for a document that does not match the schema, with the
  failing paths named. `PUT` answers 422 rather than storing it.
- A changed claim is found by what the schema says a field is, so a figure
  written as text — `5+`, `50% retention lift` — now asks for a source. The old
  check only saw JSON numbers and missed all of them.
- Image uploaders are attached because the schema says a field holds an image,
  not because its key was spelled like one.

**A2, media.** A Media section listing everything stored, with dimensions,
size, a player for recordings, and the pages pointing at each file; deleting
one still in use names where, by name, before it goes. Image fields can upload,
take something already stored, or be cleared. Uploads report real progress and
offer to try again. Recordings have their own endpoint validating four sound
formats on their bytes — the image endpoint's argument is that it reads enough
of each container to know it is a raster image, and widening it would throw
that away.

**A3, publishing.** Every publish is a numbered revision with its own copy of
the document and the source given for it. A publish declares the revision it
was built on; a stale one is refused with a sheet showing where the two
disagree and both ways out named. The history can put a revision back, as a new
revision, revalidated on the way in. A claim needs a source and the **Worker**
now insists, comparing against the published copy or against nothing — never
against a baseline the caller supplied.

**A4, accounts.** The deployment secret is exchanged once for a session; that
is all the browser holds. Sessions expire, can be ended, and are stored under a
hash of themselves. The password is set from inside the panel, stored stretched
with a per-record salt, and changing it ends every other session. A session
ending mid-edit asks for the password over the panel and keeps every draft. The
hourly lockout no longer takes the owner down with the attacker.

**A6, home.** A dashboard over the counters that already exist, with ranges in
UTC days. No weekly or monthly unique-visitor figure, and the reason is on the
page: the visitor hash is salted daily, so adding days counts returning people
again. The honest multi-day figure is the busiest single day. Averages carry
their unit. An empty dashboard says nothing is being counted rather than
implying nobody visited.

**The preview channel — the admin half only.** The editor's side of protocol v1
is built: the frame, the session, the handshake, the validated draft, selection
following the editor, locale changes, stale acknowledgements dropped, retry,
and an honest line saying what is happening. Component identifiers are
`"<file>:<path>"` as agreed, and no credential crosses the channel.

What has been proved is **the admin side of the protocol against a test
double**, not end-to-end rendering of the site. The public adapter does not
exist. The double is served by the local harness on a different origin so both
sides' origin checks do real work; it is not shipped, and the panel says the
preview has not answered when nothing does.

**The release contract.** Codex chose Astro and build-and-release.
`worker/contracts/snapshot.js` produces the `PORTFOLIO_SNAPSHOT` artifact and
its canonical digest, pinned by test to the digest Codex's own reference
implementation produces. `POST /v1/admin/release` reports whether the public
HTML is serving that revision, and the dashboard says so — including, as
instructed, refusing to call anything published to HTML while nothing serves a
release file.

**The accepted fields.** `profile.links[]`, `app.media[]`,
`interest.gallery[]` and `profile.nameAudio` are editable and validated, each
marked "not on the site yet" until its consumer lands. The recording's length
is read from the file rather than typed.

**Concurrency and credentials.** Content mutations are serialised through a
Durable Object with a revision precondition and one transactional commit, so
two publishes racing on the same base produce one revision and one conflict
rather than two "successes" and a lost history entry. Sign-in checks the
attempt limit before deriving a key, so a blocked guess costs nothing and
cannot be tested indefinitely. See [Worker operations](../worker/README.md).

Verified in Chrome against `worker/dev/serve.js`: 134 browser checks across
seven scenarios, screenshots under `docs/audits/`.

## Still missing, and why

Everything left is waiting on the public app. Each is written up with a
concrete ask in [`INTEGRATION.md`](../worker/contracts/INTEGRATION.md).

Each of these is built up to a boundary and labelled honestly in the
interface. None of them is finished work.

- **Live preview is not done.** The protocol is verified against a test double;
  the real adapter does not exist. Point `PREVIEW_ORIGIN` at it when it does.
- **HTML publication is not done.** The revision and the comparison are built,
  but nothing serves a release file, and CI triggering, artifact delivery,
  failure recovery and release rollback are unwritten integration tasks.
- **A5 is not started.** No themes, fonts or page backgrounds, and no
  Appearance section, because a setting the renderer does not read is a control
  that appears to work. The proposal is in
  [`worker/contracts/appearance.js`](../worker/contracts/appearance.js) with
  every blocker listed and a test asserting none has been quietly cleared.
- **The four accepted fields have no renderer**, and are labelled accordingly.
- **Concurrency protection is not enabled in production.** The transactional
  store is implemented and tested; the binding in `wrangler.toml` is
  deliberately commented out, because switching it on migrates where the
  owner's content lives. Until then the panel says, in the editing bar, that
  concurrent edits are not protected.
- **Video remains an external address with click-to-load**, which is the
  existing behaviour stated plainly. Direct hosting is a separate decision.
- **No real-device or screen-reader check has ever run.** Headless Chrome at
  three viewport sizes is not a phone, Safari, or a screen reader.

Two things are open on this side rather than the other:

- The password stretch is 50,000 PBKDF2 iterations, bounded by the Workers
  free-plan processor budget. Length carries the strength; the panel requires
  twelve characters. Verify a sign-in after the first deployment that sets a
  password. See [Worker operations](../worker/README.md).
- Verification is headless Chrome at three viewport sizes. Not a physical
  phone, not Safari, and no automated screen-reader pass.

## Media behavior

The existing endpoint accepts PNG, JPEG and WebP with size/type/dimension checks and rejects SVG. Media IDs are hashes of their contents. Current upload limit and dimensions are defined in `worker/src/index.js`; R3 must preserve validation while adding explicit media controls.

A1 changed which fields get an uploader, not what the endpoint accepts. The
schema marks a field as holding an image, so `portrait.src` and an evidence
`src` have one now and a caption does not. The validation at the trust boundary
is untouched.

A2 added `POST /v1/admin/media/audio`, its own endpoint on purpose: MP3, MPEG-4
audio, WAV and Ogg, each checked on its own header, 2 MiB, with the length read
where the container states it and reported as unknown where it does not. An
MPEG-4 file carrying a video brand is refused. Nothing consumes stored audio
yet — the name recording is played from a hard-coded bundle path.

Video currently uses external URLs and deliberate click-to-load playback. R3 must expose that honestly. Direct video storage is a separate hosting decision if needed, not something already supported by image KV storage.

Real app screenshots are absent from the bundled app entries. `assets/media/apps/` contains guidance only and is not currently declared as a Flutter asset directory. Adding a file there alone does not finish the gallery or publishing pipeline.

## Publishing contract to establish

R1 must choose the public HTML and content-revision strategy before R3 promises a live publish. At present the app reads Worker overrides while CV/Brief are generated from local files and the main shell metadata is written separately.

A draft preview must not publish. A publication must validate schema, references and claim provenance, protect against stale edits, and expose failure. The public document, metadata and interactive view must all refer to the same published revision, with the last successful revision available on failure.

A typed component contract should drive the editor and consumers. Arbitrary fields that are silently ignored on the website do not meet the owner's requirement.

## Security and privacy

Keep credentials separate from public previews and out of source/logs. Password management must not expose a Cloudflare account token to the browser. Test unauthorized writes, session behavior, rotation and lockout in isolated data.

The public build has analytics disabled. Rebuilding the admin does not authorize silently enabling collection. The requested analytics home must show available/disabled/empty states accurately; a graph must never imply invented visitors. Existing consent requirements remain binding.

Subscriptions were cancelled. The separate daily digest remains dormant because the original cancellation and handover differ in scope.

## Running it without production

`worker/dev/serve.js` runs the Worker on localhost with an in-memory store, the
sanitized fixtures in `worker/contracts/fixtures/` and a throwaway token printed
at startup. `worker/dev/verify-a1.js` drives it in Chrome and writes
screenshots. Neither reaches Cloudflare, and the fixtures are a fictional person
so an editor screenshot can go in a worklog without publishing the owner's
address or his marks.

## Operations and costs

See [Worker operations](../worker/README.md) for existing commands. The site and Worker deploy separately. Use the existing content binding; do not recreate a production namespace from an old setup checklist.

GitHub Pages and Cloudflare free tiers are the current hosting approach. Quotas are limits, not a permanent no-cost guarantee: [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) and [KV pricing](https://developers.cloudflare.com/kv/platform/pricing/). No new paid storage, service or package is selected by this document.
