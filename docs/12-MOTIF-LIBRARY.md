# Motif Library — KEMET

> Direction update, 2026-09-11: the owner now explicitly requests more realistic reliefs, figures, materials and Egyptian environments. The five-polylines limit, flat-only treatment and exclusions of requested environmental elements below describe the old implementation, not a veto on that request. Expand the sourced asset/motif inventory as part of the concrete [R2 visual proof](19-REINNOVATION-ROADMAP.md#r2--visual-system-home-and-entrance). Do not invent phonetic strings or an Egyptian spelling of the owner's name. Existing code and token values remain unchanged until that proof is reviewed.

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

**3. Never fake meaning.** Do not invent hieroglyphs, and do not spell English
words in glyph-shaped ornaments.

This rule was broken for most of the project's life, in a way worth recording
because it did not look like breaking it. Nobody invented a sign and nobody
spelled an English word. Four painters picked at random from the uniliteral
signs — the phonetic alphabet — and scattered the result, and the defence
written into the code was that a grid reads as ornament where a line would read
as a sentence. That is wrong. Random letters are random letters at any spacing,
and a reader who knows the signs sees nonsense laid out as decoration, which is
faking meaning by another route. Presenting letters that say nothing is the
same failure as presenting letters that say the wrong thing.

The site now scatters **ornament**, not letters. See §2.

The precise rule, which used to be a licence and is now a prohibition: **no
phonetic sign is drawn anywhere on this site.** The earlier wording here said
signs could be arranged decoratively so long as nothing presented them as
readable, and that permission is withdrawn. It was doing the opposite of its
job — it let four painters scatter letters at random and pointed at its own
carefully worded caveat as the reason that was fine.

The site draws ornament instead, which has no sound value, so the question of
what it says never arises. See §2 for the set and §0 for how the rule failed.

---

## 1. The inventory

| # | Motif | Structural job | Where | How drawn |
|---|---|---|---|---|
| 1 | **Cartouche ring** | An enclosure — the oval and bar that marked a name. Empty here, enclosing a place rather than a word | Map stops on `/signal` | `map_painter.dart`, path |
| 2 | **Register** | A horizontal band separating eras — the native form of a timeline | The wall (`/`), career chronology, `/work` grouping | Layout + hairline painter |
| 3 | **Ornament column** | A vertical decorated band — the native form of a rail | Navigation rail ≥1024px | Painter + ornament paths |
| 4 | **Ankh** | Life. The site's mark, replacing the carrier wave | Favicon, header mark, loading resolve, `/` hero | `mark_painter.dart`, path |
| 5 | **Torchlight** | A moving pool of light revealing an inscription | The wall's scroll reveal — the signature interaction | Radial gradient mask over the wall painter |
| 6 | **Obelisk** | A vertical monument, tapering, with a pyramidion cap | Scroll progress indicator; the tower in the game | Painter |
| 7 | **Scarab** | Khepri rolls the sun from horizon to horizon — a thing in motion, becoming | The indeterminate loader, replacing the carrier sweep | Painter, one rotation per cycle |
| 8 | **Seal impression** | A unique mark stamped for a unique thing | Procedural card art, replacing `station_card_painter.dart` | Painter, seeded per id |
| 9 | **Papyrus sheet** | A drawn surface with fibre tooth and deckled edge | The map ground on `/signal` | `papyrus_painter.dart`, path + fibre |
| 10 | **Register tick** | Small incised marks calibrating a band | Panel corners, scale marks, the chronology rail | Painter |
| 11 | **Djed pillar** | Stability — a vertical stack of bars | Section dividers between major page blocks | Painter |
| 12 | **Ma'at's feather** | Weighing, judgement, a measure against a standard | Education marks on `/about`; the game's score gate | Painter |
| 13 | **Stepped mastaba** | A rising stack — the honest ancestor of the pyramid | Stat panels, the game's platforms | Layout + painter |
| 14 | **Wedjat (Eye of Horus)** | Watching, protection | `/console` only — the one page that observes | Painter |
| 15 | **Sarcophagus / wrapped form** | A thing at rest, not yet opened | Empty and dormant states, the click-to-load poster | Painter |
| 16 | **Ornament field** | A low-contrast decorated ground — texture with real provenance and no phonetic content | Page backgrounds, one field per route | Pre-rendered tile, see §4 |

### Explicitly excluded

These are the obvious choices and they are excluded on purpose.

- **The Tutankhamun death mask.** The single most reproduced object on earth and the fastest route to costume. It appears in exactly one place: as the reward art at the top of the game in milestone 6, where it is earned rather than decorative.
- **The Sphinx, the Great Pyramid silhouette, camels, palm trees.** Travel-agency iconography, not design.
- **Papyrus, Cinzel, and every "Egyptian" display font.** Typography is unchanged — see §3.
- **Sand, dunes, sandstone gradient washes, animated dust.** The Black Land is silt and river, not desert. Deshret carries the desert and does it with papyrus, not sand texture.
- **Mummies as characters** outside the game. The user asked for mummies; they live in the game (`13-GAME-DESIGN.md`), where a character is appropriate, and nowhere else.

---

## 2. Ornament, and why the site spells nothing at all

**The site draws no writing.** Not in the background, not on the cards, not on
the wall, not in the game. There is no cartouche and no glyph anywhere in the
interface.

This is a reversal, and both halves of it were the owner's call. He asked for
the cartouche to be removed because its spelling could not be verified by
anyone he could point at. That left the five uniliteral signs it had been built
from with no legitimate use — and four painters still drawing them at random as
texture, which is what §0 rule 3 forbids. Removing the one honest use of the
alphabet while leaving the dishonest one standing was not a defensible place to
stop.

So the alphabet is gone from the codebase entirely. `glyph_paths.dart` and
`cartouche_painter.dart` are deleted rather than left unreferenced, because
dead code that draws letters is an invitation to draw letters again.

### What replaced it

`ornament_paths.dart`, a closed set of five motifs, all of them decoration in
the archaeological record rather than language:

| Motif | What it is | Where it comes from |
|---|---|---|
| Kheker | A bound bundle of reeds, splayed at the top | Wall cresting, the standard frieze along the top of a tomb or temple wall |
| Block border | A banded chequer, two courses deep | The border run under a cornice |
| Coil | A running spiral | Painted ceiling patterns |
| Rosette | A ring of petals around an open centre | Ceilings and broad collars |
| Lotus | A bud on its stem, with two sepals | The common frieze filler |

None of these carries a sound value. A random arrangement of them says nothing
because there is nothing there to say, which is the whole point: the site can
now repeat, scatter and tile them freely without any claim being made.

Rules, and they are tighter than the ones they replace:

- The motifs are **vector paths in the repository**, not a font. Unchanged from before, and for the same reason: no font on the bundle budget covers this material.
- **No phonetic sign is ever drawn.** Not one, not in a cartouche, not as a mark, not at 4% opacity in a background. If the owner ever wants his name in glyphs again, that is a deliberate decision with an epigrapher's sign-off attached to it, not a thing this file quietly permits.
- The set is **closed at five**, and `ornament_paths_test.dart` asserts the count, so adding a sixth is a deliberate act with a test to update.
- A motif is **decoration and is described as decoration**. Nothing in the interface, in a tooltip or in an accessible name presents it as writing.

### The one cartouche shape that remains

`/signal` draws its map stops as cartouche **rings**, and that is deliberate and
allowed. A cartouche is an enclosure, and an empty one enclosing a place on a
map is a shape doing structural work under §0 rule 1. It encloses nothing and
spells nothing. `Tokens.stationCartoucheRatio` sets how wide it sits.

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

## 4. The ornament field — how backgrounds are drawn

Every route carries a background field of low-contrast ornament. This is the
"patterns in the background" requirement, and it is the single largest
performance risk in the redesign.

**It is drawn once and tiled. It is never painted per frame.**

The rule is inherited from `grain_painter.dart`, which already solves this
problem for the film grain: render to an offscreen image once, cache it, and
blit the tile. A field of motif paths repainted every frame across a full
viewport would cost more than the frame budget for the wall and the map
combined.

Specification:

- One tile per route, recorded once to a `ui.Picture` and replayed across the surface. **No build-time generator and no image assets**, which is a change from the original plan here: recording a picture at runtime gives the same display-list replay that a cached bitmap would, costs no bytes in the bundle, and needs no second definition of the motifs to fall out of step with the first.
- Composed from the documented motif set only, at fixed rotations of 0°, laid on the register grid. No random rotation, no scatter — Egyptian decoration is aligned to its register, and aligned tiles also seam cleanly.
- Drawn at `--limestone-dim` over the ground at **4% opacity**, one step above the 3% texture so the two read as separate layers rather than mud.
- The field is **behind** the texture layer, not above it.
- Under `prefers-reduced-motion` the field is unchanged: it does not move, so there is nothing to reduce. It is disabled entirely in Recruiter Mode, which is a quiet document.
- Each route gets a distinct field so navigation is legible at a glance. **They differ by arrangement, not by motif.** This file originally said each field would be drawn from its route's own subject — craft signs for the work grid, water and land signs for `/signal`. That was written when the inventory was an alphabet, and it is exactly the idea that produced the problem in §0: a field "about" a page's subject is a field making a claim. Each route seeds its own layout instead.
- **Nothing in a field spells anything, in any arrangement.** The previous rule here permitted a grid of phonetic signs on the argument that a grid does not read as a sentence. That argument was wrong and it is withdrawn. The field draws ornament, which has no sound value, so the question of what it spells does not arise — on a grid, in a line, or anywhere else.

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
