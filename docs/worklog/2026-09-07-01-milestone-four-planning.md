# 2026-09-07-01 — Direction change: Ground Station retired, milestones 4–6 specified

**Agent:** Claude Opus 5 (Claude Code)
**Milestone:** 4 (planning)
**Started from:** `c8b9b87` — "fix(content): stop hedging the award the CV confirms"

## Goal

The owner set a new direction: replace the ground-station concept with an
Egyptian one, and fix a list of content, accuracy and interaction defects
first. Specify all of it well enough that another agent can execute it without
re-deriving the decisions. **No feature code was written this session** — docs
only, per `AGENTS.md` §2.

## What changed

**Four decisions were put to the owner and answered.**

1. **The amber-only palette rule is replaced** by four pigments each locked to one job — gold (the person and every action), faience (interaction feedback only), carnelian (errors only), and graded limestone/ink for everything else. A fifth hue remains forbidden. This required the owner's explicit approval under `AGENTS.md` §8 because it overturns a hard rule.
2. **Codename KEMET**, the Dart package left as `nocturne`. Renaming ~190 files' imports would bury the redesign inside a mechanical diff. The doc-to-token mapping is recorded once in `01-DESIGN-SYSTEM.md` §2.
3. **Arabic content ships agent-written**, on the owner's instruction, with a review file rather than a blocking gate. This is a deliberate, owner-authorised exception to `AGENTS.md` §3 and is recorded as such.
4. **Three milestones, each shipping**: 4 Provenance, 5 Kemet, 6 The Ascent.

**Both palettes were solved, not chosen.** Every role was moved on lightness
alone, preserving hue and saturation — the method recorded in
`2026-09-06-07-daybreak-contrast.md` — until it met its floor on all three
surfaces. Verified against every assertion in `contrast_test.dart`, including
the two new faience roles and all five structural "two distinct artifacts"
tests. Worst margins: `text-muted` 4.54:1 on Kemet raised, `gold` 4.52:1 on
Deshret surface. Kemet's ground is `#121826` — 4.4× the relative luminance of
the old `#05070A`, which is the owner's "too dark" complaint answered with a
number rather than a feeling.

**The owner's central complaint was that the site invents figures.** It mostly
does not: every number traces to his CV. But nothing in the repository could
demonstrate that, which is the actual defect. `14-PROVENANCE.md` now maps every
claim to a source, and `AGENTS.md` §3 now requires a provenance row before a
number may ship.

Two claims were found genuinely wrong, and one unverifiable:

- **"Six countries" overstates the CV**, which names five countries of delivery plus the UK as residence. Guardy — verified as a real German product from Guardy GmbH, Düsseldorf — would make six honest.
- **AZ Courses downloads** are 15,000 on the CV and 8,000 on the owner's LinkedIn. The site shows 15,000. Not resolvable from the sources.
- **CI Company's end date** is 04/2023 on the CV and Jul 2023 on LinkedIn.

**Nine further defects were found and recorded** in `11-OPEN-ISSUES.md` §0b,
including one the owner did not report: the README claims "Nothing is stored on
the visitor's device", which has been false since milestone 1 because theme,
language and Recruiter Mode persist through `shared_preference_store.dart`.

**Sources read this session.** The owner's CV (extracted with Swift PDFKit —
`pdftoppm` is absent on this machine and the PDF's text layer is CID-encoded, so
neither the Read tool nor a stdlib extractor could open it), both LinkedIn
screenshots, and the Medium profile screenshot. The LinkedIn projects screenshot
yielded **sixteen projects with the owner's own descriptions**, none of which
were on the site, including **Easy Go — an open-source Flutter package** that is
the only open-source artifact in the whole record.

## Files touched

- `AGENTS.md` — modified — palette rule replaced; provenance requirement added to §3; §1 reading list extended; worklog milestone range widened to 6; stale `cupertino_ui` reference corrected
- `docs/00-PROJECT-BRIEF.md` — modified — §2 gains the personality goal and the rule for when it conflicts with the first; §3 rewritten as the Black Land; §4 adds `/ascent`; §8 rewritten; new §9 "What this site will not do"
- `docs/01-DESIGN-SYSTEM.md` — modified — §1 principles and §2 colour fully rewritten with both solved palettes and the doc-to-token mapping
- `docs/09-ROADMAP.md` — modified — status header; milestones 4–6 with definitions of done; owner checklist replaced by a pointer to the provenance ledger
- `docs/11-OPEN-ISSUES.md` — modified — §0a direction change and the three changed standing rules; §0b eleven findings
- `docs/12-MOTIF-LIBRARY.md` — **created** — the closed motif inventory, the anti-kitsch rules, the cartouche transliteration, the glyph-field performance contract, the cursor and sound rules
- `docs/13-GAME-DESIGN.md` — **created** — The Ascent
- `docs/14-PROVENANCE.md` — **created** — every claim mapped to a source; fifteen open items needed from the owner; the sixteen LinkedIn projects; the six Medium articles
- `docs/worklog/README.md` — modified — full index of all nineteen prior sessions, and what survives the change of concept
- `docs/worklog/2026-09-07-01-milestone-four-planning.md` — created — this file

## Decisions made

**The palette ships in milestone 4, not 5.** It is a 36-line change in
`tokens.dart` plus the contrast suite, it fixes a live complaint immediately,
and it means milestone 5 never repaints anything twice. Colour is cheap and
high-value; form is expensive. Sequencing them separately de-risks the redesign.

**Typography does not change at all.** This is the main thing keeping the theme
out of costume — the motifs carry the identity and a clean modern grotesque lets
them. It also protects the Arabic weights, the 556KB font budget settled in
`11-OPEN-ISSUES.md` §3.12, and every golden whose geometry depends on current
metrics.

**The system cursor is never replaced.** The owner asked for a magic cursor.
What is specified is a trail that follows the real pointer, because replacing a
cursor silently breaks pointer-size, high-contrast and accessibility settings.

**No hieroglyph is invented.** The one place the site spells anything is the
cartouche, using the Egyptian uniliteral signs — the same phonetic practice
Ptolemaic scribes used for foreign names, so it is the historically correct
method rather than a pastiche of one. It is marked unverified in
`14-PROVENANCE.md` §3.14 until someone who reads Egyptian checks it. Fabricated
writing on a site whose argument is "nothing here is made up" would be
self-defeating.

**The game gets its own milestone.** Folding it into the redesign would block
the redesign's release on an engine, six audio samples and an accessibility
story. It is also specified to be *useful* — altitude bands unlock real facts
from `assets/content/`, and every fact stays readable without playing, so no
experience is gated behind reflexes.

**A live LinkedIn feed is not buildable** and is recorded as such in
`00-PROJECT-BRIEF.md` §9. Reading one's own posts requires `r_member_social`,
gated behind LinkedIn's Marketing Developer Platform partner approval and not
available to an individual. The alternatives are a third-party scraping bridge —
an external data flow on a site whose argument is that it has none — or
hand-maintained JSON, which is a worse Medium.

**Worklogs kept, not wiped.** The owner asked. Reasons in
`docs/worklog/README.md`; the index is the fast path instead.

## Tests

- Added: none — no feature code this session.
- Modified: none.
- Full suite: not run. Nothing executable changed; the only file under `test/` that this session's decisions affect is `contrast_test.dart`, which task 4.10 will extend.
- The palette was verified against that suite's assertions **arithmetically, outside the repository**, not by running it. Task 4.10 must run it for real. This is a checked prediction, not a passing test, and must not be reported as one.

## Verification run

Not run — documentation only, no Dart touched.

```
fvm dart format --set-exit-if-changed .   not run
fvm flutter analyze                        not run
fvm flutter test                           not run
fvm flutter build web --wasm               not run
```

## Known issues left open

- **Fifteen content items are blocked on the owner** — `14-PROVENANCE.md` §3. The largest are Guardy's dates and role, the AZ Courses download figure, the "74% → 75%" mark whose module cannot be identified (there is no 74 in `education.json`), and which of the sixteen LinkedIn projects may be published.
- **`docs/02-SCREEN-SPECS.md` and `docs/07-CONTENT-SCHEMA.md` have not been updated** to the new concept. They still describe the ground station, and 07 has no schema for hobbies, screenshots, the name recording or game facts. Deliberately deferred: both should be written against real implementation decisions during 4.3–4.5 rather than guessed now. **An agent reading 02 before 00 will get the old concept.**
- `docs/06-ANALYTICS-AND-PRIVACY.md` is untouched and still accurate — nothing about collection changed.
- The Guardy App Store listing was **not** verified; the fetch was rate-limited. `guardyapp.de` was verified.
- The cartouche transliteration is unverified.
- Everything in §1–§5 of `11-OPEN-ISSUES.md` from milestones 1–3 remains open, including the real-phone check, which has still never been performed.

## Next

**Task 4.1 — the claim audit**, because every other milestone-4 task writes
content and they should all write it against a completed ledger rather than
retrofitting provenance afterwards. It also closes the owner's actual
complaint first.

It needs answers to `14-PROVENANCE.md` §3.2 and §3.5 to finish, but the audit
itself, the ledger test, and the README storage correction can all proceed
without them.
