# Open Issues — NOCTURNE

Everything known to be incomplete, blocked, or decided-provisionally, in one
place. This is a living register: an agent that closes an item deletes its row
and says so in the worklog; an agent that finds a new one adds it here rather
than burying it in a worklog nobody re-reads.

Worklogs record what happened in a session. **This file records what is still
true.** If the two disagree, this file is the one to fix.

Last reviewed: 2026-09-06, at the Milestone 1 merge.

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
| 1.7 | **Five career descriptions** are incomplete per `assets/content/README.md`. | Transmission panels are thin | — |
| 1.8 | **The CV PDF.** `profile.cvFile` is null, so the hero's second action reads "Read the CV" and opens the static HTML instead of downloading. | No downloadable CV | `/brief` parity with the spec |
| 1.9 | **The portrait.** `profile.portrait` is null. Brief in `01-DESIGN-SYSTEM.md` §10. | `/about` cannot be built to spec | `/about` |
| 1.10 | **Screenshots** for Mokaf, AZ Courses and City Loom. | Device frames have nothing to scrub | 2.1 |
| 1.11 | **Case study prose** — three studies, context → problem → approach → outcome. The roadmap says explicitly that an agent cannot write these and will invent them if asked. | `/work/:slug` has no content | 2.1 |
| 1.12 | **n8n endpoint and a Resend account** for the digest. The Worker already has a `DIGEST_WEBHOOK_URL` secret and a noon Europe/London trigger waiting for one. | Digest dormant | 2.6 |
| 1.13 | **Calendly URL** is null in `profile.json`. | No booking link | — |

---

## 2. Provisional decisions an agent made that the owner may want to change

| # | Decision | Why it went this way |
|---|---|---|
| 2.1 | **Only two hero stat panels ship: "25+ shipped" and "6 countries".** | Both are traceable to supplied documents — `00-PROJECT-BRIEF.md` §2 and the `positioning` line. The spec's third panel, "4 years", is in `02-SCREEN-SPECS.md`'s `/brief` block as "4 years commercial", but nothing supplied dates it, and a tenure figure goes stale on its own. Supply it and the panel appears with no code change. |
| 2.2 | **Six countries, not five.** `02-SCREEN-SPECS.md`'s hero diagram draws a "5 countries" panel, but `00-PROJECT-BRIEF.md` §2 and §3 and the `/brief` block all say six and name them: Egypt, Saudi Arabia, Armenia, Qatar, Canada, the UK. | The diagram is the outlier. The doc should be corrected to six. |
| 2.3 | **Stat labels are English-only.** `LocalizedText.resolve` falls back to English rather than inventing Arabic. | `AGENTS.md` §3. Rolls up into 1.6. |
| 2.4 | **The ledger heading counts the content, not the docs.** It says eleven because eleven exist. | Rolls up into 1.2. |

---

## 3. Engineering follow-ups

| # | Item | Notes |
|---|---|---|
| 3.1 | **The hero's amber CTA is below the fold on a first visit at 1200×900.** Adding the two stat panels pushed it down. It is *not* obscured — the consent banner and footer are `Column` siblings, not overlays — and it returns above the fold the moment consent is answered, because the scroll viewport grows from ~670px to ~795px. But the first visit is exactly when a recruiter arrives, and `02-SCREEN-SPECS.md`'s hero diagram shows panels *and* buttons above the trace. | Resolving it means either tightening hero spacing (which is token-governed, so it needs a named token, not a raw number) or accepting the trade. Deliberately not decided by an agent. |
| 3.2 | **Trace and map frame cost have never been measured in a real browser profile.** Budgets are 4ms and 6ms. Widget tests cannot measure this. | Needs Chrome DevTools against the deployed build. |
| 3.3 | **`/about` is unbuilt and belongs to no roadmap task.** It is in `00-PROJECT-BRIEF.md` §4 and has a full screen spec, but appears in neither Milestone 1's nor Milestone 2's task list. | Suggest folding it into 2.3, since the spec puts the Medium feed at the foot of it. Blocked on 1.9 (portrait) either way. |
| 3.4 | **`/how-it-was-built` (2.7) has no route.** `AppRoute` has no entry for it. | Adding one is part of 2.7. |
| 3.5 | **`InteractiveViewer` keeps its default boundary behaviour** on the propagation map, so direct panning only becomes useful once zoomed. | From the propagation-map session. |
| 3.6 | **The acquisition sequence's once-per-tab behaviour is unobserved in a browser.** The VM test target cannot emulate a hard reload; the conditional web implementation is only proven by the WASM build compiling. | Needs the deployed site. |
| 3.7 | **The build emits a missing Material/Cupertino icon-font warning.** The app bundles and uses neither package. | Cosmetic, long-standing. |

---

## 4. Blocked behind the deploy, not behind code

These could not be verified before Milestone 1 reached `main`, because `main`
is what publishes. They are the first things to check once it has.

| # | Item |
|---|---|
| 4.1 | **The Lighthouse gate has never executed.** It is wired into the build job asserting performance ≥ 0.85 and accessibility ≥ 0.9 on `/cv` and `/brief`, but it only runs on `main`. Until it does, it is an untested assertion. |
| 4.2 | **Deep links have never been tested on the live host.** `/work` entered directly depends on the `404.html` fallback that GitHub Pages fails silently on. |
| 4.3 | **The analytics beacon has never transported anything.** The Worker is deployed and tested, but the release build only supplies the production endpoint on a Pages release, so nothing has ever been sent end to end. |
| 4.4 | **The favicon has never been seen in light and dark browser chrome.** The `--void` background makes this a real check, per roadmap 1.6b. |
| 4.5 | **No Open Graph image exists.** The plan was to capture the settled acquisition frame as the social preview. |

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
instruction without it, and it should be the first thing done against the live
site.
