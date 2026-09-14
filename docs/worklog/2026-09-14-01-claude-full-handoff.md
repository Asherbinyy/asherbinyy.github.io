# 2026-09-14-01 — Transfer app and admin to Claude

**Agent:** Codex
**Milestone:** 6
**Started from:** 2026-09-13-02-selective-restoration.md; admin 4e75259

## Goal
Stop the rejected visual work, transfer the entire project to Claude, verify the latest admin fix and prepare a concrete fix for any remaining blocker.

## What changed
- Revoked the old Codex-only public-file restrictions. Prepared the complete source/branch inventory, design constraints, remaining integrations and a ready-to-send Claude prompt.
- Found missing Material icon-font bundling and enabled it in pubspec. Did not continue visual redesign.
- Delegated a bounded independent admin review to a Codex sub-agent. Original delayed-login race is fixed; reproduced a related stale password rotation overwriting recovery credentials.
- Prepared and tested a conditional-generation rotation fix in an isolated temporary checkout; exported patch, regressions, standalone reproductions and application instructions. Shared admin checkout remains untouched.
- Checked official Cloudflare documentation: SQLite Durable Objects are available on Free. Account API read failed with authentication error; no production change.

## Files touched
- `pubspec.yaml` — modified — bundle MaterialIcons used by the existing widgets.
- `docs/29-CLAUDE-FULL-PROJECT-HANDOFF.md` — created — complete handoff and new-chat prompt.
- `docs/20-APP-ADMIN-CONTRACT.md`, `21-CLAUDE-ADMIN-HANDOFF.md`, `23-ADMIN-INTEGRATION-REPLY.md`, `26-GAME-LEADERBOARD-CONTRACT.md`, `27-CONTINUE-HERE.md` — modified — Claude owns both halves, old lane restrictions superseded, exact open work.
- Active scope notes in `docs/00`, `01`, `03`, `11`, `12`, `19`; `README.md`, `CHANGELOG.md` — modified — rejection and transfer status.
- `docs/audits/2026-09-14/admin-rotation-fix.patch`, `admin-rotation-fix-results.md`, `verify-login-generation.mjs`, `verify-rotation-generation.mjs` — created — tested isolated backend fix and evidence.
- `docs/audits/2026-09-14/handoff-about.png` — created — failed browser attempt against expired localhost, not valid UI evidence.
- `docs/worklog/2026-09-13-02-selective-restoration.md` — modified — close pending technical status and record subsequent rejection.
- `docs/worklog/2026-09-14-01-claude-full-handoff.md` — created — this record.

## Decisions made
The user authorized Claude to own all public/admin work. No Claude tool/CLI is available, so the prompt is prepared for the user; no claim that the separate Claude session was contacted. The Codex sub-agent is an internal reviewer, not Claude.

Keep backend repair isolated to avoid overwriting Claude's branch. Patch application and integrated verification remain Claude's first task. The four public integration tasks are still unimplemented, now assigned to Claude rather than blocked by ownership.

## Tests
- Added: isolated Worker regressions for stale rotation with old-session bearer and recovery bearer plus old current password; both fail on base code.
- Modified: concurrent recovery-rotation test checks one surviving final session; actual recovery credential authorizes bypass.
- Full suite: public 693 passing, 0 failing; original Worker 278 passing; isolated patched Worker 280 passing, 0 failing, 0 skipped.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 287 files unchanged
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 693 tests
fvm flutter build web --wasm               pass, 243.5s
```

Built manifest contains MaterialIcons; tree-shaken font is 7,932 bytes. CupertinoIcons dependency warning remains. Browser attempt hit an expired localhost server; it is not successful visual verification. Restart/recheck was interrupted by the final handoff request. No physical-device or design acceptance claimed.

Worker checks were run independently by the Codex review sub-agent on Node 20.2.0, not copied from Claude's report. The patch passes git apply --check against the clean 4e75259 checkout. Fixed reproductions reject stale login and rotation with 401 and preserve the recovered password/session. No new Cloudflare-runtime or admin-browser checks for the isolated patch.

## Known issues left open
- Claude must apply/commit the tested patch and perform integrated checks; shared admin source has not changed.
- Real Flutter preview, HTML release parity, new-field renderers, A5 and leaderboard remain open and now belong to Claude.
- Latest visuals rejected. Preserve sourced content/real covers and improve through bounded browser-reviewed milestones.
- Cloudflare account authentication, migration of content/auth state and production activation remain unresolved. Nothing merged or deployed.
- Arabic review, real phones and CupertinoIcons warning remain outstanding.

## Next
Send Claude the prompt in docs/29-CLAUDE-FULL-PROJECT-HANDOFF.md; Claude applies the tested blocker fix and takes both app/admin forward.
