# 2026-09-15-03 — Move the Worker's allowed portfolio origin

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** `923c87e`

## Goal
Move only the deployed `nocturne-analytics` Worker's allowed site origin and admin bundle URL to `https://lsherbini.github.io`, as explicitly requested by the owner.

## What changed
- `SITE_ORIGIN` now permits the new portfolio origin; the old origin is refused.
- The admin's bundle base now reads `https://lsherbini.github.io/assets/assets/content`.
- Downloaded the existing deployed module and changed exactly its one bundle URL literal. Uploaded that module with the new origin and inherited every other binding. No admin integration code, schema, content, other Worker or public-site build was deployed.
- Verified the new source hash, bindings, runtime settings, workers.dev settings and both unchanged cron schedules after deployment.
- Active version: `521b9914-7a56-439e-89b4-fccd48ca864d`; previous version: `5c8341e6-003b-490a-b99c-6460692f8293`.

## Files touched
- `wrangler.toml` — modified — allowed portfolio origin.
- `worker/src/admin.js` — modified — current portfolio bundle base.
- `docs/worklog/2026-09-15-03-codex-worker-origin.md` — created — deployment and verification record.

## Decisions made
Preserved `SITE_ID` as the historical analytics identity. Changing a hosting origin does not require changing the identifier used by existing records. Preserved both secrets through inherited bindings without reading their values. The upload API rejected an explicit inherited version ID despite the API schema describing it; it accepted `latest` after checking that the latest version was the reviewed active version. The rejected attempt did not deploy.

Used the exact deployed module instead of building either working admin branch. Its SHA-256 changed from `4a3fa6407bbf76b03ff8cfc7d5277bf3c8c05a91dfd6c2c7a674588b9cb90ae8` to `00ba51fe908425aa5ebeb18d894ffa32b5d8636d106455c228eb9df7acb07e00`, matching the one reviewed literal replacement.

## Tests
- Added: none; this is a URL/configuration substitution.
- Modified: none.
- Full suite: pass, 704 Flutter tests and 70 Worker tests passing, 0 failing.
- Coverage delta: not measured.
- Live `OPTIONS /v1/beacon`: new origin returns 204 and `access-control-allow-origin: https://lsherbini.github.io`; old origin returns 403 with no allow-origin header.
- Live `GET /v1/content/profile.json`: new origin is allowed (404 because no profile override is published); old origin returns 403.
- Live `/admin`: 200, new bundle URL present and old bundle URL absent.
- No valid analytics event was submitted.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 297 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 704 tests
fvm flutter build web --wasm               pass
```

The initial analysis in the fresh worktree failed because ignored generated files were absent. Ran `fvm dart run build_runner build --delete-conflicting-outputs` and `fvm flutter gen-l10n`, then all four checks passed. The existing Cupertino icon-font warning remains in the successful build.

## Known issues left open
- The new public bundle URL returned HTTP 404 during verification. The prior migration worklog says GitHub Pages still needs enabling; this session did not change Pages or deploy the public site.
- The production admin remains the existing version with only the URL corrected. The ongoing redesigned admin/Flutter preview work remains local and was not included in this deployment.

## Next
Serve the portfolio and its content bundle from the new GitHub Pages origin so the deployed admin can load its new bundle URL.
