# 2026-09-23-02 — Rotate the admin recovery token

**Agent:** Codex (GPT-6)
**Milestone:** 6
**Started from:** `5d857448`

## Goal
Replace the unreadable existing production admin recovery credential at the owner's request and verify the new credential without exposing it in the repository or deployment logs.

## What changed
- Generated a new 256-bit random recovery token and replaced the `ADMIN_TOKEN` Cloudflare Worker secret.
- Redeployed the unchanged `nocturne-analytics` Worker as version `f36f76e7-4aa8-486d-a80a-5f7b89f6b905` with the existing bindings, schedules and `https://sherbini.uk` origin.
- Exchanged the new recovery token for a real production admin session, confirmed the former local-development token returns 401, and ended the temporary verification session.

## Files touched
- `docs/worklog/2026-09-23-02-admin-token-rotation.md` — created — record the authorized secret rotation and live verification without recording the credential.

## Decisions made
Use a 64-character hexadecimal token sourced from 32 cryptographically random bytes. Keep `CONSOLE_TOKEN` and `GAME_SECRET` unchanged. Share the new recovery token directly with the owner once and keep its value out of source, tests, worklogs and command output.

## Tests
- Added: none.
- Modified: none.
- Full suite: pass from the unchanged release, 783 Flutter tests and 323 Worker tests passing, 0 failing.
- Coverage delta: not measured.
- Live verification: new recovery token 200 with a session, former local-development token 401, verification-session logout 200.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 331 files unchanged
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 783 tests
fvm flutter build web --wasm               pass, built build/web
```

## Known issues left open
Static CV, brief and search metadata remain outside runtime admin publication under SEO-5. Physical phone and screen-reader owner acceptance remain open. The successful Wasm build retains the existing Cupertino icon-font warning.

## Next
The owner should save the new recovery token in a password manager, use it once at the hosted admin, and set a personal password of at least twelve characters in Account.
