# 2026-09-05-04 — Foundation verification and Chrome preview

**Agent:** GPT-6 / Codex
**Milestone:** 1
**Started from:** 87dc32fd8559ca9556a2d336641fa26b4fd21c84

## Goal
Finish the authorized setup and task 1.1 handoff: verify the current foundation, confirm GitHub and Pages configuration, synchronize the phase branch, and run the app in Chrome.

## What changed
- Re-ran the four required local verification checks with Flutter 3.47.2 / Dart 3.13.2 through FVM; all passed.
- Confirmed the public GitHub repository uses `main` as its default branch and Pages already has `build_type: workflow`. No Pages setting change was necessary.
- Confirmed both remote branches exist: `main` at `7c94f086cee6a2eae23e8821037ed1bab32128a3` and the phase branch at the starting commit. Pushing the phase branch returned `Everything up-to-date` before this worklog was added.
- Confirmed the GitHub Actions run for the starting commit succeeded: https://github.com/Asherbinyy/asherbinyy.github.io/actions/runs/33980373320.
- Launched `fvm flutter run -d chrome --wasm --web-port=7358`; Flutter reported a successful build and active run session. The local preview at `http://localhost:7358/` returned HTTP 200.
- Confirmed no native platform directories exist, no build/SDK cache paths are tracked, and `git status --short` was empty before creating this worklog.
- Recorded the resolved package versions omitted from the earlier foundation handoff. Application code and package constraints were unchanged.

## Files touched
- `docs/worklog/2026-09-05-04-foundation-verification.md` — created — record current verification, resolved dependencies, remote configuration, preview, and remaining limitations.

## Decisions made
- Continued within the user's explicit setup and task 1.1 scope. A worklog naming task 1.2 as next is a handoff recommendation, not authorization to implement more features.
- Used the existing authorization to verify and push the phase branch. No merge or application deployment to `main` was performed.
- Retained the prescribed font subsets and recorded the budget failure instead of changing glyph coverage, weights, or Arabic shaping features without an approved tradeoff.
- Read resolved versions from the local `pubspec.lock` used by the successful checks. The lockfile remains ignored as specified by `docs/08-GIT-AND-CI.md`.

| Direct package | Resolved version |
|---|---|
| flutter, flutter_localizations, flutter_test | SDK packages from Flutter 3.47.2 (lockfile version 0.0.0) |
| material_ui | 1.1.1 |
| flutter_riverpod | 2.6.1 |
| riverpod_annotation | 2.6.1 |
| go_router | 14.8.1 |
| freezed_annotation | 2.4.4 |
| json_annotation | 4.9.0 |
| shared_preferences | 2.5.5 |
| url_launcher | 6.3.2 |
| http | 1.6.0 |
| xml | 6.6.1 |
| flutter_svg | 2.3.0 |
| intl | 0.20.3 |
| riverpod_generator | 2.6.4 |
| build_runner | 2.5.4 |
| freezed | 2.5.8 |
| json_serializable | 6.9.5 |
| very_good_analysis | 6.0.0 |
| alchemist | 0.11.0 |
| mocktail | 1.0.5 |

`cupertino_ui` 1.0.2 remains transitive through `material_ui`; it is not a direct app dependency or import. The generator's analyzer resolves to 7.6.0; the existing pure-Dart generation scope remains unchanged.

## Tests
- Added: none.
- Modified: none.
- Full suite: pass, 45 passing, 0 failing.
- Coverage delta: unchanged from the preceding worklog, 85.40% (392/459 lines covered).
- Manual: Chrome launch and local HTTP response confirmed. No visual screenshot comparison was performed; routes remain intentionally empty themed placeholders.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (41 files, 0 changed)
fvm flutter analyze                        pass (no issues found)
fvm flutter test --coverage                pass (45 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- The ten font subsets total 813,332 bytes against the 480,000-byte budget. The setup budget requirement is still unmet; the earlier worklog records that removing hinting alone was insufficient. No font changes were made in this session.
- Flutter still warns about missing stock Material/Cupertino icon fonts. The application uses no stock icons and the design specifies custom icons; this warning was already documented in the foundation worklog.
- Pages configuration is confirmed, but the foundation has not been deployed to production: application and CI commits remain on the phase branch. The phase CI result verifies the `verify` job, not a completed production build/deployment.
- The existing CI workflow does not yet implement the documented Lighthouse gate or deployment URL comment. Static route generation remains conditional on the future generator; task 1.12 should not be treated as fully complete on the strength of the green verification job alone.
- Static `/cv` and `/brief`, localisation controls and copy, loading primitives, and feature screens remain deferred. No later roadmap features were implemented here.

## Next
Resolve the outstanding font budget with an owner-approved tradeoff so the original setup acceptance criterion can be met without silently damaging Arabic shaping or removing required font coverage.
