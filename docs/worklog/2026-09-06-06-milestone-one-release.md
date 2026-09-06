# 2026-09-06-06 — Hero stats, the open-issues register, and the Milestone 1 release

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 63ff964

## Goal
Close out Milestone 1: confirm Actions on the trace-anchor commit, add the two
hero statistics the supplied documents state, stand up a durable open-issues
register, and merge `phase/1-ground-station` into `main` to publish the site.

## The Actions check the previous session was waiting on
Run 34031900691 completed **success** on `63ff964`, the exact trace-anchor SHA.
Both verification jobs passed. That closes the open item the previous handoff
left under "Next".

## What changed
- Added a `stats` block to `assets/content/profile.json` with exactly two
  entries — `25+ shipped` and `6 countries`. Both are traceable to supplied
  documents rather than inferred, and the owner authorised this specific edit
  to owner content.
- Replaced the station widget test that asserted "no panels because the shipped
  profile declares none" with two tests: one proving a profile *without* a
  stats block still renders none, and one locking the two panels the shipped
  profile now declares.
- Made the hero's primary-action test scroll the button into view before
  tapping it, because the panels move it below the fold at 1200×900 while the
  consent banner still holds its row.
- Regenerated the eight golden baselines the panels legitimately change.
- Created `docs/11-OPEN-ISSUES.md` — a standing register of everything
  incomplete, blocked or provisionally decided, including a plain description
  of what the real-phone check actually is.
- Added `docs/11-OPEN-ISSUES.md` to the required reading in `AGENTS.md` §1, so
  it is read rather than written and forgotten.
- Wrote the `CHANGELOG.md` 0.1.0 entry, which was an empty file.

## Files touched
- `assets/content/profile.json` — modified — the two documented statistics.
- `test/widget/station/station_test.dart` — modified — two stat-panel tests, and the scrolled CTA tap.
- `test/golden/goldens/hero_{dark,light}_{en,ar}.png` — modified — approved stat-panel baselines.
- `test/golden/goldens/chrome_railed_{dark,light}_{en,ar}.png` — modified — approved stat-panel baselines.
- `docs/11-OPEN-ISSUES.md` — created — the standing open-issues register.
- `AGENTS.md` — modified — §1 now requires reading the register.
- `CHANGELOG.md` — modified — the 0.1.0 release entry.
- `docs/worklog/2026-09-06-06-milestone-one-release.md` — created.

## Decisions made

**Two panels, not the spec's three.** `02-SCREEN-SPECS.md` draws three: "25
shipped", "5 countries", "4 years". Only the first two are supported by
supplied text, and one of those had to be reconciled: the hero diagram says
five countries, while `00-PROJECT-BRIEF.md` §2 and §3 and the `/brief` block
all say six and name them — Egypt, Saudi Arabia, Armenia, Qatar, Canada, the
UK. Six is what the rest of the corpus says, so six is what shipped, and the
diagram is recorded as the outlier to correct. "4 years" appears only as "4
years commercial" in the `/brief` block; nothing supplied dates it and a tenure
figure decays on its own, so it was left out rather than guessed. Supplying it
adds the panel with no code change.

**The stat labels are English-only.** `LocalizedText` falls back to English for
a null `ar`, per `AGENTS.md` §3. This is the same posture as every other
content field on the site.

**The below-the-fold consequence was investigated, not assumed.** The first
symptom was a failing tap in the primary-action test, whose hit test landed on
the consent banner. That looked like the banner overlaying the hero, which
would have been a genuine defect. It is not: the banner and footer are `Column`
siblings above an `Expanded` scroll area, so they reserve space rather than
overlay. The real effect is that the panels push the actions past the scroll
viewport's edge, and measuring the golden frames shows the viewport grows from
roughly 670px to 795px once the banner is answered — which puts the actions
back above the fold from the second view onward. The test now scrolls rather
than hiding this, and the trade-off is recorded as open issue 3.1 rather than
resolved by an agent, because tightening hero spacing would mean a new spacing
token and that is a design decision.

**The goldens were reviewed before regenerating, not blind-updated.**
`05-TESTING.md` is explicit about this. The master and test images were
compared directly: the only difference is the two panels appearing and the
action row moving below the visible area. Exactly eight baselines changed —
the four `hero_*` and the four `chrome_railed_*`, all of which render the
station hero. The `chrome_compact_*` and every other baseline are untouched.

**The register is a new document rather than another worklog.** Six worklogs
now each carry a "Known issues left open" section, and the same items —
the twelfth app, the Arabic review, the phone check — recur in several of them
with no single place saying which are still true. `docs/11-OPEN-ISSUES.md`
holds current state; worklogs stay historical.

## Tests
- Added: `renders the two panels the shipped profile declares`.
- Modified: `renders no stat panels while the content declares none` now uses a
  stats-free override rather than relying on the shipped content having none;
  `the primary action navigates to the work ledger` scrolls before tapping.
- Full suite: pass, 435 passing / 0 failing. Worker suite: 12 passing / 0 failing.
- Coverage delta: 93.33% to 93.44% (3475/3719 lines), +0.11 points.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (200 files, 0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test                           pass (435 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```
Also `node --test worker/test/*.test.js`: pass, 12 tests.

## Known issues left open
All of them now live in `docs/11-OPEN-ISSUES.md` rather than being restated
here. The one that matters at this commit:

**Milestone 1 was published without the real-phone check.** `05-TESTING.md`
requires it before every merge to `main` and it has never been performed. The
owner was told what it involves, said to merge anyway, and asked for the notes
to be written down — which is §5 of the register. It should be the first thing
done against the live site, along with the four items in §4 that could only
ever be verified after a deploy.

The build still emits the missing Material/Cupertino icon-font warning; the app
bundles neither package.

## Next
The real-phone check and the four post-deploy verifications in
`docs/11-OPEN-ISSUES.md` §4 — the Lighthouse gate, live deep links, the beacon
end to end, and the favicon in browser chrome. Then Milestone 2, whose
unblocked tasks are 2.2, 2.3, 2.4, 2.5 and 2.7; 2.1 and 2.6 are waiting on
owner content and accounts.
