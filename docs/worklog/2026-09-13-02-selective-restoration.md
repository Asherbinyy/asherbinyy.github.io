# 2026-09-13-02 — Selectively restore useful improvements

**Agent:** Codex
**Milestone:** 4
**Started from:** 2026-09-13-01-content-only-rollback.md

## Goal
Restore the football animation and article covers the owner wanted back. Their follow-up also authorizes expandable education, clearer About skills, springier game controls/Egyptian character and removal of the intro bottom credit.

## What changed
- Reconstructed football with a grounded player, synchronized contact/flight/net response, 1.4s timing and actual G O A L. Reduced motion skips directly to the result; pointer exit does not reverse the shot.
- Bundled six original published article covers and a canonical-URL/source manifest. This fixes local cover absence when the relay rejects localhost; live feed metadata remains primary.
- Added expandable education cards with existing tokens and preserved evidence/marks/highlights. About gets grouped skills/learning/tools; Home and recruiter styling stays as retained in the rollback.
- Restored manual game input forgiveness and spring feedback, replaced the scarab with an Egyptian humanoid, and prevented repeated boosts from holding against one wall.
- Removed the bottom intro credit caption and linked the full existing licence/source record from About.
- Updated active scope docs, provenance, README, changelog and handoff. Broader rejected design remains removed.

## Files touched
- `lib/core/painting/football_scene.dart` — created — contact/flight/impact scene geometry.
- `lib/core/painting/interest_painter.dart` — modified — delegates only football to the restored scene.
- `lib/features/about/presentation/widgets/interests_grid.dart` — modified — shot timing, replay, reduced motion, GOAL caption and semantics.
- `lib/features/about/presentation/widgets/education_table.dart` — modified — expandable existing-token cards; direct reduced-motion layout path.
- `lib/features/about/presentation/widgets/skills_panel.dart` — created — grouped supplied skills, learning and tools for About only.
- `lib/features/about/presentation/about_screen.dart` — modified — skills component and artwork-credits link.
- `lib/features/courtyard/game/domain/ascent_world.dart` — modified — buffered/coyote input, variable height, momentum, one-jump-per-press and landing state.
- `lib/core/painting/ascent_painter.dart` — modified — humanoid/nemes silhouette and reduced-motion-aware landing squash.
- `lib/features/courtyard/game/presentation/ascent_stage.dart` — modified — reduced-motion route/entrance transitions.
- `lib/app/theme/tokens.dart` — modified — named football duration; no existing visual token value changed.
- `lib/app/l10n/app_en.arb`, `app_ar.arb` — modified — GOAL, expansion and credits labels; literal English pending Arabic review.
- `lib/features/writing/data/writing_providers.dart` — modified — safe bundled cover manifest and canonical article identity.
- `lib/features/writing/presentation/widgets/article_card.dart` — modified — bundled covers within existing image layout/fallback.
- `assets/content/writing-covers.json`, `assets/media/article-*` — created — sourced cover lookup and six unchanged originals.
- `web/index.html`, `web/intro/models/LICENSE.md` — modified — remove caption, record relocated attribution access.
- `test/unit/features/ascent/ascent_input_test.dart` — created — manual input, timing, height, braking and wall boost regressions.
- `test/unit/features/ascent/ascent_world_test.dart` — modified — hold jump for the full-height wall-kick test.
- `test/unit/features/writing/writing_fallback_test.dart` — modified — cover identity, asset existence and external-path rejection.
- `test/widget/about/selective_restoration_test.dart` — created — education collapse/reopen and reduced-motion football replay.
- `README.md`, `CHANGELOG.md`, active `docs/00`, `01`, `03`, `11`, `12`, `13`, `14`, `19`, `27` — modified — actual selective scope, provenance, remaining work and handoff.
- `docs/worklog/2026-09-13-02-selective-restoration.md` — created — this record.

## Decisions made
The owner explicitly authorized the named restorations and local About improvement. Preserve original layouts/backgrounds/Journey and all retained content. The deleted uncommitted implementations were reconstructed from the behavior, not recovered verbatim. No packages, route changes, SDK upgrade, data collection, admin edits, merge or deployment.

Use original published cover bytes, served locally; keep their source URLs in the manifest. This is a dated cover snapshot. The game’s spring is presentation plus forgiving manual input, not unsolicited automatic jumping. Keep skill groups distinct so AI learning is not misrepresented as established expertise.

## Tests
- Added: input timing/held-jump/variable-height/braking/wall-boost cases; bundled cover matching/assets; education toggle and reduced-motion football.
- Modified: existing wall-kick test now holds input for full height rather than cutting the jump immediately.
- Full suite: 692 passed before the final same-wall boost test/icon-font fix. Final handoff verification: 693 passed; see September 14 worklog.
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass in September 14 handoff verification
fvm flutter analyze                        pass in September 14 handoff verification
fvm flutter test                           pass in September 14 handoff verification
fvm flutter build web --wasm               pass in September 14 handoff verification
```

## Known issues left open
- The owner rejected this visual result on September 14 and transferred the entire app/admin to Claude. Technical checks are not design acceptance.
- Cloud leaderboard/nickname, rewards and new level patterns remain unimplemented. Best is memory-only for the open stage.
- New Arabic labels await approved translation. Cover snapshot needs deliberate refresh for changed/new articles.
- Admin integration and SEO remain open; security review and Daybreak design stay paused.
- Physical phone review and owner visual/gameplay acceptance remain outstanding.

## Next
Review the restored behavior at localhost:8333 and continue only the next specifically authorized enhancement.
