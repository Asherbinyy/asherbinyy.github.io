# Architecture — NOCTURNE

**Flutter 3.47.2 / Dart 3.13.2** (August 2026 stable), pinned with **FVM**. **Web target only.** Feature-first clean architecture.

## Platform scope

This ships to browsers and nowhere else. There is no App Store build, no Play Store build, no TestFlight. It is a portfolio link.

```bash
fvm spawn 3.47.2 create --platforms web ...
```

Consequences:
- No `ios/`, `android/`, `macos/`, `windows/` or `linux/` directories. If one appears, delete it.
- **`cupertino_ui` is not a dependency.** Cupertino exists to match iOS system widgets; in a browser there are no system widgets to match, and the design system is bespoke anyway. Dropping it removes weight for nothing lost.
- No native plugins, no platform channels, no permissions.
- Mobile still matters — **phone browsers are a primary target** — but that is a responsive and input-type problem, not a native one. See `01-DESIGN-SYSTEM.md` §7.

## SDK version management

The SDK is pinned per-project with [FVM](https://fvm.app). Never use a floating `3.x` or the machine-global Flutter — it makes CI caches unstable and lets the toolchain shift under you mid-project.

`.fvmrc` at the repository root is the single source of truth:

```json
{
  "flutter": "3.47.2"
}
```

`.fvmrc` is committed. `.fvm/` is not — it holds a symlink to a globally cached SDK, and symlinks created on macOS do not work on Windows. FVM adds its own ignore entries automatically.

Fresh clone:

```bash
fvm install          # reads .fvmrc, installs 3.47.2 if not cached
fvm flutter pub get
```

**Every Flutter and Dart command in this repository runs through `fvm`.** `fvm flutter test`, `fvm dart format`, `fvm dart run build_runner`. A bare `flutter` command invokes whatever version happens to be on the machine's PATH, which defeats the pin entirely and produces the class of bug that only reproduces on one person's laptop.

A shell alias (`alias flutter='fvm flutter'`) is fine locally, but the documentation and CI use the explicit form so nothing depends on a developer's shell config.

`pubspec.yaml` still declares constraints, and they must agree with `.fvmrc`:

```yaml
environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"
```

To upgrade: change the version in `.fvmrc`, run `fvm install`, verify the four commands pass, commit as `chore(deps): update Flutter SDK to x.y.z`. CI picks the new version up from `.fvmrc` automatically.

---

## 0. Material and Cupertino are no longer in the SDK

This is the most important thing on this page and it postdates most training data.

As of Flutter 3.47, the Material and Cupertino design libraries ship as standalone pub.dev packages — `material_ui` and `cupertino_ui`, both at 1.0. The in-framework versions (`package:flutter/material.dart`, `package:flutter/cupertino.dart`) were frozen in 3.44 and are scheduled for formal deprecation in the November 2026 stable release.

This is a new project, so it uses the standalone packages from the first commit. No compatibility bridge — the bridge exists to unblock migrating apps with unmigrated dependencies, not to write new code against.

```dart
// Correct
import 'package:material_ui/material_ui.dart';

// Legacy — deprecated, never use in this repository
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Not a dependency here — web-only target, see Platform scope above
import 'package:cupertino_ui/cupertino_ui.dart';
```

If an agent scaffolds with the legacy imports — and most will, by habit — run `fvm dart fix --apply --code=migrate_design_widgets`, then verify `pubspec.yaml` picked up the dependencies. Add a note to the worklog. Files that mix both imports, conditional `dart:io` platform checks, and `build_runner` output need manual attention after the automated fix.

**Impeller is the default renderer** on Android, macOS, Windows and Linux as of 3.47. Do not add Skia flags.

---

## 1. Decisions and why

| Decision | Choice | Reason |
|---|---|---|
| Flutter SDK | **3.47.2, pinned via FVM** | Current stable. `.fvmrc` pins it for every machine and for CI. |
| Design libraries | **`material_ui` only** | In-framework versions deprecate in November 2026. Cupertino is not needed on web. |
| State management | **Riverpod 2 + code generation** | Compile-time safe, far less boilerplate than Bloc for a read-heavy content site, better disposal semantics for animation-heavy pages. Bloc's event/state ceremony buys nothing here — there are almost no complex state machines. |
| Routing | **go_router** | Declarative, real URLs, deep-linkable, works with the static-route split. |
| Models | **freezed + json_serializable** | Immutable, exhaustive unions, generated `fromJson`. |
| Content | **Local JSON assets** | No network on cold start. Version-controlled. Editable by hand or agent. |
| Web renderer | **WASM (skwasm)** | Meaningfully faster than CanvasKit on current Flutter. |
| Hosting | **GitHub Pages** | Free, static, HTTPS included, deploys from Actions. Custom domain is a later 5-minute change. |
| Analytics backend | **Cloudflare Workers + KV** | GitHub Pages is static-only, so the beacon endpoint needs a host. Workers' free tier needs no billing account, unlike Firebase Functions Gen 2. |
| Map | **Custom projection + CustomPainter** | No SDK, no API key, no third-party data flow, fully themeable, ~30KB instead of ~900KB. Also keeps the privacy claim honest. |
| Fonts | **Bundled locally** | No CDN round trip, no external request, no layout shift. |
| Lint | **very_good_analysis** | Stricter than `flutter_lints`. |

**Do not substitute any of these without recording the reason in a worklog entry.**

---

## 2. Directory structure

```
lib/
  main.dart                     entry, bootstrap, ProviderScope
  app/
    app.dart                    root widget, MaterialApp.router
    router.dart                 go_router config, route guards
    theme/
      tokens.dart               ALL colour/space/radius/duration constants
      typography.dart           text styles from tokens
      nocturne_theme.dart       dark ThemeData
      daybreak_theme.dart       light ThemeData
      theme_controller.dart     theme + Recruiter Mode state
    l10n/
      app_en.arb
      app_ar.arb
  core/
    platform/
      platform_service.dart     isTouch / isPointer / density resolution
      app_messenger.dart        snackbar vs toast — single source of truth
      haptics.dart              no-ops on web
    motion/
      curves.dart
      durations.dart
      reduced_motion.dart       MediaQuery wrapper, single read point
    painting/
      grain_painter.dart
      trace_painter.dart        the telemetry waveform
      projection.dart           lat/lon → canvas, equirectangular
    analytics/
      consent_controller.dart
      analytics_client.dart     no-op until consent granted
      events.dart               typed event definitions
    widgets/
      instrument_panel.dart     hairline + corner ticks
      beacon_button.dart
      telemetry_value.dart
      focus_ring.dart
    error/
  content/
    models/                     freezed models
    content_repository.dart     loads + caches JSON from assets
    providers.dart
  features/
    station/                    home, hero, acquisition sequence
    trace/                      telemetry timeline
    signal/                     propagation map
    work/                       grid + case studies
    writing/                    Medium feed
    about/
    privacy/                    consent panel, live session readout
    recruiter/                  in-app brief view
    console/                    gated analytics dashboard
```

Each feature: `data/` → `domain/` → `presentation/`. Features never import from another feature's internals — cross-feature communication goes through `content/` or a shared provider.

---

## 3. Static routes outside Flutter

```
web/
  index.html          hand-authored shell, meta, OG, JSON-LD Person
  404.html            copy of index.html — see below
  .nojekyll           REQUIRED, see below
  favicon.png         generated from assets/brand/mark.svg, see 01-DESIGN-SYSTEM.md §12
  icons/
    icon-192.png
    icon-512.png
    icon-maskable.png
  cv/index.html       plain HTML CV — no JS, no Flutter
  brief/index.html    Recruiter Mode static twin
  robots.txt
  sitemap.xml
  assets/
```

`assets/brand/mark.svg` is the single source for the mark and every icon size — generate the raster sizes from it at build time rather than designing each separately.

### Two GitHub Pages requirements

**`.nojekyll` is mandatory.** Pages runs Jekyll by default, and Jekyll strips files and directories beginning with an underscore. Flutter's build output contains several. Without this file the site fails in ways that are hard to diagnose because the build succeeds and the deploy succeeds.

**`404.html` must be a copy of `index.html`.** Pages is a static file server with no rewrite rules, so a direct hit on `/work/mokaf` looks for a file that does not exist and returns 404 — breaking every deep link, every shared URL, and every search result. Serving the app shell from `404.html` lets the router resolve the path client-side. The copy is made in CI, never committed.

Do not switch to hash routing (`/#/work/mokaf`) to avoid this. Hash fragments are not sent to the server and harm indexing, which defeats the purpose of §6.

`/cv` and `/brief` are the indexable surface. They must render with JavaScript disabled. Their content is generated from the same JSON — see `07-CONTENT-SCHEMA.md` for the generation script contract.

`/brief` (static) and the in-app Recruiter Mode show the same content. The in-app version is for viewers already inside the Flutter app; the static one is for search engines and direct links.

---

## 4. Packages

```yaml
environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Design system — standalone as of Flutter 3.47. No cupertino_ui: web-only.
  material_ui: ^1.1.0

  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0
  go_router: ^14.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  intl: any                 # let flutter_localizations pin this
  url_launcher: ^6.3.0
  flutter_svg: ^2.0.0
  shared_preferences: ^2.3.0   # theme + consent persistence only
  http: ^1.2.0                 # Medium RSS, analytics beacon
  xml: ^6.5.0                  # RSS parse

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  very_good_analysis: ^6.0.0
  mocktail: ^1.0.0
  alchemist: ^0.11.0
```

Version constraints are a starting point — resolve against pub.dev at scaffold time and record the resolved versions in the first worklog entry.

Keep this list closed. Any addition needs a worklog justification.

**Explicitly rejected:**
- `google_fonts` — network fetch, external data flow, layout shift. Fonts are bundled.
- Any map SDK — see the map decision above.
- `firebase_analytics` — the first-party pipeline in `06-ANALYTICS-AND-PRIVACY.md` covers the need with fewer data flows and a cleaner claim.
- `rive` / `lottie` — the trace is a `CustomPainter`. Imported animation would fight the token system and add weight.
- Any state management beyond Riverpod. One pattern in the codebase, not two.
- `cupertino_ui` — web-only target, bespoke design system.
- All Firebase packages — hosting is GitHub Pages, the analytics backend is a Cloudflare Worker reached over plain HTTP.

---

## 5. Performance budget

| Metric | Budget |
|---|---|
| Initial payload (gzipped, WASM) | ≤ 2.2MB |
| First contentful paint on `/cv` | ≤ 1.0s |
| Acquisition sequence to interactive | ≤ 3.5s on a 10Mbps connection |
| Trace painter frame cost | ≤ 4ms |
| Map painter frame cost | ≤ 6ms during arc animation |
| Total bundled font weight | ≤ 580KB (subset to used ranges) |
| Time to interactive, phone browser on 4G | ≤ 5s |
| Any single image | ≤ 180KB, WebP, explicit dimensions |

Rules:
- Subset fonts to Latin + Arabic ranges actually used. Full Plex Arabic unsubsetted is large.
- **The 580KB figure was raised from 480KB in Milestone 3.** The original was set
  without pricing three Arabic weights beside seven Latin faces: Plex Sans
  Arabic is roughly 100KB a weight even reduced to modern Arabic letterforms,
  so 480KB could only be met by dropping a weight and letting Arabic emphasis
  synthesise. The subsetting was tightened first — dropping the Presentation
  Forms, which HarfBuzz derives from the base block anyway, and the
  Persian/Urdu ranges took the bundle from 794KB to 556KB — and only then was
  the budget moved, to 580KB, which leaves headroom without inviting drift.
- Every screenshot ships WebP with a low-quality placeholder.
- `RepaintBoundary` around the trace and map.
- Painters must early-return when off-screen.
- Defer non-critical assets until after the acquisition sequence completes.

---

## 6. Error handling

- `ErrorWidget.builder` overridden — never show a red screen in production.
- Content load failure falls back to a bundled minimal JSON so the site always renders name, positioning and contact.
- Medium RSS failure hides the writing section silently rather than showing an error. It is not core content.
- All uncaught errors reported through the analytics client **only when consent is granted**. Without consent, errors are logged to console and dropped.
