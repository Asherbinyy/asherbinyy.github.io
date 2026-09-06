# 2026-09-06-04 — Propagation map fidelity

**Agent:** Codex / GPT-6
**Milestone:** 1
**Started from:** 21050ba

## Goal
Complete the Milestone 1 propagation map by drawing real land outlines from a local asset and supporting direct pan and zoom interaction without adding runtime network access.

## What changed
- Added the Natural Earth 1:110m land dataset as a bundled GeoJSON asset with source and public-domain attribution.
- Added a strict GeoJSON parser and provider for Polygon and MultiPolygon coastline rings.
- Drew land outlines beneath the existing graticule, links, endpoints and labels using existing monochrome design tokens.
- Added direct pointer, touch and trackpad pan and zoom through `InteractiveViewer` while preserving map hit testing and keyboard station selection.
- Updated the five signal golden baselines with the owner's explicit approval after inspecting the expected coastline-only differences.
- Added parser, coastline-rendering and zoom-interaction coverage.

## Files touched
- `assets/maps/README.md` — created — records the bundled dataset source, version and license.
- `assets/maps/ne_110m_land.geojson` — created — supplies offline Natural Earth land geometry.
- `lib/core/painting/coastline_data.dart` — created — parses and provides coastline rings.
- `lib/core/painting/map_painter.dart` — modified — paints land outlines before the map overlays.
- `lib/features/signal/presentation/signal_screen.dart` — modified — resolves coastline data for the map.
- `lib/features/signal/presentation/widgets/propagation_map.dart` — modified — supplies coastlines and direct pan and zoom interaction.
- `pubspec.yaml` — modified — bundles the maps asset directory.
- `test/golden/goldens/signal_dark_ar.png` — modified — captures the Arabic dark map with land outlines.
- `test/golden/goldens/signal_dark_en.png` — modified — captures the English dark map with land outlines.
- `test/golden/goldens/signal_light_ar.png` — modified — captures the Arabic light map with land outlines.
- `test/golden/goldens/signal_light_en.png` — modified — captures the English light map with land outlines.
- `test/golden/goldens/signal_selected_dark_en.png` — modified — captures selected-station state over land outlines.
- `test/support/station_harness.dart` — modified — waits for coastline assets before signal widget tests settle.
- `test/unit/core/painting/coastline_data_test.dart` — created — covers valid geometry, malformed data and unsupported geometry.
- `test/unit/core/painting/map_painter_test.dart` — modified — supplies coastline input to painter tests.
- `test/widget/signal/signal_test.dart` — modified — verifies coastline rendering and direct zoom interaction.

## Decisions made
Natural Earth v5.1.2 at 1:110m resolution was bundled because it is a small, public-domain world land dataset and keeps the map fully offline at runtime. The existing strong hairline colour and hairline width distinguish land from the graticule without adding a hue or design token. Flutter's documented `InteractiveViewer` scale bounds were retained because the project specifies pan and zoom gestures but does not specify numeric bounds; trackpad scrolling is configured to scale.

## Tests
- Added: `coastline_data_test.dart` (3), propagation-map coastline and zoom widget tests (2)
- Modified: `map_painter_test.dart`, `signal_test.dart`, five signal golden baselines
- Full suite: pass, 432 passing, 0 failing (396 non-golden and 36 golden)
- Coverage delta: full non-golden suite reports 92.85% line coverage; previous comparable coverage was not recorded in this session

## Verification run
```
fvm dart format --set-exit-if-changed .   pass (197 files, 0 changed)
fvm flutter analyze                        pass (no issues; run with --fatal-infos)
fvm flutter test                           pass (396 non-golden and 36 golden)
fvm flutter build web --wasm               pass
```

## Known issues left open
Trace and map frame cost still needs measurement in a real browser profile. Direct panning becomes useful once the map is zoomed because `InteractiveViewer` retains its default boundary behavior. The build continues to emit the existing warning that Material and Cupertino icon fonts are absent; the application does not bundle or use those icon packages.

## Next
Anchor telemetry trace bursts to the measured career sections so the trace reflects the rendered station layout rather than evenly spaced role indices.
