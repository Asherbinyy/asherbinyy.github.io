# 2026-09-07-04 — Deploy the cover Worker and serve the phone preview

**Agent:** GPT-6 / Codex
**Milestone:** 4
**Started from:** `e03b2a9` — complete milestone 4

## Goal
Deploy the existing Worker from the repository root, verify the cover route with
the owner's fake-image request, and serve the current build for real-phone checks.

## What changed
- Deployed `worker/src/index.js` through the root `wrangler.toml` to
  `https://nocturne-analytics.asherbinyy.workers.dev`, version
  `929f5eaa-54c8-433e-afec-257decbd1b12`.
- Verified `/v1/cover?src=https%3A%2F%2Fmiro.medium.com%2Ftest.jpg` with
  `Origin: https://asherbinyy.github.io`: HTTP **502**, the expected upstream
  failure confirming that the route shipped.
- Rebuilt `build/web` and started `python3 -m http.server 8000 --directory
  build/web`. The Wi-Fi preview at `http://192.168.1.120:8000/` returned **200**.
  The server remains running for the owner; tool session `19765` accepts Ctrl+C
  when the owner finishes testing.
- Closed Worker deployment issue 0b.12 and corrected the deployment directory
  in the changelog. Recorded the separate client endpoint limitation in 0b.10.

## Files touched
- `CHANGELOG.md` — modified — record the deployment and correct the root directory instruction.
- `docs/11-OPEN-ISSUES.md` — modified — close 0b.12 and retain client/browser verification under 0b.10.
- `docs/worklog/2026-09-07-04-worker-deploy-phone-preview.md` — created — deployment, verification and preview handoff.

## Decisions made
The user's request explicitly authorized deploying the existing Worker and
serving the local build. No application source, content, bindings, secrets or
analytics settings were changed; GitHub Pages was not deployed.

The requested `npx wrangler deploy` could not run under the default Node 20.
Used the already documented runtime from `worker/README.md`:
`npm exec --yes --package=node@22 --package=wrangler@4.129.0 -- wrangler deploy`.
No repository dependency was added. The sandboxed attempt also lacked DNS;
the successful deployment used approved network access and existing authentication.

The first sandboxed FVM invocation crashed in `cpuinfo_macos.cc` and stalled.
Stopped that session's process and ran the required checks successfully outside
the sandbox. The pinned SDK was unchanged.

Assumption: leave the preview server running so the owner can perform the checks
after this handoff. Physical iPhone/Android testing cannot be performed through
the available tools. Easy Go remains undecided; a question was sent to the owner,
and no portfolio content was changed without an answer.

## Tests
- Added: none.
- Modified: none.
- Full suite: pass, 583 passing, 0 failing.
- Worker suite: pass, 34 passing, 0 failing (`node --test worker/test/*.test.js`).
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass — 247 files, 0 changed
fvm flutter analyze                        pass — no issues
fvm flutter test                           pass — 583 passing, 0 failing
fvm flutter build web --wasm               pass — built build/web
```

## Known issues left open
- Real iPhone Safari and Android Chrome checks remain unperformed: address-bar
  collapse, safe areas, rotation and horizontal overflow; also the owner's
  visual review of the dark palette, portrait/Off duty and scrubber affordance.
- Python's static server has no SPA fallback. Navigate through the menu;
  directly opening `/work` returns a server 404. Production deep-link testing
  remains a separate check.
- `writingEndpointProvider` and `coverProxyProvider` derive from
  `ANALYTICS_ENDPOINT`. Both the standard local build and current CI omit that
  define, so deploying the cover route alone does not enable articles in these
  builds. The Worker also accepts only the configured production Origin.
  Enabling writing independently of analytics requires a separate change;
  analytics was not enabled to work around it.
- Easy Go issue 0b.11 still needs the owner's add/leave decision.
- The existing icon-font warning remains (issue 3.7). Tests also emitted the
  existing alchemist material-icon configuration warning and an undeclared
  `performance` tag warning; neither caused failures.

## Next
Have the owner perform the real-phone checks against the running preview and
report results; stop the server when finished. This is still the outstanding
device gate before publishing the site changes.
