# Admin integration review — September 17

Branch: `phase/codex-admin-ui`. Backend baseline: reviewed `edfd04c`.
The release also includes the custom-domain and leaderboard changes from main.

## Open it

Open `http://localhost:8790/admin`. Start it from this checkout with
`REAL_SITE=1 node --watch worker/dev/serve.js 8790`. The harness prints its
throwaway local sign-in credential. It serves the current owner-supplied
`assets/content/` and real compiled Flutter app; analytics are not seeded.
Its content, media and sessions are in memory and reset when it restarts.

Build the preview first:

```sh
fvm flutter build web --wasm --no-web-resources-cdn \
  --dart-define=ADMIN_PREVIEW_ORIGIN=http://localhost:8790 \
  --dart-define=WRITING_RELAY=http://localhost:8790
```

[Desktop and phone gallery](audits/2026-09-16-admin-final/index.html).
[Actual browser checks](audits/2026-09-16-admin-final/checks.json).

## What changed

- Independent expand/minimize controls for navigation and the right panel.
  The preview defaults to half the window; its smaller setting remains at
  least one third. On phones, preview and editor have a full-width switch.
- Removed the admin grain, inset gold navigation stripe, and decorative
  accent rules. Existing portfolio pigments, fonts and visible focus states
  remain. Light/Dark in the header changes only the admin tab.
- The preview renders the actual Flutter pages and validated drafts. It
  follows the selected page, retains shared edits across pages, switches
  English/Arabic, and retains the last valid render when validation fails.
- Current skills, learning topics, tools, Services and social destinations are
  editable. Existing owner content was merged from the public branch; no
  replacement biography, claims, translations or media were invented.
- Uploaded portraits, evidence images, project screenshots, project/interest
  galleries, ordered custom contact links and name recordings have public
  consumers. Videos open their external destination only on request.
- Appearance saves optional `profile.appearance` defaults using the existing
  Kemet/Deshret themes and bundled Space Grotesk/IBM Plex Sans families.
  Reset removes the override. Arabic retains its Arabic font and visitors
  retain their own theme choice.

| Destination | Working surface | Remaining limit |
| --- | --- | --- |
| Overview | Existing insights, date ranges, charts/tables for recorded data, honest disabled/empty state | No invented traffic; no separate daily page-view or exact-click series is supplied |
| Home | Introduction, figures, countries, skills/tools and shared career | Owner provenance required for claims |
| Journey | Stops, chronology and project references | No new stop/media types invented |
| Work | Projects, store links, screenshots and galleries | Bundle has no supplied project screenshots/gallery entries |
| Articles | Medium contact link and explanation of the current Work feed | Feed selection/article authoring require a separate contract |
| Services | Current list and contact/booking destinations | Service copy comes only from supplied content |
| About | Biography, portrait, education, ordered links, recording | No invented translations or records |
| Courtyard | Interests and galleries | Game/leaderboard settings remain outside the admin |
| CV & brief | Shared identity, career and education | Static HTML/metadata still need a coordinated site release; no PDF upload |
| Appearance | Existing theme/font defaults, live preview and reset | Extra presets and per-page pattern selection remain undefined |
| Media / Account | Existing validated uploads, library and account controls | Transactional production storage is enabled in this release |

Publishing applies to the selected document, including shared fields edited
from other pages. It does not rebuild the CV, brief or search metadata.

## Preview boundary

The embedded app accepts only the configured parent origin, its actual parent
window, the protocol version and a fresh session nonce. It receives documents,
never admin credentials. Draft batches are parsed before application. Its
providers use in-memory preferences, disable analytics and published override
reads, and resolve uploaded media through the admin's relay.

The preview uses the bundled Flutter runtime and a local copy of its flag
fallback font. The browser workflow checks that the current preview makes no
third-party requests and writes no cookies, local storage or session storage.
The public site's ordinary consent flow is unchanged.

The adapter navigates to pages, not exact individual fields within a page.
The CV/brief editor previews the shared Home data; static-document rendering
still requires the coordinated release work.

## Verification

- `node --test worker/test/*.test.js`: 321 passing, none failing or skipped.
- All four required FVM checks pass: format, analyze, 756 Flutter tests, Wasm build.
- All 74 browser checks pass. Results and screenshots are linked above,
  including every destination at desktop and phone widths, private edits,
  validation failure, panel controls, Arabic, Services, appearance/reset,
  media, local publication and the current game in the isolated preview.
- The existing Cupertino icon-font warning remains in the successful build.
- Physical Safari/Android and screen-reader acceptance remain open. Passing
  checks do not establish the owner's visual acceptance.

## Deployment

The merge publishes the Flutter adapter with an exact allowlist for the deployed
admin origin. The matching Worker deployment serves the redesigned panel at
`/admin`, retains the game bindings and uses `https://sherbini.uk` for content,
preview and CORS. Analytics collection remains disabled.
