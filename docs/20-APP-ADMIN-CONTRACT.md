# Public app / admin integration contract

2026-09-11. Coordination specification, not an implemented API. The owner assigned all admin work to Claude and the public app to Codex. Existing behavior below remains supported until both implementations pass integration checks.

## Ownership

| Surface | Owner | Working rule |
|---|---|---|
| `worker/**`, admin UI, backend auth/content/media, Worker tests and operations docs | Claude | Work in the separate admin worktree; no production deployment |
| `lib/**`, `web/**`, `tool/**`, public assets, Flutter tests, public frontend/build | Codex | Own public rendering, design, motion, game, SEO and preview adapter |
| `assets/content/**`, schema/provenance docs, this contract, publishing CI | Coordinated by Codex | Claude proposes additive schemas and fixtures in `worker/`; Codex implements consumers and migrates owner data after agreement |
| Worklogs | Each agent | Unique filenames; record branch, verification and integration requirements |
| Roadmap/open issues/changelog | Codex integrates | Claude records completion evidence in his handoff/worklog; avoid concurrent edits to the central queue |

Separate worktrees prevent file collisions; they do not make incompatible interfaces safe. Changes to fields, routes or release behavior need a written contract update before integration. Neither agent edits the other's checkout.

## Existing compatibility boundary

- Public reads: `GET /v1/content/{file}`. The five documents are `profile.json`, `career.json`, `apps.json`, `education.json`, `interests.json`. A missing override returns 404 and the app uses bundled content. A successful response is the document itself, **not** an envelope.
- Current admin routes: `/admin`, `/v1/admin/content`, `/v1/admin/content/{file}`, `/v1/admin/changes`, `/v1/admin/media`. Preserve existing behavior while adding versioned alternatives; test compatibility.
- Bundled Dart models under `lib/content/models/` define what the public app currently consumes. Unknown JSON properties do not become visible UI automatically.
- Existing media accepts validated PNG/JPEG/WebP up to 4 MiB. Audio, evidence attachments and video are not covered by that image upload contract.
- The release reads remote content independently of static CV/Brief generation. This is an open publication defect, not the desired long-term behavior.

## Schema work sequence

Claude first creates proposed schemas, migrations and sanitized fixtures under `worker/contracts/`. Keep this work independent of a Flutter-versus-HTML decision. Codex reviews/implements public consumers before any new field is described as supported or published to production.

Every proposed component must specify:

1. Stable ID, component type, order and optional/required fields.
2. EN/AR values and missing-translation behavior; never manufacture a translation.
3. URL/media validation, alt text and reference integrity.
4. Exact public surface that consumes it and a corresponding preview fixture.
5. Migration from the existing document and rollback/unsupported-version behavior.

First shared components: links (label, destination, order, domain icon and optional override), project media (image/video kind, source, alt/caption, order), education evidence, interest galleries, editable stats/country entries and journey stops. These are requested capabilities, not permission to invent values. Use controlled component types for custom sections; raw HTML, arbitrary JavaScript and unconsumed keys are not page customization.

Theme/font/pattern settings use allowlisted IDs exposed by the public renderer. Keep Kemet and Deshret. Claude may build selectors against fixtures, but cannot mark a preset integrated until Codex supplies a real renderer and asset support. No package or token changes are implied here.

## Proposed preview protocol v1

Codex owns the real public preview adapter. Claude owns its container, draft state and editor synchronization. Until the adapter exists, label an isolated fixture preview honestly; do not substitute a separately styled admin mockup and call it the live site.

Messages use an object with `channel: "portfolio-preview"`, `version: 1`, `sessionId`, `type` and `payload`. The editor generates an ephemeral session identifier. Both ends validate `event.origin`, `event.source`, session and message shape. Use exact configured origins, never `*` for `targetOrigin`. Localhost development origins are explicit development configuration.

| Direction/type | Payload | Rule |
|---|---|---|
| Preview → editor `ready` | supported component/schema versions | Send a draft only after this handshake |
| Editor → preview `draft` | request ID, document name, schema version, locale, validated draft | In-memory replacement only; no public publish or storage write |
| Editor → preview `select` | component ID | Scroll/highlight actual component, respecting reduced motion |
| Preview → editor `rendered` | request ID, component IDs, validation errors | Acknowledge the draft actually rendered; stale acknowledgements ignored |

No bearer token, password, management credential, production analytics or viewer identifier crosses this channel. Draft preview is excluded from indexing. Page reload establishes a new handshake. Preview failure preserves the editor draft and exposes retry.

## Publication and revisions

Claude can implement schema validation, independent in-memory page drafts, review/cancel, conflict detection and an isolated revision store now. The final public-release coordinator depends on R1's rendering decision; do not quietly choose a host or enable a deployment trigger.

Required states: draft → validated → publication pending → published, or failed. A write accepted into a content store is not proof of publication. Publishing compares the expected base revision with the current revision; stale edits return a conflict instead of silently overwriting. A retry must not create duplicate releases. Rollback points at a previously validated complete revision.

The eventual public HTML, metadata, sitemap and interactive reader must resolve one release revision. Publish success is shown only after that release is ready. Serve the previous successful revision on build/release failure. Revision metadata must not break the current raw-document read response.

Integration proof uses local/test data: edit → preview → cancel (live unchanged) → publish → matching HTML/app revision → stale-edit rejection → failed-release preservation → rollback. Do not use production mutations as a test.

## Analytics and credentials

The admin dashboard may display existing available counters and an honest no-data state. No new collection, consent changes, storage of viewer preferences or synthetic production events are authorized by this split. Weekly/monthly unique visitors cannot be inferred by adding daily unique counts. Name every aggregation correctly.

Claude owns password change, logout and lockout design. Keep Cloudflare management credentials server-side; the browser must never receive an account API token. Document session invalidation and recovery before changing the credential source. Existing production secrets and deployments remain untouched until separately authorized.
