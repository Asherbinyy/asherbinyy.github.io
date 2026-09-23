# 2026-09-23-01 — Admin release closeout

**Agent:** Codex (GPT-6)
**Milestone:** 6
**Started from:** `f6e831b`

## Goal
Verify the merged admin release in production, deploy the matching Worker, and leave an accurate owner-facing release record and test handoff.

## What changed
- Confirmed PR #47 merged as `f6e831b` and GitHub Actions run `35806357378` published the matching portfolio build.
- Deployed `nocturne-analytics` Worker version `889ce68c-54ed-42df-a14f-3a2b287bad14` with the transactional content store, game objects, current site origin and existing secrets.
- Verified the live admin and site return 200, the game endpoint allows `https://sherbini.uk`, the retired GitHub Pages origin returns 403, and unauthenticated admin content access returns 401.
- Confirmed the deployed Wasm bundle contains the exact Worker origin used by the live preview adapter.
- Updated the release review and prior release record with the deployed revisions and live verification evidence; merged the documentation in PR #48 as `edf0730d`.

## Files touched
- `docs/31-CODEX-ADMIN-UI-REVIEW.md` — modified — record the live site, Worker version and production boundary checks.
- `docs/worklog/2026-09-17-01-admin-production-release.md` — modified — replace the pending deployment step with the completed release evidence and owner acceptance step.
- `docs/worklog/2026-09-23-01-admin-release-closeout.md` — created — record this production closeout and handoff.

## Decisions made
Keep the local development token separate from production. The existing `ADMIN_TOKEN` remains configured as a Cloudflare secret and cannot be read back; rotate it only if the owner no longer has the production recovery credential. Treat static CV, brief and search-metadata publication as the separate SEO-5 release contract rather than claiming the runtime admin currently rebuilds static HTML.

The installed `/usr/local/bin/fvm` is an obsolete Intel executable that crashes on this host. The checks used the installed FVM 4.3.1 launcher with the repository's pinned ARM Dart 3.13.2 and Flutter 3.47.2 SDK, preserving the required FVM toolchain.

## Tests
- Added: none.
- Modified: none.
- Full suite: pass, 783 Flutter tests and 323 Worker tests passing, 0 failing.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 331 files unchanged
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 783 tests
fvm flutter build web --wasm               pass, built build/web
```

## Known issues left open
Static CV, brief and search metadata do not rebuild from a runtime admin publication; SEO-5 tracks that coordinated release work. Extra appearance presets and per-page patterns remain undefined under ADM-6. Physical iPhone Safari, Android Chrome and screen-reader owner acceptance remain open. The successful Wasm build still reports the existing Cupertino icon-font warning.

## Next
The owner should sign in to the hosted admin with the existing production recovery credential, exercise editing and preview on desktop and phone, and set a personal password under Account. Rotate `ADMIN_TOKEN` only if that recovery credential is unavailable.
