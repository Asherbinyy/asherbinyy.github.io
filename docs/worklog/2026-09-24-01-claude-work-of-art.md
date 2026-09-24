# 2026-09-24-01 — The work of art round: nine screenshots, the Ascent v3, the intro

**Agent:** Claude / Opus 5.5
**Milestone:** Re-innovation, full ownership
**Started from:** `b1d8af7` (main after PR #52)

## Goal

Everything in the owner's nine annotated screenshots of 2026-09-23 (Home hero, skills and career, Work, Home closing panel, About contact and top, Courtyard, the game, the intro), plus a UI/UX pass on the brief, Arabic for every string, and his answers on AZ Courses, experience and the MSc. On a branch for localhost review; nothing merged or deployed.

## What changed

- **Hero picture** (`hero_scene_painter.dart`, `hero_scene.dart`): edge-faded into the page (no frame); a 12-course pyramid whose top four courses a tower crane sets a block at a time (slung block, swing, pick-up behind the right screen), the dashed "plan" of the finished faces; two curved monitors, the left mirroring the phone beside a code editor, the right an automation (Pick, Lift, Place) lit in step with the crane plus a progress bar; the owner redrawn seated on a chair: skin, a contoured arm so the shoulder reads, a broad collar, a real nemes with lappet. Sun rests higher, clear of the jib. By day the pyramid's sunlit face takes the sky's light.
- **Flags** (`reach_row.dart`): each flies on hover (lift, scale, rippled cloth in strips, fold shading); a tap flies it briefly; still under reduced motion.
- **Skills** (`skill_groups.dart`, replaces `profile_skills.dart` and `skills_panel.dart`): gold group titles, one open at a time, natural-width chips staggering in; learning folded in; tools the last group. `profile.json` gains `skillGroups` (Worker schema updated).
- **Career cards** (`career_sequence.dart`, `stop_mark.dart`): rise-in reveal (new `RevealStyle.rise`, `RevealOnScroll.of` exposes progress); a timeline band per card (whole career, this stop inked in as it arrives); the stop's sign as a faint relief; flags; "Built here" app chips linking to /work/:id. Freelance's words translated.
- **Closing panel** (`station_screen.dart`, new `app_being_built.dart`): new copy ("Got an app in mind?"), the services with their marks, and a phone whose app drops together block by block (only while visible; finished under reduced motion). Back-to-top centred.
- **Work** (`work_card.dart`, `work_screen.dart`, new `app_maker.dart`): fanned store screenshots over the seeded ground (spread on hover, give on press, front screen lifts before the page opens); maker line (flag + company / Personal project); rows fill in order (`EvenGrid.balance`); staggered rise. **App page** (`app_detail.dart`) rebuilt: staged entrance, back link, big fan that opens, headline metric, fact cards, screens strip, "More from <company>". `ShippedApp.client`, `Engagement.personal` added (Worker schema too).
- **About**: life loop is an ankh (`life_flow_painter.dart` rewritten: nodes on loop, bar and stem; run travels the sign), "Wake up" replaces Life, caption on the ankh's meaning; `courtyard_door.dart` (climb still + four interest scenes that replay on hover); contact tiles denser, "or"/"Social links" in the reading face; booking card capped at 380 with a shadow clock.
- **Courtyard**: Scoreboard now calls `refresh()` before opening — it never fetched, so it always said the board was away; proper dialog (title, close, Play); hidden when the build has no board. Sentences on their own lines. Header brazier lifted when unlit (was 5px low).
- **Brief (in-app `recruiter_view.dart`)**: 48px between sections and after skills, shipped apps in two columns, metric wraps.
- **The Ascent, contract v3** (Dart `ascent_world.dart`, `ascent_run.dart`, `ascent_contract.dart`; JS `worker/src/game/ascent.js`, `verifier.js`): 8 levels (Temple, Sands wind, Frozen Nile ice, Duat dark, Hall of Ma'at, Apep's Coils, Lake of Fire, Field of Reeds wind+ice); full-width ledge opening each level; relics on seeded band schedules (ankh = extra life, max 3, every 100–150 m; eye = floor ×0.3 for 10 s, ~50 m; feather = 2 air jumps for 5 s, ~50 m); a spent life respawns on the highest whole ledge with the floor 6 m below; summit 800 m ends the run as a win; floor speed capped at 5 m/s; the verifier accepts a win as a complete run. Presentation: relics drawn from `SignPaths` with rings/bob/sway, sand streaks, Duat lamp, ice sheen, gold landing floors, summit line, climber in skin with a 1.6× head; HUD lives and draining effect bars, relic/life news line, level names and hints, legend (first open per visit, in memory only) and info button, golden-mask reward screen, 👑 King on the board for 800 m. Six new synthesised sounds (`tool/audio/make_sounds.py`).
- **Intro** (`web/intro/*`, `web/index.html`): opens after 2.2 s (was 4.2) and finishes in 2.1 s (was 3.7); staff strike with wind-up, slam, overshoot and a gold ring on the sand; Bastet in black stone (left); "Knock to enter" in shimmering gold replaces "The door is sealed."
- **Arabic**: all 13 remaining English strings translated, plus every new string.
- **Content** (owner-supplied): see `14-PROVENANCE.md` "September 23, second round".

## Files touched

- `lib/core/painting/hero_scene_painter.dart`, `life_flow_painter.dart`, `ascent_painter.dart` — modified
- `lib/core/widgets/skill_groups.dart` — created; `profile_skills.dart`, `features/about/.../skills_panel.dart` — deleted
- `lib/core/widgets/reveal_on_scroll.dart`, `even_grid.dart` — modified (rise style, progress scope; `balance`)
- `lib/features/station/presentation/{station_screen,widgets/career_sequence,widgets/stop_mark,widgets/reach_row,widgets/hero_scene,widgets/hero_content,widgets/back_to_top}.dart` — modified; `widgets/app_being_built.dart` — created
- `lib/features/work/presentation/{work_screen,widgets/work_card,widgets/app_detail}.dart` — modified; `lib/content/app_maker.dart` — created
- `lib/features/about/presentation/{about_screen,widgets/life_flow,widgets/contact_links}.dart` — modified; `widgets/courtyard_door.dart` — created
- `lib/features/courtyard/presentation/courtyard_screen.dart`, `game/domain/*`, `game/presentation/{ascent_stage,widgets/leaderboard_panel}.dart` — modified
- `lib/features/recruiter/presentation/recruiter_view.dart`, `lib/features/services/presentation/services_screen.dart` (public `serviceIcon`), `lib/app/chrome/theme_brazier.dart` — modified
- `lib/content/models/{apps,profile}.dart`, `lib/app/theme/tokens.dart`, `lib/app/l10n/app_{en,ar}.arb` — modified
- `assets/content/{apps,career,profile,education}.json` — modified (owner-supplied); `assets/media/apps/*/` — store screenshots added; `assets/audio/{ankh,eye,feather,life,win,sand}.wav` — created; `pubspec.yaml` — asset folders
- `worker/src/game/{ascent,verifier}.js`, `worker/contracts/content-schema.js`, `worker/contracts/fixtures/ascent-vectors.json` — modified
- `web/index.html`, `web/intro/{intro,threshold}.js`, `web/intro/models/{bastet.kmsh,LICENSE.md}`, `README.md` — intro and credits
- `tool/generate_ascent_vectors.dart`, `tool/audio/make_sounds.py`, `tool/mesh/decimate_stl.py` (keep-upright flag) — modified
- `docs/12-MOTIF-LIBRARY.md`, `docs/14-PROVENANCE.md`, `CHANGELOG.md` — modified

## Decisions made

- **Skin is a token outside the four pigments** (`Tokens.figureSkin`/`Shade`), for the drawn person only, at the owner's explicit request. Recorded in the motif library.
- **Pyramid in the hero, sand/eye/mask in the game**: owner-requested exceptions, each written into `12-MOTIF-LIBRARY.md`.
- **Relics are placed on band schedules, not per-ledge odds**, so spacing stays within what the owner asked (never a clump, never a 300 m drought) and is a pure function of the seed. Wind is a triangle wave, not `sin`, so Dart and JS agree to the bit.
- **Floor cap 5 m/s**: at 3.4 the generator's frame-perfect bot won every seed; at 5.0 it wins 3 of 7 and spends 4–5 lives. "Very hard to win" for a human.
- **Legend "first time" is per visit, in memory**, not stored — avoids a new storage write; the info button reopens it.
- **Scoreboard on localhost**: the Worker allows only `SITE_ORIGIN`, so the board will always say "away" on localhost. Not changed — it is a production security setting.
- **No hero transition between routes**: routes are `NoTransitionPage`; the "click" animation is done within the card instead of changing navigation site-wide.
- **Services list stays English in Arabic**: it is a plain string list in the content schema; localising it changes the published content's shape.
- **Anubis not delivered**: no openly licensed Anubis scan could be fetched (Scan The World's Anubis shrine needs a MyMiniFactory login). Bastet is a CC BY 4.0 model (Thingiverse, via Commons).
- **`decimate_stl.py` gained a keep-upright flag**: its plumb-line fit tilted the seated cat.
- **New tokens**: skills*, flag*, heroSceneFade*, booking*, revealRise*, careerAppThumb, careerRegister*, careerRelief*, figureSkin*, appBuild*, closingIllustrationFrom, serviceTagIconSize, work*/workFan*, appPage*/appFact*/appSibling*, contactSocialWidth, boardDialog*/boardBarrierAlpha, door*, ascentNewsHold, ascentHud*/ascentLegendMark/ascentMask*.

## Tests

- Added: `skill_groups_test.dart` (4), `ascent_relics_test.dart` (9), a life-loop caption test, ankh-geometry painter tests (2), relic-placement vector tests (Dart and JS).
- Modified: vector tests for v3 fields; Worker claims test (third stat); Work metric read from content; CV/signal tests for the Techlab rename; the CV chronology test (it compared against a company not on the page, so it could not fail).
- Goldens: hero ×4, hero stats, hero unavailable, railed chrome ×4, recruiter, console ×4, signal ×5, compact chrome ×4 — regenerated after reviewing each diff (hero picture; brazier lift; two Journey marker rings; brief spacing).
- Full suite: pass, 844 passing, 0 failing. Worker: 328 passing, 0 failing.
- Coverage: 81.0% (was 85.0%; the game stage's new HUD, legend and mask and the app page are not widget-tested).

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — 353 files, 0 changed
fvm flutter analyze                        pass — No issues found
fvm flutter test --coverage                pass — 844 passed, 0 failed, 81.0%
fvm flutter build web --wasm               pass — Built build/web
cd worker && node --test test/*.test.js    pass — 328 passed, 0 failed
```

Browser (Wasm build, localhost): Home, Work, /work/az-courses, About, Courtyard, the brief, the game (legend and a climb) and the intro captured at 1440×900. One intermittent `Exception` logged on /about in one of three identical runs, not reproduced since; likely a relay fetch refused from localhost.

## Known issues left open

- **Worker deploy must ship with the merge.** Game contract v3 and the `skillGroups`/`client`/`personal` content fields need `worker/` deployed; a v3 client against the v2 Worker gets every ranked run rejected. The v3 board is a new board (`v3`), so old v2 entries do not carry over.
- **Anubis**: needs an openly licensed scan supplied by the owner (Scan The World download, then `tool/mesh/decimate_stl.py`).
- **Services** show in English on the Arabic site (schema is a string list).
- Game levels 4–7 differ in ledges and pace; only the Sands, Frozen Nile and Duat have their own look.
- Coverage fell 4 points; widget tests for the game HUD/legend/win screen and the app page are owed.
- The static `/brief` page was checked and needed no change; the audit's fixes are on the in-app brief.
- Intermittent /about console exception, above.

## Next

The owner reviews the branch on localhost (`fvm flutter build web --wasm`, then serve `build/web`). If accepted: open the PR, deploy the Worker, then merge — in that order, so ranked climbs are never judged by the old rules.
