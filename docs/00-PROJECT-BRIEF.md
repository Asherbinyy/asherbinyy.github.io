# Project Brief — KEMET

Personal portfolio for Ahmed Elsherbini. Flutter, **web target only** — it ships to browsers and never to an app store. Phone browsers are a primary target, but as a responsive and input-type problem, not a native one.

**Codename:** KEMET *(the Dart package remains `nocturne` — see `01-DESIGN-SYSTEM.md` §2, "Token naming")*
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

**That the person behind it has shipped real software to real users, repeatedly, across six countries — and that the site itself is the proof, not a claim about it.**

Everything on the page either supports that or gets cut.

Milestone 4 adds a second, subordinate goal, because the first one was being met at the cost of the person: **that there is someone here.** A portfolio that proves only competence is a CV with better typography. This one should also be recognisably one man — Egyptian, a long way from home, who lifts and plays football and argues about *Better Call Saul*. That is not decoration on the argument; for the third audience it is most of it.

The two goals conflict exactly once, on first paint, and the first one wins. A recruiter with twelve tabs open gets the evidence. The personality is one scroll down.

---

## 3. Concept — the Black Land

The visual and interaction language is **ancient Egyptian**, in the register of a painted tomb wall rather than a museum gift shop.

Milestones 1–3 shipped a different concept — "Ground Station", signal telemetry drawn from a BEng in Communications & Electronics. It was coherent and it was well built. It was also a fact about a degree, and it said nothing about the man holding it. The owner is Egyptian; the site was not.

The replacement is grounded in the same way, more strongly: when an interviewer asks "why does it look like this?", the answer is where he is from, and then a second answer about design — that Egyptian wall art is the oldest surviving design system on earth and a stricter one than most shipped today. A fixed proportion grid. A closed palette set by which minerals could be ground. A rigid register structure. A defined sign inventory. It is treated here as a specification, and `12-MOTIF-LIBRARY.md` is that specification, closed and enforced.

**Kemet** — *the Black Land* — is the Nile silt, and the primary theme. **Deshret** — *the Red Land* — is the desert beyond it, and the second.

### How the concept resolves each requirement

| Requirement | Kemet expression |
|---|---|
| Interactive world map | **The atlas.** A map drawn on papyrus. Each stop is a cartouche; selecting one opens what the content records about that place. The journey begins at a birth in Saudi Arabia, not at a first job. |
| Scroll-driven timeline | **The wall.** The career is an inscription in registers on a dark wall, revealed by torchlight as the viewer scrolls. Scroll fast and the light smears and the glyphs stay unreadable; slow down and a register resolves and its role becomes legible. |
| Load state | **The opening.** A seal broken, torchlight entering — converting Flutter Web's unavoidable initial payload into a watchable moment. |
| Arabic | Both scripts belong here rather than one being a translation of the other. Full RTL. |
| App screenshots | Device frames that scrub through real screens as the viewer scrolls. |
| Personality | **Off duty** on `/about`, and **the Ascent** — a climb up an obelisk where every altitude band unlocks a real fact from the site's own content, so playing the game is reading the CV. |
| Privacy posture | Nothing is collected, so nothing has to be disclosed or consented to. |

### The one bold thing

Per the restraint principle: spend boldness in one place. **The wall is the memorable element.** The atlas, the work grid and the case studies stay disciplined and quiet around it. If a decision is between making a second element loud or making the wall better, make the wall better.

The game is the exception that proves this, and it is quarantined on its own route where it cannot compete.

### What this concept is not

The failure mode is a gift-shop website — sandstone gradients, Papyrus font, gold bevels, a sphinx in the corner. That result would be worse than the ground station it replaced, because it would read as costume rather than as identity.

Three defences, specified in full in `12-MOTIF-LIBRARY.md`: every motif does structural work or it is cut; pigment is flat and line is incised, never bevelled or metallic; and no glyph on this site is invented. Typography does not change at all — the type stays a clean modern grotesque and lets the motifs carry the identity, because two costumes at once is one too many.

## 4. Structure

```
/                  The wall — hero, opening sequence, the torchlit inscription
/signal            The atlas — the journey, from a birth in Saudi Arabia onward
/work              Shipped applications grid
/work/:slug        Case study, device-frame scrub
/writing           Articles (Medium RSS), with their real covers
/about             Background, education, off duty, contact
/ascent            The game (milestone 6)
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
Full task lists and definitions of done in `09-ROADMAP.md`.

**Milestones 1–3 shipped** — `v0.1.0` and `v0.2.0` are live. They built the
foundation, the content layer, the static indexable routes, both themes,
localisation and RTL, the loading language, the chrome, the trace, the map, the
work ledger, Recruiter Mode, the writing feed, the case-study machinery, the
console and the CI/deploy pipeline. Almost all of that survives the change of
concept, because it is structure rather than skin.

### Milestone 4 — Provenance (`v0.3.0`)
Everything true, and a person behind it, on the existing visual language. The
claim audit and the provenance ledger; Guardy and the freelance work; the
journey from birth rather than from a first job; off duty; real article covers;
the name as **Sherbini**, spoken; selectable text; and the Kemet and Deshret
palettes, which ship here rather than with the redesign so the dark theme stops
being too dark now and nothing is painted twice.

### Milestone 5 — Kemet (`v1.0.0`)
The redesign. Motif primitives, glyph fields, the wall, the atlas, the cartouche
chrome, seal cards, the cursor trail, the opening, and a full contrast,
accessibility and frame-cost re-verification.

### Milestone 6 — The Ascent (`v1.1.0`)
The game, and its offline variant on `404.html`.

---

## 9. What this site will not do

Recorded because each has been asked for or looks obvious, and the answer costs
a session every time it is re-litigated.

**No live LinkedIn feed.** Reading your own posts needs `r_member_social`, which
LinkedIn grants only through Marketing Developer Platform partner approval — not
available to an individual for a personal site. The alternatives are a
third-party scraping bridge, which puts an external data flow into a site whose
argument is that it has none, or hand-maintained JSON, which is a worse Medium.
If a post matters, it can be a row in the content layer like everything else.

**No CMS.** Content changes a handful of times a year. `07-CONTENT-SCHEMA.md`
explains the trade.

**No second display font, no sandstone, no bevels.** `12-MOTIF-LIBRARY.md` §0.

**No fifth pigment.** `01-DESIGN-SYSTEM.md` §2.
