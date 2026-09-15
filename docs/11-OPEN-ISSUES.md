# Open issues

> September 15 account restoration: the owner reversed the move to lsherbini.
> Active URLs and Worker CORS return to asherbinyy.github.io. The new account’s
> repository is retained until all history is verified on Asherbinyy and deletion
> scope/access is resolved. No custom domain has been selected yet.

**September 13:** owner rejected the broad visual implementation; it has been rolled back to the existing Flutter design. Current scope is content-only. See [handoff](27-CONTINUE-HERE.md). Existing visual/game issues remain open; no design acceptance is implied by prior local tests.


Reviewed 2026-09-11 against source conversations, code and browser captures; updated 2026-09-12 after the owner retained Flutter and admin afc8969 was re-reviewed. [Current admin blockers](25-ADMIN-REREVIEW.md).
Current plan: [Flutter enhancement plan](19-FLUTTER-ENHANCEMENT-PLAN.md).
Evidence: [audit](18-PROJECT-AUDIT.md). Historical issue numbers remain searchable in git and the earlier worklogs; the tables here describe current work.

“Open” means the acceptance condition has not been demonstrated. “Present” in an old backlog is not visual approval. Baseline tests do not close design complaints.

## Public pages and search

| ID | Still true | Closes when | Milestone |
|---|---|---|---|
| SEO-1 | Production Flutter deep links return 404; the rejected separate frontend has been removed | All public routes pass on the production host, including genuine missing-page 404s | F8 |
| SEO-2 | Flutter public routes lack complete initial semantic content; generated CV/Brief are the existing exception | Existing Dart generator produces useful public documents from the same release as Flutter | F8 |
| SEO-3 | Generator now derives current public routes and project IDs; retired routes/build-clock dates removed locally. Production still has the old sitemap | Deploy and verify route responses plus the generated sitemap; add modification dates only from trusted revision metadata | F8, partial local repair |
| SEO-4 | Production shell metadata uses rejected copy, homepage canonical and icon-only social art | Each public route has correct metadata and sharing preview from its content revision | F8/F2 |
| SEO-5 | Admin overrides drift from static HTML and metadata | Publishing coordinates one public content revision across renderers | F8/F1 |
| SEO-6 | Search Console/indexing status has not been inspected | Property is verified, sitemap submitted and actual index/name-query results recorded | F9 |
| SEO-7 | Independent crawlable AR content and reciprocal language alternates remain incomplete | EN/AR documents, alternates and canonical relationships verified across the released site | F8 |

## Visual experience

| ID | Still true | Closes when | Milestone |
|---|---|---|---|
| UI-1 | Minimal ornament rows and instrumentation frame do not meet requested Egyptian realism | Approved Home/entrance visual slice establishes materials, figures, relief composition and motion | F2 |
| UI-2 | Local repair bounds the map by visible content height, adds inline Close and restores narrow-pointer details. Full Journey redesign and physical-device review remain | Verify the repaired build in real browser/device layouts, then deliver F4's timeline, materials and supplied birth stop | F4, partial local repair |
| UI-3 | Intro bottom CC caption removed locally; attribution linked from About. Phone framing still needs review | Responsive camera/composition and revised assets/fallback pass visual review | F2 |
| UI-4 | Home/career composition and copy still need refinement; route transitions are absent | No repeated floating content/overlap; distinct readable hierarchy and deliberate motion | F2 |
| UI-5 | Work has procedural artwork, uneven summaries and no gallery population | Real product presentation and media workflow pass F5 acceptance | F5 |
| UI-6 | Real store/platform logo registry and club crest incomplete | Correct recognizable assets load with useful labels and owner overrides | F1/F5/F6 |
| UI-7 | Local expandable education and grouped skills restored; overall About acceptance and contact refinement remain open | Portrait/research/interests/links pass section-specific visual and interaction review | F6 |
| UI-8 | Writing remains separate and repeats on About; Work/Writing integration absent | Agreed Work tabs and preserved URLs work without repeated full feeds | F5/F6 |
| UI-9 | Off duty galleries and full social-link controls absent | Media affordances appear only where media exists, links work, editor supports them | F1/F6 |
| UI-10 | Résumé interaction needs refinement; empty footer bar and old rail remain | Chrome and résumé composition reviewed with actual content | F2/F6 |
| UI-11 | Current empty/loading primitives retain some retired motifs | Loading/fallback vocabulary matches the selected new design without delaying content | F2 |

## Admin, content and game

| ID | Still true | Closes when | Milestone |
|---|---|---|---|
| ADM-1 | Claude's branch adds schema-driven editor, language tabs and preview frame; real public adapter remains absent | Professional workspace demonstrates editing and preview on real components | F1, under review |
| ADM-2 | Claude afc8969 adds flexible field/media editors and fixes async target capture; Flutter consumers remain absent | Supported fields render correctly through actual Flutter preview and public widgets | F1, integration open |
| ADM-3 | DO content-write transaction passes local runtime concurrency; document/head and complete release reads remain non-atomic (ARR-3); binding disabled in committed config | Atomic read/write regressions pass and an integrated release uses protected storage | F1, merge blocked |
| ADM-4 | afc8969 fixes derived references, truncated media validation and exact-draft preview gate; actual Flutter preview remains absent | End-to-end real Flutter preview and coherent release validation pass | F1/F8, integration open |
| ADM-5 | afc8969 still allows concurrent password admission bypass and stale renewal after logout (ARR-1/2) | Atomic admission and revocation/renewal regressions pass | F1, merge blocked |
| ADM-6 | Extra themes, fonts and per-page patterns absent | Base themes retained and customization previews/publishes/resets correctly | F7 |
| ADM-7 | Claude's branch adds an aggregate dashboard; production client collection remains disabled. Public integration not certified | Dashboard reports available data honestly and any new collection follows explicit consent design | F7, under review |
| CON-1 | App screenshot/gallery assets absent; no screenshot fields in bundled apps | Appropriate real public/supplied media and gallery records are available | F1/F5 |
| CON-2 | Birth year/photo request not implemented | Owner-supplied 1997/Mansoura stop and cleared photo supported without invented exact dates | F4 |
| CON-3 | “The Writer” may be an erroneous third book rather than a request for authors | Original phrase clarified before editing the interests record | F6 |
| CON-4 | Seven-country prose/flags and German Guardy attribution need reconciliation | Owner-backed client/employer/residence scope recorded consistently | F2/F4 |
| CON-5 | Repetitive copy and uneven project summaries; metadata still old | Page-specific editorial pass uses sourced facts consistently | F2/F5/F6 |
| CON-6 | Arabic editorial review and provenance ledger refresh incomplete | Current translations/claims checked against their actual sources; stale review snapshots replaced | F1/F6/F9 |
| CON-7 | Guardy engagement dates, some project details and store destinations absent | Supply/verify only when required; no fabricated dates/links/case studies | F4/F5 |
| CON-8 | Snunu/AZ Exams/Mokaf lack public store URLs; Calendly is null | Remain omitted unless correct owner-approved destinations become available; projects still presented | F5/F6 |
| GAME-1 | Local restoration adds momentum, buffering, coyote time, variable height and landing squash; reward loop and owner playtest remain open | Owner-approved input and playable prototype pass F3 review | F3 |
| GAME-2 | Local Egyptian humanoid replaces the insect; levels still primarily change floor speed | Egyptian humanoid, readable rewards and distinct fair level patterns delivered | F3 |

## Verification and deferred decisions

| ID | Still true | Next action |
|---|---|---|
| QA-1 | Physical iPhone Safari and Android Chrome tests never recorded | F9 real-device matrix; current phone captures are Chrome emulation only |
| QA-2 | Map, backgrounds, cursor and game frame budgets not measured in this audit | Profile real browser/device workloads in F2/F4/F3/F9 |
| QA-3 | Once-per-tab intro, rotation, dynamic browser bars and full accessibility need browser acceptance | Exercise actual interactions, safe areas, large text, keyboard, screen reader and reduced motion |
| QA-4 | Material/Cupertino icon-font build warning remains | Determine which retained dependency needs it; don't silently bundle unwanted UI libraries |
| QA-5 | Historical Wasm deferred-loading limitation and below-threshold decorative hairlines | Re-measure for retained modules/surfaces under the chosen architecture; don't claim runtime savings without evidence |
| DEC-1 | Resolved: retain Flutter as the only interactive UI; separate frontend/artwork removed. Manual Space/tap is the planning default; routes retained | Follow the Flutter plan; playtest game feel before expanding levels |
| DEC-2 | Subscribers cancelled; daily digest cancellation ambiguous in handover | Keep digest dormant; no account setup or email until clarified |
| DEC-3 | Real phone/3D asset access may become necessary | Ask only for the specific missing device/asset/service after preparing a reviewable slice |

Production analytics positive-event and console verification from the older worklogs remains unperformed. Since the release currently disables collection, do not send synthetic production beacons to close that historical row. Test any future collection separately under F7's agreed design.

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
