# Open Issues — NOCTURNE

Everything known to be incomplete, blocked, or decided-provisionally, in one
place. This is a living register: an agent that closes an item deletes its row
and says so in the worklog; an agent that finds a new one adds it here rather
than burying it in a worklog nobody re-reads.

Worklogs record what happened in a session. **This file records what is still
true.** If the two disagree, this file is the one to fix.

Last reviewed: 2026-09-06, after deploying the Milestone 2 Worker.

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
