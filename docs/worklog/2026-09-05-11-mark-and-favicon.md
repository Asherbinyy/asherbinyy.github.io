# 2026-09-05-11 — The mark, the favicon set and the tab title

**Agent:** Claude Opus 5 / Claude Code
**Milestone:** 1
**Started from:** 37cd4c4

## Goal
Implement task 1.6b — generate `assets/brand/mark.svg` and the favicon set from
the trace curve, make the browser tab title track the route — and close the
three task-1.4 defects, which live in exactly the files this task touches.

## Owner decisions taken before starting
1. **The scaffold icons.** `web/icons/` tracked `Icon-192.png` and friends: the
   blue Flutter defaults, referenced nowhere, while `index.html` pointed at the
   lowercase names section 12 specifies. Owner approved removing them and
   generating the lowercase set from `mark.svg`, gitignored as build output.
2. **The phone number.** Owner approved removing it from `/cv` and `/brief`. It
   stays in `profile.json` for the CV document itself.

## What changed
- Added `tool/png_writer.dart`: a minimal 8-bit RGBA PNG encoder. Written
  rather than depended on — section 4 keeps the package list closed, and the
  only thing needed is uncompressed-filter RGBA on top of the zlib codec
  `dart:io` already ships.
- Added `tool/generate_mark.dart`: writes `assets/brand/mark.svg` and
  rasterises `web/favicon.png` and the three `web/icons/icon-*.png` sizes,
  including the Android maskable variant drawn inside the 80% safe zone.
- Widened the mark's sampling window to five sigmas either side of the burst,
  in both the tool and `MarkPainter`. At the previous one-window sampling the
  mark filled its box with hump and read as a hill; section 12 draws a burst on
  a flat carrier line, and the flat shoulders only appear with a wider window.
- Added `lib/app/route_title.dart` and wrapped every route in it. `Title`
  writes through `SystemChrome`, so the tab updates on client-side navigation
  rather than only on a hard reload.
- Rewrote `web/manifest.json`: it was the untouched Flutter scaffold, shipping
  `#0175C2` as both background and theme colour — a second chroma, in breach of
  section 2 — plus "A new Flutter project." as its description.
- Fixed the sitemap's trailing-slash URLs, which resolved to the router's error
  route for five of the eight advertised addresses.
- Removed the phone number from the two indexable static pages.
- Added five ARB keys in both channels and two tokens.

## Files touched
- `tool/png_writer.dart` — created — minimal PNG encoder.
- `tool/generate_mark.dart` — created — the mark and favicon generator.
- `assets/brand/mark.svg` — created — the single committed vector source.
- `lib/app/route_title.dart` — created — the per-route tab title.
- `lib/app/router.dart` — modified — wrap each route in `RouteTitle`.
- `lib/core/painting/mark_painter.dart` — modified — the wider window.
- `lib/app/theme/{tokens,token_values}.dart` — modified — `markCurveSigmas`.
- `lib/app/l10n/app_{en,ar}.arb` — modified — five section names.
- `web/manifest.json` — modified — real identity, no second chroma.
- `web/icons/Icon-*.png`, `web/favicon.png` — deleted — scaffold defaults,
  replaced by generated output. Approved by the owner.
- `tool/generate_static.dart` — modified — sitemap paths, no phone number.
- `.gitignore` — modified — the generated rasters are build output.
- `.github/workflows/ci.yml` — modified — run the generator in both jobs.
- `pubspec.yaml` — modified — bundle `assets/brand/`.
- `test/unit/tool/generate_mark_test.dart` — created — 13 tests.
- `test/unit/app/route_title_test.dart` — created — 6 tests.
- `docs/worklog/2026-09-05-11-mark-and-favicon.md` — created — this handoff.

## Decisions made

**The generator copies the curve, and a test forbids the copy from drifting.**
Section 12 requires the mark to be a frame lifted from the trace's own curve.
The generator cannot import `CarrierWave`: that library reaches `tokens.dart`,
which imports `material_ui`, and the generator runs as plain `dart run`. So the
Gaussian is duplicated, and a test asserts the two agree at 401 sample points
plus every shared token. Either one changing without the other fails the build.

**A hand-written PNG encoder rather than a new package.** Section 4 keeps the
dependency list closed and says additions need justification. Eight-bit RGBA
with no filtering is about eighty lines given `dart:io`'s zlib codec, which is
less than the justification would have been worth.

**`mark.svg` uses `currentColor`.** Section 12 wants beacon on dark, the
darkened beacon on light, and monochrome elsewhere. One file inheriting its
colour serves all three; hard-coding a hex would need three files.

**macOS hid the icon-case defect.** Writing `icon-192.png` silently overwrote
the tracked `Icon-192.png`, because the filesystem is case-insensitive — the
two cannot coexist locally, which is presumably how the mismatch survived. On
GitHub Pages, which is case-sensitive, every social preview image and the
apple-touch-icon were 404ing.

**`/cv` gets its own tab title.** Section 12's table does not list it. Sharing
the brief's title would have made two different pages indistinguishable in a
tab strip, which is the exact thing the naming pattern exists to prevent.

## Tests
- Added: 21 — 13 covering the generator, 6 covering the title table, and 2
  asserting the indexable pages publish no telephone number.
- Modified: `generate_static_test.dart`, whose sitemap assertions encoded the
  trailing slashes this task removed. All twelve goldens were regenerated: the
  header mark's shape changed, and nothing else in them moved.
- Full suite: pass, 302 passing, 0 failing.
- Coverage delta: 93.78% to 93.66% (2096/2238 lines). The dip is the PNG
  encoder's error branch and the generator's `main`, which the tests exercise
  through `rasterise` rather than by writing files a second time.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (0 changed)
fvm flutter analyze --fatal-infos          pass (no issues found)
fvm flutter test --coverage                pass (302 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- **The OG image is the 512px icon, not a composite.** Section 12 wants it
  composited over the acquisition sequence's settled frame, so the preview looks
  like a moment from the site rather than a logo on a blank field. That needs a
  rendered screenshot of the hero with real fonts, which is a capture step
  rather than a generator; deferred with the reason recorded here.
- **Favicon rendering in real browser chrome is unverified.** The tests assert
  the field is opaque `--void` and that the mark survives 16px, but section 12
  asks for both light and dark browser chrome to be checked by eye. That needs
  the deployed site.
- `profile.json` still carries no `stats` block, so the hero shows no panels.
- `docs/07-CONTENT-SCHEMA.md` and `docs/00-PROJECT-BRIEF.md` still say "five
  countries" while the content now says six.
- Forty agent-authored Arabic interface strings now want an owner read.
- Case study tab titles borrow the work section name until Milestone 2 supplies
  study content.
- Nothing has been checked on a real phone browser, which `05-TESTING.md`
  requires before any merge to `main`.

## Next
Task 1.7, the telemetry trace. It is the signature element, the roadmap allows
it more than one session, and `CarrierWave` already holds the curve it extends.
