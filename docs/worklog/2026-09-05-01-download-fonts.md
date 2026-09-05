# 2026-09-05-01 — download unsubsetted font files

**Agent:** Gemini 3.8 Flash (High)
**Milestone:** 1
**Started from:** initial repository setup (no commits yet)

## Goal
Download and verify the unsubsetted static TrueType font files for the four specified families from Google Fonts into `assets/fonts/` ahead of subsetting via `tool/fonts.sh`.

## What changed
- Created `assets/fonts/` directory.
- Downloaded and placed 10 static TTF font files directly from Google Fonts' distribution endpoints (`fonts.gstatic.com`).
- Verified font table metadata (`name` and `OS/2` tables) for all 10 files to confirm exact family name, weight class, and absence of italic variants.

## Files touched
- `assets/fonts/SpaceGrotesk-Medium.ttf` — created — static TTF weight 500
- `assets/fonts/SpaceGrotesk-Bold.ttf` — created — static TTF weight 700
- `assets/fonts/IBMPlexSans-Regular.ttf` — created — static TTF weight 400
- `assets/fonts/IBMPlexSans-Medium.ttf` — created — static TTF weight 500
- `assets/fonts/IBMPlexSans-SemiBold.ttf` — created — static TTF weight 600
- `assets/fonts/IBMPlexSansArabic-Regular.ttf` — created — static TTF weight 400
- `assets/fonts/IBMPlexSansArabic-Medium.ttf` — created — static TTF weight 500
- `assets/fonts/IBMPlexSansArabic-SemiBold.ttf` — created — static TTF weight 600
- `assets/fonts/IBMPlexMono-Regular.ttf` — created — static TTF weight 400
- `assets/fonts/IBMPlexMono-Medium.ttf` — created — static TTF weight 500
- `docs/worklog/2026-09-05-01-download-fonts.md` — created — session worklog

## Decisions made
- The prompt description mentioned "nine files", but enumerated 10 files across the 4 families (2 Space Grotesk + 3 IBM Plex Sans + 3 IBM Plex Sans Arabic + 2 IBM Plex Mono). Downloaded all 10 files.
- Fetched static TTF binaries directly from official `fonts.gstatic.com` URLs resolved via Google Fonts' manifest API (`https://fonts.google.com/download/list?family=...`).
- Automated font verification by parsing TTF headers, `OS/2` tables (`usWeightClass`), and `name` tables (`nameID` 1, 2, 4) in Python to guarantee weights match filenames and no italic variants were bundled.

## Tests
- Added: none (asset preparation task)
- Modified: none
- Full suite: pass, 1 passing, 0 failing
- Coverage delta: none

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (0 files changed)
fvm flutter analyze                        pass (no issues found)
fvm flutter test                           pass (1 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- `.gitignore` has not yet been updated with the full contents from `docs/08-GIT-AND-CI.md` (e.g. `.fvm/`, `build/`, `web/cv/index.html`), leaving `.fvm/` untracked in git status. Kept untouched per scope boundary in AGENTS.md §6.
- `docs/00-PROJECT-BRIEF.md` is referenced across project documentation but is not present in `docs/`.
- Repository has no git commits yet; initial commit and branch cut (`phase/1-ground-station`) remain to be executed.
- Subsetting script `tool/fonts.sh` has not yet been authored; fonts in `assets/fonts/` are the raw unsubsetted binaries (~1.8MB total).

## Next
Author `tool/fonts.sh` to run `pyftsubset` on Latin and Arabic ranges to bring bundled font weight under the 480KB performance budget per `03-ARCHITECTURE.md` §5 and `START-HERE.md` §9.
