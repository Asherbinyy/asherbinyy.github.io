# Open Issues — NOCTURNE

Everything known to be incomplete, blocked, or decided-provisionally, in one
place. This is a living register: an agent that closes an item deletes its row
and says so in the worklog; an agent that finds a new one adds it here rather
than burying it in a worklog nobody re-reads.

Worklogs record what happened in a session. **This file records what is still
true.** If the two disagree, this file is the one to fix.

Last reviewed: 2026-09-07, after the Milestone 4 Worker deployment.

---

## 0a. Direction changed on 2026-09-07

The owner replaced the site's concept. "Ground Station" is retired; the identity
is now Egyptian — `00-PROJECT-BRIEF.md` §3 and `12-MOTIF-LIBRARY.md`. Milestones
4, 5 and 6 in `09-ROADMAP.md` carry the work.

Three standing rules changed with it, and an agent working from memory of the
old ones will be wrong:

1. **The amber-only palette rule is gone**, replaced by four pigments each locked to one job — `AGENTS.md` §6, `01-DESIGN-SYSTEM.md` §2. This is not a loosening; a fifth hue is still forbidden and faience may never appear at rest.
2. **Every number now needs a provenance row** in `14-PROVENANCE.md` before it ships.
3. **Motifs are a closed inventory.** Not in `12-MOTIF-LIBRARY.md`, not on the site.

Content and claim gaps are no longer tracked in §1 below. **`14-PROVENANCE.md`
§3 is the authority** on what is needed from the owner; §1 here is kept for the
rows that predate the change and have not yet been folded in.

---

## 0b. Found on 2026-09-07, not yet fixed

| # | Item | Consequence | Fixed by |
|---|---|---|---|
| ~~0b.1~~ | **Closed at planning.** The README now says the aggregate tier writes nothing, and that theme, language and Recruiter Mode persist as user-requested preferences, which PECR exempts. Original text: **"Nothing is stored on the visitor's device."** Theme, language and Recruiter Mode have persisted through `shared_preference_store.dart` since milestone 1. The sentence is about the analytics tier but does not say so, and reads as a claim about the whole site. | A privacy claim that is false as written, on a site whose argument is its privacy posture | 4.1 |
| ~~0b.2~~ | **Closed 4.8.** `SelectionArea` wraps the content column. It deliberately excludes the header, rail and footer so a drag beginning on a control does not become a text drag; three tests hold that boundary in both directions. |
| ~~0b.3~~ | **Closed.** Guardy makes Germany a genuine sixth, and Evri's removal took the UK out of the working count. The five the CV names plus Germany. Original: **"Six countries" overstates the CV**, which names five countries of delivery plus the UK as residence. Guardy would make it genuinely six. | An inflated claim on the hero, the stat panel and `/brief` | 4.1, 4.2 |
| ~~0b.4~~ | **Closed.** The owner confirmed the CV's 15,000+ is current and the LinkedIn entry is stale. The site is unchanged; `14-PROVENANCE.md` §2.2 records it so it is not re-opened. |
| ~~0b.5~~ | **Closed.** The owner chose the CV's "CI Company". The public records still disagree; updating LinkedIn would close it from the other side, which is his call, not an agent's. |
| ~~0b.6~~ | **Closed.** April 2023. Original: **CI Company end date** — CV says 04/2023, LinkedIn says Jul 2023. | A three-month gap across a job boundary | 4.1 |
| ~~0b.7~~ | **Closed 4.9.** Removed, and nothing replaced it. The test asserting it was inverted rather than deleted, so a future agent finding the plumbing intact also finds the reason it went. **Still open for the owner:** the footer's remaining line reads "Manchester". His objection named the city as well as the latitude, but a footer location is ordinary and true, so it was left rather than removed on an inference. |
| ~~0b.8~~ | **Closed 4.3.** The rail is continuous instead of six disconnected segments, the selected stop is named above it, and a step control sits at each end — which is the part that makes it obviously operable on a phone, with a mouse and from the keyboard. Original: **The chronology scrubber has no legible affordance.** Nothing indicates it can be dragged. | The map's primary touch control is undiscoverable | 4.3 |
| ~~0b.9~~ | **Closed 4.3.** It filled with `surfaceRaised`, which is near-white on papyrus, so it had no edge against the page. It now fills with `surface` and carries a short gold rule above the name. Original: **The transmission panel reads as a plain card**, particularly in the light theme. | The map's content surface looks unfinished | 4.3 |
| 0b.10 | **Implementation complete 4.5; Worker deployed (0b.12).** Browser verification remains open: writing and cover providers both derive from `ANALYTICS_ENDPOINT`, which the current release and local build omit. Enabling article requests independently of analytics needs a separate change. | Article covers are not enabled by the Worker deployment alone | Follow-up implementation and browser verification |
| 0b.11 | **Easy Go, an open-source Flutter package**, is absent from the site. It is the only open-source artifact in the record. **Not resolved by 4.2**: the owner's publishing rule for the sixteen LinkedIn projects is live store links only, and a pub.dev package has no store listing, so the rule excludes it by accident rather than by intent. Worth a decision of its own. | A Flutter engineer's portfolio shows no packages | Owner |
| ~~0b.12~~ | **Closed 2026-09-07.** Deployed from the repository root using the documented isolated Node 22 / Wrangler 4.129.0 command. Worker version `929f5eaa-54c8-433e-afec-257decbd1b12` is live at `https://nocturne-analytics.asherbinyy.workers.dev`; the owner's fake-image cover request with the configured site Origin returned **502**, confirming the route shipped. | Browser checks remain separate (0b.10) | Worker deployed and endpoint verified |

---

## 0. What this build collects: nothing

**There is no consent banner and no `/privacy` route.** Both were removed in
Milestone 3 with the collection they existed for. `06-ANALYTICS-AND-PRIVACY.md`
carries a status banner saying so, and restoring collection means restoring the
consent interface and a notice along with it.

The release build supplies no `ANALYTICS_ENDPOINT`, so there is no sender, no
client, and no collection of any kind — no beacon, no consent banner, nothing
written to a visitor's device. `/privacy` says exactly that and offers no
controls, because a control that changes nothing is theatre.

**Dormant, not deleted.** The tiers, the consent model, the banner, `/console`,
the Worker and all their tests remain in the repository and still pass;
`test/widget/privacy/privacy_test.dart` runs the consent machinery against a
build that *is* collecting, so it cannot rot. Restoring collection is one
`--dart-define` on the release build line in `.github/workflows/ci.yml`.

The deployed Worker is untouched and still serves `/v1/writing`, which is
content rather than analytics and carries nothing about the viewer.

**Milestone 4 added `/v1/cover` to the same Worker**, for the same reason and
with the same posture: article cover images are relayed through this origin so
that opening `/writing` issues no request to Medium carrying the viewer's IP or
referrer. It allowlists Medium's two CDN hosts, refuses anything that is not an
image, caps the response at 2MB and passes through no upstream header but the
content type. **Deployed and endpoint verified** — see 0b.12. The client-side
endpoint configuration limitation is recorded in 0b.10.

---

## 0c. Opened during Milestone 4

| # | Item | Notes |
|---|---|---|
| 0c.1 | **Guardy has no engagement dates**, so it ships as an application rather than a stop on the map. Germany therefore appears in the ledger and in the countries claim but not on the atlas. | Supplying start and end months would let it become a stop. `14-PROVENANCE.md` §3b. |
| 0c.2 | **Malboos lost its featured slot to Guardy.** The parser caps featured entries at six and Malboos is the only one with no role description — a bare name and a link. An editorial call an agent made; reversing it is one flag in `apps.json`. | Owner may disagree |
| 0c.3 | **The research poster is cropped** to remove a header band carrying the owner's name and student number. The caption carries the title instead. | A matriculation number has no reason to be on a public page |
| 0c.4 | **`assets/media/apps/` is empty.** The screenshot pipeline is built and documented; no screenshots have been supplied. Every row still draws its procedural card, which is the designed absence rather than a defect. | Rolls up into 1.10 |
| 0c.6 | **The trace cannot fully clear the text on a phone.** It is confined to a 28% trailing strip and its labels are dropped, which fixes the collision the owner reported, but a 360px viewport has a full-width text column and a waveform cannot be disjoint from it. **A decision for milestone 5:** the wall replaces this paint, and it should decide whether the signature element exists on compact at all rather than inheriting a compromise. | Owner reported it 2026-09-07 |
| 0c.7 | **"The trace only reaches before Manchester."** Reported by the owner on a phone. Not reproduced from the code: all seven stops receive anchors, the last is the Salford entry, and the career sequence is the last thing on the page. Possibly the measured-anchor path failing on a phone and falling back to provisional spacing, which insets the last burst to 7/8 of the range. **Needs one look at the rebuilt preview to confirm before it is chased further** — no fix was guessed at. | Owner to confirm |
| 0c.5 | **The interests section is not in `02-SCREEN-SPECS.md`.** Nor are the evidence thumbnails, the redesigned scrubber, or `/ascent`. That document still describes the ground station throughout. | Deferred deliberately — see the milestone-4 worklogs |

---

## 1. Owner actions — content and assets

Nothing here can be done by an agent. `AGENTS.md` §3 forbids inventing content,
numbers and translations, and every row below is one of those.

| # | Item | Consequence while open | Blocks |
|---|---|---|---|
| 1.1 | **The real-phone check.** See §5 — it is the one merge gate that has never been performed. | Unknown behaviour on the primary audience's device | Every merge to `main` |
| 1.2 | **The twelfth application.** `apps.json` holds eleven. `02-SCREEN-SPECS.md` and roadmap 1.9 both say twelve. | Ledger heading counts eleven; the docs claim twelve | 1.9 fully done |
| 1.3 | **Snunu's App Store URL is dead.** `id1627473292` returns 404 in us, gb, sa, eg, ae and ru, and Apple's lookup API returns zero results — the listing does not exist rather than being region-locked. | The app is absent from the ledger | — |
| 1.4 | **AZ Exams has no distinct store URL.** It shared `com.crazyidea.coursesexams` with AZ Courses; one of the two was wrong. | The app is absent from the ledger | — |
| 1.5 | **Mokaf has no public listing.** It ships with an empty store map and the row says so plainly. Confirm that is correct rather than a missing link. | — | 2.1 |
| 1.6 | **Arabic copy.** `profile.json`, `career.json` and `apps.json` carry `ar: null` throughout, so Arabic falls back to English by design. Separately, ~75 agent-authored interface strings in `app_ar.arb` have never had a native read. | Arabic locale is structurally complete but linguistically unreviewed | Arabic being claimed as shipped |
| ~~1.7~~ | **Mostly closed.** Four of the five roles — MiNextStep, Hwzn Tech, Ar++ tech and Techlabs Solutions — now carry the company, title and summary transcribed from the owner's CV. **Evri remains empty**: it is the one role the CV does not cover, so its burst still falls back to the city rather than an invented employer. |
| ~~1.8~~ | **Partly closed.** The owner supplied the CV as a PDF, and its content has been transcribed into `career.json`, `education.json` and `profile.json`. The **file itself is still not in the repository**, so `profile.cvFile` stays null and the hero's second action still opens the HTML CV rather than downloading a PDF. |
| 1.8b | **The CV PDF file.** `profile.cvFile` is null, so the hero's second action reads "Read the CV" and opens the static HTML instead of downloading. | No downloadable CV | `/brief` parity with the spec |
| 1.9 | **The portrait.** `profile.portrait` is null. Brief in `01-DESIGN-SYSTEM.md` §10. | `/about` cannot be built to spec | `/about` |
| 1.10 | **Screenshots** for Mokaf, AZ Courses and City Loom. | Device frames have nothing to scrub | 2.1 |
| 1.11 | **Case study prose** — three studies, context → problem → approach → outcome. The roadmap says explicitly that an agent cannot write these and will invent them if asked. **The screen is built and tested; `assets/content/studies/` is empty on purpose.** Drop a `{slug}.json` in and it renders with no code change. | `/work/:slug` says "not written yet" for every slug | — |
| 1.12 | **n8n instance and a Resend account** for the digest. Everything buildable is built: the Worker's noon trigger, the payload, and the importable workflow with its summary and message in `automation/digest-workflow.json`. What remains is creating the two accounts, importing the workflow, adding the Resend credential and running `wrangler secret put DIGEST_WEBHOOK_URL`. Steps in `automation/README.md`. | Digest dormant, not broken | Nothing — 2.6's repository half is done |
| 1.13 | **Calendly URL** is null in `profile.json`. | No booking link | — |

---

## 2. Provisional decisions an agent made that the owner may want to change

| # | Decision | Why it went this way |
|---|---|---|
| ~~2.1~~ | **Closed.** The third panel now ships. The CV dated it — "4+ years of commercial experience" — which is what was missing when it was left out. |
| 2.2 | **Six countries, not five.** `02-SCREEN-SPECS.md`'s hero diagram draws a "5 countries" panel, but `00-PROJECT-BRIEF.md` §2 and §3 and the `/brief` block all say six and name them: Egypt, Saudi Arabia, Armenia, Qatar, Canada, the UK. | The diagram is the outlier. The doc should be corrected to six. |
| 2.3 | **Stat labels are English-only.** `LocalizedText.resolve` falls back to English rather than inventing Arabic. | `AGENTS.md` §3. Rolls up into 1.6. |
| 2.4 | **The ledger heading counts the content, not the docs.** It says eleven because eleven exist. | Rolls up into 1.2. |
| 2.5 | **No placeholder case-study prose was shipped.** The approved plan was "machinery plus clearly-marked placeholder entries". The machinery is complete and proven against fixtures in `test/widget/work/case_study_test.dart`, but nothing was written into `assets/content/studies/`: placeholder prose about real client work would be a claim the owner never made, on a page a recruiter reads as fact, and `AGENTS.md` §3 forbids exactly that. The production screen says "not written yet" instead. | Reverse this by writing the three studies; no code changes. |
| 2.6 | **Which three case studies.** `07-CONTENT-SCHEMA.md` recommended Mokaf, AZ Courses and **Tripster**; `02-SCREEN-SPECS.md` and `09-ROADMAP.md` both say Mokaf, AZ Courses and **City Loom**, and give City Loom its own section and the embedded prototype. The two agreeing documents were treated as current and 07 now records the discrepancy. | Confirm City Loom is the third. |
| 2.7 | **`studies/{slug}.json` gained an optional `prototype` field.** `02-SCREEN-SPECS.md` requires City Loom's live embedded prototype and its honest status line; no schema field carried either. Documented in `07-CONTENT-SCHEMA.md`. | — |

---

## 3. Engineering follow-ups

| # | Item | Notes |
|---|---|---|
| ~~3.1~~ | **Closed.** The hero's amber CTA was below the fold on a first visit because the consent banner held a row. The banner is gone — this build collects nothing, so there is nothing to consent to — and the CTA now sits above the fold alongside both stat panels. Resolved as a side effect rather than by tightening spacing. |
| 3.2 | **Trace and map frame cost have never been measured in a real browser profile.** Budgets are 4ms and 6ms. Widget tests cannot measure this. | Needs Chrome DevTools against the deployed build. |
| 3.5 | **`InteractiveViewer` keeps its default boundary behaviour** on the propagation map, so direct panning only becomes useful once zoomed. | From the propagation-map session. |
| 3.6 | **The acquisition sequence's once-per-tab behaviour is unobserved in a browser.** The VM test target cannot emulate a hard reload; the conditional web implementation is only proven by the WASM build compiling. | Needs the deployed site. |
| 3.7 | **The build emits a missing Material/Cupertino icon-font warning.** The app bundles and uses neither package. | Cosmetic, long-standing. |
| ~~3.12~~ | **Closed.** Fonts are 556KB. The subsetting was tightened first — dropping the Arabic Presentation Forms and the Persian/Urdu ranges took the bundle from 794KB to 556KB — and the budget in `03-ARCHITECTURE.md` §5 was then raised from 480KB to 580KB, on the owner's instruction. The original figure was set without pricing three Arabic weights beside seven Latin faces; meeting it would have meant dropping an Arabic weight and letting emphasis synthesise. |
| ~~3.8~~ | **Closed by roadmap 3.3.** `test/widget/accessibility_test.dart` now runs `androidTapTargetGuideline` and `labeledTapTargetGuideline` across all six public routes, plus keyboard traversal on `/`, `/work` and `/privacy`. It found a real defect on the first run: the primary navigation set `link: true` with no label while excluding the visible text, so **the whole nav announced nothing to a screen reader**. Fixed. |
| 3.10 | **The console's code-split lands in the JS output, not the WasmGC one.** `fvm flutter build web --wasm` emits `main.dart.js_1.part.js` — a real 9.2KB deferred chunk on the JavaScript fallback path — but a single `main.dart.wasm` with no separate part. So a browser on the WasmGC path downloads the dashboard whether or not it ever reaches the gate. Roadmap 2.5's "code-split" is met on one of the two outputs. | Not fixable from application code; it is a WasmGC deferred-loading limitation. Re-check when the SDK gains split output. |
| 3.11 | **The console token is held in memory only.** Deliberate: it is a bearer credential for the analytics store, and a site whose argument is about not writing to visitors' devices should not make an exception for its own secret. The cost is re-entering it once per tab, paid only by the owner. | Change only if the owner asks. |
| ~~3.13~~ | **Closed.** The live pages rendered with an empty `document.title`. `WidgetsApp` mounts its own `Title` and defaults it to the empty string, which does not leave `document.title` alone — it overwrites the hand-authored title from `web/index.html` and leaves the tab blank until content resolves. `RouteTitle` compounded it by mounting a second `Title` with `''` while the profile loaded. The app now carries the shell's own title, `RouteTitle` mounts nothing until it has something true to say, and a test reads `web/index.html` so the two cannot drift. |
| 3.9 | **`--hairline-strong` is below 3:1 in both themes** — 1.69 in Nocturne, 2.32 in Daybreak. It was deliberately left out of the contrast suite: it draws structural rules and panel edges, which WCAG 1.4.11 treats as decoration rather than information identifying a component, and where an edge does carry state the focus ring carries it. | A judgement call, not an oversight. Revisit in 3.3 if the audit disagrees. |

---

## 3b. Production verification remaining

The Milestone 2 Worker was deployed on 2026-09-06 as version
`d106e172-4182-4fdb-82f4-b0930f2a4ad0`, from the Worker source at `fdf851d`.
The writing relay returns valid RSS containing six articles. This closes the
version mismatch in 3b.1 and the outstanding server deployment associated with
3b.2; PR #3 had already restored the client-side Tier 0 payload.

| # | Item |
|---|---|
| **3b.3** | **Positive production Tier 1 and authenticated console verification remain open.** All 26 local Worker tests pass, the matching Worker version is deployed, `/v1/writing` returns 200, its missing-Origin gate returns 403, and an unauthenticated `/v1/aggregates` read returns 401. The existing `CONSOLE_TOKEN` secret is configured and was preserved. A proposed synthetic Tier 1 event and deletion of its isolated test records were rejected by automatic approval review because they lacked specific authorization; neither action ran. Complete the positive checks with an explicitly consented browser session and the owner's existing console token, or separately authorize the synthetic test and cleanup. No real page-view counter was incremented for verification in this session. |

---

## 4. Verified after the Milestone 1 deploy

Milestone 1 merged as `75b536c` and published on 2026-09-06. Run 34033338777
ran `verify`, `goldens`, `build` and `deploy` — the last two for the first time
ever. All four succeeded.

| # | Item | Status |
|---|---|---|
| 4.1 | **The Lighthouse gate.** | **Closed.** It executed for the first time and passed, asserting performance ≥ 0.85 and accessibility ≥ 0.9 on `/cv` and `/brief` in the desktop preset. It is no longer an untested assertion. |
| 4.2 | **Deep links on the live host.** | **Mostly closed.** `/work` serves the `404.html` fallback, which is the full hand-authored app shell with `<base href="/">`, so the app boots and `go_router` resolves the path client-side. The HTTP **status** is 404, which is inherent to GitHub Pages' SPA fallback and cannot be changed on Pages — it is exactly why `/cv` and `/brief` are real static files returning 200 to crawlers. What remains is confirming in a browser that the route actually renders, which is step 3 of the phone check. |
| 4.3 | **The analytics beacon.** | **Mostly closed.** The Worker is live and enforcing its contract: a POST without the site origin returns 403, and one carrying `Origin: https://asherbinyy.github.io` is accepted past the origin gate and 400s on a malformed payload. The release build supplies the endpoint via `--dart-define` at `.github/workflows/ci.yml:147`. A *valid* beacon was deliberately **not** sent — it would write a counter for a page view that never happened and put false data in the owner's own analytics. Confirm from a real browser visit instead. |
| 4.4 | **The favicon in light and dark browser chrome.** | **Open.** The `--void` background makes this a real check. Fold it into the phone check. |
| 4.5 | **No Open Graph image exists.** | **Open.** The plan was to capture the settled acquisition frame as the social preview. |

Live and returning 200: `/`, `/cv`, `/brief`, `/.nojekyll`, `/robots.txt`,
`/sitemap.xml`.

---

## 5. What "the real-phone check" means

`05-TESTING.md` requires this before **every** merge to `main`, and says
explicitly that a resized desktop browser window does not count. It takes about
five minutes and it is the only gate on this project that a machine cannot
perform — it needs physical devices.

Open the deployed site on a real iPhone in Safari **and** a real Android phone
in Chrome, then confirm four things:

1. **The address bar collapsing on scroll does not break the layout.** Mobile
   browsers change the viewport height mid-scroll. Anything sized to the
   viewport can jump, and a resized desktop window never reproduces it.
2. **Safe-area insets are respected** — the notch and the home indicator do not
   sit over the header or the footer.
3. **A deep link resolves.** Type `.../work` straight into the address bar
   rather than navigating to it. This is the `404.html` fallback in 4.2, and it
   fails silently when it fails.
4. **No horizontal scroll at 320px width.** The narrowest phone still in use.

Also worth doing on the same pass, since the device is already in hand: check
the favicon in both light and dark browser chrome (4.4), and watch the
acquisition sequence on a cold load and then a reload, to confirm it runs once
per tab (3.6).

**Status: never performed.** Milestone 1 was merged on the owner's explicit
instruction without it. The site is now live at
<https://asherbinyy.github.io>, so the check is no longer blocked — it is the
first thing to do, and it also closes 4.2, 4.3 and 4.4.
