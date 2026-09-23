# 2026-09-17-01 — Admin production release

**Agent:** Codex (GPT-6)
**Milestone:** 6
**Started from:** `18b8af4`

## Goal
Finish the admin workspace, connect its preview to the current Flutter site, integrate the custom-domain and leaderboard work, and prepare the matched site and Worker production release.

## What changed
- Completed independent navigation and preview-panel controls, with a half-width live preview and a one-third compact option on desktop plus a full-width phone switch.
- Connected every current public destination to the admin's schema-driven editors and real Flutter preview, including Services, social links, uploads, audio, galleries and the existing appearance defaults.
- Integrated the latest application screenshot strips and structured Off duty favourites into the same validated editor and preview after they landed on `main`.
- Replaced the decorative admin treatment with the portfolio's existing typography, limestone surfaces and functional pigment roles.
- Added honest insights charts and empty/disabled states without seeding or estimating analytics.
- Built the production site with an exact Worker-origin preview allowlist and isolated preview game, analytics, content and preference providers from public services and browser storage.
- Enabled the reviewed SQLite `CONTENT_STORE` binding after confirming the production content namespace contained zero keys, so no published content, revision, password or media data required migration.
- Integrated the custom-domain and leaderboard release while retaining all three Durable Object bindings.
- Recorded 76 passing end-to-end browser checks and representative desktop, phone and live-preview captures.

## Files touched
- `.github/workflows/ci.yml` — modified — compile the exact deployed admin origin into the Pages preview adapter.
- `lib/core/preview/preview_host.dart` — modified — keep the leaderboard client disabled inside private admin previews.
- `test/unit/content/admin_integration_test.dart` — modified — verify the preview cannot use the public leaderboard.
- `worker/src/` and `worker/contracts/` — modified — integrate the redesigned admin, current schema consumers, preview protocol and release documentation.
- `worker/dev/verify-admin-integration.js` — modified — exercise all destinations, panel modes and the current game in an isolated real preview.
- `wrangler.toml` — modified — enable the transactional content object alongside the leaderboard objects.
- `docs/audits/2026-09-16-admin-final/` — created — store the final browser results and representative captures.
- `docs/11-OPEN-ISSUES.md` — modified — close the delivered admin integration rows and retain the defined publication and appearance limits.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — document the current production release and remaining boundaries.
- `docs/31-CODEX-ADMIN-UI-REVIEW.md` — modified — provide the owner-facing review, destination inventory and validation evidence.
- `worker/README.md` — modified — document the production bindings and verified empty migration source.
- `CHANGELOG.md` — modified — record the completed admin release.

## Decisions made
The public site and Worker are released together because the preview accepts one exact parent origin. The leaderboard client is null in preview so opening the game while editing cannot create challenges, scores or replay alarms. The transactional store is enabled without a migration job because Cloudflare reported zero keys in the existing production `CONTENT` namespace immediately before release; the KV fallback remains available for development and rollback. No owner content or analytics data was invented.

## Tests
- Added: production preview assertion that the leaderboard client is disabled; browser coverage for every admin destination and the current game preview.
- Modified: admin integration browser verification and preview isolation coverage.
- Full suite: pass, 783 Flutter tests and 323 Worker tests passing, 0 failing.
- Coverage delta: not measured.

## Verification run
```
pinned Dart format --set-exit-if-changed .   pass, 331 files unchanged
pinned Flutter analyze                        pass, no issues
pinned Flutter test                           pass, 783 tests
pinned Flutter build web --wasm               pass
```

## Known issues left open
Static CV, brief and search-metadata publication still require the coordinated HTML release tracked as SEO-5. Extra appearance presets and per-page patterns remain undefined under ADM-6. Exact field-level preview scrolling, physical Safari/Android testing and a screen-reader pass remain open. The existing successful Wasm build still reports the Cupertino icon-font warning.

## Next
Merge the checked release, wait for GitHub Pages to publish the matching preview-capable build, deploy the Worker from that same revision, and verify the production origin, routes and bindings.
