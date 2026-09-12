# 2026-09-12-04 — Flutter reset and admin re-review

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** bfbaaf8; Claude admin afc8969ef056173cc1e7e0fcfc2f5a2bda56529d

## Goal
Remove the owner's rejected separate public frontend and related art/docs, preserve Flutter, and plan its enhancements. Re-review Claude's corrected admin branch before integration and supply precise remaining fixes within the existing ownership split.

## What changed
- Removed the entire rejected `site/` implementation, including uncommitted entrance/audio experiments and ignored dependencies/build outputs. Stopped its development and preview servers.
- Deleted migration-specific documentation, screenshots and generated entrance artwork. Preserved the original request audit, source evidence, Flutter browser captures and useful Journey/sitemap repairs. Git history remains intact; this is a scoped removal, not a reset of the shared branch history.
- Renamed the audit and replaced the old roadmap with a Flutter-only enhancement plan: admin reliability/preview first, then Home/intro/motion, playable game increments, Journey, Work/Writing, About, appearance, search/release and device evidence. Original request IDs remain mapped so requests do not disappear.
- Rewrote the integration reply for the same Flutter widgets in public and admin preview. Preserved protocol v1, additive field proposals, stable theme IDs and immutable release contracts; removed the deleted frontend's module dependency. The Dart generator/release-aware reader and actual preview adapter remain planned.
- Updated brief, architecture, open issues, admin handoff/spec, game spec, README, changelog and affected links. Removed rejected art/migration portions from the preceding mixed worklog while retaining its admin review evidence.
- Independently ran 262 Worker tests on afc8969. A bounded read-only backend reviewer reproduced three remaining defects; root reran the saved script and confirmed concurrent login-admission bypass, content/head mismatch and session resurrection after logout. Saved fixture-only reproduction code and output in the audit folder.
- Exercised the actual ContentStore in local Wrangler/workerd with a temporary enabled Durable Object binding and sanitized fixtures: eight simultaneous same-base saves produced one success and seven conflicts; history retained one revision. No production binding or data was touched.
- Wrote the current Claude prompt and acceptance criteria in `25-ADMIN-REREVIEW.md`. Claude's checkout remains unchanged; no direct tool to his separate session is available, so the prompt is prepared for the owner rather than claimed sent.
- Verified GET Home/Journey on the retained Flutter review server at `http://localhost:8332`. The server serves a built Flutter app; it is not yet an admin draft adapter. README provides the repeatable FVM development command. The temporary server's HEAD handling for Journey differs from GET; this is not evidence of production deep-link fixes.

## Files touched
- `site/**` — deleted — rejected separate frontend, including ignored/generated local files.
- `docs/22-HTML-FOUNDATION.md`, `docs/audits/2026-09-12/html-foundation/**`, `docs/audits/2026-09-12/r2-entrance/**`, `docs/worklog/2026-09-12-01-html-foundation.md` — deleted — rejected migration/art documentation and artifacts.
- `docs/18-REINNOVATION-AUDIT.md` → `docs/18-PROJECT-AUDIT.md` — renamed/modified — preserve source audit, replace cancelled recommendation and phase links.
- `docs/19-REINNOVATION-ROADMAP.md` → `docs/19-FLUTTER-ENHANCEMENT-PLAN.md` — replaced — Flutter-only phased implementation/acceptance plan with original request coverage.
- `docs/25-ADMIN-REREVIEW.md` — created — corrected-SHA findings, runtime evidence, limits and Claude prompt.
- `docs/audits/2026-09-12/admin-rereview/{README.md,reproduce-afc8969.mjs,result.txt}` — created — repeatable sanitized evidence for three remaining defects.
- `docs/23-ADMIN-INTEGRATION-REPLY.md`, `docs/20-APP-ADMIN-CONTRACT.md` — modified — Flutter preview/generator ownership and renderer-neutral release boundary.
- `docs/24-ADMIN-MERGE-REVIEW.md`, `docs/21-CLAUDE-ADMIN-HANDOFF.md`, `docs/15-ADMIN-AND-MEDIA.md` — modified — distinguish historical baseline from afc8969 and direct Claude to the remaining fixes.
- `docs/00-PROJECT-BRIEF.md`, `docs/03-ARCHITECTURE.md`, `docs/11-OPEN-ISSUES.md`, `docs/13-GAME-DESIGN.md` — modified — actual Flutter decision, current blockers and manual-jump planning default.
- `README.md`, `CHANGELOG.md`, `.gitignore` — modified — concise current setup/status, removal record and obsolete frontend ignores removed.
- Other affected `docs/*.md` status banners and two September 11 worklogs — modified — update audit/plan filenames and phase links without deleting source history.
- `docs/worklog/2026-09-12-03-admin-review.md` — modified — retain admin evidence, remove rejected art/migration portions and point to current re-review.
- `docs/worklog/2026-09-12-04-flutter-reset-admin-rereview.md` — created — this record.

## Decisions made
- The owner's explicit cancellation authorizes removing the rejected files. Keep Flutter as the only interactive UI; no further redesign implementation in this planning pass. No application files under `lib/`, `web/`, `tool/`, `assets/`, `test/` or `worker/` were changed by this reset.
- Keep the existing Journey/sitemap fixes rather than reverting all app work. Existing theme/token values, intro assets, routes, owner content and SDK remain unchanged.
- Use manual Space/tap as the game planning default, with forgiving timing and spring feedback. Review a playable feel prototype before expanding levels. This is a documented implementation assumption based on the earlier control request, not a claim of new playtest approval.
- Extend the existing Dart generator for search-readable output and a shared release; do not maintain another interactive frontend. New content types still require generator coverage/parity checks. The preview will reuse Flutter widgets through in-memory provider overrides and a path-to-widget registry.
- Respect Claude's admin ownership. New findings prevent merge despite passing suites and local content transaction checks. Current disabled binding/migration and three auth/read races remain separate blockers. No production enablement, main merge or deployment is implied.
- Retain source/license records for the current guardian. Removing the rejected new artwork does not authorize removing required attribution from retained assets.

## Tests
- Added: fixture-only review reproduction script; its assertions deliberately confirm the old defects and are not passing-correctness regressions. Claude must adapt them when fixing his branch.
- Modified: none in the application test suites.
- Full suite: pass, 676 Flutter passing, 0 failing; independently reviewed admin suite pass, 262 Worker passing, 0 failing.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 676 tests
fvm flutter build web --wasm               pass
```

Fresh FVM logs: `/private/tmp/nocturne-flutter-reset-{format,analyze,test,build}.log`. Existing Material/Cupertino icon-font build warning remains; the build succeeds. Admin suite log: `/private/tmp/nocturne-admin-rereview-tests.log`.

The saved reproduction runs with Node against the specified admin checkout, no network or owner data. Whole-release capture is a related source finding; the deterministic script proves its editor-read counterpart. Local Wrangler used temporary fixture-only config/state under `/private/tmp/nocturne-admin-rereview`; it is actual local workerd, not Cloudflare production. Claude's reported 136 browser checks were not all independently rerun here. Flutter GET Home/Journey responses contain `flutter_bootstrap.js`; this is a dev-server check, not a production status claim.

## Known issues left open
- ARR-1/2/3 require Claude fixes and re-review; no admin merge occurred. Durable Object production binding, migration/recovery and provider availability/cost remain unverified operational work.
- Real Flutter preview, accepted field consumers, appearance allowlist, release-aware content reader and coordinated static generation are unimplemented.
- F2–F9 enhancements are planned, not built. The owner has not approved a new rendered visual slice. Existing game/intro complaints remain.
- Production search/deep-link/metadata issues, source-content ambiguities and physical iOS/Android browser acceptance remain open. No analytics was enabled or production content changed.
- The four FVM checks do not establish that the current design is enjoyable or visually accepted. Chrome emulation cannot replace real phone testing.

## Next
Claude fixes the three afc8969 re-review defects using the committed prompt and reproductions, then returns a corrected SHA so Codex can re-review/integrate before implementing F1's real Flutter preview.
