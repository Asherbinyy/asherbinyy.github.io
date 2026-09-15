# 2026-09-15-04 — Connect the admin to the current Flutter portfolio

**Agent:** Codex / GPT-6
**Milestone:** 6
**Started from:** `b72f33f` and the public portfolio, merged first through `106c4fd` and then `923c87e`

## Goal
Finish the requested panel controls, remove the rejected decorative admin styling, and connect the current owner content to the real website preview and public consumers.

## What changed
- Navigation and preview minimize/expand independently. Preview defaults to half the viewport with an option of at least one third; phones switch between full-width editor and preview.
- Removed grain, inset gold navigation stripe and decorative accent rules. Retained existing portfolio pigments/fonts, regular control borders and keyboard focus states.
- Added a real Flutter preview with isolated draft providers, exact parent/source/session checks, validated batches, route selection, English/Arabic and render acknowledgments. Invalid drafts keep the last valid website visible.
- Added live image/gallery/link/name-audio consumers and existing theme/font defaults with reset. Current services, tools, skills and social destinations are editable.
- Merged the current public implementation, including Services, combined Work/Writing and supplied owner content. All five content JSON files match the public checkout byte for byte.
- Local real-site harness serves the compiled public app with in-memory content/media/sessions. Browser verification edits and publishes locally, confirms a fresh normal public app reads the publication without admin credentials, then withdraws the test publication.
- Preserved the reviewed backend store/auth/revisions. No admin integration was deployed. Hosting URL changes were handled separately, then restored to Asherbinyy when the owner reversed the account migration.

## Files touched
- `CHANGELOG.md` — modified — record the local admin integration
- `README.md` — modified — restore the original public URL
- `docs/00-PROJECT-BRIEF.md` — modified — restore the original hosting reference
- `docs/08-GIT-AND-CI.md` — modified — restore repository/domain setup references
- `docs/11-OPEN-ISSUES.md` — modified — separate completed local consumers from production dependencies
- `docs/15-ADMIN-AND-MEDIA.md` — modified — replace obsolete missing-adapter/audio statements
- `docs/31-CODEX-ADMIN-UI-REVIEW.md` — modified — document the real local workspace and its limits
- `lib/app/app.dart` — modified — inject the preview router and consume published font defaults
- `lib/app/bootstrap.dart` — modified — install the published default-theme provider
- `lib/app/router.dart` — modified — reuse actual public routes while bypassing preview acquisition
- `lib/app/theme/daybreak_theme.dart` — modified — apply selected existing font families without changing palette tokens
- `lib/app/theme/nocturne_theme.dart` — modified — apply selected existing font families without changing palette tokens
- `lib/app/theme/theme_controller.dart` — modified — respect owner defaults and retain visitor theme choices
- `lib/app/theme/theme_factory.dart` — modified — apply selected existing font families without changing palette tokens
- `lib/app/theme/typography.dart` — modified — apply selected existing font families without changing palette tokens
- `lib/content/content_media.dart` — created — resolve strict uploaded-media references through the relay
- `lib/content/content_parser.dart` — modified — validate new fields, galleries and uploaded references
- `lib/content/models/apps.dart` — modified — parse optional project galleries
- `lib/content/models/gallery.dart` — created — type shared gallery entries and media kinds
- `lib/content/models/interests.dart` — modified — parse optional interest galleries
- `lib/content/models/profile.dart` — modified — parse ordered links, recording, appearance and current profile data
- `lib/core/net/relay.dart` — modified — allow exact local HTTP hosts for the isolated review build
- `lib/core/preview/preview_connection.dart` — created — select the web transport without platform imports in feature code
- `lib/core/preview/preview_connection_stub.dart` — created — keep unsupported environments outside the preview channel
- `lib/core/preview/preview_connection_web.dart` — created — check exact origin, parent identity, protocol and session
- `lib/core/preview/preview_host.dart` — created — parse draft batches into isolated real app providers and routes
- `lib/core/preview/preview_transport.dart` — created — separate checked browser messaging from the Flutter host
- `lib/core/widgets/content_gallery.dart` — created — render supplied images/captions and deliberate external video links
- `lib/features/about/presentation/about_screen.dart` — modified — pass ordered contact links to the actual page
- `lib/features/about/presentation/widgets/contact_links.dart` — modified — retain current contact cards and render optional ordered links/icons
- `lib/features/about/presentation/widgets/education_table.dart` — modified — load uploaded evidence images
- `lib/features/about/presentation/widgets/interests_grid.dart` — modified — open galleries only for interests that have entries
- `lib/features/about/presentation/widgets/portrait_frame.dart` — modified — retain the current portrait treatment and load uploaded images
- `lib/features/services/presentation/services_screen.dart` — modified — consume ordered contact links alongside current services
- `lib/features/station/presentation/station_screen.dart` — modified — consume ordered contact links in Home’s contact section
- `lib/features/station/presentation/widgets/name_pronunciation.dart` — modified — play the optional uploaded recording on request
- `lib/features/work/presentation/widgets/device_frame.dart` — modified — resolve uploaded screenshots
- `lib/features/work/presentation/widgets/ledger_row.dart` — modified — resolve uploaded screenshot thumbnails
- `lib/features/work/presentation/widgets/work_card.dart` — modified — render supplied screenshots and gallery controls
- `lib/main.dart` — modified — enter private preview before persistent preferences load
- `test/unit/content/admin_integration_test.dart` — created — verify parser round trips, unsafe input rejection and private preview/default-theme behavior
- `test/unit/tool/generate_static_test.dart` — modified — restore and verify the original canonical origin
- `test/widget/preview_host_test.dart` — created — verify real rendered draft text, Arabic updates and transport lifecycle
- `tool/generate_static.dart` — modified — restore and verify the original canonical origin
- `web/flutter_bootstrap.js` — created — serve preview font fallback locally
- `web/fonts/fallback/LICENSE` — created — retain the bundled fallback font’s SIL Open Font License
- `web/fonts/fallback/notocoloremoji/v32/Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.0.woff2` — created — bundle the exact Flutter flag fallback to avoid third-party preview requests
- `web/index.html` — modified — restore the original canonical and sharing URLs
- `web/intro/threshold.js` — modified — skip the DOM intro inside the embedded preview
- `worker/contracts/INTEGRATION.md` — modified — state current consumers and retain historical requests as history
- `worker/contracts/content-schema.js` — modified — expose consumed media/appearance and current profile/contact fields
- `worker/dev/browser.js` — modified — inspect the real cross-origin Flutter iframe via CDP
- `worker/dev/serve.js` — modified — serve current owner content and the compiled app in opt-in real-site mode
- `worker/dev/verify-admin-integration.js` — created — exercise actual preview, panel, language, media and publication flows
- `worker/src/admin/client-app.js` — modified — add independent panel controls, reset and correct navigation state
- `worker/src/admin/client-fields.js` — modified — resolve bundled asset thumbnails correctly
- `worker/src/admin/client-pages.js` — modified — map Home, Services and other current pages to shared content
- `worker/src/admin/client-preview.js` — modified — send validated shared draft batches and follow actual public routes
- `worker/src/admin/client-state.js` — modified — fail closed on content reads and use semantic dirty-state comparison
- `worker/src/admin/design-tokens.js` — modified — name compact heading and preview handshake values
- `worker/src/admin/markup.js` — modified — label panel/preview controls and use the real preview by default
- `worker/src/admin/styles.js` — modified — remove rejected accents and support half/third-width responsive panels
- `worker/test/admin-panel.test.js` — modified — assert connected preview and panel controls
- `worker/test/appearance.test.js` — modified — assert the live profile subset while retaining broader proposal gates
- `worker/test/content-schema.test.js` — modified — assert new fields have declared live consumers
- `docs/audits/2026-09-15-admin-integration/` — created — 18 real-app captures, browser results and review gallery.
- `docs/worklog/2026-09-15-04-codex-live-admin-preview.md` — created — integration and verification record.

## Decisions made
The preview uses actual routes/components rather than an HTML imitation. It skips acquisition and persistent preference initialization, disables analytics and published override reads, and receives only validated documents, never credentials. JavaScript `Object.is` compares cross-origin window identity because Dart equality on a cross-origin WindowProxy raised a browser exception.

Appearance is a deliberately bounded optional `profile.appearance` subset: existing Kemet/Deshret themes and existing Space Grotesk/IBM Plex Sans families. Arabic keeps its existing Arabic font. No fifth pigment, token-value change, new package, standalone appearance endpoint, pattern preset or owner content was invented. The compact heading and preview handshake timing have named admin tokens. Existing public styling from Claude’s committed branch is retained.

The preview bundles the Flutter runtime and exact Noto flag fallback font (with its license). Current private preview requests stay on the two local origins; cookies/localStorage/sessionStorage remain empty. This does not change the public consent flow.

The browser exposed a 1024px heading overflow, stale dirty dots after restoring a removed key, and an orphan phone preview-width label; all were corrected. The uploaded-portrait test initially inspected a frame still minimized by the phone scenario. A focused visible-frame probe verified a successful image load; the full scenario now restores the frame and waits for that image to load. All 47 checks then pass.

## Tests
- Added: five parser/preview/default-theme tests in `admin_integration_test.dart`; actual widget rendering/locale/transport test in `preview_host_test.dart`; real browser integration workflow.
- Modified: admin panel, appearance and content-schema assertions; canonical origin tests during the account reversal.
- Full suite: pass, 710 Flutter tests and 289 Worker tests passing, 0 failing. Browser: 47 passing, 0 failing.
- Coverage delta: not measured locally in this integration pass.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 309 files, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 710 tests
fvm flutter build web --wasm               pass, with local preview/relay defines and --no-web-resources-cdn
```

The existing Cupertino icon-font warning remains in the successful build. The exact build command is in `31-CODEX-ADMIN-UI-REVIEW.md`. An automatic approval usage limit temporarily blocked a local Git commit; later authorized normal execution succeeded. No rejected action was bypassed.

## Known issues left open
- The redesigned admin and preview are local and require a separate production integration release. Production transactional-store activation remains an explicit migration task.
- CV/Brief/metadata still require a coordinated static release; publishing a runtime override does not rebuild them.
- Preview selection follows pages, not individual fields. The CV/Brief editor previews shared Home data.
- Per-page patterns, extra appearance presets, article feed selection/authoring, game/leaderboard controls and PDF upload have no implemented contracts. Existing limitations are stated in the UI.
- Bundled project/interest galleries are empty because no media entries were supplied; nothing was seeded. Analytics collection stays disabled and no figures were fabricated.
- Physical-device and screen-reader acceptance remain open; passing tests do not establish owner visual acceptance.

## Next
Review the current local workspace at `http://localhost:8790/admin`, then plan its production release with the reviewed transactional store and coordinated static publication.
