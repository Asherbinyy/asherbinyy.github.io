# Ahmed Elsherbini — Portfolio

Egyptian-inspired portfolio for phone and desktop browsers. The current frontend uses Flutter 3.47.2 / Dart 3.13.2, pinned with FVM. Cloudflare Workers serves content, media and the admin panel.

[Website](https://asherbinyy.github.io/) · [CV](https://asherbinyy.github.io/cv/) · [Quick résumé](https://asherbinyy.github.io/brief/) · [Admin](https://nocturne-analytics.asherbinyy.workers.dev/admin)

## Development

```bash
fvm install
fvm flutter pub get
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run tool/generate_mark.dart
fvm dart run tool/generate_static.dart
fvm flutter run -d chrome --wasm
```

## Verification

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter build web --wasm
node --test worker/test/*.test.js
```

## Content and admin

Sign in to the admin with `ADMIN_TOKEN`. It edits profile, projects, journey, education and interests. Published content overrides bundled JSON; failed remote reads fall back to the bundle. Images use the Worker media service; direct video upload is not supported. Medium articles update through the RSS relay.

Rotate the admin password from the repository root using the documented isolated CLI runtime:

```bash
npm exec --yes --package=node@22 --package=wrangler@4.129.0 -- wrangler secret put ADMIN_TOKEN
```

In-panel password changes, live preview and flexible content components are still planned. Admin edits currently do **not** update static CV/Brief HTML or shell metadata automatically.

Hosting uses GitHub Pages and Cloudflare free tiers, subject to their limits: [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) and [KV pricing](https://developers.cloudflare.com/kv/platform/pricing/). The public release currently disables visitor analytics. Saved display preferences are separate from analytics.

## Project status

The redesign is not finished. Start with the [audit](docs/18-REINNOVATION-AUDIT.md), [Re-innovation milestones](docs/19-REINNOVATION-ROADMAP.md) and [open issues](docs/11-OPEN-ISSUES.md). Read [AGENTS.md](AGENTS.md) before contributing. Session records are in [the worklog](docs/worklog/).

Public pages currently run in Flutter; `/cv/` and `/brief/` are generated HTML. The audit recommends HTML-based public pages for SEO; migration is not yet approved or implemented. Pages and the Worker deploy separately. [Worker operations](worker/README.md).

## Assets

Personal content and photographs are not reusable portfolio templates. Third-party asset sources are recorded in [the provenance ledger](docs/14-PROVENANCE.md). The current guardian mesh is CC BY-SA 4.0; see [its license and modifications](web/intro/models/LICENSE.md).
