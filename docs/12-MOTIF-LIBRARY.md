# Motif Library — KEMET

**This file is a closed inventory, not a source of inspiration.** If a motif is
not listed here, it does not go on the site. Adding one means adding a row to
this file first, with its structural job filled in, and getting that approved —
`AGENTS.md` §8.

---

## 0. The failure mode

The risk of this theme is not that it is too plain. It is that it becomes a
gift-shop website: sandstone gradients, Papyrus font, gold bevels, a sphinx
watermark, a scarab that spins for no reason. That result is one careless
flourish away at every moment, and it is worse than the ground-station design
it replaced, because it would read as costume rather than as identity.

Three rules hold the line.

**1. Every motif does structural work.** A cartouche appears because it
encloses a name. A register appears because it separates eras. A glyph column
appears because it is a navigation rail. A motif applied to a surface that has
no reason for it is deleted, however good it looks.

**2. Flat pigment, incised line.** Egyptian wall art is flat colour inside a
carved outline. No bevels, no emboss, no drop shadows, no metallic gradients,
no "shiny gold". Gold is a flat fill at `--gold`. If it looks like a trophy, it
is wrong.

**3. Never fake meaning.** Do not invent hieroglyphs, do not generate glyph
strings as texture, and do not spell English words in glyph-shaped ornaments.
Every glyph that appears on the site is a real sign from Gardiner's list, used
either as documented ornament or in the one place the site spells something —
the cartouche in §2. Fabricated writing on a site whose whole argument is
"nothing here is made up" would be a self-inflicted wound.

---

## 1. The inventory

| # | Motif | Structural job | Where | How drawn |
|---|---|---|---|---|
| 1 | **Cartouche** | Encloses a name — the oval and bar that marked a royal name | Header name treatment, `/about` identity block, app card frames | `CustomPainter`, path |
| 2 | **Register** | A horizontal band separating eras — the native form of a timeline | The wall (`/`), career chronology, `/work` grouping | Layout + hairline painter |
| 3 | **Glyph column** | A vertical inscription line — the native form of a rail | Navigation rail ≥1024px | Painter + glyph paths |
| 4 | **Ankh** | Life. The site's mark, replacing the carrier wave | Favicon, header mark, loading resolve, `/` hero | `mark_painter.dart`, path |
| 5 | **Torchlight** | A moving pool of light revealing an inscription | The wall's scroll reveal — the signature interaction | Radial gradient mask over the wall painter |
| 6 | **Obelisk** | A vertical monument, tapering, with a pyramidion cap | Scroll progress indicator; the tower in the game | Painter |
| 7 | **Scarab** | Khepri rolls the sun from horizon to horizon — a thing in motion, becoming | The indeterminate loader, replacing the carrier sweep | Painter, one rotation per cycle |
| 8 | **Seal impression** | A unique mark stamped for a unique thing | Procedural card art, replacing `station_card_painter.dart` | Painter, seeded per id |
| 9 | **Papyrus sheet** | A drawn surface with fibre tooth and deckled edge | The map ground on `/signal` | Tiled texture + edge path |
| 10 | **Register tick** | Small incised marks calibrating a band | Panel corners, scale marks, the chronology rail | Painter |
| 11 | **Djed pillar** | Stability — a vertical stack of bars | Section dividers between major page blocks | Painter |
| 12 | **Ma'at's feather** | Weighing, judgement, a measure against a standard | Education marks on `/about`; the game's score gate | Painter |
| 13 | **Stepped mastaba** | A rising stack — the honest ancestor of the pyramid | Stat panels, the game's platforms | Layout + painter |
| 14 | **Wedjat (Eye of Horus)** | Watching, protection | `/console` only — the one page that observes | Painter |
| 15 | **Sarcophagus / wrapped form** | A thing at rest, not yet opened | Empty and dormant states, the click-to-load poster | Painter |
| 16 | **Glyph field** | A wall of inscription at low contrast — texture with real provenance | Page backgrounds, one field per route | Pre-rendered tile, see §4 |

### Explicitly excluded

These are the obvious choices and they are excluded on purpose.

- **The Tutankhamun death mask.** The single most reproduced object on earth and the fastest route to costume. It appears in exactly one place: as the reward art at the top of the game in milestone 6, where it is earned rather than decorative.
- **The Sphinx, the Great Pyramid silhouette, camels, palm trees.** Travel-agency iconography, not design.
- **Papyrus, Cinzel, and every "Egyptian" display font.** Typography is unchanged — see §3.
- **Sand, dunes, sandstone gradient washes, animated dust.** The Black Land is silt and river, not desert. Deshret carries the desert and does it with papyrus, not sand texture.
- **Mummies as characters** outside the game. The user asked for mummies; they live in the game (`13-GAME-DESIGN.md`), where a character is appropriate, and nowhere else.

---

## 2. The cartouche, and the one place the site spells something

The header renders **Sherbini** in a cartouche.

The glyphs inside it are the Egyptian uniliteral signs — the phonetic alphabet
Egyptian scribes themselves used to write foreign names. Ptolemaic cartouches
spell *Ptolemy* and *Cleopatra* phonetically with exactly these signs, so
transliterating a modern name this way is the historically correct practice
rather than a pastiche of one.

| Sound | Gardiner | Sign |
|---|---|---|
| š (sh) | N37 | pool |
| r | D21 | mouth |
| b | D58 | foot |
| i | M17 | reed |
| n | N35 | water |
| i | M17 | reed |

**š – r – b – i – n – i.**

Rules for this, and they are tight:

- The glyphs are drawn as **vector paths in the repository**, not set in a font. No font on the bundle budget covers the Egyptian Hieroglyphs block, and pulling one would cost more than the seven paths it replaces.
- The cartouche spells this name and nothing else. It is not a generator. No other string is ever rendered in glyphs.
- The Latin word **Sherbini** is always present beside or beneath the cartouche at every breakpoint. The glyphs are an ornament with provenance, never the only way to read the name.
- The accessible name of the element is the Latin name. Screen readers get `Sherbini`, never a glyph description.
- **The sign choices are verified.** N37 = š, D21 = r, D58 = b, M17 = i, N35 = n are the standard uniliteral values in Gardiner's list. What is *not* verified is the spelling decision: a scribe might equally have written the final vowels with the double reed (M17A, *y*) rather than the single reed, giving š-r-b-y-n-y. Both are defensible; neither is checkable by an agent.
- **A codepoint column was removed from this table.** It listed Unicode values for the six signs, two of which were wrong and four of which were never checked — in the file whose entire job is to stop unverified things reaching the site. The glyphs are drawn as vector paths in `glyph_paths.dart` and no code ever needed the codepoints, so the column was decoration pretending to be data.
- Recorded in `14-PROVENANCE.md` §3.14, still open for a reader of Egyptian to confirm the spelling.

---

## 3. Typography does not change

Space Grotesk, IBM Plex Sans, IBM Plex Mono and IBM Plex Sans Arabic stay
exactly as they are, at the same scale, with the same tabular figures.

This is deliberate and it is the main thing keeping the theme from tipping into
costume. The motifs carry the identity; the type stays a clean modern grotesque
and lets them. A display face with chiselled serifs on top of cartouches and
glyph fields would be two costumes at once.

It also protects three things already paid for: the Arabic weights and their
RTL work, the 556KB font budget settled in `11-OPEN-ISSUES.md` §3.12, and every
golden test whose geometry depends on the current metrics.

---

## 4. The glyph field — how backgrounds are drawn

Every route carries a background field of low-contrast inscription. This is the
"patterns in the background" requirement, and it is the single largest
performance risk in the redesign.

**It is drawn once and tiled. It is never painted per frame.**

The rule is inherited from `grain_painter.dart`, which already solves this
problem for the film grain: render to an offscreen image once, cache it, and
blit the tile. A field of glyph paths repainted every frame across a full
viewport would cost more than the frame budget for the wall and the map
combined.

Specification:

- One tile per route, recorded once to a `ui.Picture` and replayed across the surface. **No build-time generator and no image assets**, which is a change from the original plan here: recording a picture at runtime gives the same display-list replay that a cached bitmap would, costs no bytes in the bundle, and needs no second definition of the glyphs to fall out of step with the first.
- Composed from the documented sign set only, at fixed rotations of 0°, laid on the register grid. No random rotation, no scatter — Egyptian inscription is columnar and aligned, and aligned tiles also seam cleanly.
- Drawn at `--limestone-dim` over the ground at **4% opacity**, one step above the 3% texture so the two read as separate layers rather than mud.
- The field is **behind** the texture layer, not above it.
- Under `prefers-reduced-motion` the field is unchanged: it does not move, so there is nothing to reduce. It is disabled entirely in Recruiter Mode, which is a quiet document.
- Each route gets a distinct field so navigation is legible at a glance. **They differ by arrangement, not by sign.** This file originally said each field would be drawn from its route's own subject — craft signs for the work grid, water and land signs for `/signal` — and that is not what shipped: the inventory in §2 is five signs, chosen because they spell the owner's name, and drawing a dozen more means verifying a dozen more. Each route seeds its own layout instead, which distinguishes the pages without adding an unverified sign to the site. Widening the inventory is a decision worth making deliberately, not a gap to be filled quietly.
- **Signs are laid on a grid, never in a line.** §0 forbids generating glyph strings as texture, and that prohibition is about faking meaning: a horizontal run reads as a sentence, and an arbitrary one is nonsense presented as writing. A diaper of single signs at fixed spacing reads as ornament, which is what it is. Nothing in a field spells anything.

**Budget: the field costs 0ms per frame after first paint.** If a profile shows
otherwise, it is being repainted and that is a bug.

---

## 5. The cursor

The owner asked for a cursor that "sparks some magic". The constraint is that a
cursor is an accessibility surface before it is an ornament.

- **The system cursor is never replaced or hidden.** People rely on their own cursor, at their own size, with their own high-contrast and pointer-size settings. A drawn cursor that replaces it breaks all of that silently.
- What ships is a **trail**: a short-lived, small particle wake that follows the real pointer, in `--gold` fading to transparent. The pointer stays the pointer.
- Pointer input only. Never on touch — ask `platform_service.dart`, never the viewport width.
- Off entirely under `prefers-reduced-motion`, and off in Recruiter Mode.
- One `RepaintBoundary`, a hard cap of 24 live particles, and the overlay stops animating when the window loses focus.
- Budget: **under 1ms per frame.** It is the least important thing on the page and it gets the smallest budget.

---

## 6. Sound

Sound exists only inside the game (`13-GAME-DESIGN.md`). No page on this site
plays audio.

The one exception is the name pronunciation on `/about` and `/`, which plays a
single recording of the owner saying his own name, on an explicit press, once.
That is content, not ambience.

- Nothing autoplays, ever. Browsers block it and it deserves to be blocked.
- The name player is a labelled control with a visible state, and it says nothing when the recording is absent rather than showing a dead button.
