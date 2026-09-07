# Roadmap — NOCTURNE

Every task in build order. One task per agent session. Each has a definition of done and a prompt to paste.

Milestones are sequenced, not scheduled. Each ends in a deployable state.

**Branching.** Each milestone is one branch — `phase/1-ground-station`, `phase/2-depth`, `phase/3-edge`, `phase/4-provenance`, `phase/5-kemet`, `phase/6-ascent` — cut from `main`. Every task in the milestone is committed onto that branch. When the milestone is complete, it goes to `main` by PR, and merging to `main` publishes the site. Nothing reaches `main` mid-milestone. Full detail in `08-GIT-AND-CI.md`.

---

## Status, 2026-09-07

**Milestones 1–3 have shipped.** `v0.1.0` and `v0.2.0` are tagged and live at
<https://asherbinyy.github.io>. Their task lists are kept below as history —
they are not work queues any more, and `11-OPEN-ISSUES.md` is the authority on
what remains open from them.

**Milestones 4–6 are the current work**, and they follow a change of direction
the owner set on 2026-09-07: the site keeps its engineering and loses its
concept. The ground-station identity is replaced by an Egyptian one, drawn from
the fact that the owner is Egyptian rather than from his first degree, and the
portfolio grows a person — origins, hobbies, real writing, a game — instead of
a résumé rendered in a nice font.

Read `00-PROJECT-BRIEF.md` for the concept, `12-MOTIF-LIBRARY.md` before any
visual work, and `14-PROVENANCE.md` before touching any claim about the owner.

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

# Milestone 4 — Provenance

Branch: `phase/4-provenance` · Tag `v0.3.0`

**Everything true, and a person behind it — on the existing visual language.**
No motifs, no glyphs, no game. This milestone exists so the site stops making a
claim it cannot source and starts showing someone with a life, and it ships
before a single pyramid is drawn. If the project stalled here it would still be
a better portfolio than it is today.

The one exception to "no visual work" is the palette, task 4.10, and the reason
is in that task.

### 4.1 The claim audit

Every figure and claim on the site checked against `14-PROVENANCE.md`, and the
ledger completed. Fix the two that are wrong: the six-countries overstatement
(§2.1) and the AZ Courses download conflict (§2.2). Correct the README's
"nothing is stored on the visitor's device" — theme, language and Recruiter
Mode have persisted since milestone 1, so the sentence is false as written.

**Done when:** every number rendered anywhere on the site has a row in
`14-PROVENANCE.md`; a test asserts the ledger covers every numeric string in
`assets/content/`; the README's storage claim matches what the code does.

### 4.2 Career and project depth

Add Guardy (§3.1), resolve Tiara (§3.6), and publish whichever of the sixteen
LinkedIn projects the owner clears (§3.8). Surface **Easy Go** — the owner's
open-source Flutter package, currently invisible — on its own terms. Settle
"CI Company" versus "Crazy Idea". Give the ledger a real count instead of a
number the docs and the content disagree about.

**Done when:** every published project traces to a source row; every store link
resolves, verified by hand; `apps.json` and the ledger heading agree; nothing is
published that the owner has not cleared.

### 4.3 The journey

The map currently starts at the first job. It should start at a birth.

Rebuild the chronology as: **born, Saudi Arabia → raised, Egypt → the working
years → Manchester, 2025**. The map painter and projection are unchanged; this
is content plus two new stop kinds.

Then fix the two things the owner named. The chronology scrubber
(`chronology_scrubber.dart`) does not communicate that it can be dragged —
replace it with a control whose affordance is legible without instruction. And
the transmission panel (`transmission_panel.dart`) sits on a flat raised
surface that reads as a plain white card in Deshret; give it a treatment.

**Done when:** stops render in life order with birth and upbringing present;
the navigation control is understood without a hint, verified on touch and
keyboard; panels no longer read as default cards in either theme; goldens pass.

### 4.4 Off duty

A section for the person: gym, football, padel, reading, television
(*Better Call Saul*), e-sports (FIFA, Valorant). Interactive rather than a
bulleted list — the owner's words were "as if I am taking them into my world".

Constraints: it is one section, not a second site; it obeys the same motion and
accessibility rules as everything else; and per `AGENTS.md` §3 it says only what
the owner said (§3.9). Portrait lands here if cleared (§3.13).

**Done when:** the section renders on `/about` at all four breakpoints; every
interaction has a keyboard path and a reduced-motion path; no claim without a
provenance row.

### 4.5 Writing, properly

`/writing` draws procedural constellations because it had no images. It has
images — every Medium article ships a cover. Render real cards using them,
hotlinked from the feed, through the existing three-stage image resolve so a
slow or failed image degrades rather than breaks.

**Done when:** all six articles render with their real covers; a failed image
falls back to the procedural card rather than a gap; no layout shift on resolve;
images are hotlinked, not committed.

### 4.6 Education, trimmed

Show top-performing modules only, not all seven. Resolve the 74/75 question
(§3.3) and the dissertation's status (§3.4).

**Done when:** the table shows the agreed subset with the agreed marks; the
dissertation appears only as the owner permits.

### 4.7 The name

Render **Sherbini** everywhere except `/cv`, which keeps the full legal name for
ATS parsers. Add a play control beneath it for a recording of the owner saying
it. The control renders nothing at all until the recording exists (§3.10) —
never a dead button.

**Done when:** every surface except `/cv` says Sherbini; the player is labelled,
keyboard-operable, and absent when the file is; `/cv` and `/brief` still carry
the full name in their JSON-LD.

### 4.8 Selectable text

The site renders to canvas, so text cannot be selected or copied — a real
defect for anyone trying to copy an email address. `SelectionArea` exists in
`material_ui` 1.1.1 (verified 2026-09-07) and is the fix.

**Done when:** body text, contact details and the ledger are selectable on
desktop and on touch; selection does not break the trace, the map or any
`CustomPainter`; a widget test covers it.

### 4.9 The footer

Drop the coordinate readout. The owner does not want to be introduced by a
latitude.

**Done when:** the footer carries no coordinates; the freed space is either used
or removed cleanly at every breakpoint.

### 4.10 The Kemet and Deshret palettes

Ships in milestone 4, not 5, for three reasons: the owner's complaint that the
dark theme is too dark is a live defect; the change is 36 lines in
`tokens.dart` plus the contrast suite; and doing it now means milestone 5 never
has to repaint anything twice.

Values are solved and recorded in `01-DESIGN-SYSTEM.md` §2 — both palettes pass
every assertion in the existing contrast suite. Add `faience` and `faienceDim`
tokens and their contrast rows.

**Done when:** both themes carry the new values; `contrast_test.dart` passes
with faience included; every golden is regenerated and reviewed by eye, not
just accepted; gold coverage stays under 8%.

### 4.11 Arabic content

Fill every `ar:` field in `assets/content/`. Interface strings are already
complete — 98 of 98 keys — so this is content only, which is why Arabic reads
as half-finished today.

Per the owner's instruction of 2026-09-07 this ships without waiting for review.
Write `docs/AR-REVIEW.md` with every string, English beside Arabic, so
corrections are a checklist rather than a hunt through JSON.

**Done when:** no `ar: null` remains in content; both locales render at every
breakpoint with correct RTL; `AR-REVIEW.md` covers every string.

### 4.12 `/cv`

Either restyle the static page or replace it with the real PDF (§3.12). It stays
hand-written HTML with JSON-LD either way — it is the indexable surface and the
one page an ATS reads, and that constraint outranks how it looks.

**Done when:** the page renders with JavaScript disabled; JSON-LD validates;
Lighthouse ≥ 85; `profile.cvFile` is populated if a PDF ships.

### 4.13 Screenshots

A path for the owner to add app screenshots without an agent: a documented
directory, a naming convention, and a manifest the work grid reads. Closes
`11-OPEN-ISSUES.md` 1.10, open since milestone 1.

**Done when:** dropping a correctly-named file into the directory makes it
appear with no code change; a missing screenshot still falls back to the
procedural card; the convention is documented in `07-CONTENT-SCHEMA.md`.

### 4.14 Release

Docs reconciled, `11-OPEN-ISSUES.md` refreshed, CHANGELOG written, tag
`v0.3.0`. **The real-phone check finally runs** — `05-TESTING.md` has required
it before every merge to `main` since milestone 1 and it has never been done.

---

# Milestone 5 — Kemet

Branch: `phase/5-kemet` · Tag `v1.0.0`

**The redesign.** Read `12-MOTIF-LIBRARY.md` first; it is a closed inventory
and the guard against this becoming a gift-shop website.

The palette already shipped in 4.10, so this milestone is entirely about form.

### 5.1 Motif primitives — **partly built**
The painters behind inventory items 1–15: cartouche, register, ankh, obelisk,
scarab, seal, feather, djed, mastaba, wedjat, sarcophagus, register tick. Plus
the seven glyph paths for §2's cartouche. Built before any screen consumes
them, so no screen invents its own — the same discipline as task 1.4b.
**Done when:** every primitive has a golden in both themes and both directions,
each is unit-tested for determinism where seeded, and none allocates per frame.

### 5.2 The glyph fields — **built**
`tool/generate_fields.dart` emits one 256×256 tile per route into
`assets/motifs/`. **Done when:** fields cost 0ms per frame after first paint,
measured in a real profile; tiles seam invisibly; Recruiter Mode has none.

### 5.3 The wall — **built**
The signature element.

**Two inputs from the owner's phone review, `11-OPEN-ISSUES.md` 0c.6 and 0c.7.**
The trace ran across the copy on a phone because one column fraction was used
at every breakpoint; milestone 4 narrowed it to a trailing strip and dropped
its labels there, which is a compromise rather than a design. The wall must
decide outright what the signature element does on a 360px viewport, where a
full-width text column leaves no clear channel beside it — including the option
that it does not appear at all and compact gets a different treatment. And the
owner reports the trace stopping short of the last stop; confirm on a device
before rebuilding the anchoring, since it is not reproducible from the code. The telemetry trace becomes an inscription revealed by
torchlight as the viewer scrolls — fast scroll smears the light and the glyphs
stay unreadable, slow down and a register resolves and its role becomes legible.
Reuses the existing velocity engine, anchor registry and geometry; only the
paint changes. **Allow more than one session.**
**Done when:** all three states behave per `02-SCREEN-SPECS.md`, frame cost
under 4ms, the painter early-returns off-screen, `shouldRepaint` is correct,
reduced motion renders static with every label visible, amplitude and torch
falloff maths unit-tested.

### 5.4 The papyrus atlas
`/signal` becomes a drawn map on papyrus: cartouche stops, a route line instead
of arcs. Projection and coastline data unchanged. **Done when:** frame cost
under 6ms; keyboard traversal and the 4.3 navigation control still work.

### 5.5 Chrome — **partly built**: ankh and cartouche done, glyph-column rail not
Cartouche name treatment, glyph-column rail, ankh mark and favicon set.
**Done when:** the ankh is legible at 16px; the favicon works in light and dark
browser chrome; the Latin name is present at every breakpoint; the accessible
name is `Sherbini`, never a glyph.

### 5.6 Cards and hover
Work and article cards become seal impressions; hover gets a real reaction. The
owner asked for the grid to be fun.
**Done when:** hover has a keyboard-focus equivalent, a touch equivalent and a
reduced-motion path; cards stay deterministic per id.

### 5.7 The cursor trail — **built**
Per `12-MOTIF-LIBRARY.md` §5. The system cursor is never replaced.
**Done when:** under 1ms per frame, capped at 24 particles, pointer-only, off
under reduced motion and in Recruiter Mode, stops on blur.

### 5.8 The opening
The acquisition sequence becomes a tomb opening — a seal broken, torchlight
entering. Same rules: once per session, skippable by any input, 200ms fade under
reduced motion, no layout shift.

### 5.9 `/cv` and `/brief`
Restyled to match, still hand-written HTML, still JS-optional, still ATS-first.

### 5.10 Verification
Contrast across every new surface, full keyboard and screen-reader audit, frame
profiles for wall, map, fields and cursor in a real browser — closing
`11-OPEN-ISSUES.md` §3.2, open since milestone 1. Every golden regenerated.
---

# Milestone 6 — The Ascent

Branch: `phase/6-ascent` · Tag `v1.1.0`

The game. Full specification in `13-GAME-DESIGN.md` — read it before starting;
it settles the form, the purpose, the audio budget, the accessibility floor and
the WasmGC bundling constraint that rules out a game engine package.

### 6.1 Engine and controls
One painter, one ticker, axis-aligned collision. No new packages. Keyboard,
touch and mouse through the platform service.
**Done when:** 60fps on a mid-range Android phone in a real profile; the ticker
stops on blur and on route exit, proven by a test.

### 6.2 Registers and content
Altitude bands unlock facts read from `assets/content/`.
**Done when:** a test proves the game surfaces no string absent from the content
layer; every fact links out to where it lives on the site.

### 6.3 Audio
Six samples, CC0 or public domain, sourced in `14-PROVENANCE.md`, fetched at
runtime, under 120KB total, mutable, persisted, never before a gesture.

### 6.4 Accessibility
Full keyboard play, practice mode reaching the summit, a labelled canvas, and
every fact readable without playing.

### 6.5 The offline variant
A self-contained canvas script in `web/` for `404.html`. Not the Flutter game —
the page has to work when the bundle does not.

### 6.6 Verification
The four commands, a real-device profile, and the phone check.

---

## Outside the repository

Owner actions. None of these can be done by an agent — `AGENTS.md` §3.

The authoritative list is **`14-PROVENANCE.md` §3**, which records what is
needed, what it blocks, and what has already been verified. It supersedes the
milestone-1 checklist that stood here.

Still true from that original list:

- [ ] Take the portrait — brief in `01-DESIGN-SYSTEM.md` §10
- [ ] Capture screenshots: Mokaf, AZ Courses, City Loom
- [ ] Write the three case studies — an agent cannot, and will invent them if asked
- [ ] n8n and Resend accounts for the digest — steps in `automation/README.md`
- [x] Repo, Pages, Cloudflare account, FVM, fonts — done in milestone 1
- [x] Arabic content — agent-written in 4.11 on the owner's instruction, pending his review in `docs/AR-REVIEW.md`