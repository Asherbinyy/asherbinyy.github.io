# 2026-09-14-04 — Admin UI review candidate

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** edfd04c6fb41ecf7d1058f2c73039edc9b4333f3

## Goal
Rebuild the rejected admin interface using the portfolio's palette and typography, make the requested page destinations discoverable, and render honest charts from existing insights while preserving Claude's reviewed backend.

## What changed
- Created isolated `phase/codex-admin-ui` from the specified admin commit. Preserved the public checkout and Claude's modified browser helper in the original admin checkout.
- Added Home, Journey, Work, Writing, About, Courtyard and CV/brief destinations. Journey, Work and Courtyard open directly in their editors; Home/About have section choices and profile fields appropriate to the page. Existing document drafts are shared and the publish scope is explicit.
- Rebuilt layout around the existing pigments, bundled Space Grotesk/IBM Plex fonts, square panels, structural rules and monochrome grain. Added a tab-local light/dark switch with no preference storage, accessible phone navigation and stacked language tabs.
- Added SVG charts with exact-value tables for recorded events and daily uniques. Missing dates stay missing. No monthly unique sum or synthetic traffic. Empty metrics are unavailable, with collection disabled explicitly stated. Audience breakdowns say events, not people.
- Added an Appearance reference page with accurate permanent-theme samples and visible integration limits. Kept unsupported setting writes unavailable.
- Fixed hidden sign-in errors, duplicate dialog body IDs, stale date-range/release responses, repeated release-error requests, and failed account reads falsely saying no password was set. Shortened Media/Account copy and formatted the account expiry from the returned session information.
- Defaulted to the honest draft outline while retaining the existing preview protocol and explicitly flagging the pending Flutter adapter.
- Captured every destination on desktop/phone plus five content editors, Arabic editing, review, errors and light appearance. Created a browser gallery and concrete integration requests.

## Files touched
- `worker/src/admin.js` — modified — assemble the UI modules; remove duplicate inline dialog styling.
- `worker/src/admin/styles.js` — modified — portfolio typography/material, responsive layout and accessibility states.
- `worker/src/admin/design-tokens.js` — created — CSS mirror of existing Flutter palette and scales, with named admin layout sizes.
- `worker/src/admin/markup.js` — modified — sign-in, menu, controls and unique dialog containers.
- `worker/src/admin/client-app.js` — modified — page navigation, shared edit context and responsive menu behavior.
- `worker/src/admin/client-pages.js` — created — page-to-content mapping, appearance references and existing bundled-font loading.
- `worker/src/admin/client-home.js` — modified — dashboard, range/release state and accurate labels.
- `worker/src/admin/client-charts.js` — created — observed-date SVG series with data tables.
- `worker/src/admin/client-state.js` — modified — page context, visible gate feedback, account error state and outline default.
- `worker/src/admin/client-preview.js` — modified — specific status wording without claiming the fixture is the site.
- `worker/src/admin/client-account.js` — modified — concise copy, readable expiry and honest failure/retry state.
- `worker/src/admin/client-media.js` — modified — concise upload/library copy.
- `worker/dev/serve.js` — modified — serve existing bundled font files in the isolated harness.
- `worker/dev/browser.js` — modified — bring the test tab forward, send the native Enter character and time out stalled CDP commands.
- `worker/dev/verify-admin-ui.js` — created — 57 browser checks and captures without analytics seeding.
- `worker/dev/verify-admin-account-ui.js` — created — five focused account error/retry and copy/layout checks.
- `worker/test/admin-ui.test.js` — created — nine behavior regressions.
- `worker/test/appearance.test.js` — modified — replace obsolete no-Appearance-page expectation with reference-only/non-publishable contract.
- `worker/contracts/INTEGRATION.md` — modified — current ownership and precise missing backend/public contracts.
- `docs/11-OPEN-ISSUES.md` — modified — review-candidate status; no acceptance item closed.
- `docs/31-CODEX-ADMIN-UI-REVIEW.md` — created — page coverage, checks and remaining integrations.
- `docs/audits/2026-09-14-admin-ui/` — created — browser captures, check results and gallery.
- `docs/worklog/2026-09-14-04-codex-admin-ui.md` — created — session record.

## Decisions made
- The current handoff/user request authorizes the UI rebuild and supersedes old ownership restrictions. Backend endpoints, schema, validation, store, auth behavior and production bindings remain unchanged.
- Keep publication per existing document. Introducing independent per-route publishing would require a new backend/content contract; the UI explicitly explains shared changes instead.
- Use the site's existing font files via allowed bundle fetches and FontFace buffers. No package, font host or CSP relaxation was added.
- Mirror existing Flutter tokens in admin CSS because the UI is HTML and editing `lib/**` is excluded. No public token value changed. Admin layout dimensions are local CSS constants.
- Use an honest Appearance reference page instead of hidden features or selectors that cannot affect the site. The public consumers and settings endpoints are still missing.
- Label `insights.byDay` as all recorded events. Daily page views and precise clicked destinations need additive backend support and are requested in INTEGRATION.md.
- Do not seed the local dashboard. Chart behavior uses unit-test inputs only. Browser captures show real empty responses from the isolated harness; content uses its pre-existing fictional fixtures.
- Use the outline by default. The real Flutter preview is still absent, and the development protocol fixture is explicitly not a website layout preview.

## Tests
- Added: empty charts contain no invented data; exact observed counts/missing-day gaps; finite single-day chart coordinates; late insights cannot replace newer range; invalid dates do not request fallback dates; palette values match Flutter source; unique dialog targets; assembled browser module compiles; account failure preserves unknown state and retry recovers.
- Modified: Appearance surface contract now permits the requested reference page while preserving the non-publishable settings contract.
- Full suite: pass, 666 Flutter passing, 0 failing; 289 Worker passing, 0 failing, 0 skipped.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 281 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 666 passing
fvm flutter build web --wasm               pass, build/web generated
```

Worker suite: `node --test worker/test/*.test.js`, 289 passing.
Browser: 57/57 primary checks; 5/5 focused Account/Media checks. Captures use actual Chrome at desktop and emulated-phone sizes. No physical-phone or screen-reader certification.

Initial FVM runs failed because the isolated checkout lacked ignored generated providers/models and localization files. Ran `fvm dart run build_runner build` and `fvm flutter gen-l10n`, then reran the required checks successfully. Dart itself also crashed in the sandbox; verified runs used the approved local pinned SDK outside it. No tracked public source or dependency files changed.

The first browser pass exposed the existing driver's incomplete Enter event; the corrected driver verifies the menu natively. The first custom-range scenario changed the DOM start value without dispatching its change event; the corrected scenario passes. Visual inspection caught inherited light colors in the Kemet reference sample; that was fixed and checked. These earlier failures are not counted as successful runs.

## Known issues left open
- This is a local review candidate, not the owner's visual acceptance, a merged branch or a release. Passing tests do not close that gap.
- Actual Flutter preview, coordinated HTML/interactive release and current field consumers remain pending. Appearance has reference samples only; it cannot publish theme/font/background settings.
- Writing has no feed/article editing contract. Game and leaderboard controls have no admin schema. The latest public skills/learning/tools fields need schema reconciliation by Claude.
- Daily page views and exact clicked destinations are not available from the current insights response. Charts show the existing event and daily-unique series only.
- The public release still disables analytics. No counters were seeded and no production read/write was performed in this session.
- Base `edfd04c` predates the public branch's icon-font fix. Its Wasm build succeeds with the existing Material/Cupertino icon-font warning; the prohibited public files were not edited to fix it.
- Existing browser scenario scripts for the former UI contain outdated label/layout assumptions; the new checks cover the rebuilt navigation. Full old-scenario compatibility is not claimed.
- The harness uses fictional content and a protocol preview fixture. It cannot certify behavior against the owner's production content, real preview or real devices.

## Next
Review the local panel and capture gallery with the owner, then have Claude supply the concrete contracts in INTEGRATION.md so the unavailable settings and public consumers can be completed without false working controls.
