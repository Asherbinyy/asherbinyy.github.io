# 2026-09-23-02 — The wall behind the page, a picture beside the hero, and a life that runs on a loop

**Agent:** Claude / Opus 5.5
**Milestone:** Re-innovation, full ownership
**Started from:** `c7ad476` (main after PR #51)

## Goal

The owner's next round, built on a branch for him to test on localhost and
accept or reject: an n8n-style animation of his life beside the About portrait;
on a desk, the Home wall as a faint pattern behind the whole page with a hero
picture on the right that differs by night and day; more skills from his
resumes; the dissertation's 80%; the unfinished second game hidden and the
Icy Tower inspiration said; cards under the Home career entries; every section
on every page the same width.

## What changed

- **The Home wall is the page's background on anything wider than a phone.**
  It spans the window (not the capped frame) and rests at 0.2: the whole
  resting wall is drawn into one faded layer and the pointer's torch is drawn
  over it at full gold, so the carving is faint behind the reading and comes
  up wherever the hand holds the light. On a phone nothing changed: the strip
  and the page's reservation for it are as they were. The location cards the
  wall used to draw beside itself are gone (there is no clear ground for them
  any more; every career card prints its own location).
- **A picture beside the hero** (`HeroScene`, ≥900px of hero). Night on the
  dark theme, day on the light: moon and five-pointed stars; Ra's disc with
  Khepri rolling it over the horizon while it is low; a pair of obelisks with
  gilded pyramidions; the river; a desk with a laptop (code being typed), a
  phone showing an app, a cup; the game's climber sat at the desk in gold.
  The sun (or moon) is a button that toggles the theme, and a theme change —
  from there or from the header — is a 2.4 s dawn or dusk: the picture blends
  between the two palettes by the sun's height. Idle motion (stars, river,
  cursor, steam, pointer parallax) runs only while on screen and never under
  reduced motion. Day or night follows the rendered theme, not the stored
  choice, so it matches the page even under the app's external `themeMode`.
- **Home sections share one width.** Skills card full width (out of the hero
  column); career stops as a stretched grid; each career entry on a card with
  facts beside story on a wide card; the page ends on one panel — "Need
  something built?" with the Services page's own sentence and button, beside
  the contact links. On a phone the career card takes the whole column (no
  stop mark beside it) so names stop breaking mid-word.
- **About: the life loop** (`LifeFlow`) in the column held open beside the
  portrait: Life (the ankh) → Study → Code → Build apps → Automate → Gym, and a
  dashed wire back. A run travels through it: each node lights gold as it
  executes and keeps a tick, a gold packet moves down the wire to the next.
  Hover gives a faience ring. Reduced motion shows the finished run, still.
  Stacks under the biography on narrower screens.
- **About: open skills groups show five rows** and "N more skills" for the
  rest (the strings Home already uses). Courtyard teaser and contact block run
  the full width, contact on a panel as on Home and Services.
- **Writing grid stretches** to the full width on `/writing`, `/work` and
  `/about`; covers scale at their old proportions.
- **Courtyard:** the "Something else — a second game is coming" panel is gone;
  the Ascent panel runs full width with a still of a fresh run (the game's own
  painter) beside it on a wide screen, and the Icy Tower line under the pitch.
- **Content:** 34 skills and 9 tools added from `main resume.pdf` (CV2 SKILLS)
  plus Docker from the owner; the dissertation line reads "Dissertation (80%)"
  in both languages. Provenance rows for all of it, and the AZ Courses
  15,000+ (CV) vs 8,000 (LinkedIn) conflict recorded.
- **Fixes found on the way:** the "Social links" label could not wrap and
  overflowed inside a phone-width panel; `AnimatedSize` with reduced motion's
  zero duration asserted when a full-width panel changed size mid-layout
  (`SettlingSize` is just the child under reduced motion).

## Files touched

- `lib/app/chrome/chrome_scaffold.dart` — modified — the wall layer fills the window
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — new strings (AR literal English); the second-game strings removed
- `lib/app/theme/tokens.dart` — modified — new tokens only (listed under Decisions)
- `assets/content/profile.json` — modified — skills 13→47, tools 8→17 (owner-requested)
- `assets/content/education.json` — modified — dissertation mark (owner-requested)
- `lib/core/motion/settling_size.dart` — created — AnimatedSize that is the child under reduced motion
- `lib/core/painting/hero_scene_painter.dart` — created — the hero picture
- `lib/core/painting/life_flow_painter.dart` — created — the loop's wires and run
- `lib/core/painting/wall_painter.dart` — modified — `restAlpha`; faded layer + torch pass
- `lib/core/widgets/profile_skills.dart` — modified — SettlingSize
- `lib/features/about/presentation/about_screen.dart` — modified — life loop in the held column; full-width sections
- `lib/features/about/presentation/widgets/contact_links.dart` — modified — label wraps
- `lib/features/about/presentation/widgets/life_flow.dart` — created — the life loop
- `lib/features/about/presentation/widgets/skills_panel.dart` — modified — five-row preview; SettlingSize
- `lib/features/courtyard/presentation/courtyard_screen.dart` — modified — placeholder gone; full-width panel with still
- `lib/features/station/presentation/station_screen.dart` — modified — hero row, skills, closing panel
- `lib/features/station/presentation/widgets/career_sequence.dart` — modified — entries on cards
- `lib/features/station/presentation/widgets/career_stops.dart` — modified — stretched grid
- `lib/features/station/presentation/widgets/hero_content.dart` — modified — skills moved out
- `lib/features/station/presentation/widgets/hero_scene.dart` — created — the picture's widget and sun button
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — full width on a desk, no labels drawn
- `lib/features/writing/presentation/widgets/article_card.dart`, `writing_list.dart` — modified — stretched grid
- `docs/12-MOTIF-LIBRARY.md` — modified — #17 Ra's disc, #18 star; new uses of #2/#4/#6/#7/#10
- `docs/14-PROVENANCE.md` — modified — September 23 section
- tests — see Tests; 11 goldens regenerated after review

## Decisions made

- **Wall resting strength 0.2, not the owner's 0.5.** At 0.5, and at 0.3, pale
  signs ran through the grey positioning line in a browser. The torch lifts a
  sign to full gold, so the wall still reads as the pattern he asked for.
  One number (`wallPatternOpacity`) if he wants it stronger.
- **No pyramids or palms in the picture**: the motif library excludes them.
  The culture is carried by Ra's disc, Khepri, obelisks and tomb-ceiling
  stars. Two motifs added to the library on the owner's request (#17, #18).
- **The picture is painted, not an image.** It changes with the theme, the sun
  moves, and it is a control; a raster from an image model could not do those
  without layered assets. If the owner prefers an illustrated figure, a Nano
  Banana image can replace the foreground later.
- **The life loop stays inside the palette**: gold for the run (live state),
  limestone at rest, faience on hover. The owner asked for "colorful"; a
  fifth hue needs him to relax `01-DESIGN-SYSTEM.md` §2.
- **Skills stay a flat list** (no categories): grouping would change
  `profile.json`'s schema, which the admin editor and the deployed Worker
  validate against — a coordinated Worker deploy the owner has not asked for.
- **Arabic**: every new string is literal English in `app_ar.arb`, per the
  standing policy (`27-CONTINUE-HERE.md`); the list is in Known issues.
- **Trace tests restated, not deleted**: "keeps a column of its own" and "the
  wall never reaches the copy" became "is the background of the whole page"
  and "covers the window at every desk width"; "a locked label sits in the
  gap" was removed because those labels are no longer drawn; the torch test
  now leaves the window rather than the column. `TraceBurstLabel` and the
  label data are kept, undrawn, so the column can come back in one change.
- **New tokens:** `wallPatternOpacity` 0.2; `heroSceneAspect` 0.96,
  `heroParallaxEase` 0.08, `heroSunTravel` 2400 ms, `heroSunTargetScale` 2.6,
  `heroSunFocusRadius` 999, `heroSunSplashAlpha` 0.18, `heroSceneMinWidth` 900,
  `heroCopyFlex` 11, `heroSceneFlex` 9; `lifeFlowStep` 1400 ms,
  `lifeFlowHeight` 560, `lifeFlowNodeSize` 56, `lifeFlowLabelWidth` 120,
  `lifeFlowMaxWidth` 420, `lifeFlowGlowAlpha` 0.35, `lifeFlowGlowBlur` 18,
  `lifeFlowTickSize` 18, `lifeFlowTickInset` 6; `careerCardSplitWidth` 720,
  `careerFactsFlex` 2, `careerStoryFlex` 3; `stopCardMinWidth` 220;
  `skillsPreviewCount` 15; `courtyardStillHeight` 240, `courtyardStillSeed` 7
  (replacing the now-unused `courtyardPanelWidth`).

## Tests

- Added: `hero_scene_test.dart` (4), `courtyard_test.dart` (4),
  `life_flow_test.dart` (4), `skills_preview_test.dart` (1),
  `home_sections_test.dart` (3), a Writing full-width test,
  `hero_scene_painter_test.dart` (5), `life_flow_painter_test.dart` (3).
- Modified: `trace_test.dart` as above.
- Goldens: 11 regenerated after master/new/diff review (railed chrome ×4,
  recruiter, hero ×4, hero with stats, hero unavailable). Every compact
  golden passed unchanged — the phone layout is as it was.
- Full suite: pass, 829 passing, 0 failing; coverage 85.0%.

## Verification run

```
fvm dart format --set-exit-if-changed .   pass — exit 0, 350 files, 0 changed
fvm flutter analyze                        pass — No issues found
fvm flutter test --coverage                pass — 829 passed, 0 failed, 85.0%
fvm flutter build web --wasm               pass — Built build/web
```

Browser: every change captured against the Wasm build at 1440×900 and
390×844 (dark and light; the dawn captured frame by frame after pressing the
moon). No console errors in any capture.

## Known issues left open

- **Arabic needed** for: `courtyardGameInspiration`, `heroSceneSunset`,
  `heroSceneSunrise`, `aboutFlowLife`, `aboutFlowStudy`, `aboutFlowCode`,
  `aboutFlowApps`, `aboutFlowAutomate`, `aboutFlowGym`, `aboutFlowLabel`.
- The overall MSc mark stays 79; whether it includes the dissertation is the
  owner's to confirm.
- AZ Courses downloads: 15,000+ (CV, site) vs 8,000 (LinkedIn).
- The resume says 4+ years; the site's stat says 5+ (owner-supplied earlier).
- The pointer torch now answers anywhere on a desk page; on touch it is held
  at the reading position as before.

## Next

The owner reviews this branch on localhost and says which parts to keep.
