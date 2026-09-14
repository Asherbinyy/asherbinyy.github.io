# 2026-09-13-01 — Restore the design, keep content updates

**Agent:** Codex
**Milestone:** 4
**Started from:** 48f4076

## Goal
Follow the owner’s correction: undo the expanded Flutter redesign and retain only requested content updates. Record the precise limits of any future stat-card/pattern work.

## What changed
- Restored original navigation, page composition, education and stat surfaces, backgrounds, game/football, intro and credit treatment. Removed the new papyrus/wall assets and design widgets. Original supplied references remain untouched.
- Retained Senior Software Engineer positioning, “years experience”, plainer client/company wording, established skills, explicit AI learning, and stated tools. The new lists are plain text in the existing Home/About/recruiter layouts and are shared with static CV/Brief generation.
- Home Freelance now reads Remote and suppresses detail text. This is a Home copy change; it does not relocate map coordinates or rewrite other geographic consumers.
- Retained six sourced article metadata entries as Writing fallback. The live feed wins when available; a request is bounded to eight seconds. Localhost was rejected by the public relay, while a browser-like request with the published origin returned the feed.
- Updated the handoff and active docs to say content-only. Future papyrus applies only to the two Home stat cards, with roll-close/open interaction; a fixed background image is explicitly rejected.

## Files touched
- `assets/content/profile.json` — modified — supplied positioning, experience label and skill/learning/tool lists.
- `assets/content/writing.xml` — created — owner’s published titles, URLs, dates and tags; no article bodies/covers.
- `lib/content/models/profile.dart` — modified — optional arrays, empty for older documents; generated bindings rebuilt.
- `lib/core/widgets/profile_skills.dart` — created — plain existing-style text, no new card/chip surface.
- `lib/features/station/presentation/widgets/hero_content.dart` — modified — renders shared skills as content within the existing measure.
- `lib/features/station/presentation/widgets/career_sequence.dart` — modified — Home-only Remote label and detail suppression.
- `lib/features/about/presentation/about_screen.dart` — modified — adds plain skills to existing identity text.
- `lib/features/recruiter/presentation/recruiter_view.dart` — modified — uses the same supplied lists.
- `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_ar.arb` — modified — content labels; new English wording is literal pending Arabic copy review.
- `lib/app/theme/tokens.dart` — modified — Writing timeout only; all visual/game token changes rolled back.
- `lib/features/writing/data/writing_providers.dart`, `writing_repository.dart` — modified — live feed then bundled metadata fallback with bounded request.
- `tool/generate_static.dart` — modified — shared skill/learning/tool data in existing CV/Brief; no new designed frontend.
- `test/unit/features/writing/writing_fallback_test.dart` — created — failed relay, live precedence, disabled relay and missing bundle cases.
- `test/widget/about/about_test.dart` — modified — evidence-control test isolates unrelated asynchronous feed loading, which caused pumpAndSettle to time out.
- `test/golden/goldens/hero_*.png`, `chrome_*.png` — modified — reviewed content-dependent snapshots; original styling retained.
- `docs/00-PROJECT-BRIEF.md`, `01-DESIGN-SYSTEM.md`, `03-ARCHITECTURE.md`, `11-OPEN-ISSUES.md`, `12-MOTIF-LIBRARY.md`, `14-PROVENANCE.md`, `19-FLUTTER-ENHANCEMENT-PLAN.md` — modified — current scope, content contract and provenance.
- `docs/27-CONTINUE-HERE.md` — created — current rollback/handoff, overriding earlier broader design work.
- `docs/26-GAME-LEADERBOARD-CONTRACT.md` — created earlier in session — proposal retained as deferred, not implemented.
- `docs/28-ADMIN-AUTH-EPOCH-REVIEW.md`, `docs/audits/2026-09-13/admin-rereview/` — created earlier in session — historical admin review evidence retained; subsequent owner instruction pauses review.
- `README.md`, `CHANGELOG.md` — modified — concise current scope and content status.

## Decisions made
The user explicitly rejected the scope expansion. Restored the pre-pass implementation, not a second interpretation of the design. Only content and necessary content consumers remain. No packages, routes, SDK, appearance controls, consent or deployment changed. Papyrus animation and a new inspired pattern are deferred; do not infer approval to implement them from this worklog.

English source wording is preserved literally in the Arabic channel where no owner-approved translation exists. This avoids fabricating a translation but remains incomplete Arabic copy. Existing Arabic evidence is unchanged.

## Tests
- Added: five Writing fallback cases (403, 502, fresh live result, disabled relay, missing bundle).
- Modified: one evidence-control test isolates the unrelated feed; 13 content-dependent golden images refreshed after inspection.
- Full suite: pass, 681 passing, 0 failing. Initial content-only run had 667 passing, 14 failing (13 expected copy snapshots and one asynchronous feed-dependent test).
- Coverage delta: not measured.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass, 283 files, 0 changes
fvm flutter analyze                        pass, no issues
fvm flutter test                           pass, 681 tests
fvm flutter build web --wasm               pass, 41.4s
```

Chrome: desktop Home/About and 390px Home inspected after rollback, no browser exceptions. Original backgrounds, right-hand wall, stat card style and six navigation destinations restored. Local preview running at http://localhost:8333. Captures are saved in `docs/audits/2026-09-13/content-rollback/`. These are desktop/emulated checks, not physical phone tests. Static generator ran successfully.

## Known issues left open
- Content-only scope: no new papyrus interaction or background pattern. Existing game, football, education, intro, page consolidation and real-logo requests remain deferred, not completed.
- New Arabic copy requires owner-approved translation.
- Home Freelance copy is corrected; shared geographic/map/static consistency needs a separate content pass.
- Writing fallback is a dated metadata snapshot and has no covers; live nonempty feed remains primary. No Worker origin configuration changed.
- Admin preview/release coordination and support for the new profile arrays are unverified. Security review paused; nothing merged or deployed.
- Earlier generated design snapshots/builds do not validate the retained change. Only the content-only verification above applies.

## Next
Let the owner review the restored design and retained copy. Continue only the explicitly requested content corrections; if a design task is requested later, constrain it to the two stat cards and their specified roll interaction.
