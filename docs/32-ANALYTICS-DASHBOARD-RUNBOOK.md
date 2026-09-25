# Analytics dashboard runbook

This is the implementation and operations handoff for the portfolio analytics
and its admin dashboard. It lets another engineer or AI diagnose, test and
release the system without reconstructing its design from commits.

## User-visible result

The admin home has four reports:

| Report | Contents |
|---|---|
| Overview | Page views, link clicks, CV opens, clicks per 100 views, previous-period comparisons, a daily traffic graph, top links and top pages |
| Links & apps | Public destination, stable target, type, click count, source pages, app detail views and other interactions |
| Pages | Views, outbound clicks, mean active seconds and mean scroll quartile by route |
| Audience | Daily unique estimates, referrer hosts, countries, input devices and campaigns; every share is based on page views |

Ranges are 7, 28 or 90 days, or a custom UTC range up to 366 days. Tables are
searchable and sortable. Each report exports its own CSV. CSV cells are quoted
and spreadsheet formulas are neutralised.

The interface uses the portfolio's type, rules and spacing. It has real empty,
loading, retry and disabled states. Publication status is kept in a disclosure
below analytics rather than competing with the report.

## End-to-end flow

```text
Visitor grants consent
        |
Flutter route/actions or static CV/brief
        |
POST /v1/beacon (exact sherbini.uk Origin)
        |
Worker validates the closed event schema and redacts destination
        |
AnalyticsStore Durable Object transaction
        |
Atomic aggregate row + numeric total + daily unique estimate
        |
Authenticated GET /v1/admin/insights
        |
Report arithmetic -> Overview / Links / Pages / Audience / CSV
```

No action before the consent grant enters this flow.

## Source map

### Public Flutter client

- `lib/core/analytics/analytics_consent.dart` — first-choice and footer settings
  controls plus the detailed notice.
- `consent_controller.dart`, `consent.dart` — versioned stored decision and
  effective tier.
- `analytics_route_view.dart` — one page view for the current route after a
  grant, including a grant made while the page is open.
- `tracked_link.dart` — common outbound click wrapper and destination
  redaction.
- `engagement_reporter.dart` — foreground active seconds and deepest quartile.
- `browser_analytics_context_web.dart` — in-memory campaign and tab-only ID.
- `events.dart`, `beacon_sender.dart`, `analytics_client.dart` — closed event
  type, wire format and final consent gate.
- Widget call sites under `features/` and `core/widgets/content_gallery.dart`
  name apps, articles, booking, contact, media, audio, CV and game actions.

### Static CV and brief

- `tool/generate_static.dart` adds the analytics script only when the build has
  a valid HTTPS `ANALYTICS_ENDPOINT`.
- `web/static-analytics.js` implements the same choice key, exclusions, route
  view, outbound click and engagement measurements. It exits immediately when
  framed, so the admin preview is excluded.

### Worker

- `worker/src/index.js` owns routes, CORS, authentication and strict beacon
  validation.
- `worker/src/analytics-store.js` is the SQLite-backed Durable Object. One
  named object (`portfolio`) serialises counter updates and runs retention.
- `worker/src/analytics-report.js` derives comparisons, trends, link and page
  tables, audience breakdowns and explicitly named ratios.
- `worker/src/insights.js` contains older aggregate arithmetic retained for
  historical KV compatibility.
- `worker/src/admin/client-dashboard.js` renders the four reports and CSV.
- `worker/src/admin/client-charts.js` draws observed series and always includes
  an exact accessible table.
- `wrangler.toml` binds `ANALYTICS_STORE`, enables collection and declares the
  `v3-analytics-store` migration.

## Event dictionary

| Event | Trigger | Extra data |
|---|---|---|
| `route_view` | Consented public route becomes current | none |
| `outbound_click` | Public external link/app activation | target, redacted destination |
| `cv_opened` | CV open/download action | target and public path |
| `media_opened` | Gallery opens | stable target |
| `name_played` | Pronunciation audio starts | stable target |
| `game_started` | A climb actually starts | none |
| `game_finished` | Result screen is reached | none |
| `map_node_opened` | Journey stop opens | existing stable action |
| `case_study_opened` | Case study opens | existing stable action |
| `language_changed` | Visitor changes language | existing action |
| `theme_changed` | Visitor changes theme | existing action |
| `section_dwell` | Route is left after two active seconds | integer seconds, maximum 3,600 |
| `scroll_depth` | Route is left after reaching a quartile | integer 1–4 |
| `error_reported` | A visible reportable error occurs | no message or stack |

Event, route, target and campaign values are allowlisted by shape and length.
Unknown fields are rejected. Contact destinations become `email` or `phone`;
they never carry the address or number. HTTP destinations lose query and hash,
except the public Google Play `id`.

## Storage and calculations

The Durable Object key for a counter encodes these dimensions:

```text
row|date|event|route|country|device|referrer|campaign|target|destination
```

Each transaction updates the count, numeric total when present, daily-visitor
marker and metadata together. A failed write rolls back all of them. The
per-daily-hash limit is 120 accepted beacons per minute; the next one receives
429 and is not counted.

The alarm removes aggregate rows older than 24 months and visitor/rate keys
older than one day, giving those short-lived values at most two UTC dates in
storage. It then schedules the next UTC midnight alarm.

`/v1/admin/insights` reads the requested range plus an equal-length previous
range. It merges historical KV counters with the new object, then produces the
report. The previous period is used only when it contains records.

## Local verification

Use the repository-pinned SDK for every Flutter command:

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter build web --wasm
node --test worker/test/*.test.js
```

For the dashboard browser run, use only the local in-memory harness:

```bash
ANALYTICS_DEV=1 node worker/dev/serve.js 8790
npm exec --yes --package=node@22 -- node worker/dev/verify-analytics-dashboard.js
```

The harness prints a throwaway local token. It never reads Cloudflare or writes
production metrics. Do not send synthetic beacons to production for a health
check: they cannot be separated reliably from visitor counts.

For a production-like Worker runtime without deploying, run Wrangler locally
and exercise `/v1/beacon` and `/v1/admin/insights` against its local state. Keep
all test credentials in ignored local environment files.

## Release order

The Worker and GitHub Pages deploy separately. Release in this order:

1. From the tested release revision, run `wrangler deploy`. This creates or
   reuses the `AnalyticsStore` migration and deploys the new beacon contract.
2. Record the Worker version ID in the worklog.
3. Let the merged `main` Pages workflow build with `ANALYTICS_ENDPOINT`. The
   generated CV/brief and Flutter app then expose the same consented client.
4. Verify the public site shows the consent choice with a clean browser
   profile. Reject and confirm no `/v1/beacon` request occurs. In a separate
   profile, accept and navigate once; that real owner-consented visit may be
   used to confirm the dashboard receives activity.
5. Sign in to `/admin`, check all four reports, range changes and CSV. Confirm
   the last-received timestamp matches the consented check.

If the Worker is unavailable, the public site still works and drops analytics.
If collection must be stopped quickly, remove `ANALYTICS_ENDPOINT` from the
Pages build and redeploy Pages, or set `ANALYTICS_ENABLED = "false"` and deploy
the Worker. Do not delete the Durable Object or KV namespace as a rollback.

## Authentication and secrets

The admin accepts either the password set in **Account** or the recovery secret
stored as Cloudflare `ADMIN_TOKEN`. Both exchange for a short-lived browser
session. No real credential belongs in source, a worklog, a screenshot or a
command transcript.

To rotate recovery access:

```bash
npx wrangler secret put ADMIN_TOKEN
npx wrangler deploy
```

Generate and store the value in a password manager. The Worker cannot reveal an
existing secret. A password can be changed from the Account screen; changing it
ends other sessions.

## Honest limitations

- Collection begins with this release. It cannot reconstruct prior app/link
  clicks or fill historical gaps.
- Counts include only visitors who accept.
- Destination activation is not downstream conversion.
- Daily uniques cannot become a cross-day people count.
- Active-time and scroll samples are best effort when a page is left; browsers
  can terminate an outgoing request.
- Country comes from Cloudflare and may be unknown or affected by a VPN.
- Referrer policies often remove the source; those views appear as direct or
  unavailable.
- Headless browser checks do not replace a physical-phone or screen-reader
  pass.

These limitations belong in the interface and future handoffs. Do not replace
them with estimates, seeded production rows or inferred claims.
