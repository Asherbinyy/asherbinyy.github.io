# Roadmap — NOCTURNE

Every task in build order. One task per agent session. Each has a definition of done and a prompt to paste.

Milestones are sequenced, not scheduled. Each ends in a deployable state.

**Branching.** Each milestone is one branch — `phase/1-ground-station`, `phase/2-depth`, `phase/3-edge` — cut from `main`. Every task in the milestone is committed onto that branch. When the milestone is complete, it goes to `main` by PR, and merging to `main` publishes the site. Nothing reaches `main` mid-milestone. Full detail in `08-GIT-AND-CI.md`.

**Task order for Milestone 1: 1.1, then 1.12, then 1.2 onward.** CI is pulled forward deliberately — a deploy pipeline that has never run is not a pipeline, and the GitHub Pages failure modes (`.nojekyll`, `404.html`) are silent. Discover them on day one, not at the merge.

**Rule: do not start a task until the previous one's definition of done is fully met.** Half-finished foundations compound. An agent that "mostly" set up theming will produce a hundred small inconsistencies that cost more to find than the setup cost to do properly.

---

# Milestone 1 — Ground station online

Branch: `phase/1-ground-station`

Ships live to GitHub Pages. Dark theme, English and Arabic, core experience, analytics collecting.

---

### 1.1 Foundation

Project skeleton, tokens, theming, platform service, routing.

**Done when:** `fvm flutter --version` reports 3.47.2, the app builds and runs, every route resolves to a placeholder screen, `tokens.dart` contains every value from `01-DESIGN-SYSTEM.md` with nothing invented and nothing missing, both themes construct, platform service tests pass, all four verification commands green.

```
Read AGENTS.md, then docs/00-PROJECT-BRIEF.md, docs/01-DESIGN-SYSTEM.md,
docs/03-ARCHITECTURE.md and docs/04-FLUTTER-STANDARDS.md.

Task 1.1 — foundation only. No visual work beyond placeholder screens.

0. Confirm `fvm flutter --version` reports 3.47.2 / Dart 3.13.2 before
   starting. Run every command through fvm.
1. pubspec.yaml with exactly the dependencies in 03-ARCHITECTURE.md §4.
   material_ui, NOT cupertino_ui — this is a web-only target. No Firebase.
   The environment constraints must agree with .fvmrc. Bundle the four
   font families.
2. analysis_options.yaml using very_good_analysis.
3. Full directory structure from 03-ARCHITECTURE.md §2.
4. app/theme/tokens.dart — every colour, spacing, radius, duration and
   curve from 01-DESIGN-SYSTEM.md as named constants, exposed via a
   ThemeExtension and a BuildContext extension.
5. app/theme/typography.dart — the full type scale, tabular figures on
   all numeric styles.
6. nocturne_theme.dart and daybreak_theme.dart.
7. core/platform/platform_service.dart and app_messenger.dart per
   01-DESIGN-SYSTEM.md §7.
8. core/motion/reduced_motion.dart and core/motion/{curves,durations}.dart.
9. app/router.dart with every route from 00-PROJECT-BRIEF.md §4.
10. Unit tests for platform service, messenger resolution, reduced motion.

Confirm: package:material_ui (not package:flutter/material.dart), web
platform only, no ios/ or android/ directories present.

Per AGENTS.md §2, tell me your plan and wait for approval before writing
any files.

Run the four verification commands through fvm. Write the worklog per
AGENTS.md §3, recording the resolved package versions.
```

### 1.2 Localisation scaffold

ARB files, generated l10n, locale switching, RTL.

**Done when:** the app runs in both locales, direction flips correctly, no hardcoded user-facing string exists, a golden test renders one placeholder screen in both directions.

Do this **before** any UI is built. Retrofitting RTL means auditing every padding and alignment in the codebase.

### 1.3 Content layer

Models, repository, JSON loading, validation, fallback.

**Done when:** all files in `07-CONTENT-SCHEMA.md` parse into typed models, malformed JSON falls back rather than crashing, the fallback path is tested, 95% coverage on models.

### 1.4 Static routes

`tool/generate_static.dart`, `/cv` and `/brief` HTML output, meta and JSON-LD in `index.html`, `robots.txt`, `sitemap.xml`.

**Done when:** both pages render with JavaScript disabled, JSON-LD validates, Lighthouse ≥ 85 on `/cv`.

**Early on purpose.** This is the indexable surface. If the project stalls after this task you still have something a recruiter and Google can find, which is more than most portfolios manage.

### 1.4b Loading and placeholder primitives

The shared sweep, skeletons, the carrier loader, the three-stage image resolve, and the procedural station card. Built before any screen consumes them, so no screen invents its own.

**Done when:** all primitives render per `01-DESIGN-SYSTEM.md` §11, one shared `AnimationController` drives every sweep on a page, station cards are deterministic for a given app id, everything has a reduced-motion path, skeleton geometry matches real content geometry with zero layout shift, goldens pass in both themes and directions.

Do this early. Retrofitting a loading language after six screens exist means editing six screens.

### 1.5 Global chrome

Header, rail, footer, theme toggle, language toggle, Recruiter Mode toggle.

**Done when:** chrome renders across all four breakpoints, the rail collapses below 1024px, all three toggles work and persist, keyboard traversal is complete, goldens pass in both themes and directions.

### 1.6 Hero and acquisition sequence

**Done when:** the sequence runs once per session, is skippable by any input, reduced motion resolves to a 200ms fade, the settled hero matches `02-SCREEN-SPECS.md`, no layout shift on completion.

### 1.6b The mark and favicon

Depends on 1.7's curve function existing, even in early form — pull one frame from it rather than drawing the mark independently. Generate `assets/brand/mark.svg`, then the favicon set, per `01-DESIGN-SYSTEM.md` §12.

**Done when:** the mark is legible at 16px, favicon renders correctly in both light and dark browser chrome (the `--void` background matters here — test both), tab title updates per route including on client-side navigation (not just on hard reload), `index.html`'s static title and OG image are set, the mark in the header links to `/`.

### 1.7 Telemetry trace

The signature element. **Allow more than one session for this.**

**Done when:** all three states behave per `02-SCREEN-SPECS.md`, transitions are smooth, frame cost stays under 4ms, the painter early-returns off-screen, `shouldRepaint` is correct, reduced motion renders static with labels visible, amplitude maths is unit-tested.

Do not rush this. If it is merely competent, the site is merely competent — everything else is disciplined and quiet by design, so this is the only thing carrying the impression.

### 1.8 Propagation map

**Done when:** projection is unit-tested against known coordinates, all six nodes land correctly, arcs draw in sequence on viewport entry, the scrubber works on touch, transmission panels present correctly per platform, keyboard arrow navigation works, frame cost under 6ms.

### 1.9 Work ledger

**Done when:** all twelve applications render, every store link resolves — **verify each one manually** — hover preview works on pointer, thumbnails on touch, goldens pass.

### 1.10 Consent and Tier 0 analytics

**Done when:** every test in `06-ANALYTICS-AND-PRIVACY.md` §9 passes, zero network calls occur before consent resolves, the salt rotation job is deployed and verified, the live readout on `/privacy` matches actual state.

### 1.11 Recruiter Mode

**Done when:** in-app mode matches `/brief` content exactly, state persists, no motion in the mode.

### 1.12 CI and deploy

Do this task **early on the phase branch, not last** — a deploy pipeline that has never run is not a deploy pipeline. Get `verify` working as soon as there is something to verify.

**Done when:** `verify` runs on every push to the phase branch, all gates enforced, the `build` job produces `.nojekyll` and `404.html`, `deploy` runs only on `main`, the site resolves over HTTPS at `asherbinyy.github.io`, deep links such as `/work` load directly rather than 404ing, Lighthouse gate active.

**Milestone 1 ships here.** Merge `phase/1-ground-station` into `main`, confirm the deploy published, tag `v0.1.0`, then branch `phase/2-depth`. Do not begin Milestone 2 before the site is live and you have loaded it on a real phone.

---

# Milestone 2 — Depth

Branch: `phase/2-depth`

### 2.1 Case studies — Mokaf, AZ Courses, City Loom
Device-frame scrubbing. City Loom carries the embedded prototype, lazy-loaded behind a click-to-load poster.

### 2.2 Daybreak theme
A second identity, not an inversion. Contrast verified in both.

### 2.3 Writing
Medium RSS, cached, fails silently.

### 2.4 Tier 1 analytics
Consent-gated session events. Withdrawal stops collection immediately.

### 2.5 `/console`
Auth-gated dashboard. Code-split. Monochrome charts.

### 2.6 Digest pipeline
n8n workflow, daily 12:00 email. This is where the automation learning becomes a running system rather than a claim.

### 2.7 `/how-it-was-built`
Architecture, Lighthouse scores, coverage, privacy decisions. The page that converts "creative" into "hireable."

---

# Milestone 3 — Edge

Branch: `phase/3-edge`

### 3.1 Campaign links `/r/:campaign`
### 3.2 Performance pass against every budget in `03-ARCHITECTURE.md` §5
### 3.3 Accessibility audit — full keyboard, screen reader, contrast
### 3.4 Easter egg. One. Discoverable, not intrusive.

---

## Outside the repository

Do these alongside the build, not after:

- [ ] Install FVM and the pinned SDK — `fvm install 3.47.2`
- [ ] Download the four font families, then run `tool/fonts.sh` to subset them
- [ ] Create the repo named `asherbinyy.github.io`, enable Pages with source "GitHub Actions"
- [ ] Create a Cloudflare account for the analytics Worker — free tier, no card
- [ ] Register a domain when convenient — not a blocker, see `08-GIT-AND-CI.md`
- [ ] Resend account for the digest (Milestone 2)
- [ ] Take the portrait — brief in `01-DESIGN-SYSTEM.md` §10
- [ ] Capture screenshots: Mokaf, AZ Courses, City Loom
- [ ] Write Arabic content for `profile.json`, `career.json`, `apps.json`
- [ ] Verify all twelve store links resolve
- [ ] Fix the CV inconsistencies flagged separately
- [ ] Write the three case studies in English before 2.1 — the agent cannot invent these, and inventing them is exactly what it will do if the content is missing
