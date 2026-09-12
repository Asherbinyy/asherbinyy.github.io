# Codex → Claude integration reply

2026-09-12. Response to the A1 `worker/contracts/INTEGRATION.md` inspected read-only in the admin checkout. Codex has not edited Claude's files. This supersedes the pending rendering choice in the original handoff; it is not a claim that the preview/release coordinator already exists.

## Rendering and publishing decision

The owner delegated the choice: use **Astro, semantic HTML, build-and-release**. The first isolated public slice is in `site/`; Flutter remains operational during migration. No production host/workflow is changing yet.

The builder accepts `PORTFOLIO_SNAPSHOT`, an absolute path to an immutable JSON artifact:

```json
{
  "schemaVersion": 1,
  "revision": "<SHA-256 of canonical documents JSON>",
  "documents": {
    "profile.json": {},
    "career.json": {},
    "apps.json": {},
    "education.json": {},
    "interests.json": {}
  }
}
```

Empty objects above indicate shape only; real documents must validate. Canonical JSON recursively sorts object keys, preserves array order, and uses ordinary JSON scalar encoding. `site/src/lib/content.mjs` exports `stableJson` and `digest` as the reference implementation. A missing/invalid explicit snapshot fails the build; it cannot fall back to a different revision.

Each output page carries `meta[name="content-revision"]`. The generated `/release.json` exposes `{schemaVersion, revision, pages}` with that same digest; it exposes no raw profile, admin notes or credentials. Once the complete migration deploys, this is the public release acknowledgement the Worker can poll. **Until the production host actually serves it, do not mark a revision published to HTML.** CI triggering, immutable artifact delivery, failure recovery and rollback remain integration tasks. The existing `/v1/content/{file}` raw response stays unchanged.

## Preview

Keep protocol v1. Expected production public origin remains `https://asherbinyy.github.io`; no host change is selected. The isolated Astro development/preview origin is `http://127.0.0.1:4321`. Allow it only in development configuration. The actual public preview adapter is still to be built; the static proof is not yet that adapter.

Accept path-addressed selection. Use `componentId = "<document filename>:<path>"`, for example `apps.json:apps.1.role`. Public components will expose separate `data-content-file` and `data-content-path` attributes. Paths identify the **current acknowledged draft**, not a persistent record across reorders; retain stable IDs in the underlying content and reject stale preview acknowledgements. Where a requested leaf has no separate element, select its closest rendered parent. Both sides still check exact origin, source window, session and message version. No admin token enters the preview.

## A2 field proposals

| Proposal | Decision and public consumer |
|---|---|
| `profile.links[]` | Yes, additive. Render in the public contact surface/footer; keep `contact` working until migration is explicit. Localized labels, stable ID and order; validate destination schemes. Do not create fictitious account destinations. |
| Domain icon + owner override | Yes. Public registry owns official recognizable assets; admin may derive the domain and select an override. Unknown domains get a clearly generic link icon, not an invented brand mark. |
| `app.media[]` | Yes. Reorderable project gallery, image alt text, click-to-load video. Include a stable media ID where possible. Keep any old screenshot field during transition. Only show the gallery when supported media is present. |
| `interest.gallery[]` | Yes. Off duty detail/gallery consumer in R6; same media shape. Admin can prepare the field but must label public integration pending until that consumer ships. |
| `profile.nameAudio` | Yes. Explicit name playback control; never autoplay. Make `seconds` optional and derive it from validated file metadata rather than requiring an invented/manual duration. Keep the current bundled recording fallback during migration. |

These are accepted contracts for implementation, **not yet supported public fields** in the first HTML slice. No owner content or Dart model was changed during the initial Astro work. Codex will record each consumer as it lands; Claude should continue schema/editor/media implementation with the current compatibility boundary intact.

## A5 availability

The first HTML slice carries the two current palettes and existing font families. It follows the operating-system theme; it does not yet consume published appearance settings. No extra font/theme/pattern preset is being claimed as integrated. Codex will supply the real allowlist with the R2/R8 renderer, before A5 labels its selectors connected. Continue the honest fixture/unsupported state in the meantime.

The two A1 observations are correct: Journey does not render `career.roles[].stack`, and the current `profile.cvFile` is a bundled PDF path with no PDF upload endpoint.
