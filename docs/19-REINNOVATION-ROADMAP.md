# Re-innovation milestones

Current plan, 2026-09-11. This replaces the old milestone queue for new work.
Read the [audit](18-REINNOVATION-AUDIT.md) for code, browser and conversation evidence.
R0 is the audit/documentation session. R1–R9 are **planned**, not implemented or visually approved.

**Owner assignment, 2026-09-11:** Claude owns all admin/Worker work; Codex owns the public app, SEO, design, motion and game. The owner starts Claude separately using the [admin handoff](21-CLAUDE-ADMIN-HANDOFF.md). Work proceeds concurrently in separate worktrees under the [integration contract](20-APP-ADMIN-CONTRACT.md). Claude can begin admin layout/drafts and schema proposals while the public-rendering decision is pending. Final preview/publication integration still depends on R1. Codex can repair confirmed defects in the retained app without treating that as a migration decision or completion of a whole milestone.

## Product direction

Make the portfolio discoverable by the owner's name and make exploring it feel like entering an Egyptian architectural world. Public content must be readable before an animation or app runtime finishes. The game exists for enjoyment. The admin lets the owner manage the whole experience without editing code.

The experience should use a consistent material and lighting language, rather than repeating the same frame on every page. Egyptian identity belongs in the architecture, relief composition, motion and transitions. Professional writing remains plain, specific and supported by the owner's records.

**Design proposal:** an entrance leading into a sequence of distinct spaces. Home is an open entrance hall with a strong architectural composition; Journey is a map table; Work is a product exhibition; Writing is an editorial archive within Work; About combines portrait, interests and research objects. These are internal design references, not mandatory theatrical page names or copy.

Use realistic relief and material detail where it can be seen, with quieter areas behind text. Figures and inscriptions must have identifiable references. Never assemble random phonetic signs or invent an Egyptian translation of the owner's name. A sparse wireframe symbol field is not the requested final art.

Keep Kemet and Deshret as permanent base themes. Their current token values remain unchanged until a concrete visual proposal is reviewed. Extra theme presets and per-page backgrounds are part of R8, not a reason to turn the base experience into unrelated designs. Real media and official logos should retain their recognizable appearance.

## Decisions and assumptions

| Decision | Current position |
|---|---|
| Public rendering | Recommend semantic HTML pages with CSS/scene enhancements; owner asked whether a frontend migration is acceptable. **Pending**, no framework selected or installed |
| Alternative if Flutter stays | Complete generated HTML at public URLs with correct status and publishing parity; account for two-renderer maintenance |
| Work/Writing | Separate Projects and Writing tabs in one Work experience, based on the original request. Retain existing links through an explicit redirect/deep-link plan |
| About/Courtyard | Recommend Off duty in About with a game entry that opens a focused full-screen experience. Owner asked; **pending** |
| Game input | Recommend Space/tap manual jumping, momentum, forgiving timing and elastic feedback. Owner asked; **pending**. Do not silently restore auto-bounce |
| Game character | Egyptian humanoid/stick figure with a gold headpiece, as requested in this session |
| Real logos | Already requested explicitly. Implement recognizable assets; no repeat approval needed |
| Intro | Automatic entrance, no visible Enter/Skip choice per the original request. Retain Escape and non-motion/failed-load routes to usable content |
| Bottom CC caption | Remove from the intended entrance composition by using original/CC0 entrance assets; retain source records. Current asset remains untouched until replacement |
| Subscriber feature | Cancelled; excluded |
| Daily digest | Handover says cancelled; original cancellation only names subscriptions. Dormant, not assumed approved for implementation |
| Analytics | Requested dashboard is in scope. Collection remains disabled until a concrete consent/data design is agreed; no fake live statistics |
| Content changes | Editing and rewriting are requested, but new facts, translations and metrics cannot be fabricated. Resolve the book-author interpretation and country scope before dependent edits |

These are decisions for the relevant milestone, not a request for the owner to answer every possible implementation question up front. Missing app media should be researched using real public product sources where available; ask for an owner asset only when it cannot be obtained appropriately. Stock or generated art must not masquerade as a screenshot of a real app.

## Milestone map

| Milestone | Deliverable | Depends on | State |
|---|---|---|---|
| R0 | Audit, original-request recovery, corrected docs and concise README | — | This session; verification in worklog |
| R1 | SEO and a consistent public publishing foundation | Rendering decision | Planned |
| R2 | Visual system, home and entrance proof | R1 | Planned |
| R3 | Professional admin, content components, preview and media | R1; R2 component contract | Planned |
| R4 | Journey and timeline in one view | R2, R3 | Planned |
| R5 | Projects, galleries and Writing | R2, R3 | Planned |
| R6 | About, education, Off duty and quick résumé | R2, R3; navigation decision | Planned |
| R7 | Rebuilt game feel, character, rewards and levels | R2; input decision | Planned |
| R8 | Theme/font/pattern customization and honest analytics | R3; collection decision | Planned |
| R9 | Device, accessibility, performance and search release checks | R1–R8 | Planned |

Each lane uses its own phase branch and worktree, starting with `phase/reinnovation-admin` for Claude and `phase/reinnovation-app` for Codex after the shared R0 checkpoint. Work is delivered in coherent milestone increments within each lane. A screenshot alone cannot pass an interaction milestone; a test suite alone cannot pass a visual milestone. Review the rendered result before extending the design to the next section.

## R0 — Audit and recovery

**Deliver:** inspect the repository and source conversations; examine the four original annotated screenshots; capture the current public pages and a local admin fixture; identify SEO, design, content and publishing failures; maintain a single new milestone queue.

**Acceptance:** findings distinguish code inspection, live browser observation, local fixtures and untested physical devices. README describes the current system concisely. Old docs clearly identify superseded instructions. No application change, published content update, merge or deployment is implied by finishing the audit.

## R1 — Search visibility and publishing foundation

**Outcome:** a direct link is a real, useful document, and the content the owner publishes is the same content that search engines and visitors receive.

**Implementation scope:** `web/index.html`, `tool/generate_static.dart`, route/metadata definitions, content publishing and validation in `worker/src/index.js`, and CI. If migration is approved, establish a dedicated public-frontend directory and document the selected toolchain before replacing route ownership. Keep the existing app operational while a single page proves the approach.

Tasks:

- Choose the HTML rendering approach and a single content-revision contract. Existing Worker/KV and bundled fallback remain useful; do not add a second CMS without a concrete need.
- Prove a Home document and one project URL with semantic headings, links and content returned in the HTTP response. Readable with JavaScript disabled; scene failure leaves the same content available.
- Serve valid public pages with HTTP 200. Return a true 404 for nonexistent pages. Define redirects for retired URLs, including `/signal`, and preserve shared project links. If the host cannot return the required redirects, propose a host change rather than quietly accepting fake redirects.
- Generate route-specific titles, descriptions, canonical URLs and social cards from the same revision. Use the current owner-supplied English/Arabic name; add aliases only when supplied or explicitly verified as the owner's.
- Use appropriate Person/site/profile metadata where supported by the visible page. No invented awards, review stars or keyword stuffing.
- Replace the sitemap's retired paths; include canonical public project pages and meaningful content-modification dates. Keep admin and console out of indexing.
- Give Arabic content a crawlable URL/alternate-language strategy. Preserve EN/AR navigation, RTL and canonical relationships without duplicating an English body under an Arabic URL.
- Decide whether publishing means a build-and-release or server-rendered revision change. In either case, do not show “Published” before the public HTML and interactive content use that revision. Expose validation/build failures and preserve the last successful release.
- Add content-schema and revision checks at the publish boundary; validate URLs and references. Draft preview must not require publishing.
- Prepare Search Console verification and sitemap submission steps. Do not create a new tracking dependency for Search Console. Ask for property access/verification only when that concrete setup is ready.

**Review artifact:** the actual HTML response, disabled-JavaScript view, a status/canonical table for all existing routes, and an end-to-end draft → preview → published-revision example in a local/test environment.

**Acceptance:** no public route relies on `404.html` for a successful response; basic content and links exist without WebGL/Flutter; metadata and HTML agree with published content; no analytics is enabled; old links have a documented outcome. Ranking is measured after launch, never promised.

## R2 — Visual system, Home and entrance

**Outcome:** establish a convincing world in one finished section before copying visual decisions across the site.

**Implementation scope:** design/motif/animation specs and tokens, shared chrome, Home/hero/wall, `web/intro/`, asset records, and their equivalent modules if R1 changes the frontend. Token changes require a concrete reviewed proposal; no SDK upgrade is part of this milestone.

Tasks:

- Assemble a small reference set with source/license records for stone relief, architectural proportion, figures, pigment and lighting. Distinguish historically sourced inscriptions from invented scenic artwork.
- Produce two compositions for the same real Home content. Review them at laptop and phone sizes, with actual typography. Select one before rebuilding all pages.
- Build the selected composition as a working vertical slice: readable identity and actions, one substantial environmental feature, an intentional scroll transition into career evidence, and a settled reduced-motion version.
- Replace the thin random ornament rows with composed relief/figure panels. Keep readable content clear at rest and during scrolling. No duplicate floating role/company block on top of the career copy.
- Rework the introduction and typography hierarchy. Avoid the repeated name and repeated years/master's statements. Keep name recording as an obvious labeled action; make its asset editable in R3.
- Build a shared real-logo registry and clear interaction/focus styles. Preserve the useful brazier idea, improve its legibility, and give the résumé action a readable label and purposeful transition.
- Define motion by action: material reveal on entry, short depth response on hover/focus, layout continuity on selection, interruption and reversal on back/close. Avoid using one fade/scale effect everywhere.
- For the intro, fit the entire entrance/guardian composition to scene bounds at each viewport; use realistic material scale, lighting and camera travel. Connect its final frame to the Home composition. No stranded overlay if scene assets fail.
- Replace the entrance asset/caption dependency so no CC line occupies the bottom of the scene. Keep license/source records away from the staging copy. Do not merely delete required records while retaining the old asset.
- Decide the small-screen scene/fallback explicitly, including 320–375px widths; do not silently disable the design below an arbitrary cutoff.
- Keep background motion subtle, pause it off-screen/on tab blur, and provide static alternatives. No sound on page entry. Do not delay readable content to complete a cinematic.

**Review artifact:** a runnable Home/intro slice plus screenshots of dark/light, desktop/phone and reduced motion; a short interaction recording; asset register and motion states.

**Acceptance:** the owner approves the rendered direction; identity and primary actions are readable in the first view; no overlapping text/art; no bottom CC caption in the revised scene; real-browser measurement records initial load and motion cost. A generated mood board alone does not pass.

## R3 — Admin as an editing workspace

**Outcome:** the owner can change a page, see exactly what changes, and publish it reliably.

**Implementation scope:** split `worker/src/admin.js` into maintainable UI modules as required; Worker content/media/auth endpoints; shared schemas and preview adapters; site content consumers; `15-ADMIN-AND-MEDIA.md` and the schema docs.

Desktop composition: persistent section navigation, editor in the middle, live preview on the right, and a visible save/review area for the current page. Use “Sherbini's Portfolio” for the interface, not Nocturne. Compact item lists expand into editing panels; avoid giant forms around a single scalar value.

Tasks:

- Define reusable content components with stable IDs, types, order, optional fields and validation. Arbitrary fields must render meaningfully on the site, not just survive as unused JSON keys.
- Replace fixed contacts with editable links: label, URL, order, domain-detected logo, optional icon override, and shared fallback. Support social/fun links and support links without inventing account URLs.
- Allow creation, editing, reordering and removal for stats, country entries, journey stops, projects, education evidence, interests and supported page sections. Preserve existing data during migration and reject broken references.
- Provide vertically stacked EN/AR language tabs with a single clear field context. The Arabic editor and preview use RTL; switching language preserves both drafts.
- Live preview uses the real public components and the current draft. Selecting an editor section scrolls/highlights the corresponding preview section. Support desktop/phone previews and all content types, not just text.
- If a cross-origin preview is necessary, define an allowlisted, versioned message protocol; never send admin credentials to the preview.
- Maintain independent page drafts. Switching pages, reordering a list or changing an input type cannot silently discard work. Warn before navigation if unsaved changes cannot be restored.
- Page-specific save opens a structured before/after confirmation. Cancel changes nothing live. Duplicate submit and stale revision conflicts are handled. Distinguish saving a draft from publishing.
- Build a media library and real per-field media controls: image upload, aspect/crop metadata, alt text, reorderable project images/videos, featured image, evidence attachments and interest galleries. Show upload progress, failure and retry.
- Name audio needs its own validated upload/player path; an image-only endpoint cannot accept it. Do not accept arbitrary active files merely to add audio.
- Keep video URL embedding as the existing default, with click-to-load playback. State current hosting constraints; direct video hosting is a separate decision if required.
- Enforce schema validation and provenance at the server, including claims written as strings. Record revision, change source and publication state. No “saved” state for content the public parser discards.
- Add change-password and logout flows without exposing a Cloudflare management credential in the browser. Re-authenticate sensitive actions, handle stale sessions, and review the global login-lockout behavior.

**Review artifact:** demonstrate changing a link, adding a stat, editing a journey stop, uploading media, switching EN/AR, switching pages with a draft, cancelling publication, then publishing a valid revision and withdrawing it in a test environment.

**Acceptance:** preview matches the site, every supported field has a consumer, edits survive normal navigation, a cancelled review makes no production change, invalid content/claims are rejected, unauthorized writes remain blocked, and HTML/interactive content share the published revision. All verification uses isolated data until publication is authorized.

## R4 — Journey in one view

**Outcome:** map and timeline are visible together before any selection; selecting a stop reveals its story without losing orientation.

**Implementation scope:** current Signal/Journey screen, propagation map, scrubber, detail surface, platform layout service and journey content/schema/editor.

Tasks:

- Reserve the heading/navigation/timeline space first, then constrain map height to the remaining viewport. Keep map proportions within that area instead of using width alone to determine height.
- Desktop initial state: a bounded wide map and a readable timeline underneath. On selection, animate the map into its narrower state and reveal details on the right. Close reverses the layout; subsequent selections update details without reopening the whole scene.
- Phone/tablet: keep a recognizable map and the active timeline control together. Use a compact scrolling/stepping timeline when all years cannot fit; never shrink text/targets until they become unusable. A detail sheet has readable height, safe-area padding, consistent surface, dismissal and preserved selection.
- At very short landscape viewports or large text zoom, prioritize the timeline and selected content with a compact map; allow scrolling rather than clipping. “Same view” applies to map plus the timeline control, not every date label and all detail text simultaneously.
- Improve papyrus material and route reveal without losing legible coastlines. Reduce marker bulk and retain keyboard navigation, pan/zoom and touch behavior.
- Add the supplied 1997 birth stop and cleared baby photo, with year-level precision if that is all the source provides. Associate apps with their stops and show real linked names. Preserve overlapping roles and dates intelligibly.
- Keep technology-list chips removed; use the contribution and linked evidence.

**Review artifact:** initial/selected/closed states at 1440×900, 1366×768, tablet, 390×844, 320px-wide phone and short landscape; both locales, themes, reduced motion and larger text.

**Acceptance:** initial timeline is visible alongside the map at normal target sizes; details never clip; desktop selection/close animates continuously; sheet and keyboard behavior are operable; every stop is editable and has a source. Verify dynamic browser bars on physical phones during R9.

## R5 — Work, galleries and Writing

**Outcome:** visitors see actual products, understand one useful fact quickly, and can explore the supporting media.

**Implementation scope:** Work/Writing navigation, cards and detail routes, shared gallery/media components, real logos, RSS/cache behavior, project schema/admin and metadata.

Tasks:

- Place Projects and Writing in one Work experience with shareable tab state and preserved legacy URLs. Avoid duplicating the full article grid on About.
- Lead with selected work; keep Tripster/MiNextStep prominent using existing owner preferences. Replace count-led/florid copy with concise descriptions.
- Apply one short card-summary strategy consistently. Project detail can separately show product context, personal contribution and evidence. No fabricated metrics to fill sparse projects.
- Use real project screenshots/product imagery. Where unavailable, label artwork honestly and record the missing media; do not turn a generic image into false product evidence.
- Card hover/focus gives a restrained preview; activation opens a media-rich detail view with a real URL. On touch, one deliberate activation opens it. Hover must not trap scrolling or launch media unexpectedly.
- Build image/video galleries with a selected feature image, gallery navigation, device frames where useful, close/back focus restoration and an accessible media list. Support downloads for assets the owner actually offers; verify browser behavior rather than promising forced cross-origin download.
- Use real Apple/Google Play/pub.dev marks with text or accessible names. Absence of a public listing is not a reason to downgrade the project or show a dead action.
- Keep Medium automatic, preserving original titles/dates and real covers. Show an explicit destination, sensible cached/empty behavior and a path to more writing. Do not build a manual article editor for the RSS feed.

**Acceptance:** every card opens its intended detail/destination; featured media matches admin selection; failed/absent media has a designed and honest state; downloads/video/back/keyboard/touch work; public project HTML contains the same content and links.

## R6 — About, education, Off duty and résumé

**Outcome:** About introduces the person; education is evidence worth exploring; the résumé is fast and useful.

**Implementation scope:** About, education/evidence, interests, links, quick résumé/Brief/CV presentation and their admin controls.

Tasks:

- Compose the portrait with a short personal introduction and clear actions. Avoid repeating the Home pitch, country count and qualification verbatim.
- Present the dissertation, dashboard/poster, robotics and smart-tank work as a curated set of research/achievement objects. Let the reader open evidence and details. Keep the full academic record in the data and CV.
- Use the actual supplied project scope and marks. Reconcile content issues in the audit before rewriting affected statements; do not invent research conclusions, competition names or missing dates.
- Bring Off duty into the agreed navigation arrangement. Preserve the successful idea of small interactions, improving the book, controller, football/net, padel and television scenes for legibility.
- Use the real club crest. Show the supplied favorites with context. Resolve whether “the writer” meant authors before treating it as a third book.
- Interests with media open an indicated gallery; those without media can animate but must not pretend a gallery exists. No mandatory interest feature image.
- Add the editable social/support links with domain-matched icons. Keep destinations owner-supplied and make their clickability obvious.
- Give résumé mode a concise, recognizable label and a purposeful reveal. Show experience, selected work, education and contact with balanced columns, no repeated titles and full-name consistency. Static CV/Brief remain printable, readable and indexable.

**Acceptance:** each section tells something distinct; About's content has a deliberate layout on wide and narrow screens; evidence is explorable; links are recognizable; no dead galleries; résumé and public content share the same revision.

## R7 — The game

**Outcome:** enjoyable first input, satisfying movement and a reason to retry. No CV lessons or work facts in the reward loop.

**Implementation scope:** Ascent world/input/stage/painter/audio or the replacement game module chosen under R1; game configuration and art records. Keep game changes separate from unrelated portfolio refactors.

Tasks:

- First make a playable physics prototype using simple art. Test keyboard and touch before commissioning final animation. Confirm the owner's chosen input model.
- For manual input: directional acceleration/deceleration, bounded air steering, jump buffering, coyote time, held-height control and predictable wall kicks. A landing compression/rebound should look elastic without unexpectedly initiating a full jump.
- Create the requested Egyptian humanoid: readable silhouette, small gold headpiece, clear arms/legs, jump/landing/turning/falling poses. Collision geometry follows playability, not ornamental costume dimensions.
- Add clearly earned feedback: wall-kick bonus, consecutive-landing combo, collectible/reward tally, personal best and restart feedback. Explain rewards in play, without adding a dashboard over the playfield.
- Build distinct level patterns and environments. Start with generous platforms, introduce moving/crumbling patterns separately, then combine them with the rising hazard. Validate reachable gaps and fair recovery; difficulty is more than floor speed.
- Keep score, sound, restart and exit controls readable and compact, clear of the playfield. Space must control the focused game rather than scroll the document. On exit restore page focus and scroll.
- Use short responsive sound effects after a player gesture, with mute. Pause on blur and stop rendering/audio on exit. Reduced motion removes shake/particles/parallax, preserving deliberate play.
- Keep a practice/assistance option discoverable without bloating the default HUD. High-score persistence follows the existing privacy constraints; no leaderboard/data collection is implied.
- Tune by playing complete runs. Record whether a new player can discover steering, jump, wall kick, danger and retry without explanation.

**Review artifact:** a playable movement prototype first; then early/middle/late level recordings and touch/keyboard runs with final character. Avoid claiming the game is fun because collision tests pass.

**Acceptance:** input is responsive, landings feel elastic, rewards are understandable, later levels differ visibly and mechanically, generated paths are reachable, controls don't obscure play, and no portfolio content is required to enjoy it.

## R8 — Customization and analytics

**Outcome:** the owner controls presentation and can inspect real available data without misleading counters.

**Implementation scope:** admin settings/home, theme/font/pattern schemas and consumers, Worker aggregate APIs and any separately agreed consent interface.

Tasks:

- Keep both base themes permanent. Add/create/preview extra presets, per-page pattern settings and a reliable return to defaults. Christmas/tech/Batman are the owner's examples, not pre-approved asset packs or required trademarked artwork.
- Provide bundled font selection per language or both, preserving the current default. Validate Arabic shaping, fallback, load weight and contrast before publishing a preset.
- Centralize token roles so themes don't introduce one-off feature colors. Validate uploaded media/icon formats at their own trust boundary rather than allowing arbitrary executable content.
- Admin homepage: views over week/month/custom range, real available click targets, audience aggregates and last-published status, with clear date/timezone and empty/error states.
- First inventory which analytics events exist and whether there is any current data. Disabled collection must say so to the owner. Do not populate attractive charts with invented traffic.
- Define daily unique counts and date-range interpretation honestly. Daily rotating hashes cannot provide deduplicated monthly users. Do not add identifiers to make a chart possible without an explicit privacy decision.
- Any new viewer collection must have the agreed consent/withdrawal behavior and test coverage before enabling it. Existing no-collection behavior is retained until then.
- Do not implement subscriptions. Leave the separate digest dormant until its ambiguity is resolved; no automated email is sent as part of a visual dashboard demonstration.

**Acceptance:** changes preview/publish/reset correctly in both languages; themes remain legible and base themes cannot be deleted; analytics labels reflect the actual event/count model; disabled collection remains silent on the public site.

## R9 — Release evidence

**Outcome:** the redesigned site is demonstrated, measured and ready to publish; outstanding limits are explicit.

Tasks:

- Exercise cold/warm loads, direct URLs, browser back/forward, EN/AR, both base themes, large text, keyboard, reduced motion, scene/media failures and remote-content outages.
- Test Chrome and Safari on desktop, Android Chrome and iPhone Safari on physical devices or a connected real-device service. Emulator screenshots must be labeled. Include viewport bar changes, safe areas, rotation and touch gestures.
- Profile scene, map, game and background work on representative hardware. Measure actual loading and interaction responsiveness on a throttled connection; optimize the measured bottleneck, not an imagined package count.
- Run Lighthouse/accessibility checks across public content routes and inspect actual semantic HTML, heading order, alternate links, status codes, canonical URLs, structured data and sharing images.
- Verify admin auth, draft retention, conflict handling, media failures and publication consistency in isolated test data. Confirm old sessions are handled as specified after password rotation.
- Submit the sitemap and request indexing through the verified Search Console property when authorized and configured. Record actual property/indexing results, and schedule a later name-query review; indexing is not instantaneous.
- Rewrite final docs around the shipped system, close only evidenced issue rows, and create a release worklog. Run the four FVM checks while Flutter is retained, plus the public-frontend/Worker checks for the chosen architecture.

**Acceptance:** a device/browser matrix with actual results, visual sign-off for every section, passing checks, no undisclosed placeholders and a reviewable release. Merging/deploying is a separate explicit action, not a side effect of the audit.

## Original-request coverage

The IDs below preserve the old backlog even where its “shipped” label overstated fulfillment. “Present” means implementation was observed, not owner acceptance. Detailed findings are in the audit; this is the work mapping so requests do not disappear between sessions.

| Old ID | Requirement / current state | New milestone |
|---|---|---|
| A1 | Professional desktop admin: open | R3 |
| A2 | Free hosting explanation: documented with current provider links; stay within quotas | R0/R3 |
| A3 | README admin address/access: present, rewritten concisely | R0 |
| A4 | Password change inside panel: open | R3 |
| A5 | Flexible links and arbitrary supported fields: open | R3 |
| A6 | Stacked EN/AR tabs: open | R3 |
| A7 | Live section preview on right: open | R3 |
| A8 | Extra themes, permanent base themes, per-page patterns: open | R8 |
| A9 | Per-language/both font choice and default: open | R8 |
| A10 | Analytics home, ranges, audience/clicks: open; collection disabled | R8 |
| A11 | Flexible social/support links, domain icons and overrides: open | R3/R6 |
| A12 | All site changes reflected in admin: ongoing acceptance requirement | R3–R8 |
| A13 | Remove Nocturne from admin: open | R3 |
| A14 | Per-page save and confirm changes: selected-file publish exists; requested workflow open | R3 |
| A15 | Compact/collapsible grid instead of tall sparse forms: open | R3 |
| B1 | Home naming and route: present | R2 regression check |
| B2 | Name audio as obvious action: recording present; affordance to improve | R2/R3 |
| B3 | Rule under name removed: present | R2 regression check |
| B4 | Greeting, consistent name, no unverifiable cartouche: partly present; quality open | R2 |
| B5 | Concise personable hero copy: changed, still requires editorial review | R2 |
| B6 | Commercial experience/MSc and country flags: present; country scope needs reconciliation | R2 |
| B7 | Editable/new stats and countries: existing fields editable, flexible authoring incomplete | R3 |
| B8 | Floating wall label must add different information and avoid overlap: partly changed | R2 |
| B9 | Convincing organic reliefs/figures: open | R2 |
| B10 | Desktop ornament line/composition too wide: open | R2 |
| B11 | Journey name present; 1997 birth/photo absent | R4 |
| B12 | Every journey stop editable including new stop types/media | R3/R4 |
| B13 | Papyrus ground present; finish material/reveal quality | R4 |
| B14 | Remove generic technology chips: present | R4 regression check |
| B15 | Named linked apps and detail views: present; gallery/media incomplete | R4/R5 |
| B16 | Timeline controls aligned: improved; responsive acceptance still required | R4 |
| B17 | Lighter map marker: changed; current visual review still required | R4 |
| B18 | Wide map then shrink: present; latest request adds viewport-height/timeline constraint | R4 |
| B19 | Phone detail sheet styling: changed; physical-device acceptance open | R4/R9 |
| B20 | Work heading copy: changed; current count-led wording still weak | R5 |
| B21 | Store icons/no empty-store message: message removed; drawn marks rejected | R5 |
| B22 | One consistent useful fact per project: open | R5 |
| B23 | Per-app gallery and feature selection from admin: open | R3/R5 |
| B24 | Category overlay: present; visual treatment revisited with real media | R5 |
| B25 | Writing within Work as separate tab: open | R5 |
| B26 | Article title/rounded card/read action: present and browser-observed | R5 integration |
| B27 | About text differs from Home: present; still repetitive/weak | R6 |
| B28 | About/education interaction and redesign: open | R6 |
| B29 | Empty right side, recognizable contact actions and more-writing path: open | R6 |
| B30 | Remove theatrical tomb-wall intro to fun area: present | R6 |
| B31 | Game dynamics/progression: partial implementation, owner rejects feel | R7 |
| B32 | Merge game/Off duty with About: proposed, owner answer pending | R6/R7 |
| B33 | Interest scenes/favorites: partly present; author interpretation and crest incomplete | R6 |
| B34 | Open interest media only when it exists, show affordance: open | R3/R6 |
| B35 | Brazier toggle present; résumé interaction still needs design | R2/R6 |
| B36 | Résumé columns/name/title repetition: partly improved; editorial/visual review open | R6 |
| B37 | Convincing figures/entrance; remove bottom caption: open | R2 |
| B38 | Phone intro too close: reproduced in captured framing | R2 |
| C1 | Real desktop/browser/device verification: audit adds Chrome evidence, physical phones still open | R9 |

Additional requests from U1–U8 that the short backlog underrepresented:

| Request | New milestone |
|---|---|
| Search by owner's name; SEO as leading priority | R1/R9 |
| Shared Egyptian spatial system, sourced reliefs, depth, lighting and route motion | R2 and each page milestone |
| Consistent naming, distinct page narratives, no generic skills/CV repetition | R2/R5/R6 |
| Russia via Tripster/Ar++; accurate MiNextStep/freelance periods and overlapping work | R4 content check |
| Prominent MiNextStep even without a listing | R5 |
| Galleries, videos, hover/click opening, close and sample downloads | R3/R5 |
| Dissertation, robotics, smart-tank evidence; supplied grades only | R6 |
| Real links/logos for contact platforms and club | R3/R5/R6 |
| Gold-headpiece Egyptian humanoid, springy jump feel, stronger wall reward, distinct later levels | R7 |
| Name recording editable from admin | R3 |
| No CV-related game rewards, no subscriber feature | R7 / excluded |
| Daily digest status distinct from cancelled subscriptions | R8 unresolved, dormant |
| Four annotated screenshots and latest map/timeline layout requirement | R2/R4/R6 |
| Concise README with no stale concept, missing screenshot or promotional filler | R0 |

## Completion protocol

For every milestone record: source request IDs, exact delivered behaviors, changed files, rendered review artifact, checks actually run, unresolved items and the next milestone. Move issue rows to closed only when their acceptance condition is demonstrated. Preserve owner corrections as decisions instead of asking the same questions again.

Before the next implementation, settle R1's public-rendering choice. The recommended first deliverable is the semantic Home/project pair with a shared publication revision, followed by the Home/intro visual proof in R2. This prevents a second complete redesign from being built on the same indexing and publishing problems.
