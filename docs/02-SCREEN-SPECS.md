# Screen Specifications — NOCTURNE

Tokens alone do not produce a good design. An agent handed only a palette will produce a competent, forgettable layout — centred hero, three cards, footer. This document specifies composition so it doesn't have to guess.

Read alongside `01-DESIGN-SYSTEM.md`. Where they conflict, the design system wins on values and this document wins on arrangement.

---

## Global chrome

Present on every route except `/cv` and `/brief`.

```
┌────────────────────────────────────────────────────────────┐
│ AE          station  signal  work  writing  about   ⬡ EN ◐ │  ← 64px, hairline base
├──┬─────────────────────────────────────────────────────────┤
│  │                                                          │
│ R│                                                          │
│ A│                  content column                          │
│ I│                                                          │
│ L│                                                          │
│  │                                                          │
├──┴─────────────────────────────────────────────────────────┤
│ Manchester · consent · github · linkedin       lat 53.4808 │  ← 48px
└────────────────────────────────────────────────────────────┘
```

**The rail** is 56px, left edge (right under RTL), full height, `--surface` with a hairline. It carries, top to bottom: a vertical scroll-position tick scale, the current section name set vertically, and the `LOCK` state indicator. It is the persistent instrument frame — it makes the page feel like a device rather than a document. Hidden below 1024px, where its content collapses into a 3px progress line under the header.

**Header** is not sticky-shrinking. It stays 64px and does not animate on scroll. Shrinking headers are a generic tell and would fight the rail.

`⬡` is the Recruiter Mode control. `EN` toggles language. `◐` toggles theme. All three are 6px-radius controls, `--instrument-mid`, amber on active.

**Footer** carries the live coordinate readout in `IBM Plex Mono` — the viewer's resolved coarse location if consented, otherwise Manchester. Small, quiet, `--text-muted`. It is the one place the concept winks.

---

## `/` — Station

### Acquisition sequence

The only non-triggered animation on the site. Runs once per session, ~2.4s, skippable by any input.

```
    beat 1 (0–600ms)     empty field, grain fades in, one amber tick
                         appears at centre
    beat 2 (600–1400ms)  tick becomes a horizontal scan line sweeping
                         outward to full width, monochrome
    beat 3 (1400–2000ms) scan line resolves into the trace baseline;
                         name types in beneath it, left-aligned
    beat 4 (2000–2400ms) rail, header and footer draw in from their edges
```

Reduced motion: 200ms fade directly to the settled state.

This exists because Flutter Web has an unavoidable initial payload. The choice is a blank white screen or a designed one. Assets continue loading behind the sequence.

### Settled hero

```
┌──┬─────────────────────────────────────────────────────────┐
│  │                                                          │
│  │  Ahmed Elsherbini                                        │  display-xl, --text-primary
│  │  ──────────────────                                      │  2px amber rule, 120px wide
│  │                                                          │
│  │  Mobile engineer. 25 applications shipped                │  display-m, --text-secondary
│  │  across six countries.                                   │
│  │                                                          │
│  │  ╭─ 25 shipped ──╮ ╭─ 5 countries ─╮ ╭─ 4 years ─╮      │  instrument panels
│  │  ╰───────────────╯ ╰───────────────╯ ╰───────────╯      │  mono numerals, corner ticks
│  │                                                          │
│  │  See the work        Download CV                         │  amber primary / hairline ghost
│  │                                                          │
│  │  ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿          │  trace enters here
└──┴─────────────────────────────────────────────────────────┘
```

Everything left-aligned to the rail. Nothing centred. The three stat panels are the only place large mono numerals appear above the fold, and they are the fastest thing on the page to read — which is deliberate, because a recruiter's first sixty seconds is the whole game.

The amber rule under the name is 120px and does not span the column. A full-width rule reads as a divider; a short one reads as a mark.

**Do not** add: a background gradient mesh, floating particles, a typewriter loop that cycles job titles, or a scroll-down chevron. All four are the default gestures and all four would cheapen it.

---

## The telemetry trace

The signature element. Full spec in `01-DESIGN-SYSTEM.md` §6; composition here.

The trace runs continuously down the right two-thirds of the page from the hero to the end of the career sequence. It is one continuous painted path, not per-section widgets.

```
scroll velocity 0                 scroll velocity high
─────────────────────             ─────────────────────
  ╭─╮   ╭──╮                        ⌇⌇╌⌇  ⌇╌⌇⌇ ╌⌇
──╯ ╰───╯  ╰──  --instrument       ⌇ ╌⌇⌇╌ ⌇  ⌇⌇  --instrument-dim
    │                                   
  ╭─┴──────────────╮                (no label, no lock)
  │ CI Company     │  ← burst label fades in at --beacon
  │ 2021–2023 · EG │     only under lock
  │ 16 apps        │
  ╰────────────────╯
```

Three states:

| State | Trigger | Rendering |
|---|---|---|
| **Rest** | no scroll, ≥1.2s | Low-amplitude carrier, `--instrument-dim`, 0.2Hz idle. Rail reads `standby`. |
| **Scanning** | velocity > 900px/s | Amplitude jitter, phase breaks, `--instrument-dim`. No labels. Rail reads `scanning`. |
| **Lock** | velocity < 120px/s, nearest burst within 200px | Clean waveform in `--instrument`, burst peak in `--beacon-glow`, label panel fades in over 280ms. Rail reads `lock` in amber. |

Lock is the reward for slowing down. It is the moment the site teaches the viewer how to use it, and it should be the thing people describe afterwards.

Reduced motion: static waveform at rest amplitude, all burst labels permanently visible, no state machine.

---

## `/signal` — Propagation map

```
┌──┬─────────────────────────────────────────────────────────┐
│  │  Where the work happened                                 │
│  │                                                          │
│  │      ·  ·   ╭──────────────────────────────╮            │
│  │   ·      ╭──┤ MiNextStep                   │            │
│  │  ·    ⊙──╯  │ Toronto, Canada · 2023–2025  │            │
│  │      ╱      │ Led mobile and web delivery  │            │
│  │     ╱   ⊙───┤ Flutter · Firebase · REST    │            │
│  │    ╱   ╱    │ 4 applications        →      │            │
│  │   ⊙───╯     ╰──────────────────────────────╯            │
│  │    ╲ ⊙ ⊙                                                │
│  │     ⊙                                                    │
│  │                                                          │
│  │  ○────○────●────○────○────○                             │  chronology scrubber
│  │  2021  2023 2023 2024 2025 2025                         │
└──┴─────────────────────────────────────────────────────────┘
```

- Equirectangular projection, custom painter. Landmasses are hairline outlines only — no fills, no terrain, no labels for countries the career doesn't touch.
- Six station nodes at role coordinates. Idle: 6px ring, `--instrument-dim`. Active: 10px, `--beacon`, with a single expanding pulse ring.
- Arcs are great-circle curves drawn in chronological order, `--instrument-dim` at 40% opacity. The active leg is `--beacon`.
- On first view the arcs draw in sequence over 1.6s — triggered by entering the viewport, so it counts as a response, not ambient motion.
- The scrubber at the bottom is the primary control on touch, where precise node tapping is awkward. Dragging it moves through the career chronologically and the map follows.
- Transmission panel appears to the side on pointer, as a bottom sheet on touch, per `01-DESIGN-SYSTEM.md` §7.

Evri sits on the map as a station with a smaller node and no arc weight. It is present and factual, not featured.

---

## `/work` — Shipped applications

**Superseded in Milestone 3: this is now a grid of visual cards.** The ledger
below is kept because its reasoning still constrains the design.

The original objection to cards was twofold — that they would be "twelve
identical rounded rectangles", and that they would bury the store links. Both
are answered rather than overruled. The artwork is `StationCard`, seeded from
the application id and drawing the propagation map's own node vocabulary, so no
two cards are alike and an application with a recorded country places its node
where the country is. The store links remain their own separately focusable
controls rather than being folded into a card-wide tap target, so the thing the
page exists for is still the most actionable element on it.

There is deliberately no decorative hover on the card body: motion answers
actions, and a card that lights up while offering nothing to press answers
nothing.

`/writing` follows the same pattern, seeded from each article's URL. There, the
whole card *is* the link, because an article has exactly one destination.

---

### The original ledger specification

Not a card grid. A ledger.

```
┌──┬─────────────────────────────────────────────────────────┐
│  │  Twelve of twenty-five                                   │
│  │  Everything below is live and publicly linkable.         │
│  │                                                          │
│  │  ─────────────────────────────────────────────────────   │
│  │  Mokaf                    Mobility    QA   2025    ⌐ →   │
│  │  Smart parking · payments · real-time maps               │
│  │  ─────────────────────────────────────────────────────   │
│  │  AZ Courses               Education   EG   2023    ⌐ →   │
│  │  15,000+ downloads · video, PDF and audio delivery       │
│  │  ─────────────────────────────────────────────────────   │
│  │  Tripster                 Travel      AM   2024    ⌐ →   │
│  │  Android to Flutter migration · 20% faster               │
│  │  ─────────────────────────────────────────────────────   │
└──┴─────────────────────────────────────────────────────────┘
```

Hairline-separated rows, not cards. Cards would put twelve identical rounded rectangles on screen and lose the fact that these are *shipped products with store links*, which is the entire point of the page.

On hover (pointer) the row's left edge grows a 2px amber bar and a screenshot preview fades in on the right at 30% width. On touch, the screenshot is always visible as a 48px thumbnail.

Rows with a case study get `→`. Rows without get the store glyph only.

Real numbers appear in the row subtitle wherever one exists. `15,000+ downloads` is the strongest single string on this page.

---

## `/work/:slug` — Case study

Context → problem → approach → outcome, in that order, one screen-height each. The device frame is pinned to the right column and scrubs through screenshots as the left column scrolls.

```
┌──┬─────────────────────────────────────────────────────────┐
│  │                                     ╭───────────╮        │
│  │  Problem                            │ ┌───────┐ │        │
│  │                                     │ │       │ │        │
│  │  Three payment providers, none      │ │ screen│ │  ← pinned,
│  │  with a Flutter SDK. Eight weeks    │ │       │ │    scrubs
│  │  to MVP.                            │ │       │ │    with scroll
│  │                                     │ └───────┘ │        │
│  │                                     ╰───────────╯        │
└──┴─────────────────────────────────────────────────────────┘
```

Outcome carries a number where one honestly exists. Where none does, describe what changed qualitatively. Do not invent a percentage — a fabricated metric is the fastest way to fail a technical interview that probes it.

Three case studies: **Mokaf**, **AZ Courses**, **City Loom**.

---

## `/work/city-loom` — City Loom

Given its own case study rather than a line in About, because it is the only thing on this site the owner originated rather than delivered for a client. "Shipped 25 applications" and "started something" are different signals and a recruiter reads them differently.

Same four-part structure, with two changes:

- The prototype is **embedded live** in an iframe at the top of the page — an interactive walking tour of Greyfriars Kirkyard, Edinburgh. A recruiter can use it without leaving the site. Lazy-loaded, with a static poster frame and a click-to-load control so it costs nothing on first paint.
- A single honest status line above it: early-stage prototype, no company formed. Understating this is safe; overstating it is not, and anyone interested enough to matter will check.

What this page demonstrates is initiative and the ability to take an idea to something usable. It does not need to claim traction to do that.

---

## `/about`

Portrait in the duotone treatment, left column, 4:5. Biography right, plainly written — no instrument metaphor in prose about the person.

Education as a compact table: institution, award, dates, status. Modules with marks listed for the MSc, highest first, so `Business Data Insights & Analytics — 94` reads first. Status line: *on track for Distinction*. No overall average until the award is confirmed.

Below: the Edumundo simulation, one line. Then writing, pulled from the Medium feed.

---

## `/privacy`

A plain-language notice, and the same three controls the banner offers. Full
behaviour in `06-ANALYTICS-AND-PRIVACY.md` §5.

```
┌──┬─────────────────────────────────────────────────────────┐
│  │  Privacy                                                 │
│  │                                                          │
│  │  This site counts page views so I know what people       │
│  │  read. No cookies, no third-party trackers, and no       │
│  │  profile of you is ever built.                           │
│  │                                                          │
│  │  Currently: essential only                               │
│  │                                                          │
│  │  [ Accept all ]  [ Essential only ]  [ Reject ]          │
│  │                                                          │
│  │  What is collected · what never is · retention ·         │
│  │  how to ask for erasure                                  │
└──┴─────────────────────────────────────────────────────────┘
```

The three controls carry equal visual weight and none of them is amber. Making
"accept" the amber one would be a dark pattern on a page whose entire subject
is not using them.

### The consent banner

Shown at the foot of the viewport on first visit, until a choice is made. One
sentence, three controls, no pre-selection. It does not block the page.

## `/brief` and Recruiter Mode

One screen. No rail, no trace, no map, no motion.

```
Ahmed Elsherbini · Mobile engineer · Manchester

4 years commercial. 25 applications shipped across Egypt, Saudi
Arabia, Armenia, Qatar, Canada and the UK. MSc Managing Innovation
& IT, University of Salford — on track for Distinction.

Shipped        Mokaf · AZ Courses (15k+) · Tripster · Enjoy
               Malboos · Tiara Beauty          [store links]
Stack          Flutter · Dart · Swift · SwiftUI · Firebase · CI/CD
Education      MSc Salford · BEng Communications & Electronics
Contact        email · phone · LinkedIn · GitHub
               [ Download CV ]
```

Set in the same type and palette so it reads as the same product in a different mode — not as a fallback page.

`/brief` is static HTML. In-app Recruiter Mode renders identical content. Both exist: one for search engines and direct links, one for viewers already inside the app.

---

## `/console` — Analytics dashboard

Auth-gated, single account. Not linked from anywhere in the public site.

```
┌──┬─────────────────────────────────────────────────────────┐
│  │  Last 30 days                                            │
│  │                                                          │
│  │  ╭─ 412 ────╮ ╭─ 287 ────╮ ╭─ 34 ─────╮ ╭─ 2m14s ──╮   │
│  │  │ views    │ │ unique   │ │ CV       │ │ median   │   │
│  │  ╰──────────╯ ╰──────────╯ ╰──────────╯ ╰──────────╯   │
│  │                                                          │
│  │  ▁▂▅▃▂▇█▅▃▂▁▄▆▃▂▁▃▅▇▄▂▁▃▂▅▃▁▂                          │
│  │                                                          │
│  │  Applications              Views   CV   Last seen        │
│  │  deloitte-tech-grad          18     3   2h ago           │
│  │  bjss-mobile                 11     2   yesterday        │
│  │  kpmg-cyber                   4     0   4 days ago       │
│  ╰──────────────────────────────────────────────────────    │
└──┴─────────────────────────────────────────────────────────┘
```

Monochrome ramps for all charts. At most one series in amber — the one being drawn attention to. Same instrument-panel language as the public site, because this is also a portfolio artifact: building a privacy-preserving analytics stack is a much better interview story than installing someone else's.

The campaign table is the operationally useful part. Knowing that the Deloitte application produced eighteen views and three CV downloads two hours ago is directly actionable in a way no aggregate number is.
