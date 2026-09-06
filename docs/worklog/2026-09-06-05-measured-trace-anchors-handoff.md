# 2026-09-06-05 — Measured trace anchors

**Agent:** Codex / GPT-6
**Milestone:** 1
**Started from:** 876a984

## Goal
Resolve the Milestone 1 telemetry-trace gap by anchoring bursts to rendered career sections, preserve and review the existing handoff, and complete the authorized validation before committing and pushing.

## What changed
- Added a provider-scoped trace anchor registry that gives each career entry a stable `GlobalKey` and resolves its rendered centre into the trace's document coordinate system.
- Connected the career sequence and fixed trace background to the same registry.
- Replaced even production burst positions with measured career-section positions after layout while retaining the existing provisional geometry for the first frame.
- Expanded the anchor regression into normal-motion and reduced-motion cases that compare painted centres with rendered entries before scrolling, after scrolling, and after resizing.
- Moved measurements to a post-frame callback and cached them, so sibling layout changes are observed after layout and lock calculations reuse the same positions.
- Updated the static reduced-motion trace when its scroll offset changes, and preserved the current offset when reduced motion is enabled.
- Extracted the burst label and immutable frame into their own files to keep the trace widget below the 300-line limit.
- Reviewed and regenerated the five explicitly approved station baselines and, after the owner approved the additional differences, eight chrome baselines that also capture the station trace. The content-unavailable station baseline and unrelated baselines remain unchanged.
- Reviewed all eight chrome isolated differences; they contain only waveform changes (0.11–0.28%).
- Fixed the consent banner's zero-duration AnimatedSize resize assertion with the owner's explicit approval: reduced motion now renders the same ConsentBanner child directly. Consent decisions, persistence, and collection behavior are unchanged.
- Verified that pushed propagation-map commit `876a984` passed both GitHub Actions jobs before starting this work.

## Files touched
- `lib/features/trace/presentation/trace_anchor_registry.dart` — created — shares and resolves rendered career-entry anchors.
- `lib/features/station/presentation/station_screen.dart` — modified — supplies the shared registry to the career sequence.
- `lib/features/station/presentation/widgets/career_sequence.dart` — modified — attaches stable anchor keys to career entries.
- `lib/features/trace/domain/trace_geometry.dart` — modified — documents evenly spaced layout as provisional geometry.
- `lib/features/trace/presentation/station_trace.dart` — modified — supplies the shared registry to the trace.
- `lib/features/trace/presentation/telemetry_trace.dart` — modified — resolves measured anchors and retries after initial layout.
- `lib/features/trace/presentation/trace_burst_label.dart` — created — extracted the existing burst label and its content type.
- `lib/features/trace/presentation/trace_frame.dart` — created — extracted the immutable repaint state.
- `test/widget/trace/trace_test.dart` — modified — verifies painted centres before and after scroll and resize in both motion modes.
- `test/golden/goldens/hero_dark_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/hero_dark_ar.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/hero_light_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/hero_light_ar.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/hero_stats_dark_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_railed_dark_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_railed_dark_ar.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_railed_light_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_railed_light_ar.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_compact_dark_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_compact_dark_ar.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_compact_light_en.png` — modified — approved measured-waveform baseline.
- `test/golden/goldens/chrome_compact_light_ar.png` — modified — approved measured-waveform baseline.
- `lib/features/privacy/presentation/widgets/consent_banner.dart` — modified — uses a static child under reduced motion to avoid an SDK layout assertion.
- `docs/worklog/2026-09-06-05-measured-trace-anchors-handoff.md` — created — records the trace-anchor implementation and validation.

## Decisions made
The registry uses stable global keys because the trace background and station scroll content are siblings in `ChromeScaffold`. Entry centres are converted from global coordinates to fixed-trace document coordinates by adding the current scroll offset. Measurement happens after layout and publishes only changed geometry; provisional positions remain the first-frame fallback. Lock detection uses the cached measurements, with one nearest-burst lookup per label build.

The registry remains a manual presentation provider because it owns Flutter GlobalKeys. This follows the existing `build.yaml` workaround for Riverpod 2's inability to summarize this SDK's widget syntax, documented in worklog `2026-09-05-02-foundation.md` and linked to dart-lang/sdk issue 61870. Widgets now watch the shared provider in build. No package, token, route, owner content, consent decision, analytics, or storage behavior was changed.

The owner explicitly approved the consent presentation fix and the eight additional chrome goldens on continuation. The reduced-motion resize regression was kept and now passes with the banner fix; no test was skipped or removed. The banner renders its existing child directly under reduced motion, avoiding the SDK's zero-duration AnimatedSize self-layout assertion without changing consent behavior.

## Tests
- Added: `bursts follow career centres through scroll and resize (reduced motion: false)` and its reduced-motion counterpart.
- Modified: `test/widget/trace/trace_test.dart`, five station and eight chrome golden baselines.
- Full suite: pass, 434 passing / 0 failing. Separate suites: 398 non-golden and 36 golden passing. Worker suite: 12 passing / 0 failing.
- Coverage delta: 92.85% at the propagation-map handoff to 93.33% (3471/3719 lines), +0.48 percentage points.

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (200 files, 0 changed)
fvm flutter analyze                        pass (no issues; run with --fatal-infos)
fvm flutter test                           pass (434 passing, 0 failing)
fvm flutter build web --wasm               pass (built build/web)
```

Additional CI-equivalent commands:
- `fvm flutter test --coverage --exclude-tags golden --reporter expanded`: pass, 398 tests.
- `fvm flutter test --tags golden --reporter expanded`: pass, 36 tests.
- `node --test worker/test/*.test.js`: pass, 12 tests.
- `fvm flutter test test/golden/station_test.dart --update-goldens --name 'the settled hero|the hero with the stat panels' --reporter expanded`: pass, exactly five approved baselines regenerated.
- `fvm flutter test test/golden/chrome_test.dart --update-goldens --name 'chrome with the rail' --reporter expanded`: pass, exactly eight additionally approved baselines regenerated.

The sandboxed Dart VM crashed during CPU detection; subsequent SDK commands ran through FVM with approved sandbox escalation. Review initially found the reduced-motion resize failure and eight additional expected chrome golden mismatches. Both were resolved with the owner's explicit approval. No failed test was removed or skipped.

## Known issues left open
All local verification gates pass after the approved corrections. Actions must be checked on the exact committed SHA after push. The previous propagation-map commit `876a98445e8cbe52f04dd2ef762a9c9ef7f9053f` passed Actions run 34001185236. Do not stage the ignored `test/golden/failures/` directory.

Trace and map frame costs remain unmeasured in a real browser profile. An isolated Chrome session and local server were prepared and then closed; no browser acceptance result is claimed. The acquisition-composite OG image, favicon verification in light and dark browser chrome, real-phone browser testing, Lighthouse on the deployed main build, profile stats, Arabic native review, missing twelfth app, and CV PDF remain open. The existing missing Material/Cupertino icon-font build warning remains. Do not merge to main, publish, tag, or start Milestone 2 without the required approvals.

## Next
Verify Actions on the exact trace-anchor commit, then capture the settled acquisition frame for the social preview and measure trace/map painter costs in a real browser profile.
