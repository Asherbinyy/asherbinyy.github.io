# Ahmed Elsherbini — Portfolio

Flutter portfolio for phone and desktop browsers, with a Three.js intro and Cloudflare Worker content/admin service. Flutter 3.47.2 / Dart 3.13.2 are pinned with FVM.

[Website](https://asherbinyy.github.io/) · [CV](https://asherbinyy.github.io/cv/) · [Quick résumé](https://asherbinyy.github.io/brief/) · [Admin](https://nocturne-analytics.asherbinyy.workers.dev/admin)

## Run locally

```bash
fvm install
fvm flutter pub get
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run tool/generate_mark.dart
fvm dart run tool/generate_static.dart
fvm flutter run -d chrome --wasm --web-port 8332
```

Open `http://localhost:8332` while the command is running. If that port is already serving a review build, stop that server first or choose another port. Localhost needs a running server; it is not a deployed website.

## Verify

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter build web --wasm
node --test worker/test/*.test.js
```

## Content and status

Bundled JSON lives in `assets/content/`; the current app reads published Worker overrides with a bundled fallback. Static CV/Brief and metadata are not yet coordinated with admin publication. Visitor analytics is disabled in the public release.

Flutter remains the public UI. [Enhancement plan](docs/19-FLUTTER-ENHANCEMENT-PLAN.md) · [Open issues](docs/11-OPEN-ISSUES.md) · [Audit](docs/18-PROJECT-AUDIT.md) · [Worklogs](docs/worklog/).

Claude owns the admin/Worker in a separate checkout. Its updated editor is not merged: [review blockers and next prompt](docs/25-ADMIN-REREVIEW.md). Codex owns Flutter and the [real preview/release integration](docs/23-ADMIN-INTEGRATION-REPLY.md). Pages and Worker deployments are separate. [Worker setup and password operations](worker/README.md).

Read [AGENTS.md](AGENTS.md) before contributing. Personal content/photos are not reusable templates. [Asset sources](docs/14-PROVENANCE.md) · [Guardian license and modifications](web/intro/models/LICENSE.md).
