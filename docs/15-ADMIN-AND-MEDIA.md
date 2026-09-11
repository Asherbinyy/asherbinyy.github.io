# Admin and media

Current state: 2026-09-11, after admin phase **A1**. Audit baseline was `1cfd039`.
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

### Phase A1, delivered

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

Verified in Chrome against `worker/dev/serve.js`: 27 browser checks, screenshots
in `docs/audits/2026-09-11-admin-a1/`.

## Still missing

- **The third column is an outline of the draft, not the site.** It says so, in
  the panel. The real preview needs the adapter in
  [`INTEGRATION.md`](../worker/contracts/INTEGRATION.md) §3.2 (A3).
- Media is still one image endpoint and one uploader per image field. No media
  library, gallery ordering, alt text, progress or retry (A2).
- Editable links, project media lists, interest galleries and evidence
  attachments are proposed in `INTEGRATION.md` §3.4 and not built (A2).
- Video is not uploaded. Name recording has no upload endpoint; an image
  endpoint must not be used for audio (A2).
- Review shows a before/after diff, but there is no publish confirmation step,
  no revision store, no stale-edit conflict detection and no rollback (A3).
- The server records a provenance note when one is sent; it does not yet
  require one. That enforcement needs a trustworthy baseline and lands with
  revisions (A3).
- No coordinated static HTML publication. A publish changes the app and not the
  CV, Brief or metadata (A3, blocked on R1).
- The token is still in tab `sessionStorage`. No in-panel password change or
  logout, and failed attempts still share an hourly counter that can lock out
  the correct token (A4).
- No theme, font or pattern management (A5). No analytics homepage (A6).

## Media behavior

The existing endpoint accepts PNG, JPEG and WebP with size/type/dimension checks and rejects SVG. Media IDs are hashes of their contents. Current upload limit and dimensions are defined in `worker/src/index.js`; R3 must preserve validation while adding explicit media controls.

A1 changed which fields get an uploader, not what the endpoint accepts. The
schema marks a field as holding an image, so `portrait.src` and an evidence
`src` have one now and a caption does not. The validation at the trust boundary
is untouched.

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
