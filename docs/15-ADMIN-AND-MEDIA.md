# Admin and media

Current-state audit: 2026-09-11. Implementation baseline: `1cfd039`.
Target workflow and acceptance: [R3](19-REINNOVATION-ROADMAP.md#r3--admin-as-an-editing-workspace). Customization and analytics: [R8](19-REINNOVATION-ROADMAP.md#r8--customization-and-analytics).

## What exists

The Worker serves `/admin` from `worker/src/admin.js`. The HTML is public and marked noindex; write endpoints require a separate `ADMIN_TOKEN`. The panel edits profile, apps, career, education and interests as forms generated from existing JSON shapes.

Public content reads use `/v1/content/<file>`. Authenticated content writes/withdrawals use `/v1/admin/content/<file>`. The site tries the published document, with a timeout and bundled fallback. Image upload/list/remove endpoints and `/v1/media/<hash>` use the content KV binding.

The admin HTML is deployed according to the prior handover. This audit rendered a local fixture of the panel, not a production authenticated editing session. Public content reads during browser captures returned 404 for the requested overrides, so those views used bundled content. That does not by itself prove whether the content binding is configured.

## Current limitations

- No preview of the actual website. Image thumbnails are not the requested live preview.
- Objects expose existing keys; lists clone an existing item. There is no generic supported-field/component system and no flexible contact-link model.
- English and Arabic appear as separate inputs rather than the requested language tabs.
- Switching documents replaces the single draft without a dirty-state guard.
- Publish already sends only the selected document. The toolbar looks global; a page-specific confirmation/review flow is still missing.
- Image inputs are detected by matching their final field name. That misses `src` fields and cannot add screenshot fields absent from a document.
- Video is not uploaded. Name recording also has no upload endpoint.
- The server checks valid JSON and a top-level object, not full content-schema validity. The client may reject an accepted publish and silently fall back.
- The browser asks for sources on changed numeric values, but misses numeric claims embedded in strings. The server accepts publishes without a provenance note.
- No revision-conflict detection or coordinated static HTML publication.
- The panel stores its bearer token in tab `sessionStorage`, not a session cookie. In-panel password change and logout are absent. Failed attempts share an hourly counter and can lock out the correct token.
- No theme/font/pattern management or analytics homepage. The UI still says Nocturne.

## Media behavior

The existing endpoint accepts PNG, JPEG and WebP with size/type/dimension checks and rejects SVG. Media IDs are hashes of their contents. Current upload limit and dimensions are defined in `worker/src/index.js`; R3 must preserve validation while adding explicit media controls.

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

## Operations and costs

See [Worker operations](../worker/README.md) for existing commands. The site and Worker deploy separately. Use the existing content binding; do not recreate a production namespace from an old setup checklist.

GitHub Pages and Cloudflare free tiers are the current hosting approach. Quotas are limits, not a permanent no-cost guarantee: [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) and [KV pricing](https://developers.cloudflare.com/kv/platform/pricing/). No new paid storage, service or package is selected by this document.
