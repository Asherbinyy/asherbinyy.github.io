# 2026-09-05-05 — Localisation scaffold

**Agent:** GPT-6 / Codex
**Milestone:** 1
**Started from:** b6f5285

## Goal
Implement task 1.2 and push it separately before content and static routes. During this task the owner expanded authorization to the whole first milestone, in roadmap order with separate pushes.

## What changed
- Added English and Arabic ARB channels, generated localization configuration and context access, and an in-memory Riverpod language controller.
- Connected locale selection to app delegates, direction and Arabic typography while preserving the router instance and current URL.
- Added both-theme/both-direction placeholder goldens and runtime language switching tests.
- Added explicit localization generation in both CI jobs that compile application code.

## Files touched
- `l10n.yaml` — created — formatted generation into an ignored directory.
- `lib/app/l10n/app_en.arb`, `lib/app/l10n/app_ar.arb` — created — empty copy channels pending supplied UI strings.
- `lib/app/l10n/app_locale.dart` — created — supported locale enum.
- `lib/app/l10n/locale_controller.dart` — created — generated in-memory locale state.
- `lib/app/l10n/localizations_context.dart` — created — generated copy accessor.
- `lib/app/app.dart` — modified — active locale and compatible material_ui delegates.
- `pubspec.yaml` — modified — enable localization generation; no package changes.
- `build.yaml` — modified — include the pure-Dart controller in generation.
- `.gitignore`, `analysis_options.yaml` — modified — exclude generated localization output.
- `.github/workflows/ci.yml` — modified — regenerate localization before analysis/build.
- `test/unit/app/l10n/locale_controller_test.dart` — created — language state and scope isolation.
- `test/widget/locale_switching_test.dart` — created — direction/delegate changes preserve navigation.
- `test/golden/locale_placeholder_test.dart`, `test/golden/goldens/*.png` — created — four placeholder baselines and direction assertions.
- `docs/worklog/2026-09-05-05-localisation.md` — created — task handoff.

## Decisions made
- Default remains English; language choice stays in memory. No storage or analytics was introduced. The visible language control belongs to task 1.5.
- Use only the generated app delegate alongside material_ui's delegates. The SDK-generated aggregate includes legacy Material delegates, which are not the correct types for this app.
- Alchemist 0.11.0 fails compilation against this SDK because its Canvas adapter lacks `clipRSuperellipse` and `drawRSuperellipse`. Retained every golden case using Flutter's built-in comparator; no test was skipped and no dependency was replaced or upgraded.
- Empty ARBs are deliberate while screens remain empty. The owner directed use of documented content for subsequent tasks; literal ellipses and missing Arabic copy will not be treated as publishable text.
- Resolved packages remain those in worklog 04, including material_ui 1.1.1, riverpod_generator 2.6.4 and intl 0.20.3; SDK remains Flutter 3.47.2 / Dart 3.13.2.

## Tests
- Added: two controller tests, one runtime language/navigation test, four golden cases.
- Modified: none of the existing tests.
- Full suite: pass, 52 passing, 0 failing.
- Coverage delta: 85.40% to 86.01% (418/486 lines).

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (51 files, 0 changed)
fvm flutter analyze                        pass (no issues)
fvm flutter test --coverage                pass (52 tests)
fvm flutter build web --wasm               pass
```

## Known issues left open
- Real Arabic content and UI translations are absent. ARBs currently have locale metadata only; these goldens validate empty screens, not Arabic glyph rendering.
- The prescribed Alchemist version is incompatible with the pinned SDK when imported; native Flutter goldens are the recorded workaround.
- Existing font budget and stock icon warnings remain as recorded in worklog 04.
- No application deployment to main occurred. Full production CI/Lighthouse and deployment verification remain later milestone work.

## Next
Implement task 1.3 using the documented schemas and supplied facts, keeping missing content explicit and testing malformed-data fallbacks.
