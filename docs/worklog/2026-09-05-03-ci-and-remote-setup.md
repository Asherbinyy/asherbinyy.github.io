# 2026-09-05-03 — ci and remote setup

**Agent:** Gemini 3.8 Flash (High)
**Milestone:** 1
**Started from:** 2026-09-05-02-foundation.md

## Goal
Resolve git remote and pushing blockage left by Codex, implement Roadmap Task 1.12 CI and deployment automation, and push `main` and `phase/1-ground-station` to GitHub.

## What changed
- Connected Git remote `origin` to `git@github.com:Asherbinyy/asherbinyy.github.io.git` using verified SSH authentication.
- Pushed `main` to `origin/main` to publish the specification base commit.
- Committed doc specification updates for mark, favicon, and tab title (§12).
- Implemented Roadmap Task 1.12 CI workflow `.github/workflows/ci.yml` featuring `verify`, `build`, and `deploy` jobs matching `docs/08-GIT-AND-CI.md`.
- Added `web/.nojekyll` to bypass GitHub Pages Jekyll directory processing.
- Added unit tests in `test/unit/app/theme/theme_test.dart` for `ThemeTokens` (copyWith, lerp, token getters, and theme factories), lifting line coverage to 85.40%.
- Pushed `phase/1-ground-station` to `origin/phase/1-ground-station`.

## Files touched
- `.github/workflows/ci.yml` — created — GitHub Actions CI pipeline for verify, build, and deploy
- `web/.nojekyll` — created — bypasses Jekyll processing on GitHub Pages
- `test/unit/app/theme/theme_test.dart` — created — unit tests for ThemeTokens, accessors, and themes
- `docs/01-DESIGN-SYSTEM.md` — modified — committed brand mark, favicon, and tab title specifications (§12)
- `docs/03-ARCHITECTURE.md` — modified — committed web icons and single source mark.svg architecture
- `docs/09-ROADMAP.md` — modified — committed Task 1.6b mark and favicon milestone entry
- `docs/worklog/2026-09-05-03-ci-and-remote-setup.md` — created — session worklog

## Decisions made
- Used SSH remote (`git@github.com:Asherbinyy/asherbinyy.github.io.git`) rather than HTTPS because the developer environment has validated SSH keys for `Asherbinyy`, allowing clean non-interactive pushes.
- Added `theme_test.dart` to cover `ThemeTokens` accessors and theme construction, bringing test suite coverage up from 66.23% to 85.40%, satisfying the ≥ 80% CI pre-merge threshold in `08-GIT-AND-CI.md`.
- Kept the current 10 subset font files as generated in Task 1.1; the font size optimization pass remains deferred to Roadmap Task 3.2 per project brief.

## Tests
- Added: `ThemeTokens nocturneTokens exposes valid non-null semantic colors and weights`, `ThemeTokens daybreakTokens exposes valid non-null semantic colors`, `ThemeTokens copyWith retains original values when fields are null`, `ThemeTokens copyWith updates specified color values`, `ThemeTokens lerp interpolates between two ThemeTokens`, `ThemeTokens shared measurements through ThemeTokenValues match static Tokens`, `ThemeTokens NocturneTheme and DaybreakTheme construct valid ThemeData`.
- Modified: none
- Full suite: pass, 45 passing, 0 failing.
- Coverage delta: 66.23% -> 85.40% (+19.17%).

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (0 files changed)
fvm flutter analyze                        pass (no issues found)
fvm flutter test                           pass (45 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- The ten font subsets total 813KB, above the 480KB target in `03-ARCHITECTURE.md` §5; optimization pass is scheduled for Task 3.2.
- GitHub Pages build source setting in repository settings (`Settings -> Pages -> Source: GitHub Actions`) needs to be confirmed by the owner.
- Static `/cv` and `/brief` implementations, loading primitives, and actual screens remain to be implemented on subsequent roadmap tasks.

## Next
Roadmap Task 1.2: Localisation scaffold (ARB files, generated l10n, locale switching, RTL support, and golden tests).
