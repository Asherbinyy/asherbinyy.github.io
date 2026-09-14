# 2026-09-14-02 — Taking both trees, and the first About slice

**Agent:** Claude / Opus 5
**Milestone:** Re-innovation, full ownership
**Started from:** `48f4076` (public), `4e75259` (admin)

## Goal

Take ownership of both trees, preserve everything uncommitted, apply the tested
rotation fix, and make the first reviewed visual slice: About — education and
skills.

## What changed

**Preservation first.** 73 uncommitted items in the public tree, 50 tracked and
23 untracked. Snapshotted externally to
`nocturne-snapshots/2026-09-14-pre-integration/` — a binary-safe patch that
reverses cleanly against the working tree, plus a tar of every untracked file —
then committed as `6f85156` so the diff is reviewable rather than floating.
Nothing was rolled back.

**The rotation blocker.** Reproduced on `4e75259` first: a stale password change
returned 200 where 401 is required. Applied `admin-rotation-fix.patch`, which
moves the generation read inside the rotation transaction and compares it
before any write. 280 Worker tests pass; both independent reproductions now
answer 401. Committed on the admin branch as `edfd04c`.

**Education.** The owner's complaint was that he was being told things twice.
He was right: every module with an artefact appeared once in the transcript and
again in a second row underneath, with the same name and the same mark in a
different shape.

Each module now appears once, carrying its own coursework at transcript size
and opening the same full-size dialog. Modules without a supplied artefact keep
their place with a drawn placeholder rather than a stand-in photograph — the
owner may supply those later, and filling the gap with a picture of something
else would be claiming an artefact that does not exist. The list is held to a
readable measure; across a 1440px page the mark had ended up half a metre from
the module it graded.

The two runs are named now: **Modules** and **Projects**. Before this, a reader
met a column of numbers and a pair of unlabelled cards and had to work out what
either was.

**Skills.** The three groups were drawn as identical grey pills, which said
that five years of Flutter and a fortnight of LangChain were the same kind of
claim. They are not, and the owner was explicit that he is *learning* the
second group — so the page has to show both that he works in this area and that
he is not overstating it. Skills now carry the gold rule this site reserves for
the person and for what is live; Currently learning is outlined in dimmer ink,
visibly a different assertion; Tools is one small line, because a list of
editors is context rather than a qualification.

## Files touched

- `lib/features/about/presentation/widgets/skills_panel.dart` — rewritten — three tiers that do not look alike.
- `lib/features/about/presentation/widgets/education_table.dart` — modified — module rows carry their own coursework; section headings; readable measure; the duplicate artefact row removed.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — four strings.
- `worker/dev/browser.js` (admin tree) — modified — real wheel and click input, so a Flutter canvas can actually be scrolled by a capture run.
- `docs/audits/2026-09-14/about-slice/*.png` — created — before and after, desktop and phone.

## Decisions made

**A missing artefact gets a drawn placeholder, not a picture.** The owner asked
for a default image. A photograph of something else in the slot where his
coursework goes would read as coursework. A marked empty plate says what it is.

**The Arabic strings carry the English text.** Four new keys, and the owner
supplies translations. Inventing them is forbidden and leaving the keys out
breaks the build, so they fall back visibly.

**No layout or navigation change.** The handoff is explicit, and the page
mergers in the owner's original transcript are not authorised by the current
instruction.

## Tests

- Full suite: **pass, 693 passing, 0 failing.** The two About tests that cover
  this area — the coursework opening, and a module with no artefact rendering
  its mark alone — still pass against the new structure.
- Worker suite after the patch: **pass, 280 passing.**

## Verification run

```
fvm dart format --set-exit-if-changed .   pass, 0 changed
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 693 tests
fvm flutter build web --wasm               pass, build/web generated
node --test worker/test/*.test.js          pass, 280 tests (admin tree)
```

Rendered in Chrome at 1440x900 and 390x844 against a local server with the SPA
fallback GitHub Pages gets from its 404 copy. Captures in
`docs/audits/2026-09-14/about-slice/`.

## Known issues left open

- **The right third of the About header is still empty.** The skills block has
  hierarchy now but not the width; the top board still does not fill its space.
- **Home still prints skills as three grey sentences.** Same content, worse
  presentation than About now has. Next slice.
- **Arabic for the four new strings is English.**
- The unchanged large items: real Flutter preview, HTML release parity, content
  renderers, A5, both halves of the leaderboard, papyrus on the two Home cards,
  football, game and intro.
- No physical-device test has ever run.

## Next

Home: the same treatment for skills, the career column as a grid, and the
papyrus roll on the 5+ and MSc cards only.
