# 2026-09-25-01 — Dashboard analytics

**Agent:** Codex
**Milestone:** 6
**Started from:** `8d1fc02260e48896d194dee67101a84aa5f14a0f`

## Goal
Replace the sparse admin insights page with a useful, restrained analytics
dashboard and connect every supported public surface to an explicit-consent,
privacy-bounded collection pipeline. Document enough of the implementation and
release process for a different engineer or AI to operate it safely.

## What changed
- Replaced the admin home with Overview, Links & apps, Pages and Audience
  reports. Added observed daily graphs, exact stored counts, previous-period
  comparisons, stable targets and redacted public destinations, source pages,
  engagement, audience breakdowns, search, sorting and formula-safe CSV.
- Replaced the old three-tier analytics state with one explicit choice:
  unresolved and rejected visitors send nothing; a visitor who chooses **Allow
  analytics** enables both page and interaction events. The new storage-key
  version asks holders of the older, narrower grant again while preserving old
  rejections.
- Added a single outbound-link wrapper and attached stable targets to apps,
  articles, contacts, bookings, CV actions, gallery/media opens, name audio,
  journey stops, case studies, language/theme changes and the ascent game.
- Added active foreground time and deepest scroll quartile per route. Admin
  previews and `/console` are excluded, and all send failures remain invisible
  to public navigation.
- Added equivalent consent, route, link and engagement measurement to the
  standalone HTML CV and brief. The static script is emitted only in a build
  with a valid HTTPS analytics endpoint and exits when framed.
- Added `AnalyticsStore`, one SQLite-backed Durable Object using atomic
  aggregate updates, a daily salted visitor estimate, 120-beacon-per-minute
  abuse control and alarms for two-day short-lived hashes and 24-month
  aggregate retention. Raw request addresses and browser headers are discarded
  after hashing and never become dimensions.
- Kept historical KV counters readable, while all new events use the Durable
  Object. Added report arithmetic for links, pages, actions, audience and
  equal-length prior periods without summing daily unique estimates.
- Enabled the consented client in the Pages workflow and declared the
  `ANALYTICS_STORE` binding plus `v3-analytics-store` migration. The Worker must
  deploy before the Pages build.
- Rewrote the binding privacy contract and added
  `docs/32-ANALYTICS-DASHBOARD-RUNBOOK.md` as the implementation, testing,
  release, authentication and failure-recovery handoff.
- Used only in-memory/local data for test fixtures. No synthetic production
  beacon was sent and no owner content or content schema was changed.

## Files touched
- `.github/workflows/ci.yml` — modified — supply the analytics endpoint to the
  production Flutter and static-route builds.
- `CHANGELOG.md` — modified — record the analytics release.
- `docs/05-TESTING.md` — modified — align the privacy checks with explicit
  consent and transient request hashing.
- `docs/06-ANALYTICS-AND-PRIVACY.md` — modified — replace the obsolete tier
  design with the binding opt-in contract.
- `docs/11-OPEN-ISSUES.md` — modified — close the disabled-analytics state and
  retain the real consented-production-visit check.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — update the admin release state and
  A6 dashboard description.
- `docs/31-CODEX-ADMIN-UI-REVIEW.md` — modified — record the delivered report
  coverage and its historical-data limit.
- `docs/32-ANALYTICS-DASHBOARD-RUNBOOK.md` — created — complete technical and
  operational handoff.
- `lib/app/chrome/app_footer.dart` — modified — expose reversible consent
  settings.
- `lib/app/chrome/app_header.dart` — modified — name language and theme actions.
- `lib/app/chrome/chrome_scaffold.dart` — modified — host consent and route
  engagement on public chrome.
- `lib/app/l10n/app_ar.arb` — modified — add Arabic consent copy.
- `lib/app/l10n/app_en.arb` — modified — add English consent copy.
- `lib/app/router.dart` — modified — keep public route measurement and campaign
  attribution out of previews.
- `lib/core/analytics/analytics_client.dart` — modified — enforce the new grant
  and carry target/destination fields.
- `lib/core/analytics/analytics_consent.dart` — created — accessible first-use
  and settings controls plus the detailed notice.
- `lib/core/analytics/analytics_providers.dart` — modified — expose collection
  state from the configured transport.
- `lib/core/analytics/analytics_route_view.dart` — modified — record the current
  route when consent is granted after page load.
- `lib/core/analytics/beacon_sender.dart` — modified — send the explicit grant
  marker and report dimensions.
- `lib/core/analytics/browser_analytics_context.dart` — modified — bound campaign
  length and expose session clearing.
- `lib/core/analytics/browser_analytics_context_stub.dart` — modified — support
  session clearing in VM tests.
- `lib/core/analytics/browser_analytics_context_web.dart` — modified — use
  memory-safe campaign/session fallbacks and clear them on withdrawal.
- `lib/core/analytics/consent.dart` — modified — reduce consent to unresolved,
  rejected or granted.
- `lib/core/analytics/consent_controller.dart` — modified — version the wider
  grant and preserve old rejections.
- `lib/core/analytics/engagement_reporter.dart` — modified — measure visible
  active seconds and deepest quartile from the real chrome scroll controller.
- `lib/core/analytics/events.dart` — modified — add link, media, audio and game
  events plus stable report dimensions.
- `lib/core/analytics/interactions.dart` — modified — carry item and destination
  through the common consent gate.
- `lib/core/analytics/tracked_link.dart` — created — redact destinations and
  record outbound activation without blocking launch.
- `lib/core/platform/preference_store.dart` — modified — use the version-two
  consent key.
- `lib/core/widgets/content_gallery.dart` — modified — name gallery and external
  media actions.
- `lib/features/about/presentation/widgets/contact_links.dart` — modified — use
  redacted tracked contact links.
- `lib/features/about/presentation/widgets/interests_grid.dart` — modified —
  give interest galleries stable targets.
- `lib/features/courtyard/game/presentation/ascent_stage.dart` — modified —
  record actual game start and finish points.
- `lib/features/recruiter/presentation/recruiter_view.dart` — modified — route
  recruiter contact actions through the link wrapper.
- `lib/features/services/presentation/services_screen.dart` — modified — track
  booking and contact activations.
- `lib/features/signal/presentation/signal_screen.dart` — modified — identify the
  selected journey stop.
- `lib/features/station/presentation/widgets/cv_button.dart` — modified — attach
  the public CV destination.
- `lib/features/station/presentation/widgets/name_pronunciation.dart` — modified
  — record only after audio begins.
- `lib/features/work/presentation/case_study_screen.dart` — modified — report the
  actual case-study route.
- `lib/features/work/presentation/widgets/ledger_row.dart` — modified — use the
  shared tracked-link path.
- `lib/features/work/presentation/widgets/store_links.dart` — modified — name
  each app/store target.
- `lib/features/work/presentation/widgets/work_card.dart` — modified — identify
  case-study actions.
- `lib/features/writing/presentation/widgets/article_card.dart` — modified —
  name and redact article destinations.
- `test/unit/core/analytics/beacon_sender_test.dart` — modified — verify the new
  wire contract.
- `test/unit/core/analytics/privacy_test.dart` — modified — verify the strict
  consent model and version migration.
- `test/unit/core/analytics/tier_one_test.dart` — modified — align session-event
  checks with the explicit grant.
- `test/unit/core/analytics/tracked_link_test.dart` — created — cover destination
  redaction.
- `test/unit/tool/generate_static_test.dart` — modified — verify production-only
  static analytics inclusion and clean restoration.
- `test/widget/analytics_consent_test.dart` — created — verify equal actions and
  short-screen layout.
- `test/widget/analytics_route_view_test.dart` — modified — verify post-load
  consent, fast routes and exclusions.
- `tool/generate_static.dart` — modified — inject the shared static client only
  for a valid HTTPS endpoint.
- `web/static-analytics.js` — created — consented analytics parity for CV and
  brief.
- `worker/README.md` — modified — update binding, retention and release
  operations.
- `worker/dev/durable-double.js` — modified — model list pagination, alarms and
  object access for tests.
- `worker/dev/serve.js` — modified — opt into the in-memory analytics object for
  local dashboard verification.
- `worker/dev/verify-analytics-dashboard.js` — created — seed local aggregates
  and exercise all four reports in headless Chrome.
- `worker/src/admin/client-app.js` — modified — install the dashboard renderer.
- `worker/src/admin/client-charts.js` — modified — retain exact accessible data
  beside graphs.
- `worker/src/admin/client-dashboard.js` — created — implement reports,
  controls, tables, comparisons and CSV.
- `worker/src/admin/client-home.js` — modified — replace the old home dashboard.
- `worker/src/admin/styles.js` — modified — add restrained responsive report
  layout and phone-safe tabs.
- `worker/src/analytics-report.js` — created — derive the dashboard without
  estimates or fake points.
- `worker/src/analytics-store.js` — created — atomic Durable Object storage,
  daily unique estimate, rate limit and retention.
- `worker/src/index.js` — modified — validate/store the expanded consented event
  contract and serve the new report.
- `worker/src/insights.js` — modified — normalise embedded separators while
  retaining historical KV arithmetic.
- `worker/test/analytics-store.test.js` — created — cover concurrency, rollback,
  redaction, reporting, pagination, consent, limits and retention.
- `worker/test/index.test.js` — modified — align endpoint fixtures with the new
  grant requirement.
- `wrangler.toml` — modified — enable collection and declare the analytics
  Durable Object migration.

## Decisions made
- A single explicit grant covers the named scope. There is no hidden
  cookieless tier and no pre-consent queue.
- Click means activation only. The dashboard says it does not prove an install,
  download, booking, message or other downstream conversion.
- Destination identity is useful only after removing credentials, fragments and
  queries; the sole query exception is a public Google Play application ID.
- Daily visitor hashes are used only for one-day estimates and abuse control.
  They are never exposed as a cross-day person count.
- New aggregate writes use one named Durable Object so increments and daily
  uniqueness are strongly consistent. Historical KV data stays readable; it
  is not rewritten or guessed into the richer schema.
- Missing graph dates remain missing. Empty ranges, disabled collection and
  read failures have separate states.
- Production verification will use a real owner-consented visit after release;
  synthetic production events would permanently contaminate the report.
- No package, route, Flutter version, owner claim or content document changed.

## Tests
- Added: `tracked_link_test.dart`, `analytics_consent_test.dart`,
  `analytics-store.test.js`, and the 14-check local Chrome dashboard verifier.
- Modified: beacon sender, privacy, consent/session, static generator, route
  view and Worker endpoint tests.
- Full suite: pass, 860 Flutter tests and 340 Worker tests; 0 failing, 0 skipped.
- Coverage delta: not measured locally; CI retains the existing 80% line gate.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass; 361 files, 0 changed
fvm flutter analyze                        pass; no issues
fvm flutter test                           pass; 860 tests
fvm flutter build web --wasm               pass; build/web produced
```

Additional verification:
- `node --test worker/test/*.test.js` — pass; 340 tests.
- `node worker/dev/verify-analytics-dashboard.js` against the local in-memory
  harness — pass; 14 browser checks and no JavaScript errors.
- Wrangler 4.139 local runtime — pass; SQLite Durable Object accepted a
  consented beacon with 202 and exact-origin preflight returned 204 with the
  expected allow-origin header.
- Wrangler bundle dry run — pass; `ANALYTICS_STORE` and all existing bindings
  resolved.
- `git diff --check` and JavaScript syntax checks — pass.

## Known issues left open
- A real physical-phone and screen-reader pass remains owner verification.
- The positive production analytics check waits for one real, owner-consented
  public visit after the coordinated Worker and Pages release.
- Older counters cannot acquire link destinations or targets retroactively.
- Exit-time engagement is best effort because a browser may terminate a
  keepalive request.

## Next
Deploy the tested Worker revision first, merge the branch so Pages enables the
client against that contract, then verify deployment health without inserting a
synthetic production event.
