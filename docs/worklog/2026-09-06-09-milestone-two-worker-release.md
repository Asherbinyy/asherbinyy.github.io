# 2026-09-06-09 — Deploy the Milestone 2 Worker

**Agent:** Codex / GPT-6
**Milestone:** 2
**Started from:** fdf851d27d927bc852372a2c7d29b8c807aa6d70

## Goal
Continue Claude's Milestone 2 handoff by deploying the matching analytics Worker and verifying the production writing relay and backend boundary. Reconcile the release documentation without changing the published Flutter client.

## What changed
- Confirmed main and tag `v0.2.0` point at the PR #3 compatibility fix, `fdf851d`. GitHub Actions run 34046808863 passed; the preceding Milestone 2 release run 34046131989 also passed.
- Ran Wrangler 4.129.0 using an isolated Node 22.23.2 npm runtime, leaving the machine's default Node 20.2.0 unchanged.
- Tested and dry-ran the existing Worker source, then deployed it as version `d106e172-4182-4fdb-82f4-b0930f2a4ad0` at 2026-09-06T17:13:36.192Z. The previous deployed version was `fa218355-3c1d-4be6-bee7-d821fe7ab4c8` from September 5.
- Preserved the production KV binding, existing `CONSOLE_TOKEN` secret, site origin, and both cron schedules. No secret was rotated and no application or Worker source was changed.
- Verified `/v1/writing` changed from 404 to 200 and returns parseable RSS with six articles. Missing Origin returns 403. An unauthenticated `/v1/aggregates` request returns 401.
- Opened the live `/writing` route in isolated Chrome at 1200×900 with beacon URLs blocked before navigation. Visually confirmed all six articles and the bundled fonts; the relay also returned `x-nocturne-cache: hit` on a subsequent request.
- Added the tested Node 22 deployment invocation and a release-verification procedure to the Worker README, including the fact that Pages CI does not deploy the Worker.
- Updated the issue register to close the deployed-version mismatch and retain the remaining positive production verification as 3b.3. Removed stale rows claiming `/about` and `/how-it-was-built` are unbuilt; both were completed in worklog 08.
- Corrected the changelog's stale Unreleased wording: Milestone 2 is already published and tagged, with its Worker deployed separately.

## Files touched
- `worker/README.md` — modified — records the verified isolated runtime command and Worker release checks.
- `docs/11-OPEN-ISSUES.md` — modified — records the deployed backend and the precise remaining production verification limits.
- `CHANGELOG.md` — modified — marks the existing 0.2.0 release as published and records the client compatibility fix and Worker deployment.
- `docs/worklog/2026-09-06-09-milestone-two-worker-release.md` — created — records deployment identity, verification and remaining work.

## Decisions made
The handoff was a deployment mismatch, so the already-tested Worker source at the published client revision was deployed without application changes. Using npm's isolated Node 22 runtime solves the tool requirement without a global Node upgrade or a new project dependency. Existing secrets and the KV namespace were preserved.

The production probe used read-only endpoint checks and the writing relay's normal cache path. A proposed synthetic Tier 1 event on a unique test-only route, followed by deletion of only its two test KV records, was rejected by automatic approval review for lacking specific authorization for consent and production cleanup. The rejected command did not run. Explicit authorization was requested; no positive production Tier 1 or authenticated console result is claimed while that request is pending. The console secret's presence was checked by name only; its value was neither retrieved nor exposed.

The repair records live on `fix/analytics-worker-release`, branched from published main. No main merge, new tag, Pages publish or Milestone 3 work was performed.

## Tests
- Added: none — deployment and documentation repair only.
- Modified: none.
- Full suite: pass, 538 passing, 0 failing. Separate suites: 502 non-golden and 36 golden passing. Worker: 26 passing, 0 failing under Node 22.
- Coverage delta: 90.89% (4502/4953 lines), compared with worklog 08's 90.88%; no application source changed in this session.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (244 files, 0 changed)
fvm flutter analyze                        pass (no issues; run with --fatal-infos)
fvm flutter test                           pass (538 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

Also passed:
- `fvm flutter test --coverage --exclude-tags golden --reporter expanded`: 502 tests.
- `fvm flutter test --tags golden --reporter expanded`: 36 tests, no regeneration.
- `npm exec --yes --package=node@22 -- node --test worker/test/*.test.js`: 26 tests.
- Wrangler dry run: 14.39 KiB upload, 4.51 KiB gzip, expected production bindings.
- Wrangler deploy and version inspection: fetch and scheduled handlers, configured writing feed, existing console secret, expected compatibility date and schedules.
- Live writing relay: 200, valid RSS, six articles; missing-Origin writing request: 403; unauthenticated aggregates: 401.

Python urllib initially received Cloudflare's edge-level 1010 rejection before reaching the Worker. The ordinary curl client reached the Worker and produced the application responses above. This was a probe-client difference, not an application error or a change to Cloudflare security settings.

## Known issues left open
- Positive live Tier 1 acceptance and authenticated console reads remain unverified, as recorded in issue 3b.3. Local Tier 1 and aggregate-shape tests pass. No synthetic beacon was sent and no production analytics record was deleted in this session.
- The real-phone check is still unperformed across both releases. The content, assets and digest-account gaps remain in the standing issue register.
- The existing missing Material/Cupertino icon-font build warning remains.
- The writing-page browser check returned an empty `document.title` after the app rendered. This is separate from the Worker deployment and remains to be investigated; the visible route and article content rendered correctly.
- The Worker and Pages still deploy independently. The README now makes the required Worker release step explicit; no new automatic production deployment workflow or secret was introduced.

## Next
Complete an explicitly consented live Tier 1 session and authenticated console check, then perform the real-phone acceptance pass before starting Milestone 3.
