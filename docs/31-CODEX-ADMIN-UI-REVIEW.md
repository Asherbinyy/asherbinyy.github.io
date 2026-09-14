# Admin UI review — September 14

Branch: `phase/codex-admin-ui`, based on reviewed backend commit `edfd04c`.
This is a local review candidate. It is not deployed or visually accepted.
The source brief is the public checkout's `docs/30-CODEX-ADMIN-HANDOFF.md`.

## Open it

Run `node worker/dev/serve.js 8790` from this checkout and open
`http://localhost:8790/admin`. This uses the existing isolated in-memory harness
and fictional content fixtures. The harness prints its local credential; no
production credential is needed. The review run does not seed analytics.

[Desktop and phone capture gallery](audits/2026-09-14-admin-ui/index.html).
[Browser check results](audits/2026-09-14-admin-ui/checks.json).
[Account follow-up checks](audits/2026-09-14-admin-ui/account-checks.json).

## What is implemented

| Page | Working surface | Remaining integration |
| --- | --- | --- |
| Overview | Existing insights endpoint; range selection, unavailable metrics, observed-date SVG charts with exact-value tables, event/route/audience breakdowns, publication status, retry | No recorded local analytics; endpoint does not expose daily page views separately or exact clicked targets |
| Home | Introduction, statistics, countries, contact and career editors | New public skills/learning/tools fields are absent from this backend schema |
| Journey | Direct stop editor with add/reorder/edit and project references | Additional stop types/media depend on schema and public components |
| Work | Direct project editor with existing links, screenshots and gallery authoring | New gallery rendering remains pending in the public app |
| Writing | Page-specific explanation and existing Medium contact-link editor | Feed selection and article authoring have no admin contract; the contact link does not control the feed |
| About | Biography/portrait, education/research, flexible links and name-audio editors | Flexible link and audio public consumers remain pending |
| Courtyard | Direct interest editor | Gallery public consumer; game/leaderboard settings are unavailable |
| CV & brief | Shared identity, experience and education editors | Generated documents and metadata require the public release integration; no PDF upload endpoint |
| Appearance | Accurate Kemet/Deshret samples and typography/background availability | Public settings persistence and consumers, pattern allowlist, extra preset definitions |
| Media | Existing upload/library/usage controls in the new layout | Unchanged validated formats and direct-video limits |
| Account | Existing session/password controls in the new layout | Production transactional binding remains disabled as instructed |

Shared data keeps a single draft per document across page navigation. Publish
still applies to that document, which may supply more than one public page.
The editor says this explicitly; it does not claim isolated per-route publication.

The admin uses the existing pigments and bundled Space Grotesk/IBM Plex fonts,
square panels, structural rules and subtle monochrome grain. The admin-only
Light/Dark control changes this tab's appearance in memory and writes no new
preference storage. It does not change the public site's default theme.

## Behavior checked in the browser

- Sign-in errors appear at the sign-in field.
- Every destination and five content editors fit desktop and phone sizes.
- Drafts survive navigation; English and Arabic switch by keyboard, with RTL inputs.
- Review opens in its own dialog. Cancel preserves the draft and makes no publish.
- The empty dashboard states collection is disabled and shows unavailable values.
- Appearance samples remain distinct when the admin itself changes palette.
- Invalid date ranges show an error, without an automatic backend date substitution.
- No analytics data is inserted for the screenshots.

The two dialogs previously shared an ID; they now have unique bodies. The UI
also ignores stale insights/release responses, and a failed release check offers
a retry instead of automatically repeating requests forever.

## Limits of this review

Screenshots use the harness's pre-existing fictional content fixtures, not the
owner's live data. Chart geometry and stale responses are checked with unit-test
inputs; no populated chart is presented as real traffic. The browser captures
show the honest empty state.

The default right pane is the draft outline. It explicitly says it is not the
website. The existing preview protocol is retained, but the actual Flutter
adapter remains pending. A local protocol fixture cannot prove visual parity.

No production deployment, bindings, secret rotation, content source changes,
public-app edits, analytics activation or new dependencies are included.
Physical-device and screen-reader acceptance remains open. Passing checks do
not establish the owner's visual acceptance.

## Next dependency work

See the September 14 request in `worker/contracts/INTEGRATION.md`. Claude owns
the backend and public consumers; Codex owns this panel. Each missing control
can become active only when it can persist valid data and the site consumes it.

## Verification recorded

- `node --test worker/test/*.test.js`: 289 passing, no failures or skips.
- `fvm dart format --set-exit-if-changed .`: 281 files, unchanged.
- `fvm flutter analyze`: no issues.
- `fvm flutter test`: 666 passing.
- `fvm flutter build web --wasm`: successful; existing base-branch icon-font warning remains.
- Browser: 57 primary checks and 5 focused Account/Media follow-up checks passed.

The FVM runs verify the requested `edfd04c` baseline, which predates the public
checkout's latest Flutter work. The isolated checkout first needed its ignored
Riverpod/model and localization outputs generated. Initial checks failed until
that setup was complete; those runs are not counted as passes.
