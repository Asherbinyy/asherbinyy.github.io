# Nocturne

Personal portfolio for Ahmed Elsherbini. Flutter 3.47, web target, built for phone and desktop browsers alike.

**Live:** [asherbinyy.github.io](https://asherbinyy.github.io) · **Recruiter view:** [/brief](https://asherbinyy.github.io/brief)

<!-- badges: CI, coverage, Flutter version -->

![Screenshot](docs/assets/screenshot.webp)

---

## What this is

A portfolio built as an instrument panel. The visual language is signal telemetry — the design comes from a first degree in Communications and Electronics, and the structure follows a career that moved across Egypt, Saudi Arabia, Armenia, Qatar, Canada and the UK.

The central interaction is a telemetry trace that runs the length of the page and responds to scroll velocity: scroll fast and the waveform degrades into noise, slow down and it resolves and locks, revealing the role beneath it. It rewards attention rather than demanding it.

> **This is what is live today, and it is being replaced.** From 2026-09-07 the
> concept changes: the identity becomes Egyptian, drawn from where the owner is
> from rather than from what he studied, and the site grows a person around the
> résumé. The engineering below survives it almost entirely — the change is
> skin, not structure. See [`docs/00-PROJECT-BRIEF.md`](docs/00-PROJECT-BRIEF.md)
> §3 for the concept, [`docs/09-ROADMAP.md`](docs/09-ROADMAP.md) for milestones
> 4–6, and [`docs/12-MOTIF-LIBRARY.md`](docs/12-MOTIF-LIBRARY.md) before any
> visual work.

## Notable decisions

**Standalone design package.** Built against `material_ui` rather than the in-framework Material library, which was frozen in Flutter 3.44 and deprecates in November 2026. No `cupertino_ui` — the target is browsers, where there are no iOS system widgets to match.

**Flutter Web is not indexable, so `/cv` and `/brief` are not Flutter.** CanvasKit and WASM both render to canvas, meaning search engines and ATS parsers see an empty document. Those two routes are hand-written static HTML generated from the same JSON content, so they can never drift from the app. The rest of the site is free to be as ambitious as it likes.

**Cookieless analytics, built rather than installed.** No third-party tracking script — no Google Analytics, no tag manager, nothing in the network tab that isn't first-party. Unique visitors are counted with a rotating-salt hash computed server-side — the salt regenerates every 24 hours and the old one is destroyed, so identifiers are mathematically unlinkable across days. IP addresses are resolved to a coarse country and discarded in the same function invocation; they are never written or logged. The aggregate tier writes nothing to the visitor's device, so PECR consent is not engaged by it. The site does store three things locally — the theme, the language and Recruiter Mode — because the visitor chose them; those are user-requested preferences, which PECR exempts, and they never leave the browser. Session-level analytics are strictly opt-in.

The `/privacy` page shows a live table of every field the site can collect, its status, and the visitor's own current values — including the rows marked *never collected*.

**A custom map instead of an SDK.** The propagation map is an equirectangular projection drawn with a `CustomPainter`. Roughly 30KB against ~900KB for a mapping SDK, no API key, no third-party data flow, and fully themeable.

**Recruiter Mode.** A single control collapses the whole experience into a quiet, fast, scannable page. Knowing when not to be flashy is part of the work.

**Static hosting, deliberately.** The site is a static bundle on GitHub Pages, with a single Cloudflare Worker for the analytics endpoint. `404.html` mirrors the app shell so client-side routes resolve on direct hits, and `.nojekyll` keeps Pages from stripping Flutter's underscore-prefixed output.

## Stack

Flutter 3.47.2 (pinned with FVM) · Dart 3.13.2 · Riverpod 2 · go_router · freezed · GitHub Pages · Cloudflare Workers

## Running

The Flutter SDK is pinned with [FVM](https://fvm.app) via `.fvmrc`.

```bash
fvm install          # installs the pinned SDK (3.47.2)
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run -d chrome --wasm
```

Generated files (`*.g.dart`, `*.freezed.dart`) are not committed, so `build_runner` must run before the first build.

```bash
fvm flutter test                    # unit, widget, golden
fvm flutter test --coverage
fvm dart run tool/generate_static.dart   # regenerate /cv and /brief
fvm flutter build web --wasm --release
```

## Structure

```
lib/
  app/        bootstrap, router, theme, l10n
  core/       tokens, platform, motion, painting, analytics, shared widgets
  content/    models and repository — content is local JSON, no CMS
  features/   station, trace, signal, work, writing, about, privacy, console
docs/         specification, provenance ledger, and build worklog
web/          hand-authored shell and static routes
```

## Documentation

The specification lives in [`docs/`](docs/) and was written before the first line of code. [`AGENTS.md`](AGENTS.md) defines the operating rules, and [`docs/worklog/`](docs/worklog/) records every build session — what changed, what was decided and why, what was tested, what was left open.

## Licence

Source is MIT. Content, design and personal data are not — please don't ship this as your own portfolio.
