# 2026-09-06-02 — Tier zero analytics Worker

**Agent:** Codex GPT-5
**Milestone:** 1
**Started from:** d35207c

## Goal
Close the Milestone 1 analytics transport gap by implementing, testing and
deploying the first-party Cloudflare Worker, then connect release builds to it
without enabling network traffic in local builds.

## What changed
- Added a Cloudflare Worker that validates the closed beacon schema, resolves
  coarse country at the edge, increments aggregate KV counters and deduplicates
  daily visitors with a rotating SHA-256 salt.
- Added daily salt rotation, hourly salt-age enforcement, optional failed-salt
  and CV-open alerts, a once-per-day Europe/London digest webhook, and an
  authenticated aggregate endpoint.
- Provisioned the production KV namespace, generated the console secret without
  printing or storing it, registered the account's `asherbinyy.workers.dev`
  subdomain, and deployed the Worker with separate midnight rotation and
  post-midnight hourly verification/digest triggers.
- Added an HTTPS-only Flutter beacon sender, consent-aware providers and route
  instrumentation. Local builds omit the endpoint and perform no analytics
  requests; the Pages release build supplies the deployed Worker endpoint.
- Implemented `/r/:campaign` as a session-scoped campaign capture followed by a
  redirect to the station. It stores only the owner-defined campaign slug in
  `sessionStorage`, never a viewer or cross-session identifier.
- Added Worker tests to CI. A live check returned 204 for the permitted CORS
  preflight, 202 for a valid beacon and 401 for an unauthenticated aggregate
  read. Its synthetic counter and visitor marker were removed afterward.

## Files touched
- `.github/workflows/ci.yml` — modified — run Worker tests and configure the
  production beacon endpoint for the Pages build.
- `.gitignore` — modified — exclude Wrangler state and local secret files.
- `wrangler.toml` — created — Worker, KV, cron, privacy and production routing
  configuration.
- `worker/package.json` — created — dependency-free Node test entry point.
- `worker/README.md` — created — deployment and privacy-boundary runbook.
- `worker/src/index.js` — created — Worker request, aggregation, salt and
  schedule handlers.
- `worker/test/index.test.js` — created — twelve Worker privacy and behavior
  tests.
- `lib/core/analytics/analytics_providers.dart` — created — consent and
  compile-time endpoint wiring.
- `lib/core/analytics/analytics_route_view.dart` — created — one route-view
  attempt per routed page.
- `lib/core/analytics/beacon_sender.dart` — created — compact first-party HTTP
  transport.
- `lib/core/analytics/browser_analytics_context.dart` — created — conditional
  campaign and referrer boundary.
- `lib/core/analytics/browser_analytics_context_stub.dart` — created — VM-safe
  browser-context fallback.
- `lib/core/analytics/browser_analytics_context_web.dart` — created — browser
  campaign storage and referrer-host extraction.
- `lib/app/app_route.dart` — modified — document the campaign entry behavior.
- `lib/app/router.dart` — modified — capture campaign entries, redirect them and
  wrap pages in route instrumentation.
- `test/unit/core/analytics/beacon_sender_test.dart` — created — endpoint,
  schema and failure tests.
- `test/widget/analytics_route_view_test.dart` — created — app integration,
  capability and refusal tests.
- `test/widget_test.dart` — modified — assert the campaign redirect.
- `docs/worklog/2026-09-06-02-tier-zero-worker.md` — created — this record.

## Decisions made
The account-wide Workers subdomain is `asherbinyy`, matching the published
GitHub Pages account name. Preview URLs and Wrangler telemetry are disabled.

The active salt occupies one fixed KV key. Rotation overwrites that key, so the
old value is destroyed rather than retained alongside the new one. Visitor
markers expire after two days and counters after 24 calendar months.

The endpoint is injected with `ANALYTICS_ENDPOINT` only in the production Pages
build. This makes an absent or invalid endpoint a true no-op and keeps tests and
ordinary local runs from reaching production.

Wrangler 4.60.0 was used because the newest release requires Node 22 while this
machine has Node 20.2. Its dry run and both deployments validated the bundle;
the first publish attempt also showed that Cloudflare's UTC control plane would
not yet accept a 2026-09-06 compatibility date, so the config uses 2026-09-05.

## Tests
- Added: 12 Worker tests, 4 beacon sender tests, 3 route-view widget tests and 1
  campaign redirect test.
- Modified: `test/widget_test.dart`.
- Full suite: pass, 390 non-golden and 36 golden tests passing, 0 failing.
- Coverage delta: 92.82% to 92.64% (3284/3545 lines).

## Verification run
```
fvm dart format --set-exit-if-changed .            pass (192 files, 0 changed)
fvm flutter analyze --fatal-infos                   pass (no issues found)
fvm flutter test --coverage --exclude-tags golden   pass (390 passing)
fvm flutter test --tags golden                      pass (36 passing)
fvm flutter build web --wasm                        pass (built build/web)
```

Additional verification: `node --test worker/test/*.test.js` passed 12 tests;
the deployed Worker passed its live CORS, beacon and auth checks.

## Known issues left open
- `ALERT_WEBHOOK_URL` and `DIGEST_WEBHOOK_URL` are not configured because the
  repository contains no owner-supplied notification or n8n endpoints. Salt
  rotation still recovers automatically; optional alerts and digest delivery
  remain dormant until those secrets exist.
- The session-over-90-seconds alert depends on Tier 1 dwell-time events, which
  are Milestone 2 work. The Worker currently handles the Milestone 1 CV-open
  alert path when an alert webhook is configured.
- The Worker is live, but the Pages site is still built from `main`, so the
  Flutter sender will not go live until this phase branch is reviewed and
  merged.

## Next
Address the remaining Milestone 1 acquisition, propagation-map and trace
fidelity gaps before preparing the phase branch for its real-device review and
merge.
