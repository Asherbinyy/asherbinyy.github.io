# 2026-09-25-02 — Default cookieless analytics

**Agent:** Codex
**Milestone:** 6
**Started from:** `72b7fc283800bae527d0fe92913436043455859d`

## Goal
Remove the public analytics consent panel and enable the existing bounded,
first-party analytics automatically without adding cookies or a browser
identifier. Keep the dashboard, storage guarantees and preview exclusions
intact, then release the compatible Worker before the public client.

## What changed
- Removed the first-visit consent panel, its footer settings control, all
  consent copy and the stored analytics decision.
- Removed the random tab identifier and every analytics read or write to
  `localStorage` and `sessionStorage`. Theme, language, recruiter mode and
  voluntary game participation remain separate functional preferences.
- Made configured Flutter, CV and brief clients record route views,
  interactions and bounded engagement immediately. Builds without an endpoint,
  admin previews and `/console` remain silent.
- Changed the public beacon payload to omit `consent` and `sessionId`. The
  Worker accepts the new shape and temporarily accepts the old granted shape so
  the Worker-first rollout does not reject visitors on the previous Pages
  artifact.
- Updated the admin's status, chart and explanatory copy to describe recorded
  cookieless activity without referring to consent or rejected visitors.
- Rewrote the active privacy, testing, admin and operations documentation so a
  future engineer or AI has the exact event, storage, retention, release and
  rollback contract.
- Deployed Worker version `4f61c52c-bc8f-498a-b7db-03e9031ee50e` before the
  public client. The live Worker returned the exact `https://sherbini.uk` CORS
  origin and served the updated dashboard bundle.

## Files touched
- `.github/workflows/ci.yml` — modified — describe the production analytics
  build as default-on and cookieless.
- `CHANGELOG.md` — modified — record the prompt removal and client contract.
- `docs/04-FLUTTER-STANDARDS.md` — modified — remove the deleted consent enum
  from coding examples.
- `docs/05-TESTING.md` — modified — replace consent-transition checks with
  default startup, no-storage and preview-exclusion checks.
- `docs/06-ANALYTICS-AND-PRIVACY.md` — modified — define the binding default-on
  cookieless collection contract.
- `docs/11-OPEN-ISSUES.md` — modified — update the production verification
  state.
- `docs/15-ADMIN-AND-MEDIA.md` — modified — align the admin description with
  default collection.
- `docs/31-CODEX-ADMIN-UI-REVIEW.md` — modified — record the new dashboard data
  boundary.
- `docs/32-ANALYTICS-DASHBOARD-RUNBOOK.md` — modified — document the new client
  flow, source map, release checks and limitations.
- `lib/app/chrome/app_footer.dart` — modified — remove the consent settings
  button and dialog.
- `lib/app/chrome/chrome_scaffold.dart` — modified — remove the consent overlay.
- `lib/app/l10n/app_ar.arb` — modified — remove unused Arabic consent copy.
- `lib/app/l10n/app_en.arb` — modified — remove unused English consent copy.
- `lib/core/analytics/analytics_client.dart` — modified — send configured
  events without a decision tier or tab identifier.
- `lib/core/analytics/analytics_consent.dart` — deleted — remove the public
  consent interface.
- `lib/core/analytics/analytics_providers.dart` — modified — create the client
  directly from a configured transport.
- `lib/core/analytics/analytics_route_view.dart` — modified — record the first
  public route immediately.
- `lib/core/analytics/beacon_sender.dart` — modified — omit consent and session
  fields from the wire payload.
- `lib/core/analytics/browser_analytics_context.dart` — modified — remove tab
  identifier creation and clearing.
- `lib/core/analytics/browser_analytics_context_stub.dart` — modified — remove
  obsolete storage hooks.
- `lib/core/analytics/browser_analytics_context_web.dart` — modified — retain
  only in-memory campaign attribution and referrer-host parsing.
- `lib/core/analytics/consent.dart` — deleted — remove the obsolete tier model.
- `lib/core/analytics/consent_controller.dart` — deleted — remove the stored
  decision controller.
- `lib/core/analytics/engagement_reporter.dart` — modified — measure configured
  public routes from load while retaining foreground and bounds checks.
- `lib/core/analytics/events.dart` — modified — remove the session identifier
  from the closed beacon type.
- `lib/core/analytics/interactions.dart` — modified — depend only on transport
  availability.
- `lib/core/analytics/tracked_link.dart` — modified — record configured public
  link activations without a decision tier.
- `lib/core/platform/preference_store.dart` — modified — remove the analytics
  decision from the closed preference-key set.
- `test/unit/app/theme/theme_controller_test.dart` — modified — align preference
  expectations with the remaining functional choices.
- `test/unit/core/analytics/analytics_client_test.dart` — created — verify
  immediate events, bounded values and surfaced transport failures.
- `test/unit/core/analytics/beacon_sender_test.dart` — modified — verify the new
  wire shape.
- `test/unit/core/analytics/privacy_test.dart` — modified — verify immediate
  collection and the absence of an analytics preference or sensitive fields.
- `test/unit/core/analytics/tier_one_test.dart` — deleted — remove obsolete
  consent and session-tier tests.
- `test/unit/tool/generate_static_test.dart` — modified — verify the static
  client has no consent UI or browser-storage access.
- `test/widget/analytics_consent_test.dart` — deleted — remove tests for the
  deleted prompt.
- `test/widget/analytics_route_view_test.dart` — modified — verify immediate
  configured startup and absent-endpoint behavior.
- `test/widget/station/station_test.dart` — modified — remove obsolete prompt
  setup notes.
- `tool/generate_static.dart` — modified — remove consent-panel styles from the
  generated CV and brief.
- `web/static-analytics.js` — modified — start immediately and remove the
  choice panel and browser storage.
- `worker/README.md` — modified — document the cookieless default behavior.
- `worker/dev/verify-analytics-dashboard.js` — modified — exercise beacons
  without a consent field.
- `worker/src/admin/client-charts.js` — modified — remove consent wording from
  empty charts.
- `worker/src/admin/client-dashboard.js` — modified — use factual activity and
  cookieless reporting copy.
- `worker/src/index.js` — modified — accept the new beacon shape and report the
  actual collection configuration.
- `worker/test/analytics-store.test.js` — modified — verify storage and public
  reporting without a consent field.

## Decisions made
- Default collection remains first party and aggregate. Removing the prompt did
  not broaden the event list, add a cookie, add a browser identifier, create an
  event log or change retention.
- The old `consent: granted` and interaction `sessionId` fields remain accepted
  only as a rollout compatibility surface. New clients emit neither and the
  analytics store persists neither.
- The Worker deployed before Pages so the prior consented client and the new
  cookieless client can both operate throughout the release window.
- No package, route, content document, schema, owner claim or design token
  changed.

## Tests
- Added: `analytics_client_test.dart`.
- Modified: analytics sender, privacy, static generation, route-view, theme,
  station and Worker storage/dashboard tests; removed tests for deleted consent
  and tier behavior.
- Full suite: pass, 841 Flutter tests and 340 Worker tests; 0 failing, 0 skipped.
- Coverage delta: not measured locally; CI retains the existing 80% line gate.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass; 356 files, 0 changed
fvm flutter analyze                        pass; no issues
fvm flutter test                           pass; 841 tests
fvm flutter build web --wasm               pass; build/web produced
```

Additional verification:
- `node --test worker/test/*.test.js` — pass; 340 tests.
- Local dashboard browser verification — pass; 14 checks and no JavaScript
  errors.
- Wrangler local runtime — pass; a valid beacon with no consent field returned
  202 and `Access-Control-Allow-Origin: https://sherbini.uk`.
- Live Worker — pass; version `4f61c52c-bc8f-498a-b7db-03e9031ee50e`, exact
  site-origin preflight returned 204 and the updated admin bundle returned 200.
- `git diff --check` — pass.

## Known issues left open
- Historical counters cannot acquire link destinations or targets
  retroactively.
- Exit-time engagement remains best effort because a browser may terminate an
  outgoing keepalive request.
- A physical-phone and screen-reader pass remains owner verification.

## Next
After the Pages deployment completes, open the public site normally and confirm
the first real route view appears in Overview and Pages, then complete the
physical-phone and screen-reader pass without seeding production data.
