# Project Brief — NOCTURNE

Personal portfolio for Ahmed Elsherbini. Flutter, **web target only** — it ships to browsers and never to an app store. Phone browsers are a primary target, but as a responsive and input-type problem, not a native one.

**Codename:** NOCTURNE
**Hosting:** GitHub Pages, repository `asherbinyy.github.io`
**Domain:** none yet — a custom domain is a later DNS change, not a blocker

---

## 1. Who this is for

Three audiences, in priority order.

**1. UK technical recruiters and hiring managers.** Skimming. On a laptop, often mid-morning, often with twelve other tabs open. They need to answer one question fast: *can this person build things that ship?* If they can't answer it in sixty seconds they leave.

**2. Engineering leads and interviewers.** Arriving after a CV has already landed. Looking for depth, judgement and evidence that the CV is honest. They will click into a case study. They will look at the code.

**3. Prospective clients and collaborators.** Freelance and founder-adjacent traffic. Smaller volume, higher intent.

The site must serve (1) without boring (2) or losing (3). This is the entire reason Recruiter Mode exists.

---

## 2. The one thing this site has to prove

**That the person behind it has shipped real software to real users, repeatedly, across five countries — and that the site itself is the proof, not a claim about it.**

Everything on the page either supports that or gets cut.

---

## 3. Concept — Ground Station

The visual and interaction language is **signal telemetry**, presented in a nocturnal, tactical register: a monitoring console in a dark room.

This is not decoration picked for looks. It comes from the subject: a BEng in Communications & Electronics, followed by a career that propagated across Egypt → Saudi Arabia → Armenia → Qatar → Canada → United Kingdom. The site is the ground station receiving that signal.

Grounding the aesthetic in the subject matters practically: when an interviewer asks "why does it look like this?", the answer is a story about the person, not a mood board.

### How the concept resolves each requirement

| Requirement | Ground Station expression |
|---|---|
| Interactive world map | **Propagation map.** Countries appear as ground stations. Arcs animate between them in career order. Selecting a node opens a transmission panel: employer, dates, apps shipped, stack, live store links. |
| Scroll-driven timeline | **Telemetry trace.** A continuous waveform runs down the page. Scroll velocity modulates amplitude — scroll fast and it degrades into noise, slow down and it resolves and locks. Each role is a burst on the trace. |
| Analytics | Telemetry is already the native visual language. The consent panel and live session readout belong to the design rather than sitting on top of it. |
| Load state | **Signal acquisition sequence.** Converts Flutter Web's unavoidable initial payload into a deliberate, watchable moment rather than a blank screen. |
| Arabic | Dual-channel transmission. Language switch framed as a frequency change. Full RTL. |
| App screenshots | **Received transmissions.** Device frames that scrub through real screens as the viewer scrolls. |
| Privacy posture | The consent panel shows, live, which fields are collected and which are off — including a readout of the viewer's own current session. |

### The one bold thing

Per the restraint principle: spend boldness in a single place. **The telemetry trace is the memorable element.** The map, the work grid and the case studies stay disciplined and quiet around it. If a decision is between making a second element loud or making the trace better, make the trace better.

---

## 4. Structure

```
/                  Ground station — hero, acquisition sequence, live trace
/signal            Propagation map + career transmissions
/work              Shipped applications grid
/work/:slug        Case study, device-frame scrub
/writing           Articles (Medium RSS)
/about             Background, education, the venture, contact
/privacy           Consent controls + live session readout
/console           Analytics dashboard — auth-gated, not publicly linked
/cv                Plain HTML, indexable, ATS-readable — NOT Flutter
/brief             Recruiter Mode — static, fast, sixty-second read
/r/:campaign       Tracked application entry points
```

`/cv` and `/brief` are deliberately outside the Flutter app. See §6.

---

## 5. Recruiter Mode

A persistent control in the header collapses the entire experience into a single quiet page: name, one-line positioning, current status, six shipped apps with store links, education with marks, contact, CV download. No map, no trace, no motion.

This is the highest-leverage feature on the site. It demonstrates the judgement to know when *not* to be flashy, and it removes the risk that a conservative reviewer bounces off the main experience. State persists across the session.

---

## 6. Constraint: Flutter Web is not indexable

Flutter renders to canvas. Search engines and ATS scrapers see an empty document. For a site whose purpose is being found by recruiters, this is the single largest technical risk on the project.

Mitigations, all mandatory:

1. Build with the **WASM (skwasm) renderer** — substantially faster than CanvasKit on current Flutter.
2. Hand-authored `index.html` shell containing full `<meta>`, Open Graph, Twitter card and JSON-LD `Person` schema.
3. `/cv` served as **static hand-written HTML** — no Flutter, no JS required, complete career text. This is the page Google indexes and ATS bots read.
4. `/brief` likewise static HTML.
5. `sitemap.xml` and `robots.txt` at root.
6. All fonts bundled locally. No third-party font CDN — removes a network round trip and an external data flow.

Without these the site is invisible. They are not optional polish.

---

## 7. Content

Content lives in local JSON under `assets/content/`. No CMS, no database, no admin panel.

Rationale: content changes a handful of times a year. A custom admin panel would consume a meaningful share of total build effort to solve a problem that editing a file already solves. JSON is version-controlled, diffable, editable by hand or by an agent, and works with no network.

Schema in `04-CONTENT-SCHEMA.md`.

---

## 8. Build order

Milestones are sequenced, not scheduled. Each one ends in a deployable state.

### Milestone 1 — Ground station online
Dark theme only. English and Arabic.
- Project skeleton, tokens, theming, routing
- Hero + acquisition sequence
- Telemetry trace (the bold element — build this properly, it carries the site)
- Propagation map with transmission panels
- Work grid, real store links
- Static `/cv` and `/brief`
- Localisation scaffold and RTL — built in from the start, not retrofitted
- Consent panel + Tier 0 analytics with cookieless unique-visitor counting
- CI green, deployed live to GitHub Pages

**Milestone 1 ships live.** Nothing waits for Milestone 2.

### Milestone 2 — Depth
- Case studies with device-frame scrubbing — Mokaf, AZ Courses, City Loom
- Daybreak (light) theme
- Tier 1 analytics
- `/console` dashboard
- n8n digest pipeline
- `/how-it-was-built`

### Milestone 3 — Edge
- Tracked campaign links `/r/:campaign`
- Easter eggs
- Performance and motion refinement

---

## 9. Quality floor

Non-negotiable, present from Milestone 1:

- Lighthouse performance ≥ 85 on the static routes
- Visible keyboard focus on every interactive element; full tab traversal
- `prefers-reduced-motion` respected — every animation has a static or minimal fallback
- Colour contrast ≥ 4.5:1 for body text in both themes
- No layout shift after load
- Works with JavaScript disabled on `/cv` and `/brief`
- Zero analytics network calls before consent

---

## 10. Explicitly out of scope

- Custom admin panel
- Firestore-backed content
- Any third-party analytics SDK
- Demographic or gender inference
- Session replay
- Real map SDK (Google Maps / Mapbox) — the propagation map is a custom projection, see `03-ARCHITECTURE.md`
- Native iOS, Android or desktop builds — web only
- Any third-party analytics script
- Blog engine — writing links out to Medium

---

## 11. City Loom

Given its own case study page rather than a line in About.

Of the twenty-five applications the owner has delivered, all were built for clients. City Loom — an interactive walking tour of Greyfriars Kirkyard in Edinburgh, live as a web prototype — is the only thing originated rather than delivered. To a recruiter, "shipped a lot for other people" and "started something" are different signals, and burying the second wastes it.

The prototype is embedded live on the page, lazy-loaded behind a poster frame. A reviewer can use it without leaving the site.

Status is stated plainly: early-stage prototype, no company formed. Understating this is safe. Overstating it is not, and anyone interested enough to matter will check.
