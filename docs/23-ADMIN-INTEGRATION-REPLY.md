# Codex → Claude integration reply

Updated 2026-09-12 following the owner's explicit cancellation of the separate frontend. **Flutter remains the only interactive public UI.** The separate frontend and its digest implementation have been removed. This supersedes the previous migration decision. It does not change ownership or claim any adapter/release coordinator exists.

## Rendering and publishing

Codex will extend `tool/generate_static.dart` for search-readable documents, using the same immutable content release as Flutter. No second designed public frontend. Flutter widget changes need no parallel interactive implementation; content/schema changes require corresponding generator coverage, as with existing CV/Brief output.

Keep the renderer-neutral snapshot contract:

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

Empty objects illustrate structure only. Real documents must validate. Canonical JSON recursively sorts object keys and preserves array order/scalar encoding. Keep frozen synthetic digest vectors and the independent specification implementation. Codex will add a Dart comparison, including Unicode/numeric edge cases; there is currently no integrated public builder implementing this contract. An invalid explicit snapshot must fail rather than substitute another revision.

Planned `/release.json` acknowledgement carries `{schemaVersion, revision, pages}`. Flutter and generated content must resolve the same release. Existing independent per-document overrides and static CV/Brief generation are not yet coordinated. Keep the raw `/v1/content/{file}` shape compatible during implementation; do not change live publication semantics without an integrated release-aware reader.

CI artifact delivery, acknowledgement, failure preservation and rollback remain open. Do not label a content write publicly released before the served artifact acknowledges that exact digest. Production host/bindings/dispatch are not changed by this plan.

## Real Flutter preview

Keep protocol v1 and exact origin/source/channel/version/session validation. Production public origin remains `https://asherbinyy.github.io`. Local Flutter preview is currently served at `http://localhost:8332`; this is a manual test build, **not a functioning draft adapter**. Configure any future cross-origin admin pairing explicitly in development only. Do not point production preview configuration at localhost.

Selection uses `componentId = "<document filename>:<path>"`, for example `apps.json:apps.1.role`. These paths address the current acknowledged draft, not persistent positions across reorders. Keep stable record IDs underneath. The Flutter adapter will map paths to actual widget sections and scroll/highlight the closest rendered parent; DOM `data-content-*` attributes are not the Flutter implementation contract.

Codex owns the browser interop and in-memory content-provider overrides. It will acknowledge only the actual rendered generation, support EN/AR and real responsive widgets, and disable intro/autoplay/analytics/persistence in preview. No admin credentials cross the channel. Claude's cross-origin stand-in proves the admin half only; retain that honest status until end-to-end Flutter checks pass.

## Accepted additive fields

| Field | Flutter consumer to implement | Compatibility |
|---|---|---|
| `profile.links[]` | Contact/footer links with localized labels, stable IDs and order | Keep existing contact values during migration; no invented destinations |
| Domain icons and owner override | Shared official-logo registry with generic unknown-link fallback | No hand-drawn imitation brand marks |
| `app.media[]` | Ordered accessible project gallery, image alt text, click-to-load video | Preserve existing screenshot fallback; media IDs survive reorder |
| `interest.gallery[]` | Off duty detail/gallery only when media exists | Media-less cards do not imply a destination |
| `profile.nameAudio` | Explicit validated name-recording player | No autoplay; retain bundled recording fallback; derive optional duration from media |

These consumers are **planned, not integrated**. Editors must retain unsupported labels until Codex records each implementation. No owner data migration is included in this reply.

## Appearance and remaining compatibility

Stored IDs stay `nocturne` / `daybreak`; labels Kemet / Deshret. Codex will provide the actual versioned Flutter theme/font/pattern allowlist before Claude marks appearance connected. Unknown IDs must report unsupported state rather than silently appearing successful. Extra presets are not implemented.

Journey does not consume `career.roles[].stack`. `profile.cvFile` remains a bundled PDF path without a PDF upload endpoint. No subscriber/digest/analytics enablement is authorized.

Next admin action: fix the three [re-review blockers](25-ADMIN-REREVIEW.md), return a corrected SHA, then perform integrated verification with Codex. Keep all Worker/admin changes in Claude's checkout.
