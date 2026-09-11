# Design System — NOCTURNE

> Current direction, 2026-09-11: use [the brief](00-PROJECT-BRIEF.md) and [Re-innovation R2](19-REINNOVATION-ROADMAP.md#r2--visual-system-home-and-entrance). The values below document the existing Flutter implementation. The old instrumentation, flat-only material rules, ban on environmental depth and single-animation limit are superseded as creative direction by the owner's later requests. New token values/type choices require the concrete R2 review; none are changed by this audit. Provenance, legibility, focus, reduced motion and shared tokens remain requirements.

Authoritative. Any value not listed here is a bug. No raw hex, no magic numbers, no ad-hoc durations anywhere in feature code.

---

## 1. Principles

**The wall, not the interface.** The reference object is a painted tomb wall: registers, a canonical grid, incised outlines, pigment laid in flat fields. Not cards on a page. Egyptian wall art is the oldest surviving design system in the world and it is stricter than most shipped today — proportion grid, fixed palette, rigid register structure, a defined glyph inventory. This project treats it as a specification, not a mood board.

**Four pigments, each with one job.** Egyptian palettes were limited by the minerals available: gold leaf, lapis lazuli, Egyptian blue and faience, carnelian, ochre, carbon black, gypsum white. That constraint is inherited here as a rule, not a look. Gold is the person and every action. Faience is interaction feedback. Carnelian is error. Everything else is graded limestone and ink. A pigment used outside its job is a bug, not a preference. See section 2.

**Ornament earns its place or it is kitsch.** The failure mode of this theme is a gift-shop website: sandstone gradients, Papyrus font, gold bevels, a sphinx in the corner. The guard against it is that every motif must be doing structural work — a cartouche because it encloses a name, a register because it separates eras, a glyph column because it is a navigation rail. Decoration applied to a surface that has no reason for it gets cut. See `12-MOTIF-LIBRARY.md`, which is a closed inventory: if a motif is not in that file it does not go on the site.

**Dark is the identity, not a mode.** Kemet — *the Black Land*, the Nile silt — is the primary artifact. Deshret — *the Red Land*, the desert beyond it — is a genuine second artifact on papyrus, not an inverted dark theme.

**Motion answers actions.** One orchestrated non-triggered moment exists on the site: the opening sequence on first load. Everything else responds to the viewer. No fade-and-slide-up on section entry.

**Radius encodes hierarchy.** Structural panels are square, as incised stone is square. Only controls the viewer can touch are rounded. Uniform radius is a tell; here it carries information.

---

## 2. Colour

### The four pigments

| Pigment | Job | Never used for |
|---|---|---|
| **Gold** | The person. Live state. Every control the viewer can act on. | Decoration of any kind |
| **Faience** | Interaction feedback only — hover, focus, links, in-game state | Static content, headings, categories |
| **Carnelian** | Errors. At most once per session. | Warnings, emphasis, "important" |
| **Limestone / ink** | Everything else — all text, all data, all telemetry, all structure | — |

This replaces the single-chroma amber rule that governed milestones 1–3. It is not a loosening. Amber-only was one pigment with several jobs; this is four pigments each locked to exactly one, which is a stricter statement and a testable one. **A fifth hue may not be introduced for any reason** — not for a success state, not for a chart series, not for a tag category. If two things need distinguishing, use weight, size, position, or a glyph.

Success in particular does not get a colour. `verified` resolves to the limestone ramp: confirmation is a change in weight, a glyph, or a state label. Green would be a fifth pigment and this system does not have one.

### Kemet (primary theme)

The Black Land. Lapis-tinted night, never pure black.

```
--void              #121826   page base — lifted off black, blue-led
--surface           #1A2233   panels
--surface-raised    #232D40   elevated panels, modals
--hairline          #2E3A50   1px structural rules, panel edges
--hairline-strong   #3F4D66   active/hovered edges

--gold              #E3A93F   THE PERSON. Live state, CTAs, focus, active
--gold-dim          #92702E   at rest: register ticks, inactive marks
--gold-glow         #FFD98A   peak under torchlight, hover fill

--faience           #45B8B2   INTERACTION ONLY. Hover, links, game state
--faience-dim       #2D827D   inactive interactive affordance

--limestone         #CBD6E6   values, live readouts, the wall under torchlight
--limestone-mid     #93A2B8   secondary data, axis labels
--limestone-dim     #69788F   gridlines, inactive data, the wall at rest

--carnelian         #E3716C   errors only
--verified          #CBD6E6   success is monochrome — a state change, not a hue

--text-primary      #EDF1F8
--text-secondary    #A8B4C6
--text-muted        #8895A8   metadata, timestamps, disabled
```

**On the base being lighter.** Milestones 1–3 used `#05070A`, which the owner found too dark. `#121826` has 4.4× the relative luminance and carries a lapis cast, which is both the requested correction and the correct pigment: the Black Land is silt, not void.

### Deshret (secondary theme)

The Red Land. Papyrus and desert light. Not an inversion.

```
--void              #F2E9D8   papyrus
--surface           #E9DEC8
--surface-raised    #FCF7EC
--hairline          #D6C8AC
--hairline-strong   #AD9C7C

--gold              #885912   darkened for contrast on papyrus
--gold-dim          #9C7534
--gold-glow         #6F4409

--faience           #1C6B68
--faience-dim       #2E8481

--limestone         #37424F
--limestone-mid     #586472
--limestone-dim     #8A7C63

--carnelian         #9C2E26
--verified          #37424F

--text-primary      #13181F
--text-secondary    #48545F
--text-muted        #5A6470
```

### Token naming

The Dart token names do **not** change in milestone 5. `beacon` continues to name the gold role, `instrument` the limestone ramp, `alert` the carnelian, `void_` the ground. Renaming ~190 files' worth of references to express a theme change would produce an enormous diff carrying no behavioural change and would bury the actual redesign inside it. The mapping is recorded once, here:

| Doc name | Dart token |
|---|---|
| gold / gold-dim / gold-glow | `beacon` / `beaconDim` / `beaconGlow` |
| faience / faience-dim | `faience` / `faienceDim` *(added in 5.1)* |
| limestone / -mid / -dim | `instrument` / `instrumentMid` / `instrumentDim` |
| carnelian | `alert` |
| ground | `void_` |

### Texture

Both themes carry a static texture at 3% opacity over the base, rendered once as a tiled image and never per-frame: limestone tooth under Kemet, papyrus fibre under Deshret. This is what stops either theme reading as a flat fill. It replaces the film grain of milestones 1–3 and reuses `grain_painter.dart` unchanged apart from its source texture.

### Rules

- **No fifth hue, for any reason.** An agent that adds green, purple or a second blue outside these four pigments has broken the system.
- Charts and data visualisations are monochrome limestone ramps, with at most one series in gold — the one the viewer is meant to read first.
- No gradients as decoration. Gradients only where they represent a real falloff — torchlight, depth into the wall, signal amplitude.
- No coloured shadows, no bevels, no emboss. Elevation is a `--hairline-strong` edge and a background shift. Gold bevel is the single fastest way to make this theme look cheap.
- **Gold coverage stays under roughly 8% of any viewport.** If a screen looks gold, it is wrong. The limit is higher than milestone 1's 5% because gold now carries the name treatment and the register ticks, and lower than it feels like it should be.
- **Faience never appears at rest.** If a faience pixel is on screen and the viewer is not hovering, focusing or playing, it is a bug.

### Contrast is a constraint on this palette, not a review step

Every value above is verified by `test/unit/app/theme/contrast_test.dart`, which checks each role against every surface it is painted on: 4.5:1 for text, 3:1 for gridlines, inactive data and register ticks. Nothing in the type scale reaches WCAG's large-text allowance — the largest role carrying a non-primary colour is `heading` at 22px and the threshold is 24px — so 4.5:1 applies everywhere text is coloured.

The primary call to action is checked as its label on its own fill rather than as gold on the page, because `BeaconButton` fills with gold and labels in the ground colour.

Both palettes were solved rather than picked: each role was moved on lightness alone, preserving hue and saturation, until it met its floor on all three surfaces. The worst margins in the shipped set are `text-muted` at 4.54:1 on Kemet's raised surface and `gold` at 4.52:1 on Deshret's surface. **Changing any value here means running that test**, not eyeballing it.

The `faience` and `faience-dim` roles are added to the suite in task 5.1. `hairline` and `hairline-strong` remain deliberately outside it, for the reason recorded in `11-OPEN-ISSUES.md` §3.9.

---

## 3. Typography

Bundled locally under `assets/fonts/`. No network font fetch.

| Role | Family | Notes |
|---|---|---|
| Display | **Space Grotesk** | Headlines, the name, section titles. Weights 500, 700. |
| Body (Latin) | **IBM Plex Sans** | 400, 500, 600. |
| Body (Arabic) | **IBM Plex Sans Arabic** | Metric-matched to Plex Sans. Same weights. |
| Telemetry | **IBM Plex Mono** | 400, 500. Numerals, coordinates, timestamps, live values, code. |

Plex Mono is used because the subject is instrumentation — measured values genuinely belong in a monospace face here. It must not leak into general small labels; that usage is a generic tell.

### Scale

Fluid, `clamp()` between compact and expanded breakpoints.

```
display-xl   clamp(48px, 9vw, 112px)   Space Grotesk 700   line 0.92   tracking -0.03em
display-l    clamp(36px, 5.5vw, 64px)  Space Grotesk 700   line 1.00   tracking -0.02em
display-m    clamp(26px, 3.2vw, 40px)  Space Grotesk 500   line 1.10   tracking -0.01em
heading      22px                      Space Grotesk 500   line 1.25
body-l       18px                      Plex Sans 400       line 1.6
body         16px                      Plex Sans 400       line 1.6
body-s       14px                      Plex Sans 400       line 1.55
meta         13px                      Plex Sans 500       line 1.4    --text-muted
telemetry    13px                      Plex Mono 400       line 1.3    tabular figures on
telemetry-s  11px                      Plex Mono 400       line 1.3    tabular figures on
```

### Rules

- Body measure capped at **68 characters**. Enforce with max-width, not guesswork.
- **No all-caps labels.** Sentence case throughout.
- **No eyebrow labels** above headings.
- No single-word colour or weight accents inside a headline.
- Arabic uses the same scale; line-height increases by 0.15 across the board for Arabic ascenders/descenders.
- Tabular figures enabled everywhere a number can change (`fontFeatures: [FontFeature.tabularFigures()]`).

---

## 4. Layout

8pt base grid. Spacing tokens: `4, 8, 12, 16, 24, 32, 48, 64, 96, 128`.

```
compact    < 600px    single column, 20px gutter
medium     600–1023   single column, 32px gutter, wider measure
expanded   1024–1439  12-col, 32px gutter, max content 1180
large      ≥ 1440     12-col, 40px gutter, max content 1280
```

Content is **left-aligned throughout.** Centred text belongs to marketing pages; an instrument panel aligns to a rail. The only centred element is the acquisition sequence on first load.

### Radius

```
0px    structural panels, the trace container, map surface
2px    hairline chips, tags, station nodes
6px    buttons, inputs, the theme and language switches
10px   modals, the consent panel
9999   nothing
```

### Panel language

Panels are defined by a 1px `--hairline` edge plus **corner ticks** — 8px marks at each corner, `--beacon-dim`, offset 4px outside the edge. This is the instrument signature and replaces card shadows entirely. Never use a drop shadow on a panel.

---

## 5. Motion

```
instant     100ms   state flips, checkbox, toggle
quick       180ms   hover, focus, small reveals
standard    280ms   panel open, route change
considered  480ms   map node selection, transmission panel
sequence    900ms   acquisition sequence beats
```

Curves:
```
emphasized      Cubic(0.2, 0.0, 0.0, 1.0)    default for anything entering
exit            Cubic(0.4, 0.0, 1.0, 1.0)
spring          SpringDescription(mass 1, stiffness 180, damping 22)  physical elements only
linear                                        trace scrub, progress only
```

### Rules

- **One non-triggered animation on the site:** the acquisition sequence. Everything else is a response to input.
- No entrance animation on scroll for sections. The trace reacting to scroll is the scroll behaviour; adding fade-ups on top is noise.
- Every animation reads `MediaQuery.disableAnimations` / `prefers-reduced-motion`. Under reduced motion: acquisition sequence becomes a 200ms fade to the settled state; the trace renders static at rest amplitude; map arcs draw instantly; scrub becomes a discrete stepper.
- Nothing animates for longer than 900ms.
- No infinite loops except the trace idle at ≤ 0.2Hz, which pauses when off-screen.

---

## 6. The telemetry trace

The signature element. Specified here because it carries the site.

- Rendered by a `CustomPainter` driven by a single `AnimationController` and the scroll offset. No widget-per-point.
- Baseline: a low-amplitude carrier at rest, `--instrument-dim`.
- Each career role is a **burst** on the trace, positioned at its scroll anchor. Burst amplitude scales with role duration; burst density with number of apps shipped.
- **Scroll velocity modulates coherence.** Above a velocity threshold the waveform degrades toward noise (amplitude jitter, phase break, colour drifts to `--instrument-dim`). As velocity falls the signal resolves and locks — clean waveform in `--instrument`, and the nearest burst label fades in at `--beacon`.
- A `LOCK` indicator in the rail reads the current state. This is the moment the site rewards slowing down.
- Painter must be capped at 60fps and skip repaint when off-screen. Budget: ≤ 4ms per frame on a mid-range laptop.

---

## 7. Platform adaptation

This is a **web-only** product. It ships to browsers, never to an app store. But "web" is not one platform — a phone browser and a laptop browser want genuinely different behaviour, and the difference is input type, not operating system.

Centralised in `core/platform/`. Feature code never checks viewport width or user agent directly — it asks the platform service, which resolves on pointer capability (`hover` and `pointer: fine` media queries) with viewport width as a secondary signal.

| Concern | Touch browser (phone, tablet) | Pointer browser (laptop, desktop) |
|---|---|---|
| Transient message | Bottom snackbar, safe-area inset, swipe to dismiss | Top-right toast, 4s, hover-to-persist, close affordance |
| Secondary surface | Bottom sheet, drag handle | Side panel or centred dialog, Esc to close |
| Hover | none | Full hover states on every interactive element |
| Cursor | n/a | Pointer on interactive, crosshair over the map surface |
| Keyboard | n/a | Full tab order, Esc closes, `/` focuses search, arrow keys move map selection |
| Map interaction | Pinch zoom, tap node, drag pan | Scroll zoom, click node, drag pan, hover preview |
| Scrub | Touch drag | Scroll, drag, and arrow keys |
| Tooltip | Long-press → sheet | Hover → tooltip, 400ms delay |
| Density | Comfortable, 48px min target | Compact, 40px min target |

The snackbar case is a specific requirement: a bottom snackbar on a wide desktop viewport is wrong. `AppMessenger` in `core/platform/` resolves this once, and every feature calls that.

No haptics. The Vibration API is unavailable or gated in most browsers, and a feature that works on one Android browser and silently does nothing everywhere else is not worth the branch.

Every layout must be verified on a real phone browser, not a desktop window resized narrow. Mobile Safari and Chrome on Android differ from a narrow desktop viewport in ways that matter — dynamic viewport units, the address bar collapsing on scroll, and safe-area insets on notched devices. Use `100dvh`, never `100vh`.

---

## 8. Iconography

Custom line set at 1.5px stroke, 24px grid. Instrument vocabulary: crosshair, waveform, antenna, aperture, node, transmission, lock. **No off-the-shelf icon pack** — a stock icon set inside a bespoke instrument language breaks it immediately. Twelve to sixteen icons total; if a concept needs a seventeenth, use a word.

Never append `→` to link or button text. If direction needs indicating, use an icon slot.

---

## 9. Voice

Sentence case. Active voice. Plain verbs. No exclamation marks.

The instrument framing lives in **labels and structure**, never in prose about the person. "Signal acquired" is a fine state label. "I am a signal that propagated across five countries" is not — that reads as costume. Biography is written plainly; the interface around it carries the concept.

CTA names match their outcomes: a button reading "Download CV" produces a toast reading "CV downloaded."

Empty and error states give direction, not mood. Errors state what happened and what to do. They do not apologise.

---

## 10. Portrait — placeholder and shot brief

**Placeholder:** a duotone silhouette treatment — subject rendered in `--void` and `--beacon-dim`, hard-edged, three-quarter turn, shoulders in frame, gaze to camera-left. Positioned in `/about` at 4:5 portrait crop. Ship this at Milestone 1. The site must never depend on a photograph.

**Shot brief for the real photo** — so it drops into the identical treatment:

- **Framing:** 4:5 portrait. Head and shoulders. Crop at mid-chest. Eyes on the upper third line.
- **Angle:** body turned ~20° from camera, head returned to face it. Not square-on.
- **Background:** a plain matte wall, mid-to-dark tone. Stand at least 1.5m clear of it so it falls out of focus and casts no shadow.
- **Light:** one large soft source at roughly 45° to your left and slightly above eye line — a north-facing window in daytime is ideal. Nothing directly behind you. No overhead ceiling light, no flash.
- **Wardrobe:** solid dark tone, no pattern, no logo, collar or crew. Avoid pure black — it merges with the treatment.
- **Expression:** neutral to slightly warm. Not a broad smile.
- **Capture:** phone rear camera, portrait mode off, someone else holding it at your eye level, roughly 1.5m away. Shoot thirty frames, keep three.

The duotone treatment is applied in code, so the source file should be an ordinary unedited photo.

---

## 11. Loading, empty and missing states

Most sites treat these as leftovers — a grey skeleton, a spinner, a broken-image icon. Here they are the states a visitor sees *first*, before any content arrives, so they carry the first impression. They also happen to be where the concept pays off, because a ground station has a natural vocabulary for "signal not yet acquired."

**Governing rule: the loading language is the acquisition sequence, reused.** The hero's opening beat is a scan line sweeping outward. Every loading state on the site is a variation of that same gesture. This is what makes the site feel like one object rather than a set of screens with a spinner bolted on.

### Do not use the `shimmer` package

Write it. A packaged shimmer ships its own colours, its own gradient angle and its own timing, none of which come from `tokens.dart`, and it renders the diagonal white sweep that every templated site uses. A `ShaderMask` over a `LinearGradient` driven by one `AnimationController` is roughly forty lines and stays inside the system.

### Skeletons

Not solid grey rounded rectangles. Skeletons use the **instrument panel language**: 1px `--hairline` edge, corner ticks in `--beacon-dim`, transparent fill. The layout is visible as an empty instrument waiting for a reading, which is both truthful and better looking than a grey block.

- Skeleton geometry must match the real content's geometry exactly. A skeleton that is a different height than what replaces it causes layout shift, which violates the quality floor in `00-PROJECT-BRIEF.md` §9.
- Text skeletons are hairline rules at the line positions, at 60% of the measure — never full width, which reads as a solid block.

### The sweep

The single shimmer treatment, used on every skeleton and every loading image.

- A soft-edged band of `--instrument-dim` at 18% opacity, 20% of the container width.
- Travels **start → end** — left to right in LTR, right to left in RTL. Reads direction from `Directionality`, never hardcoded.
- 1400ms linear, 400ms pause between passes. Slower than the conventional 800ms shimmer, which reads as urgent; this should read as scanning.
- All sweeps on screen share **one** `AnimationController`, hoisted to the nearest common ancestor. Twelve cards with twelve controllers is twelve times the frame cost for an identical effect.
- Under reduced motion the sweep does not run. The skeleton renders static.

### Indeterminate loader

**No spinner.** A spinner is the single most generic element available and would undo the rest of the system.

Instead: a 32×12px carrier wave — a miniature of the telemetry trace, oscillating at 0.6Hz in `--instrument-dim`. It is the same painter as the main trace with different parameters, so it costs nothing extra and is immediately legible as belonging here.

Determinate progress uses the rail's tick scale: ticks fill in `--beacon` from start to end.

### Images

Three-stage resolve, mirroring signal acquisition:

1. **Placeholder** — a 20×25px WebP blurred up, extracted at build time. Under 400 bytes, ships inline, prevents any layout shift.
2. **Sweep** — the scan band passes over the blurred placeholder while the full image loads.
3. **Resolve** — 280ms cross-fade from blur to sharp on the `emphasized` curve.

Every image declares explicit width and height. No exceptions — an image without dimensions is a layout shift waiting to happen.

### Missing screenshots — the station card

A real problem: twelve applications, and screenshots for perhaps three of them. The wrong answer is a grey box with a mountain icon, which looks like a bug and reads as an incomplete portfolio.

Instead, generate a **station card** procedurally for any app with no screenshot:

- A deterministic seed derived from the app's `id` string, so a given app always renders the same card, and cards never shift between loads.
- The seed drives a constellation of station nodes and connecting hairlines on a `--surface` field — the same visual vocabulary as the propagation map, at card scale.
- Over it: the app name in `display-m`, and its domain and country in `telemetry-s`.
- A single `--beacon` node marks the app's country position within the constellation.

The result is that every card is visibly distinct, obviously intentional, and consistent with everything else on the site. A viewer reads it as a designed treatment rather than a gap. It also reuses `projection.dart` and the panel language already built for the map, so the marginal cost is small.

**Replace station cards with real screenshots as they become available.** The card is a good default, not a substitute — a real screenshot of a shipped app is stronger evidence and should win wherever one exists.

### Empty states

Three cases, all using the carrier-at-rest waveform plus one line of direction:

| Case | Treatment |
|---|---|
| Writing feed unavailable | Section hidden entirely. It is not core content and an error is worse than an absence. |
| Search or filter returns nothing | Carrier at rest, one line naming what to change. Never "no results found" alone. |
| Console has no data yet | Carrier at rest, plus what will appear once traffic arrives. |

### Errors

Errors state what happened and what to do next. They do not apologise, and they do not use `--alert` unless something is actually broken — a slow load is not an error.

A failed image falls back to its station card. A failed content section falls back to the bundled minimum. The site should degrade to something that still looks deliberate.

### Accessibility

- Every loading region carries `Semantics(liveRegion: true, label: ...)` so screen readers announce state changes.
- Skeletons are `ExcludeSemantics` — a screen reader should not read out placeholder geometry.
- Loading states must be perceivable without motion, since the sweep is disabled under reduced motion. The skeleton's structure carries the meaning on its own.

---

## 12. The mark, the favicon, and the tab title

Not designed from scratch — derived from a decision already made, so it can't drift from the rest of the system and doesn't need a separate design pass.

### The mark

**One waveform burst, the shape used for every career role on the telemetry trace (§6), frozen at its peak.** Not initials, not a circle, not an abstract geometric logo. The trace is already the site's signature and the most-described element; the mark is a single frame lifted directly from it.

```
     ╭─╮
────╯   ╰──── 
```

Rules:
- Single stroke, 2px at the mark's native 32×32 size, scales as a vector — SVG source, never a raster export.
- Colour: `--beacon` on dark backgrounds, `--beacon` (the darkened Daybreak value) on light. Monochrome everywhere else — the mark is the one place amber appears with no content around it, which is exactly why it reads as a mark rather than decoration.
- No wordmark version. No "AE" monogram variant. No circular badge container. The waveform stands alone at every size down to 16px — test this at favicon size specifically, since a burst with too many inflection points collapses into noise at 16px. Two or three curves maximum.
- Lives at `assets/brand/mark.svg`, single source, every other size generated from it at build time.

This is a five-minute asset once the trace painter's curve function exists in code — sample it at one fixed phase and export the path. It should not be designed independently of that function; if the trace's curve shape changes, regenerate the mark from it rather than hand-tuning both.

### Favicon

Generated from `mark.svg`, not designed separately:

```
web/favicon.png       32×32, standard
web/icons/icon-192.png    192×192, PWA / bookmark
web/icons/icon-512.png    512×512, PWA / share cards
web/icons/icon-maskable.png   512×512, safe zone per Android maskable spec
```

Background is `--void` (`#05070A`), not transparent — a transparent favicon on a bright browser tab strip goes invisible in light-mode browser chrome, which is the most common favicon failure. Mark rendered in `--beacon`.

No Daybreak-specific favicon variant. Browser chrome uses OS theme, not site theme, and shipping two favicons that swap on toggle is complexity with no visible benefit — nobody watches their browser tab while toggling site theme.

### Browser tab title

Not a static string. It changes with route, the same way a real instrument's readout changes with what it's currently displaying:

| Route | Tab title |
|---|---|
| `/` | `Ahmed Elsherbini — Mobile Engineer` |
| `/signal` | `Signal — Ahmed Elsherbini` |
| `/work` | `Work — Ahmed Elsherbini` |
| `/work/:slug` | `{App name} — Ahmed Elsherbini` |
| `/about` | `About — Ahmed Elsherbini` |
| `/writing` | `Writing — Ahmed Elsherbini` |
| `/privacy` | `Privacy — Ahmed Elsherbini` |
| `/brief` | `Ahmed Elsherbini — Brief` |
| `/console` | `Console` (name omitted — this route isn't a public surface) |

Pattern: name first only on the two entry points a stranger lands on (`/` and `/brief`); everywhere else, section first, name second, so a stack of open tabs is scannable — a recruiter with `/work`, `/about` and a case study open in three tabs sees what each one is without hovering.

Set via `SystemChrome` / the `title` element in `router.dart`'s route builder, not hardcoded once in `index.html` — a title fixed in the HTML shell never updates on client-side navigation, which is a common Flutter Web miss.

**`index.html`'s static `<title>`** — the one search engines and the very first paint see, before the app has mounted — is fixed: `Ahmed Elsherbini — Mobile Engineer, Manchester`. Include the location; it's a real signal for a UK-based search and costs nothing.

### Where the mark appears

Header, top-left, 24px, always links to `/`. Favicon. `index.html` OG image, composited over the acquisition sequence's settled frame rather than shown alone — the static social-preview image should look like a moment from the site, not a logo on a blank field. Nowhere else. It is a wayfinding element, not a decorative one, and it should not turn up as a watermark, a loading-screen centrepiece, or a repeated background pattern — that would compete with the trace for the role of "the one bold thing" that `00-PROJECT-BRIEF.md` §3 already assigns elsewhere.
