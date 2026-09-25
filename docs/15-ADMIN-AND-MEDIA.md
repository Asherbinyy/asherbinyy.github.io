# Admin and media

Release state: September 25. The real Flutter preview, collapsible panels,
current-content schema, uploaded-media consumers and base theme/font defaults
are in production. The analytics home is now the four-report dashboard
described in [the analytics runbook](32-ANALYTICS-DASHBOARD-RUNBOOK.md). See the
[UI review](31-CODEX-ADMIN-UI-REVIEW.md) for the wider admin workspace.

Backend delivery baseline: 2026-09-12, after admin phases **A1-A4 and A6**, plus the
preview channel, the release contract and the fields Codex accepted in
[`23-ADMIN-INTEGRATION-REPLY.md`](23-ADMIN-INTEGRATION-REPLY.md). A5 remains
blocked on the renderer allowlist. Audit baseline was `1cfd039`.
Target workflow and acceptance: [R3](19-REINNOVATION-ROADMAP.md#r3--admin-as-an-editing-workspace). Customization and analytics: [R8](19-REINNOVATION-ROADMAP.md#r8--customization-and-analytics).
Phases and ownership: [handoff](21-CLAUDE-ADMIN-HANDOFF.md). Requests to the public app: [`worker/contracts/INTEGRATION.md`](../worker/contracts/INTEGRATION.md).

## Reviewed backend baseline (local integration branch)

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

**A6, home.** Four reports cover overview, links and apps, pages and audience.
They show observed daily series, equal-length previous-period comparisons,
public destinations, source pages, named interactions, page engagement,
referrers, countries, input devices and campaigns. Search, sorting and CSV are
built in. No weekly or monthly unique-visitor figure is invented: the visitor
hash is salted daily, so adding days would count returning people again. Empty,
disabled and failed states remain distinct.

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

**The release contract.** Build-and-release, from an immutable snapshot.
`worker/contracts/snapshot.js` produces the `PORTFOLIO_SNAPSHOT` artifact and
its canonical digest, pinned by test to a frozen synthetic document set. The
renderer is Flutter; the contract describes documents and a digest, and did not
have to change when that was settled. `POST /v1/admin/release` reports whether the public
HTML is serving that revision, and the dashboard says so — including, as
instructed, refusing to call anything published to HTML while nothing serves a
release file.

**The accepted fields.** `profile.links[]`, `app.media[]`,
`interest.gallery[]` and `profile.nameAudio` are editable and validated, each
marked "not on the site yet" until its consumer lands. The recording's length
is read from the file rather than typed.

**Concurrency, sessions and credentials.** Content mutations, the session
lifecycle, the password verifier and the failed-attempt counter all live in one
Durable Object, so each is serialised: two publishes racing on the same base
produce one revision and one conflict; a renewal cannot resurrect a session a
logout has revoked; and admission takes a slot atomically before any key is
derived, so a burst of guesses gets exactly the attempts that were left. A
document and the revision it is are read in one operation, as is the whole set
that goes into a release.

The production release enables this binding after confirming that the existing
CONTENT namespace contains no keys, so there is no published document,
revision or password record to migrate. The KV fallback remains in code for
development and rollback, but the deployed admin uses the transactional path.
See [Worker operations](../worker/README.md).

Verified in Chrome against `worker/dev/serve.js`: 134 browser checks across
seven scenarios, screenshots under `docs/audits/`.

## Still missing, and why

The remaining deployment and publication dependencies are recorded in [`INTEGRATION.md`](../worker/contracts/INTEGRATION.md).

Each of these is built up to a boundary and labelled honestly in the
interface. None of them is finished work.

- **Real preview works.** The production build accepts only the deployed admin
  origin. Exact field-level scrolling remains open; selection follows pages.
- **HTML publication is not done.** The snapshot contract exists, but the
  public release manifest, coordinated build delivery and rollback are open.
- **Appearance is partial.** Existing theme/font defaults preview and publish
  through `profile.appearance`; extra presets and per-page patterns still
  need a renderer allowlist. The broader `appearance.js` proposal stays blocked.
- **Accepted media/link/audio fields now have Flutter consumers.** Empty
  galleries remain absent and missing overrides retain bundled defaults.
- **Concurrency protection is enabled for this release.** The transactional
  store serialises revisions, sessions, password admission and release reads.
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

The existing endpoint accepts PNG, JPEG and WebP with size/type/dimension checks and rejects SVG. Media IDs are hashes of their contents. Current upload limit and dimensions are defined in `worker/src/index.js`; F1 must preserve validation while adding explicit media controls.

A1 changed which fields get an uploader, not what the endpoint accepts. The
schema marks a field as holding an image, so `portrait.src` and an evidence
`src` have one now and a caption does not. The validation at the trust boundary
is untouched.

A2 added `POST /v1/admin/media/audio`, its own endpoint on purpose: MP3, MPEG-4
audio, WAV and Ogg, each checked on its own header, 2 MiB, with the length read
where the container states it and reported as unknown where it does not. An
MPEG-4 file carrying a video brand is refused. The public name button now consumes `profile.nameAudio`; absent an override,
it uses the existing bundled recording.

Video currently uses external URLs opened deliberately by the visitor. Direct video storage is a separate hosting decision if needed, not something already supported by image KV storage.

Real app screenshots are absent from the bundled app entries. `assets/media/apps/` contains guidance only and is not currently declared as a Flutter asset directory. Adding a file there alone does not finish the gallery or publishing pipeline.

## Publishing contract to establish

F8 will extend the existing Dart static generator and coordinate one content revision with Flutter before publication is labelled complete. At present the app reads Worker overrides while CV/Brief are generated from local files and the main shell metadata is written separately.

A draft preview must not publish. A publication must validate schema, references and claim provenance, protect against stale edits, and expose failure. The public document, metadata and interactive view must all refer to the same published revision, with the last successful revision available on failure.

A typed component contract should drive the editor and consumers. Arbitrary fields that are silently ignored on the website do not meet the owner's requirement.

## Security and privacy

Keep credentials separate from public previews and out of source/logs. Password management must not expose a Cloudflare account token to the browser. Test unauthorized writes, session behavior, rotation and lockout in isolated data.

The public build enables first-party analytics only after an explicit grant.
Rejected and unresolved visits send nothing, admin previews are excluded, and
a graph must never imply invented visitors. The binding collection contract is
[`06-ANALYTICS-AND-PRIVACY.md`](06-ANALYTICS-AND-PRIVACY.md).

Subscriptions were cancelled. The separate daily digest remains dormant because the original cancellation and handover differ in scope.

## Running it without production

`REAL_SITE=1 node worker/dev/serve.js 8790` serves the actual built Flutter site
and current owner content with in-memory local storage. The default fixture mode
of `worker/dev/serve.js` instead uses the sanitized fixtures in `worker/contracts/fixtures/` and a throwaway token printed
at startup. `worker/dev/verify-a1.js` drives it in Chrome and writes
screenshots. Neither reaches Cloudflare, and the fixtures are a fictional person
so an editor screenshot can go in a worklog without publishing the owner's
address or his marks.

## Operations and costs

See [Worker operations](../worker/README.md) for existing commands. The site and Worker deploy separately. Use the existing content binding; do not recreate a production namespace from an old setup checklist.

GitHub Pages and Cloudflare free tiers are the current hosting approach. Quotas are limits, not a permanent no-cost guarantee: [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) and [KV pricing](https://developers.cloudflare.com/kv/platform/pricing/). No new paid storage, service or package is selected by this document.
