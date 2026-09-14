# Flutter enhancement plan

> **September 14 ownership transfer:** the owner rejected Codex’s latest visual result and assigned **both public Flutter and all admin/backend work to Claude**. Former Codex-only file restrictions are revoked. Read [the complete handoff and prompt](29-CLAUDE-FULL-PROJECT-HANDOFF.md). Keep the Flutter foundation; no production deployment or destructive reset is implied.


2026-09-12. **Planning checkpoint, not an implemented redesign.** The owner rejected the separate frontend and generated entrance studies. Those files are removed. Flutter remains the only interactive UI. Existing Flutter styling, assets and the measured Journey repair are the starting point.

Claude now owns Flutter, web intro, SEO, motion, game and all Worker/admin implementation. Fix and re-review the [remaining admin defects](25-ADMIN-REREVIEW.md) before integration. Nothing in this plan deploys or merges to `main`.

## Decisions

- Improve the current app section by section; no replacement framework or separate designed public UI. A Flutter widget change will affect both the public app and its eventual real admin preview.
- Keep routes, pinned SDK, existing palette and typography as the baseline. Stored theme IDs remain `nocturne` / `daybreak`; display labels remain Kemet / Deshret. Review concrete token changes in a working slice before applying them throughout the app.
- Keep manual Space/tap jumping as the planning default, following the owner's earlier control request. Improve spring and forgiveness; do not silently restore auto-jumping. Playtesting decides final feel.
- Egyptian identity comes from the existing scene, convincing material scale, sourced relief and spatial transitions. No arbitrary inscription strings or invented ancient translation of the owner's name. Register any new motif with sources in the closed motif inventory before implementation.
- Content and navigation appear promptly. Intro failure cannot strand the visitor. Every animation handles reduced motion, interruption, hidden tabs and input type.
- Admin flexibility means supported components with stable IDs and real Flutter consumers. Saving unused JSON fields does not complete a feature.
- No personal content changes in this planning pass. Later writing uses supplied records and the provenance ledger, including Arabic. Do not invent claims, dates, metrics, translations or account destinations.

## Delivery order

| Phase | Concrete result | Owner | State |
|---|---|---|---|
| F0 | Recovered request inventory and browser baseline | Claude | Audit recorded; rejected frontend removed |
| F1 | Reliable admin and real Flutter draft preview | Claude, both sides | Three remaining review defects; adapter absent |
| F2 | Existing Home, intro and shared motion polished | Claude | Planned; current intro retained |
| F3 | Springy game prototype, then rewards and levels | Claude | Planned; current game retained |
| F4 | Journey selection/timeline continuity | Claude | Viewport repair verified locally; visual/content work open |
| F5 | Work, real media and Writing integration | Codex; Claude editor | Planned |
| F6 | About, education, Off duty and résumé | Codex; Claude editor | Planned |
| F7 | Connected appearance controls and honest dashboard | Claude controls; Codex renderers | Allowlist/public consumers open |
| F8 | Search documents and coordinated release using Flutter | Codex; Claude release endpoints | Sitemap repair local; HTML/release work open |
| F9 | Device, accessibility, performance and release evidence | Codex with owner device access | Physical device checks open |

F1 starts first as requested. F8 contract preparation can happen during F1; it does not put another frontend migration ahead of the Flutter work. Each phase delivers a runnable local build, rendered review artifacts, exact verification and current issue status. Review a small working slice before extending a visual decision across the app.

## F1 — Admin reliability and real Flutter preview

**First gate:** Claude fixes atomic login admission, session revocation/renewal races, and atomic content/revision reads including whole-release snapshots. [Re-review and Claude prompt](25-ADMIN-REREVIEW.md). A disabled Durable Object binding, content migration and provider availability remain operational gates. An unsafe-write warning does not make a release concurrency-safe.

After the corrected SHA passes re-review, integrate on a non-production branch, preserving Journey/sitemap repairs. Run combined Worker/FVM checks and browser flows with fixtures. Deployment remains separate.

**Public areas:** `lib/content/models/`, content providers/repository, browser interop under `lib/core/`, app/chrome widgets and `web/` bootstrap. Use the existing platform abstraction rather than feature-level user-agent logic.

- Implement protocol v1 through validated browser messages and in-memory provider overrides, rendering the same Flutter widgets as the public app. A separately styled preview or HTML attributes on canvas widgets cannot substitute for the actual adapter.
- Check exact origin, source window, channel, version, session and request generation before using payloads. Reject stale drafts/selections after navigation, reorder, language change or reconnect.
- Map `<file>:<path>` to a widget/section registry with stable record IDs internally. Select the closest rendered parent when a leaf has no separate widget. Acknowledge the matching rendered frame, including errors, rather than merely message receipt.
- Preview has no admin credentials, production writes, analytics, persistence, autoplay or intro. Desktop/phone size and EN/AR use the real responsive and RTL app.
- Add compatible consumers for `profile.links[]`, domain icons/overrides, `app.media[]`, `interest.gallery[]` and `profile.nameAudio`. Preserve current contact/screenshot/audio fallbacks until explicit content migration. Editors keep unsupported labels until consumers land.
- Tie every async operation to its original document, stable item and submitted draft. Exercise uploads and publication during navigation, reorder and removal.

**Acceptance:** edit a fixture link/audio/gallery, select its real Flutter section, change language, resize preview, cancel save, submit a stale edit and reload. Preview matches the exact valid draft; invalid/cancelled edits never change the release. A late response cannot label a newer draft published. Include actual admin-to-Flutter browser evidence.

## F2 — Home, intro and shared motion

**Areas:** `web/intro/`, shared chrome, Home/hero/wall widgets, `app/theme/tokens.dart`, design/motif/source docs. Retain the current Three.js pipeline and guardian assets until a reviewed improvement is ready. No SDK/package upgrade is implied.

Record the existing intro on phone/laptop. Fit camera framing to actual scene bounds and safe areas, including rotation and short landscape. Settle camera travel into the Home composition rather than a hard cut. Escape, reduced motion and failed loads reach usable content. No sound on entry.

Build one working proof with current Flutter content: clear identity/actions, stronger hierarchy, one convincing relief treatment and entry-to-career continuity. Remove duplicated visual statements and overlapping career blocks through layout/copy review. Refine limestone depth, figures and inscription scale at actual viewing sizes; keep text backgrounds quiet.

The bottom CC caption should leave the composition only when a documented compliant credit placement or asset replacement is ready. Retain required attribution/license records for assets still used. Original/CC0 replacements can remove that dependency; a generated flat picture is not the requested interactive entrance.

| Trigger | Intended response | Interruption / reduced motion |
|---|---|---|
| Intro settles | Camera and Home controls form a continuous composition | Escape/failure reaches content; static settled scene |
| Route change | Short spatial transition with stable chrome and heading focus | Rapid navigation cancels old transition; immediate layout |
| Hover/focus/press | Subtle depth, gold affordance, faience feedback only | Visible keyboard focus; touch requires no hover |
| Expand/close | Surface changes size/position with continuous selection | Reverse from current progress; preserve scroll/focus |
| Ambient scene | Subtle movement only while visible | Pause hidden/off-screen work; static equivalent |
| Media load/failure | Reserved geometry and restrained reveal/fallback | No layout jump or blocked controls |

Name motion tokens centrally by purpose; measure before choosing final spring/duration values. Do not scatter constants through feature widgets.

**Acceptance:** runnable intro/Home at narrow phone, laptop, both themes, EN/AR, reduced motion, keyboard and failed asset load. Review screenshots plus a recording. No first-view overlap, clipped guardian, unreadable action or forced cinematic delay.

## F3 — Game feel, character and progression

**Areas:** existing simulation, input adapter, painters, level definitions and tests. Inspect physics/render separation first; retain useful mechanics. Deliver three playable increments:

1. **Feel:** immediate manual jump, jump buffering, coyote time, variable height on release, predictable acceleration, squash/stretch and a small visual landing rebound. A rebound must not turn into automatic jumping. Handle held/repeated keys, touch cancel, focus loss and varying frame intervals.
2. **Character/feedback:** requested Egyptian humanoid/stick figure with gold headpiece; readable poses and contact at phone scale. Use short particles/impact response and optional user-enabled sound. Keep collision geometry predictable despite decorative limbs/headpiece. No entry autoplay or required haptics.
3. **Progression:** distinct learnable obstacle patterns, safe introductions, clear finishes, checkpoints, relic collectibles, combo feedback and visible progress. Fast restart and recoverable mistakes; no CV or career-content rewards. Teach controls in the first playable segment.

States: ready → playing → checkpoint/level complete → next level, with explicit pause/failure/restart/exit. Pause simulation/input on hidden tab or blur and resume deliberately. No accounts, tracking, leaderboard or pre-consent score storage.

**Acceptance:** owner plays the feel increment before level expansion. Verify input-to-jump, edge timing, release height, collision fairness, restart and progression with keyboard and touch. Use deterministic simulation checks across frame intervals. Reduced motion removes shake/particles without hiding gameplay cues; exit always works.

## F4 — Journey and timeline

Keep the measured viewport repair and inline Close from `615c6ce`. Map and active timeline control stay visible together. Very short viewports/large text may scroll; never shrink labels merely to show every year.

Desktop selection shrinks the map to the left and reveals information on the right; repeated selection updates details without replaying the entire entrance. Close reverses from current progress. Preserve selection, keyboard focus and scroll. Phone uses a compact map/timeline plus dismissible details respecting browser bars/safe areas.

Refine papyrus, route reveal and marker weight within that bounded layout. Add the supplied 1997/Mansoura stop and cleared photo in a separately recorded content edit, with year precision. Keep linked app names and overlapping roles; no invented dates. Draft stop edits must reach these exact widgets.

**Acceptance:** initial/selected/closing/reselected states on desktop/tablet/phone/short landscape, pan/zoom, keyboard timeline and touch sheet. Review recording and screenshots; emulation does not replace physical-phone checks.

## F5 — Work, galleries and Writing

Use real product media and official store/platform marks in a shared registry. Keep MiNextStep prominent without inventing a store listing. Omit unavailable destinations. Replace generic project art only with useful genuine assets. Give each project one consistent sourced fact and a concise role/contribution description.

Galleries support owner order, alt text, reserved aspect ratios, keyboard/touch controls, close/focus restoration and click-to-load video. Unknown domains get a generic link icon; recognizable official marks retain their proportions.

Plan Projects/Writing tabs within Work while preserving `/writing` and current project URLs. Specify route behavior before navigation edits. Avoid a duplicated full feed on About. Preserve explicit reading actions and useful relay-error states.

**Acceptance:** media-rich and media-less fixture projects, opted-in video, missing listing, long Arabic text, compact cards, browser back navigation; admin reorder/edit reaches the same preview/public widgets.

## F6 — About, education, Off duty and résumé

Give About its own purpose: person, education evidence, interests and contact. Refine portrait placement, education hierarchy and supplied research/coursework artifacts; recorded grades only. Fill layout gaps with better composition rather than fabricated content.

Off duty opens only when meaningful media/content exists and shows an appropriate affordance. Resolve the ambiguous “The Writer” source before editing that record. Preserve the game route and add a contextual entry from About without assuming an unapproved route merge.

Keep CV download clear. Refine quick résumé columns and hierarchy without repeating name/title. Generated CV/Brief joins F8 release consistency. Contact shares F1's registry and owner overrides.

**Acceptance:** evidence opens/closes accessibly, media-less cards are honest, links work, Arabic fits, résumé scales/prints legibly, and every personal claim has provenance.

## F7 — Appearance and dashboard

Codex supplies a versioned allowlist of implemented themes, fonts and patterns; Claude connects selectors, preview/reset and publication. Keep stored IDs `nocturne` / `daybreak`. Unsupported settings report their state instead of silently falling back after an apparent successful save.

Extra presets need reviewed examples using approved pigments/motifs and licensed fonts with Arabic coverage. Pattern intensity cannot undermine contrast. No arbitrary CSS/script injection. Existing dashboard aggregates may show honest no-data states; collection stays disabled. Subscribers remain cancelled; ambiguous daily digest remains dormant.

**Acceptance:** every exposed setting has a real Flutter consumer, previews/publishes/resets consistently, and handles unknown IDs/font failures. No new analytics or pre-consent storage behavior.

## F8 — Search without replacing Flutter

Extend `tool/generate_static.dart`, `web/index.html`, route metadata and release CI. Generate useful semantic headings, content, links and metadata from the same validated JSON as Flutter, extending the existing CV/Brief approach. This is accessible/search-readable output, not a second authored interactive design. Content edits require no manual duplication; new content types need generator coverage/parity checks.

Prove Home and one project first: useful initial HTML with JavaScript disabled; Flutter boots without duplicated visible content; correct names, route-specific title/description/canonical, appropriate structured data and an EN/AR strategy. Do not hide text solely for crawlers. Preserve current routes. Verify host feasibility for successful direct documents and genuine missing-page 404s before implementation.

Publish one immutable complete snapshot. Flutter, generated documents, CV/Brief, metadata and sitemap must share its digest. Independent live overrides cannot silently diverge from static output: implement a release-aware reader with deliberate backward compatibility. Expose `/release.json`; acknowledge publication only after the artifact serves that exact revision. Failed builds preserve the previous successful release. Production dispatch/secrets are separate operational steps.

**Acceptance:** fixture edit → preview → cancel → publish → matching Flutter/HTML digest; stale edit, failed build and rollback tests. Record URL statuses, disabled-JavaScript output, sitemap/canonical/language relationships and social previews. Prepare Search Console verification/submission when the release is ready. Name-search ranking cannot be guaranteed.

## F9 — Device and release evidence

Capture real browser screenshots/recordings for each visual increment. Matrix: both themes, EN/AR, keyboard, screen reader, reduced motion, 200% text, narrow phone, short landscape, tablet, laptop, wide desktop, failed/slow assets and back navigation. Chrome emulation does not certify iPhone Safari or Android Chrome; request specific device access when a concrete build is ready.

Measure startup, intro, route transitions and game frame costs. Pause hidden work and bound media/memory use based on observed results; no invented performance figures. Behavior tests and rendered review both matter.

Run all four FVM checks and relevant Worker/browser regressions for integrated milestones. Record exact results and remaining issues in `11-OPEN-ISSUES.md` and the worklog. Local completion does not deploy or authorize production credentials/bindings/content changes.

## Unresolved content

Country-count scope, ambiguous book-author wording, missing engagement dates and absent store destinations require source confirmation before dependent edits. They do not block reliability, preview architecture or motion prototypes. Real logos, the requested character/headpiece and retaining Flutter are already decided.

## Original-request coverage

Historical request IDs below are retained from the source audit. Their baseline descriptions are not current completion claims; the phase table and open issues govern delivery status.


The IDs below preserve the old backlog even where its “shipped” label overstated fulfillment. “Present” means implementation was observed, not owner acceptance. Detailed findings are in the audit; this is the work mapping so requests do not disappear between sessions.

| Old ID | Requirement / current state | New milestone |
|---|---|---|
| A1 | Professional desktop admin: open | F1 |
| A2 | Free hosting explanation: documented with current provider links; stay within quotas | F0/F1 |
| A3 | README admin address/access: present, rewritten concisely | F0 |
| A4 | Password change inside panel: open | F1 |
| A5 | Flexible links and arbitrary supported fields: open | F1 |
| A6 | Stacked EN/AR tabs: open | F1 |
| A7 | Live section preview on right: open | F1 |
| A8 | Extra themes, permanent base themes, per-page patterns: open | F7 |
| A9 | Per-language/both font choice and default: open | F7 |
| A10 | Analytics home, ranges, audience/clicks: open; collection disabled | F7 |
| A11 | Flexible social/support links, domain icons and overrides: open | F1/F6 |
| A12 | All site changes reflected in admin: ongoing acceptance requirement | F1–F7 |
| A13 | Remove Nocturne from admin: open | F1 |
| A14 | Per-page save and confirm changes: selected-file publish exists; requested workflow open | F1 |
| A15 | Compact/collapsible grid instead of tall sparse forms: open | F1 |
| B1 | Home naming and route: present | F2 regression check |
| B2 | Name audio as obvious action: recording present; affordance to improve | F2/F1 |
| B3 | Rule under name removed: present | F2 regression check |
| B4 | Greeting, consistent name, no unverifiable cartouche: partly present; quality open | F2 |
| B5 | Concise personable hero copy: changed, still requires editorial review | F2 |
| B6 | Commercial experience/MSc and country flags: present; country scope needs reconciliation | F2 |
| B7 | Editable/new stats and countries: existing fields editable, flexible authoring incomplete | F1 |
| B8 | Floating wall label must add different information and avoid overlap: partly changed | F2 |
| B9 | Convincing organic reliefs/figures: open | F2 |
| B10 | Desktop ornament line/composition too wide: open | F2 |
| B11 | Journey name present; 1997 birth/photo absent | F4 |
| B12 | Every journey stop editable including new stop types/media | F1/F4 |
| B13 | Papyrus ground present; finish material/reveal quality | F4 |
| B14 | Remove generic technology chips: present | F4 regression check |
| B15 | Named linked apps and detail views: present; gallery/media incomplete | F4/F5 |
| B16 | Timeline controls aligned: improved; responsive acceptance still required | F4 |
| B17 | Lighter map marker: changed; current visual review still required | F4 |
| B18 | Wide map then shrink: present; latest request adds viewport-height/timeline constraint | F4 |
| B19 | Phone detail sheet styling: changed; physical-device acceptance open | F4/F9 |
| B20 | Work heading copy: changed; current count-led wording still weak | F5 |
| B21 | Store icons/no empty-store message: message removed; drawn marks rejected | F5 |
| B22 | One consistent useful fact per project: open | F5 |
| B23 | Per-app gallery and feature selection from admin: open | F1/F5 |
| B24 | Category overlay: present; visual treatment revisited with real media | F5 |
| B25 | Writing within Work as separate tab: open | F5 |
| B26 | Article title/rounded card/read action: present and browser-observed | F5 integration |
| B27 | About text differs from Home: present; still repetitive/weak | F6 |
| B28 | About/education interaction and redesign: open | F6 |
| B29 | Empty right side, recognizable contact actions and more-writing path: open | F6 |
| B30 | Remove theatrical tomb-wall intro to fun area: present | F6 |
| B31 | Game dynamics/progression: partial implementation, owner rejects feel | F3 |
| B32 | Merge game/Off duty with About: proposed, owner answer pending | F6/F3 |
| B33 | Interest scenes/favorites: partly present; author interpretation and crest incomplete | F6 |
| B34 | Open interest media only when it exists, show affordance: open | F1/F6 |
| B35 | Brazier toggle present; résumé interaction still needs design | F2/F6 |
| B36 | Résumé columns/name/title repetition: partly improved; editorial/visual review open | F6 |
| B37 | Convincing figures/entrance; remove bottom caption: open | F2 |
| B38 | Phone intro too close: reproduced in captured framing | F2 |
| C1 | Real desktop/browser/device verification: audit adds Chrome evidence, physical phones still open | F9 |

Additional requests from U1–U8 that the short backlog underrepresented:

| Request | New milestone |
|---|---|
| Search by owner's name; SEO as leading priority | F8/F9 |
| Shared Egyptian spatial system, sourced reliefs, depth, lighting and route motion | F2 and each page milestone |
| Consistent naming, distinct page narratives, no generic skills/CV repetition | F2/F5/F6 |
| Russia via Tripster/Ar++; accurate MiNextStep/freelance periods and overlapping work | F4 content check |
| Prominent MiNextStep even without a listing | F5 |
| Galleries, videos, hover/click opening, close and sample downloads | F1/F5 |
| Dissertation, robotics, smart-tank evidence; supplied grades only | F6 |
| Real links/logos for contact platforms and club | F1/F5/F6 |
| Gold-headpiece Egyptian humanoid, springy jump feel, stronger wall reward, distinct later levels | F3 |
| Name recording editable from admin | F1 |
| No CV-related game rewards, no subscriber feature | F3 / excluded |
| Daily digest status distinct from cancelled subscriptions | F7 unresolved, dormant |
| Four annotated screenshots and latest map/timeline layout requirement | F2/F4/F6 |
| Concise README with no stale concept, missing screenshot or promotional filler | F0 |
