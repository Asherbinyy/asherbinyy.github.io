# 2026-09-16-05 — Activate the game Worker on the custom domain

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** `ec4ee8e21383783b62dbc535140532d30fa92e12`

## Goal
Set the game's signing secret, deploy Claude's leaderboard Worker and verify the live service on `sherbini.uk`. The owner explicitly asked to pause further admin work until they say go.

## What changed
- Generated a separate 48-byte random `GAME_SECRET` and piped it directly into Wrangler's secret command. Its value was not displayed, saved to a file or committed. Existing admin and console secrets were preserved.
- Found and fixed a production-only clock mismatch: the normal Worker entrypoint supplies a `Date`, but the game adds milliseconds to it. That produced a string expiry, rejected by both the Flutter challenge parser and the token validator. The game boundary now converts the clock to epoch milliseconds. Existing tests had injected a numeric clock and missed this.
- Made the existing admin's bundled-content base derive from `SITE_ORIGIN`. Otherwise its old GitHub URL conflicts with the CSP after the custom-domain change.
- Merged PR #42 after both CI runs and security checks passed. Deployed exact main revision `13e8a7f257827ac0b04df9326070b37692319ac4` with cached Wrangler 4.129.0.
- Applied the existing `v1-ascent-board` migration and `GAME_BOARD` / `GAME_VERIFIER` SQLite Durable Object bindings. Updated the live origin to `https://sherbini.uk`; preserved both KV namespaces, `SITE_ID`, feed URL, admin/console secrets and both cron schedules.
- Active Worker version: `6589b4dc-763f-4965-811c-3d21df37749c`, receiving 100% of traffic at `https://nocturne-analytics.asherbinyy.workers.dev`.
- Corrected the open-issues deployment status. The admin redesign, public content and analytics collection were not changed.

## Files touched
- `worker/src/index.js` — modified — normalize the game clock without changing the Date-based analytics paths.
- `worker/src/admin.js` — modified — load bundled documents from the configured public origin.
- `worker/test/release.test.js` — created — production-clock challenge/submission and admin bundle/CSP regressions.
- `docs/11-OPEN-ISSUES.md` — modified — close the custom-domain Worker deployment blocker and record the phone check still needed.
- `CHANGELOG.md` — modified — record activation and the two necessary release fixes.
- `docs/worklog/2026-09-16-05-codex-game-worker-release.md` — created — deployment evidence and handoff.

## Decisions made
Use the current `sherbini.uk` configuration supplied by Claude's latest main, rather than reverting to either GitHub Pages origin. Keep `SITE_ID` unchanged so historical analytics keys are not renamed. Use the already available Wrangler version and credentials; no package or SDK upgrade.

The production replay probe submitted 1,025 idle ticks, first replayed locally against the server-issued seed to prove the tape could not finish a climb. This requires three alarm chunks and is rejected as incomplete, so it verifies actual Durable Object execution without creating a synthetic public score. Temporary verification state uses the existing ten-minute cleanup alarm.

Source fixes are merged in [PR #42](https://github.com/Asherbinyy/asherbinyy.github.io/pull/42). This deployment record is saved on `fix/game-worker-release` after that merge. Future admin integration must retain the new game exports, bindings, migration and secret.

## Tests
- Added: `a challenge can be submitted with the production default clock`; `a challenge can be submitted with the explicit Date clock`; `admin bundled content uses the origin permitted by its CSP`. All three were observed failing before the fixes and passing afterward.
- Modified: none.
- Full suite: pass, 750 Flutter tests and 102 Worker tests passing, 0 failing.
- Coverage delta: not measured locally; both GitHub verification jobs passed the existing coverage gate.
- GitHub CI: `35134608646` and `35134648773` passed verify and macOS goldens; GitGuardian passed.
- Live leaderboard GET: 200, season `v1`, empty entries, correct `access-control-allow-origin` for `https://sherbini.uk`.
- Live origin refusals: 403 for `https://asherbinyy.github.io`, `https://lsherbini.github.io`, and a missing Origin; no allow-origin header.
- Live beacon: OPTIONS 204 with correct CORS; an invalid POST body returned 400 rather than 403. No synthetic analytics event was sent.
- Live admin: 200; bundle base and CSP both use `sherbini.uk`.
- Live game challenge: 200 with numeric expiry; submission: 202 pending; real alarms completed the three-chunk replay and returned `rejected / incomplete-run`. The leaderboard remained empty.
- Actual live Flutter page opened in isolated Chrome; Play opened the game, the height semantics appeared, and a fetch from the site's real browser origin returned the live board with 200. Browser closed afterward. The helper disables GPU, so the Three.js entrance reported WebGL-context errors; this is not evidence of physical-phone rendering or a clean graphics-console run.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 314 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 750 tests
fvm flutter build web --wasm               pass, 82.4 seconds
```

## Known issues left open
- A human's complete ranked climb through the actual Flutter UI still needs the owner's phone check. The deployed API, signing, origin boundary and alarm execution are verified; physical input feel and a real accepted score are not claimed.
- The first climb is local. Joining happens after that result; a subsequent climb uses the signed challenge fetched after joining. Wait briefly after joining before pressing Climb again.
- The pre-existing Cupertino icon-font build warning remains; Material and Simple Icons were found. No dependency changes were made.
- The admin redesign remains on `phase/codex-admin-ui`; it must merge the current custom-domain/game changes before any future Worker deployment. Do not deploy its older Worker over this game release.
- Replay validates reachable physics, not human participation; the existing design limitation remains.

## Next
The owner should open `https://sherbini.uk/courtyard` on their phone, finish a climb, join the board, then play another and check the verification/result plus touch controls. Wait for their go before resuming the admin work.
