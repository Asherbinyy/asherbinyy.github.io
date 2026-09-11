# Open issues

Reviewed 2026-09-11 against source conversations, code and browser captures.
Current plan: [Re-innovation milestones](19-REINNOVATION-ROADMAP.md).
Evidence: [audit](18-REINNOVATION-AUDIT.md). Historical issue numbers remain searchable in git and the earlier worklogs; the tables here describe current work.

“Open” means the acceptance condition has not been demonstrated. “Present” in an old backlog is not visual approval. Baseline tests do not close design complaints.

## Public pages and search

| ID | Still true | Closes when | Milestone |
|---|---|---|---|
| SEO-1 | Public Flutter deep links return 404 while drawing working pages | Valid public URLs return correct successful responses with readable content; missing URLs return a real 404 | R1 |
| SEO-2 | Home/app HTML lacks the main portfolio content; generated CV/Brief cover only part of the site | Semantic public documents work without the app/scene runtime | R1 |
| SEO-3 | Sitemap includes retired `/signal` and `/privacy`; project URLs and Journey are absent | Sitemap matches canonical public routes and content-change dates | R1 |
| SEO-4 | Shell metadata uses rejected copy, homepage canonical and icon-only social art | Each public route has correct metadata and sharing preview from its content revision | R1/R2 |
| SEO-5 | Admin overrides drift from static HTML and metadata | Publishing coordinates one public content revision across renderers | R1/R3 |
| SEO-6 | Search Console/indexing status has not been inspected | Property is verified, sitemap submitted and actual index/name-query results recorded | R9 |
| SEO-7 | No independent Arabic crawlable route/alternate-link strategy | EN/AR documents, alternates and canonical relationships verified | R1 |

## Visual experience

| ID | Still true | Closes when | Milestone |
|---|---|---|---|
| UI-1 | Minimal ornament rows and instrumentation frame do not meet requested Egyptian realism | Approved Home/entrance visual slice establishes materials, figures, relief composition and motion | R2 |
| UI-2 | Map pushes timeline below desktop viewport before selection | Initial map plus timeline fit the supported viewport layouts; selected/closed behavior is verified | R4 |
| UI-3 | Phone intro is tightly cropped; figures absent in captured view; CC caption occupies bottom | Responsive camera/composition and revised assets/fallback pass visual review | R2 |
| UI-4 | Home/career composition and copy still need refinement; route transitions are absent | No repeated floating content/overlap; distinct readable hierarchy and deliberate motion | R2 |
| UI-5 | Work has procedural artwork, uneven summaries and no gallery population | Real product presentation and media workflow pass R5 acceptance | R5 |
| UI-6 | Real store/platform logo registry and club crest incomplete | Correct recognizable assets load with useful labels and owner overrides | R3/R5/R6 |
| UI-7 | About, education and contact presentation remain weak | Portrait/research/interests/links pass section-specific visual and interaction review | R6 |
| UI-8 | Writing remains separate and repeats on About; Work/Writing integration absent | Agreed Work tabs and preserved URLs work without repeated full feeds | R5/R6 |
| UI-9 | Off duty galleries and full social-link controls absent | Media affordances appear only where media exists, links work, editor supports them | R3/R6 |
| UI-10 | Résumé interaction needs refinement; empty footer bar and old rail remain | Chrome and résumé composition reviewed with actual content | R2/R6 |
| UI-11 | Current empty/loading primitives retain some retired motifs | Loading/fallback vocabulary matches the selected new design without delaying content | R2 |

## Admin, content and game

| ID | Still true | Closes when | Milestone |
|---|---|---|---|
| ADM-1 | Narrow JSON-shaped forms; Nocturne branding; no live preview or language tabs | Professional workspace demonstrates editing and preview on real components | R3 |
| ADM-2 | Fixed object fields, missing links/components and heuristic upload controls | Supported flexible content/media authoring reaches every corresponding site surface | R3 |
| ADM-3 | Switching tabs discards draft; no enforced before/after publish confirmation or revision conflict check | Retained drafts, page save/review/cancel and stale-edit handling verified | R3 |
| ADM-4 | JSON shape/provenance validation incomplete on server | Invalid schema/references/unsupported claims rejected before public revision changes | R1/R3 |
| ADM-5 | No in-panel password change/logout; shared failed-login counter | Auth lifecycle and lockout behavior reviewed and verified in isolated data | R3 |
| ADM-6 | Extra themes, fonts and per-page patterns absent | Base themes retained and customization previews/publishes/resets correctly | R8 |
| ADM-7 | Analytics home absent; production client collection disabled | Dashboard reports available data honestly and any new collection follows explicit consent design | R8 |
| CON-1 | App screenshot/gallery assets absent; no screenshot fields in bundled apps | Appropriate real public/supplied media and gallery records are available | R3/R5 |
| CON-2 | Birth year/photo request not implemented | Owner-supplied 1997/Mansoura stop and cleared photo supported without invented exact dates | R4 |
| CON-3 | “The Writer” may be an erroneous third book rather than a request for authors | Original phrase clarified before editing the interests record | R6 |
| CON-4 | Seven-country prose/flags and German Guardy attribution need reconciliation | Owner-backed client/employer/residence scope recorded consistently | R2/R4 |
| CON-5 | Repetitive copy and uneven project summaries; metadata still old | Page-specific editorial pass uses sourced facts consistently | R2/R5/R6 |
| CON-6 | Arabic editorial review and provenance ledger refresh incomplete | Current translations/claims checked against their actual sources; stale review snapshots replaced | R3/R6/R9 |
| CON-7 | Guardy engagement dates, some project details and store destinations absent | Supply/verify only when required; no fabricated dates/links/case studies | R4/R5 |
| CON-8 | Snunu/AZ Exams/Mokaf lack public store URLs; Calendly is null | Remain omitted unless correct owner-approved destinations become available; projects still presented | R5/R6 |
| GAME-1 | Current manual jump/landing feel rejected; momentum/buffering/reward loop incomplete | Owner-approved input and playable prototype pass R7 review | R7 |
| GAME-2 | Insect-like climber; levels primarily change floor speed | Egyptian humanoid, readable rewards and distinct fair level patterns delivered | R7 |

## Verification and deferred decisions

| ID | Still true | Next action |
|---|---|---|
| QA-1 | Physical iPhone Safari and Android Chrome tests never recorded | R9 real-device matrix; current phone captures are Chrome emulation only |
| QA-2 | Map, backgrounds, cursor and game frame budgets not measured in this audit | Profile real browser/device workloads in R2/R4/R7/R9 |
| QA-3 | Once-per-tab intro, rotation, dynamic browser bars and full accessibility need browser acceptance | Exercise actual interactions, safe areas, large text, keyboard, screen reader and reduced motion |
| QA-4 | Material/Cupertino icon-font build warning remains | Determine which retained dependency needs it; don't silently bundle unwanted UI libraries |
| QA-5 | Historical Wasm deferred-loading limitation and below-threshold decorative hairlines | Re-measure for retained modules/surfaces under the chosen architecture; don't claim runtime savings without evidence |
| DEC-1 | HTML frontend recommendation, About/Courtyard arrangement and game input await owner answers | Resolve before dependent implementation; roadmap records the recommended defaults |
| DEC-2 | Subscribers cancelled; daily digest cancellation ambiguous in handover | Keep digest dormant; no account setup or email until clarified |
| DEC-3 | Real phone/3D asset access may become necessary | Ask only for the specific missing device/asset/service after preparing a reviewable slice |

Production analytics positive-event and console verification from the older worklogs remains unperformed. Since the release currently disables collection, do not send synthetic production beacons to close that historical row. Test any future collection separately under R8's agreed design.

## Closed or corrected by this audit

| Old issue | Evidence / corrected state |
|---|---|
| 0b.10 writing coupled to analytics | `core/net/relay.dart` separates content relay configuration; live Writing rendered six article cards with covers and titles |
| 1.2 / 2.4 missing twelfth app / eleven-app count | Bundled inventory now contains 14 apps; no extra project is required merely to match an obsolete target |
| 1.6 missing Arabic fields / 2.3 English-only stats | Current content has Arabic fields; linguistic review remains CON-6 |
| 1.8 / 1.8b missing PDF | `profile.cvFile` points to the existing bundled CV PDF |
| 1.9 missing portrait | Portrait exists and was observed in the About capture |
| 1.7 Evri empty | Evri is absent from current career content on the owner's prior instruction |
| 1.11 every detail page “not written yet” | App detail fallback exists; richer media/case-study evidence remains open |
| 0d.5 atlas has no papyrus | Papyrus painter is used; quality/layout still open under UI-2 |
| 0e.9 / B18 empty desktop selection column | Initial map uses the width, selecting a stop opens the side panel; viewport-height regression remains UI-2 |
| 0e.24 admin wholly unbuilt/needs original setup | Admin source exists; handover says deployed. Audit does not certify production auth or repeat namespace creation |
| Footer Manchester decision | Current footer has no location/copy; it is an empty reserved bar |
| README missing screenshot/stale instrument explanation | Replaced by concise current setup/admin/status documentation |

The missing session worklogs after September 7 remain a historical gap. This audit records the evidence it found without backdating or fabricating those sessions.
