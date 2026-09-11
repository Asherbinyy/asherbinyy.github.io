# Re-innovation audit

Date: 2026-09-11. Repository baseline: `1cfd039`, originally on `docs/handover`.
This is an assessment of the existing product, not a claim that the redesign is complete.
Execution plan: [Re-innovation milestones](19-REINNOVATION-ROADMAP.md).

## Findings that determine the next work

1. **Search visibility needs architectural work.** Public Flutter routes return HTTP 404 on direct entry. The HTML response does not contain their portfolio content. The static CV and Brief help, but do not make the rest of the site search-ready.
2. **The design rules have been working against the requested design.** The owner asked for realistic Egyptian environments, depth, material, figures and environmental motion. The docs prohibit several of those things and preserve the retired instrumentation vocabulary.
3. **The admin is a JSON-shaped form, not the requested editing workspace.** It lacks a real preview, flexible content components, theme management and a safe draft/publish workflow.
4. **The map complaint is reproducible.** At 1440×900 the initial map pushes the timeline below the viewport. Selecting a stop does shrink the map and show a right-hand panel; that existing behavior should be retained and refined.
5. **Many implemented features are still visually unaccepted.** A renamed heading or a passing painter test is not evidence that the owner's design request has been met. Do not report a percentage complete using the old backlog's strike-through count.

## Evidence and limits

Read the brief, design system, architecture, Flutter standards, testing guidance, privacy status, content schema, roadmap, issues, motif inventory, game design, provenance, admin spec, redesign backlog, handover and changelog. Reviewed the three latest worklogs in full and the goals, outstanding issues and next steps of the earlier worklogs. Cross-checked the relevant code, JSON content, assets and CI workflow.

The three latest worklogs are consistent as a September 7 sequence: palette/footer work, milestone 4 completion, then Worker deployment. They do **not** describe the September 8–11 redesign and admin changes. Git history and the original conversations fill that gap; no missing worklog has been reconstructed as if it existed.

Original project-scoped Claude conversation records were available locally. The substantive source is conversation `b28008ff-6dd7-46be-8615-074e5b54e404`; other records include earlier sessions and repeated context. These records and the owner's attached screenshots remain outside the repository.

| Source | What it establishes |
|---|---|
| U1: September 7, 22:55 UTC, 37 numbered sections | Egyptian environment; realistic depth; project exhibition; distinctive page roles; responsive interactions; quality over superficial completion |
| U2: September 8, 00:04 and 01:00 UTC | Ice Tower-inspired game, independent fun area, original character, media-ready projects and a separate admin |
| U3: September 8, 00:22 and September 9, 19:07 UTC | No visible Enter/Skip choice in intro; remove CV facts from the game; recording and personal-detail corrections |
| U4: September 9, 21:18 UTC, plus four annotated images | Detailed admin requirements; all page-by-page changes; map/timeline alignment; no repeated floating career text; recognizable real logos |
| U5: September 9, 22:03 UTC | Subscriber feature cancelled. The message says “no need for the sub”; it does not explicitly cancel the separate daily digest |
| U6: September 10, 18:59 and 19:01 UTC | Space/tap jumps; stronger wall kicks and rewards; progressive levels; compact controls; real Manchester United crest; favorites |
| U7: September 11 handover request | Owner rejects current quality and asks for an independent audit |
| U8: Current request | SEO becomes the leading priority; section-by-section re-innovation; more convincing Egyptian character/world; no bottom CC caption; map and timeline together; admin included |

### Browser evidence

Captured the deployed site in isolated headless Chrome 152. Desktop viewport: 1440×900. Phone emulation: 390×844. Normal pages used reduced motion to inspect their settled layout; the intro capture used normal motion. Public route captures are the deployed build, not a newly built local preview.

| Capture | Observation |
|---|---|
| [Home](audits/2026-09-11/home-desktop.png) | Large introduction and repeated experience statement; right half consists of thin ornament rows; old rail remains |
| [Journey initial](audits/2026-09-11/journey-desktop.png) | Map consumes most available height; timeline is below the visible content area |
| [Journey selected](audits/2026-09-11/journey-selected-desktop.png) | Selection opens a right panel and reduces the map; timeline becomes visible |
| [Journey phone](audits/2026-09-11/journey-phone.png) | Map and timeline fit at this size, but large unused space and weak stop context remain |
| [Work](audits/2026-09-11/work-desktop.png) | Repeated procedural images, inconsistent copy lengths, title collisions on artwork and weak evidence of the products |
| [About](audits/2026-09-11/about-desktop.png) | Long line measure beside portrait, large unused area, transcript-like education |
| [Writing](audits/2026-09-11/writing-desktop.png) | Real covers and visible titles now work; the old “Writing is empty” issue is closed for this observed load |
| [Courtyard](audits/2026-09-11/courtyard-desktop.png) | Game promotion is a plain panel; interests are small line scenes, with terse labels below |
| [Game](audits/2026-09-11/game-after-space.png) | Full-screen shaft with platforms and an insect-like climber; does not match the newly requested Egyptian humanoid |
| [Intro phone](audits/2026-09-11/intro-phone.png) | Gate tightly framed; guardians absent from this captured view; attribution occupies the bottom |
| [Admin, local fixture](audits/2026-09-11/admin-apps-local.png) | Existing admin HTML rendered with local content fixtures and network stubs; narrow, tall forms and global-looking bottom bar |

The admin capture does **not** verify production authentication, publishing or password rotation. No production content was written. The initial game capture was still settling; only the later painted capture is retained as design evidence. Space input was exercised, but a full gameplay/playability review remains open. Phone emulation is not physical iPhone Safari or Android Chrome testing. No frame-time or Lighthouse score is claimed from screenshots.

## SEO and publishing

| ID | Finding and evidence | Consequence |
|---|---|---|
| S1 | Direct browser document responses for `/journey`, `/work`, `/about`, `/writing` and `/courtyard` are 404. CI copies the shell into `404.html` | Rendering a working app after a 404 does not repair the HTTP status |
| S2 | `web/index.html` contains the intro, metadata and bootstrap scripts; the initial document has no career, project or About body content | Metadata alone cannot represent the full public portfolio |
| S3 | Both deployed sitemap and `tool/generate_static.dart` still list `/signal` and `/privacy`; `/journey` and individual projects are absent | Crawlers are directed to retired routes and miss intended destinations |
| S4 | Shell description/OG copy still says “from the first idea to the release notes”; all app paths inherit the homepage canonical | Rejected copy remains in previews, and public routes lack independent metadata |
| S5 | `tool/generate_static.dart` reads bundled JSON; `ContentRepository` prefers Worker overrides; `web/index.html` has a third manual copy | An admin publish can change the app while CV, Brief, metadata and search content remain stale |
| S6 | Sitemap `lastmod` is the generator's current date for every URL | Build time is represented as content-change time |
| S7 | EN/AR switches change client state; no independent Arabic page URLs or alternate-language links are generated | Arabic needs an explicit crawlable route strategy, not just RTL rendering |
| S8 | OG image is the small brand icon; README references missing `docs/assets/screenshot.webp` | Sharing does not introduce the person or work effectively |

**Recommendation:** deliver semantic HTML for public content, with CSS and lazily loaded scene/game modules for motion. Keep the existing Worker, verified content and reusable geometry. The choice of frontend framework and public serving/publishing strategy belongs to R1 and is pending the owner's answer; this audit does not install or migrate anything.

**If Flutter is retained:** generate complete HTML documents at each public URL, with matching visible content, correct status codes and route metadata, and define how admin publishing updates them. Do not use a hidden keyword block, user-agent-specific bot page, or the 404 shell as the SEO solution. Maintaining two renderers has an ongoing parity cost.

R1 must resolve publishing consistency, not just generate another static snapshot. Either publish a validated content revision and rebuild before marking it live, or serve HTML and interactive views from the same published revision. A saved draft and a live release must be visibly different states in the admin.

Google documents the importance of crawlable links, rendered HTML and meaningful status codes in its [JavaScript SEO guidance](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics). Flutter's [web FAQ](https://docs.flutter.dev/platform-integration/web/faq) recommends separating search-oriented document content from app experiences. Those recommendations support the architectural direction; they are not a guarantee of ranking.

Search checks surfaced the owner's Medium and LinkedIn profiles and several unrelated people with the same name. The portfolio did not surface in the returned results for the two audit queries. This is **not** proof of Google's complete indexing state or a ranking measurement. Search Console property access is still needed to inspect Google's index status, submit the sitemap and monitor name-query impressions. Follow [Search Console guidance](https://developers.google.com/search/docs/monitor-debug/search-console-start); do not promise that every name search will show the site.

## Design, motion and assets

| ID | Finding | Required response |
|---|---|---|
| V1 | `ornament_paths.dart` defines five simplified polylines. They are ornament, not hieroglyphic writing | Replace visual stand-ins with sourced relief panels/figures and intentional compositions. Never fabricate a name translation |
| V2 | `01-DESIGN-SYSTEM.md` still specifies instrumentation, corner ticks, flat surfaces and a single dominant animation; `12-MOTIF-LIBRARY.md` prohibits requested environmental elements | Revise art direction around the owner's current request before using old rules to reject new designs |
| V3 | Home, Work and About share similar rails, fills and frames | Give pages distinct spatial compositions while sharing navigation, material, typography and interaction behavior |
| V4 | Route pages use `NoTransitionPage` | Design an interrupted/reversible route transition with a reduced-motion alternative; do not hide readable content behind it |
| V5 | Map uses a fixed 2:1 aspect ratio inside a scrollable page; timeline follows it | Reserve height for heading, navigation and timeline, then size the map from the remaining space |
| V6 | Intro camera starts at a fixed position and updates aspect ratio without framing the scene bounds; short dimensions under 380 disable it | Fit camera distance/composition to viewport and actual scene bounds; supply a deliberate small-screen fallback |
| V7 | The intro already includes Three.js, scanned geometry and PBR textures | More tooling alone will not repair composition, lighting, framing or visual continuity |
| V8 | Store marks are custom `CustomPainter` approximations. There is no general platform-logo registry; Contact is a fixed set of text links | Real recognizable assets, shared domain lookup, owner override, fallback icon and accessible labels |
| V9 | `interests.json` names a club-crest asset that does not exist; browser request returns 404 | Fetch the real approved crest and record its source; do not claim the slot is the delivered logo |
| V10 | App media folder contains only guidance; no app declares a screenshot; that directory is also absent from `pubspec.yaml` asset roots | Complete the media path, gallery model and actual media population, rather than just telling the owner to upload |
| V11 | Footer is an empty reserved bar | Revisit the composition; no replacement tagline is needed merely to fill it |

There is no need for access to another 3D platform merely to start. R2 should choose an asset pipeline after a small visual proof. The entrance should have no bottom CC caption. Prefer original or CC0 entrance assets so the composition is not dependent on a persistent caption; keep an asset-source/license inventory. No asset or credit was changed during this audit.

## Content

The bundled records contain 14 applications, 8 journey stops, 2 education entries and 6 interests. These are inventory counts, not career claims. The PDF, portrait, name recording, coursework images and Medium covers exist. “Missing portrait,” “missing PDF” and “eleven apps” in the old issue list are obsolete.

- **Home:** greeting is now present, but positioning repeats the experience stat. Metadata still uses the previous rejected sentence. Write one clear introduction and reserve proof for the next layer.
- **Work:** the cards alternate between a feature description, contribution, long case-study summary, metric and no description. Use one consistent short contribution or product fact, with depth in the detail view. Keep MiNextStep prominent even without a public listing.
- **About:** the biography opens with work and country count again. The owner has already supplied interests and AI-automation interest; use them without elevating an interest into an unsupported expertise claim.
- **Education:** dissertation topic, research evidence, smart-tank project and robotics placing are already supplied. Present selected work as explorable evidence rather than inventing fresh achievements.
- **Birth stop:** the September 9 request supplies 1997 and authorizes the baby photograph; an earlier correction identifies Mansoura rather than Saudi Arabia. No need to ask for the year again. Exact date and additional biographical detail must not be invented.
- **Books:** “The Writer” has been added as a third title. The original phrase was “The Alchemist and farm animal, and - the writer.” It may mean display each book's author. Treat this as unresolved interpretation before changing content, not a verified favorite.
- **Countries:** current reach flags exclude Germany, although Guardy is explicitly German; the prose now says seven countries. Reconcile client geography, employer geography and residence with the owner-backed sources. Do not automatically replace seven with eight.
- **Claims:** the provenance ledger is still largely a milestone 4 snapshot. Its existence test does not establish source accuracy, and the admin's numeric check misses figures embedded in strings such as `5+` or `50% retention lift`.
- **Arabic:** fields and shaping support exist, but the old AR review page is not a current content snapshot and a native editorial review remains outstanding.

## Admin and backend

| ID | Finding and evidence | Milestone |
|---|---|---|
| A-F1 | `admin.js` iterates existing object keys and clones list shapes; it cannot create a reusable arbitrary link/component schema | R3 |
| A-F2 | `open(name)` replaces `live` and `draft` when tabs change without preserving or warning about unsaved edits | R3 |
| A-F3 | Publish already sends only the selected file, despite the global-looking toolbar. The real gap is visible per-page saves, retained drafts and mandatory change confirmation | R3 |
| A-F4 | Image controls are selected by a regex on the final key. `portrait.src`, evidence `src`, and the absent app screenshot fields do not form a reliable upload UI | R3 |
| A-F5 | Fields are often labeled with a visual `<label>` not associated with an input ID. There is no application preview pane | R3 |
| A-F6 | Worker publishing checks JSON syntax and a top-level object, not the Dart schema. Invalid shapes can be accepted and then silently rejected by the app | R1/R3 |
| A-F7 | Numeric provenance is prompted only in the browser and is optional at the Worker; there is no revision-conflict protection or publication/HTML parity | R1/R3 |
| A-F8 | Auth is a separate bearer token, not the session-cookie design described in the old spec. The panel persists it in `sessionStorage`; there is no in-panel rotation or explicit logout control | R3 |
| A-F9 | Failed login counting uses a shared hourly key; a series of failures can also block the correct token | R3 auth review |
| A-F10 | No theme/font/pattern controls or analytics homepage | R8 |
| A-F11 | Analytics client has no endpoint in the release build. `aggregateSnapshot` reads counters; it does not mean the site currently collects the requested data | R8 |

An analytics dashboard must distinguish no data, disabled collection and real zero values. Daily rotating identifiers cannot produce deduplicated weekly/monthly people by summing daily unique counts. Existing events also need inspection before promising clicks broken down by exact target. No collection is enabled by this audit. Existing privacy constraints remain binding.

Subscriber email is out of scope. The handover also calls the daily digest cancelled, but the original cancellation only mentions subscriptions. Leave the digest dormant and explicitly unresolved; do not send messages or set up an email service from that ambiguous record.

## Game

`AscentWorld` has static, cracked and moving ledges; Space/tap initiates a jump while grounded, wall contact can boost vertical velocity, and a floor rises with level. The implementation is not missing all mechanics.

What is missing is the requested feel and progression: horizontal momentum, forgiving jump timing, held-height control, readable landing recovery, meaningful combo/reward feedback and levels that change their challenge/composition. A ring after a wall kick is feedback, not a reward loop. The figure currently reads as a scarab, not the requested Egyptian stick person with a gold headpiece.

The old game document's continuous bounce and CV-unlock concept have been superseded by owner messages. Do not restore those accidentally. The recommended control interpretation is manual Space/tap with elastic animation and forgiving timing; the owner was asked to confirm manual versus automatic bounce. Game facts and career copy must remain outside the reward system.

## What is worth keeping

The content models and fallback behavior, projection/coastline data, pointer-capability abstraction, reduced-motion infrastructure, local font assets, existing Worker/media plumbing, real Medium relay, provenance practice and focused validation tests are useful foundations. The four verification commands remain required while Flutter is in the repository.

The handover's description of all tests as spelling checks is too broad. Worker tests exercise authentication, media validation and data boundaries; content and geometry tests check actual rules. Some tests do encode incidental strings/counts and some goldens historically had no fonts. Add behavior and real-browser acceptance where those gaps matter; do not discard the suite.

Baseline command results and any remaining verification limits are recorded in the [session worklog](worklog/2026-09-11-01-reinnovation-audit.md).
