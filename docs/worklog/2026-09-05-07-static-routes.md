# 2026-09-05-07 — Static routes and SEO shell enrichment

**Agent:** Gemini 3.8 Flash / Antigravity
**Milestone:** 1
**Started from:** 353872f

## Goal
Implement task 1.4: build-time static route generator producing semantic, JS-free `/cv` and `/brief` HTML pages, `robots.txt`, and `sitemap.xml`, and enrich `web/index.html` with full meta, Open Graph, and JSON-LD Person schema.

## What changed
- Created `tool/generate_static.dart` as a standalone build tool using `dart:io` and `dart:convert` (no Flutter imports) that consumes the bundled JSON files (`assets/content/{profile,career,apps,education}.json`) and emits static HTML pages for `/cv` and `/brief`, `robots.txt`, and `sitemap.xml`.
- Enriched `web/index.html` with static title, meta description, author, Open Graph, Twitter Cards, canonical URL, and JSON-LD `Person` schema (`alumniOf`, `knowsAbout`, `sameAs`).
- Added gitignore entries for generated routes (`web/cv/`, `web/brief/`, `web/robots.txt`, `web/sitemap.xml`).
- Created `test/unit/tool/generate_static_test.dart` containing 37 tests verifying all generated files: HTML5 compliance, lang/dir attributes, meta tags, JSON-LD schema parsing and keys, reverse chronological career ordering, app count in brief vs CV, absence of JavaScript tags, store links, robots.txt directives, and sitemap.xml structure/routes.
- Verified generator runs cleanly via `fvm dart run tool/generate_static.dart` and produces all 4 static files.

## Files touched
- `tool/generate_static.dart` — created — build-time CLI generating static HTML routes, sitemap.xml, and robots.txt.
- `web/index.html` — modified — enriched with SEO metadata, Open Graph, Twitter Card, and JSON-LD Person schema.
- `.gitignore` — modified — exclude generated static artifacts (`web/cv/`, `web/brief/`, `web/robots.txt`, `web/sitemap.xml`).
- `test/unit/tool/generate_static_test.dart` — created — 37 unit tests covering static generation output and schema validation.
- `docs/worklog/2026-09-05-07-static-routes.md` — created — record task 1.4 execution, verification, and handoff.

## Decisions made
- Used pure `dart:io` and `dart:convert` in `tool/generate_static.dart` rather than importing Freezed models from `lib/`. Build tools in `tool/` run via `dart run` at build time, avoiding Flutter/build_runner runtime coupling or circular dependencies.
- Direct read from `assets/content/*.json` ensures the static pages reflect the authoritative bundled content files without runtime overhead.
- Inline CSS on `/cv` and `/brief` uses the exact design tokens (`--void`, `--surface`, `--beacon`, `--instrument`, etc.) from `docs/01-DESIGN-SYSTEM.md` so that the pages look identical in aesthetic tone to the ground station theme without any JS or external stylesheet dependencies.
- Sitemap and canonical URLs use `https://asherbinyy.github.io` via a single `baseUrl` constant in `tool/generate_static.dart`, easily updated when a custom domain is configured.
- Placeholders for OG image link to `https://asherbinyy.github.io/icons/icon-512.png` pending the acquisition sequence frame and mark asset generation in task 1.6b.

## Tests
- Added: 37 tests in `test/unit/tool/generate_static_test.dart`.
- Modified: none of the prior tests.
- Full suite: pass, 126 passing, 0 failing.
- Coverage delta: unchanged for `lib/` at 91.26% (856/938 lines); generator is a build tool in `tool/`.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (79 files, 0 changed)
fvm flutter analyze                        pass (no issues found)
fvm flutter test                           pass (126 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

## Known issues left open
- Font budget and stock icon warnings from earlier tasks remain as documented.
- CI workflow does not yet run Lighthouse assertion for `/cv ≥ 85` (part of task 1.12 finisher).
- Alchemist incompatibility with pinned SDK remains worked around with native Flutter goldens.

## Next
Implement Task 1.4b: Loading and placeholder primitives (sweep, skeletons, carrier loader, procedural station cards) per `docs/01-DESIGN-SYSTEM.md` §11 and `docs/09-ROADMAP.md`.
