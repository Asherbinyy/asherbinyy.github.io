# 2026-09-05-06 — Typed content and bundled fallback

**Agent:** GPT-6 / Codex
**Milestone:** 1
**Started from:** 153fc79

## Goal
Implement task 1.3 using the owner's instruction to use the docs as the content source, then push it separately before static routes.

## What changed
- Transcribed the documented profile, six career stations, eleven applications and two education records into bundled JSON. Missing translations remain null; absent PDF, portrait and Calendly references are null.
- Added immutable Freezed/json_serializable models for all documented shapes, including case studies without inventing production study prose.
- Added semantic validation for identity, links, assets, chronology, coordinates, burst weights, marks, IDs and featured membership.
- Added a cached asset repository with explicit ready, identity fallback and unavailable results. Corrupt primary and fallback JSON cannot escape as an uncaught load error.
- Added a generated repository provider with injected asset access so its dependency graph remains pure Dart.

## Files touched
- `assets/content/{profile,career,apps,education,fallback}.json` — created — supplied facts transcribed from docs/07.
- `assets/content/README.md` — created — content provenance and omissions.
- `lib/content/models/{localized_text,profile,career,apps,education,study}.dart` — created — immutable typed schemas.
- `lib/content/content_parser.dart` — created — validation at the decoding boundary.
- `lib/content/content_result.dart` — created — explicit successful and degraded states.
- `lib/content/content_repository.dart` — created — bundled loading, caching and fallback.
- `lib/content/providers.dart` — created — generated provider owning the repository cache.
- `build.yaml` — modified — generate content provider and checked, nested JSON serialization.
- `pubspec.yaml` — modified — bundle local content assets.
- `test/unit/content/content_models_test.dart` — created — round trips, immutability and malformed-data rejection.
- `test/unit/content/content_repository_test.dart` — created — cache, fallback and provider behavior.
- `docs/worklog/2026-09-05-06-content-layer.md` — created — task handoff.

## Decisions made
- The owner explicitly directed use of docs and expanded scope to all of Milestone 1. The docs' real supplied values are source data; literal ellipses and missing fields are not facts to complete by inference.
- Fallback uses the documented minimum: the same name, positioning and contact fields as Profile. Other Profile fields are optional, also accommodating partial source records without inventing details.
- Arabic resolves to supplied English when its translation is absent. This is a visible fallback, not a claim of complete Arabic translation.
- Freezed 2.5.8 emits final formal parameters rejected under the SDK's default language mode. The six model libraries use `// @dart=3.9`, which source_gen propagates into generated parts. This retains immutable models and allows generation, formatting and compilation without patching cached packages or generated files. The project still runs Flutter 3.47.2 / Dart 3.13.2.
- No dependencies or token values changed; resolved versions remain those in worklog 04. checked JSON conversion and explicit nested serialization are build options, not added packages.
- Tests load the actual bundled documents to validate the owner's content, and use clearly named synthetic values only for invalid-input and optional-field cases.

## Tests
- Added: 37 content tests covering valid documents, model round trips, unsafe links, invalid copy/dates/coordinates/weights/marks, duplicate IDs, featured limits, cache coalescing, missing assets, corrupt fallback, traversal and provider reuse.
- Modified: none of the prior tests.
- Full suite: pass, 89 passing, 0 failing.
- Coverage delta: 86.01% to 91.26% overall (856/938 lines). Content models including generated JSON: 100% (282/282); parser: 100% (99/99); repository: 100% (23/23). These are line measurements, not branch coverage.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (76 files, 0 changed)
fvm flutter analyze                        pass (no issues)
fvm flutter test --coverage                pass (89 tests)
fvm flutter build web --wasm               pass
```

## Known issues left open
- The source contains eleven apps, despite the intended twelve. Mokaf has no store URLs; five career records lack full role copy. Most Arabic translations, the PDF and imagery are absent. No fabricated replacements were added.
- docs/07 names writing.json and strings_en/ar.json without defining their structures or contents. These files and corresponding bespoke models remain deferred. UI-copy authority remains ARB under the Flutter standards. Task 1.3's literal all-files acceptance therefore still has this documented gap.
- The schema mentions Tripster as a suggested study while the screen spec and roadmap name City Loom; no study content was shipped in this task, and Milestone 2 should follow the requested study selection.
- Existing font budget and icon warnings remain. Task 1.2's push passed remote CI; this task has not deployed application code to main.

## Next
Implement task 1.4 with a build-only file-I/O CLI and semantic static pages generated from these same validated records.
