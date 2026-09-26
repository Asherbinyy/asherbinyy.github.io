# 2026-09-26-01 — Admin analytics redesign

**Agent:** Codex (GPT-6)
**Milestone:** 6
**Started from:** `6ce841e51f6216ad6aff13c34551744cebeb0889`

## Goal
Replace the weak admin analytics presentation with a clean, responsive and
more informative dashboard, add honest Today/month/year ranges, and improve
reporting without creating an event log or inventing visitor figures.

## What changed
- Rebuilt Overview, Links & apps, Pages and Audience around compact controls,
  four range KPIs, a combined views/clicks graph, ranked performance, factual
  highlights, exact sortable tables and report-specific CSV.
- Added Today, 7-day, 30-day, 3-month, 12-month, 2-year and custom UTC ranges.
  The report chooses hourly, daily or monthly buckets and never fills missing
  periods with invented zeroes.
- Added a two-digit UTC-hour aggregate dimension to new Durable Object counter
  rows. Historical rows stay in all exact totals and are visibly excluded only
  from an hourly plot they cannot support.
- Added click and view shares, page interaction counts, CV comparison, busiest
  day, leading page/link/country and active-day facts calculated directly from
  stored aggregates.
- Added a local country choropleth and exact country table. Geometry is a
  generated 1:110m equirectangular projection of public-domain Natural Earth
  data; the upstream revision and source checksum are recorded in the module.
  The admin makes no map-tile or third-party request.
- Extended the authenticated report range from one year to the existing
  two-calendar-year aggregate retention boundary.
- Deployed Worker version `e5efb35a-2098-45ea-bbb7-da9702813440`. The live
  admin returned the redesigned bundle with no-store/noindex headers, and the
  production-origin beacon preflight returned the exact `https://sherbini.uk`
  allow-origin header.
- Installed no plugin or package. The existing repository browser driver,
  Worker runtime and test tooling covered the work without another dependency.

## Files touched
- `CHANGELOG.md` — modified — record the redesigned dashboard and hourly aggregate.
- `docs/06-ANALYTICS-AND-PRIVACY.md` — modified — bind the UTC-hour dimension and reporting rules.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — update A6 and the production release state.
- `docs/32-ANALYTICS-DASHBOARD-RUNBOOK.md` — modified — document ranges, charts, map source and operations.
- `worker/README.md` — modified — update the deployed analytics/store summary.
- `worker/dev/verify-analytics-dashboard.js` — modified — cover Today, two years, factual insights, the map, CSV and responsive layout.
- `worker/src/admin/client-charts.js` — modified — add dual-series, ranked, exact-value and country-map visualizations.
- `worker/src/admin/client-dashboard.js` — modified — replace the analytics information architecture and report layouts.
- `worker/src/admin/client-home.js` — modified — add the clean range presets and calendar-year arithmetic.
- `worker/src/admin/client-state.js` — modified — make 30 days the default range.
- `worker/src/admin/styles.js` — modified — implement the responsive dashboard visual system.
- `worker/src/admin/world-map-data.js` — created — bundle pinned public-domain Natural Earth country geometry.
- `worker/src/analytics-report.js` — modified — add adaptive time buckets, shares, comparisons and factual highlights.
- `worker/src/analytics-store.js` — modified — append the aggregate UTC hour to new counter keys.
- `worker/src/index.js` — modified — align the report limit with 24-month retention.
- `worker/test/admin-insights.test.js` — modified — cover the two-calendar-year boundary.
- `worker/test/admin-ui.test.js` — modified — cover Today, missing chart periods and local map integrity.
- `worker/test/analytics-store.test.js` — modified — cover hourly compatibility and monthly grouping.

## Decisions made
- Today receives hourly detail only from the deployment onward. Historical
  daily rows were not guessed into hours or rewritten.
- Long ranges group observed counters by month. Daily unique estimates remain
  daily and are never added into a monthly people total.
- Range highlights state arithmetic facts instead of recommendations or
  inferred causes. Clicks remain activations and are not called conversions.
- The map uses the existing limestone chart palette. Gold remains reserved for
  controls and selected state; no new pigment was introduced.
- Natural Earth geometry is bundled because runtime map requests would weaken
  the admin CSP and add an unnecessary external dependency.

## Tests
- Added: hourly legacy-compatibility, monthly grouping, two-year range and map-integrity coverage.
- Modified: admin chart assertions and the local Chrome dashboard verifier.
- Full suite: pass, 841 Flutter tests and 344 Worker tests; 0 failing, 0 skipped.
- Coverage delta: not measured locally; CI retains the existing coverage gate.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass; 356 files, 0 changed
fvm flutter analyze                        pass; no issues
fvm flutter test                           pass; 841 tests
fvm flutter build web --wasm               pass; build/web produced
```

Additional verification:
- `node --test worker/test/*.test.js` — pass; 344 tests.
- Local Chrome dashboard verifier — pass; 19 checks, desktop and 390 px phone,
  with no JavaScript errors or horizontal overflow.
- Wrangler 4.129 dry run — pass; 472.54 KiB upload, 134.39 KiB gzip.
- Production deploy — pass; version `e5efb35a-2098-45ea-bbb7-da9702813440`,
  472.75 KiB upload and 2 ms startup.
- Live admin — HTTP 200, `no-store`, `noindex`, redesigned bundle present.
- Production CORS — HTTP 204 with exact `Access-Control-Allow-Origin:
  https://sherbini.uk`; no synthetic production beacon was sent.
- `git diff --check` — pass.

## Known issues left open
- Records written before this release have no hour. They remain in totals but
  cannot appear on the Today hourly graph.
- Natural Earth 1:110m omits some tiny territories from the drawn geometry;
  every received country code remains available in the exact table and CSV.
- A physical-phone and screen-reader pass remains owner verification.

## Next
Sign in after ordinary portfolio traffic arrives and compare Today, 30 days and
12 months on the owner's phone; this confirms the first naturally collected
hourly bucket without contaminating production analytics.
