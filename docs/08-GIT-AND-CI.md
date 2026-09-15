# Git and CI — NOCTURNE

The repository is public and forms part of the portfolio. A recruiter may read the commit history. It should read like a professional project, because it is one.

---

## Commits

Conventional Commits.

```
<type>(<scope>): <subject>

<body — why, not what>

<footer>
```

Types: `feat` `fix` `refactor` `perf` `style` `test` `docs` `build` `ci` `chore`

Scopes: `station` `trace` `signal` `work` `writing` `about` `privacy` `recruiter` `theme` `l10n` `content` `core` `ci` `docs`

Subject: imperative mood, lower case, no trailing full stop, ≤ 72 characters.

```
feat(trace): modulate waveform coherence by scroll velocity

The trace degrades to noise above 900px/s and resolves as the viewer
slows, so the burst labels reward stopping. Painter is capped at 60fps
and early-returns when off-screen to stay inside the 4ms budget.

Refs: docs/01-DESIGN-SYSTEM.md#6
```

Body explains reasoning. The diff already shows what changed.

Commit in logical units — one coherent change per commit. Not one commit per session, not one per file.

---

## Branches — one branch per phase

`main` is the published site. Whatever is on `main` is what the world sees, so nothing lands there until a whole phase is finished and verified.

```
main                       always deployable, protected, auto-publishes
phase/1-ground-station     all Milestone 1 tasks
phase/2-depth              all Milestone 2 tasks
phase/3-edge               all Milestone 3 tasks
fix/<scope>-<slug>         branched from main, for live breakage only
```

The flow:

1. `git checkout -b phase/1-ground-station` from `main`.
2. Work every task in that milestone on the phase branch, committing per task. CI runs `verify` on every push — analyze, test, build — but does **not** deploy.
3. When the milestone's definition of done is met in `09-ROADMAP.md`, open a PR into `main`.
4. `verify` must pass on the PR. Review the diff.
5. Merge. The merge to `main` triggers `build` then `deploy`, and the site updates.
6. Tag the release: `v0.1.0` for Milestone 1, and so on.
7. Branch the next phase from the new `main`.

**Deployment only ever happens from `main`, and only after a full phase.** A half-finished feature is never live. This is the point of the phase branch — you get continuous verification without continuous publishing.

No direct pushes to `main`. Merge via PR. **Do not squash phase branches** — the per-task commits are the build record and they pair with the worklog entries. Squash only for `fix/` branches.

Hotfixes for something broken in production branch from `main`, not from a phase branch, and merge straight back.

---

## .gitignore

Generated code is ignored and regenerated in CI. This keeps the repository readable — a reviewer opening it sees written code, not thousands of lines of `.g.dart`.

```gitignore
# FVM — .fvmrc IS committed, the SDK symlink is not
.fvm/

# Dart / Flutter
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
pubspec.lock          # app, not package — SDK pinned via .fvmrc instead

# Generated
*.g.dart
*.freezed.dart
*.config.dart
coverage/
lcov.info

# Generated static routes
web/cv/index.html
web/brief/index.html

# IDE — note the negation, see below
.idea/
.vscode/*
!.vscode/settings.json
*.iml
*.swp

# OS
.DS_Store
Thumbs.db

# Native platform dirs — web-only project, these should not exist at all
ios/
android/
macos/
windows/
linux/

# Secrets — never commit
.env
.env.*
**/google-services.json
**/GoogleService-Info.plist
firebase-service-account*.json
*.keystore
*.jks
key.properties

# Golden failures
**/failures/

# Agent scratch
.agent/
*.tmp
```

**`.vscode/settings.json` is deliberately un-ignored.** With FVM the editor must be pointed at the pinned SDK, or the analyzer runs a different Flutter version than the terminal and reports errors that don't exist:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": { "**/.fvm": true },
  "files.watcherExclude": { "**/.fvm": true }
}
```

This is project configuration, not personal preference, so it belongs in the repository.

---

## What IS committed, and why

The ignore list is only half the rule. An agent that does not know what belongs in the repository will either omit something important or commit build artefacts. Both are visible to anyone reading the repo.

| Path | Committed | Reason |
|---|---|---|
| `.fvmrc` | yes | **The SDK pin.** Without it, a fresh clone and CI both build on whatever Flutter happens to be installed. |
| `.fvm/` | **no** | Symlink to a globally cached SDK. Symlinks made on macOS break on Windows, and the SDK itself is ~1.5GB. |
| `.vscode/settings.json` | yes | Points the analyzer at `.fvm/flutter_sdk`. Without it the editor and terminal disagree about the SDK version. |
| `AGENTS.md` | yes | The agent reads it. Without it in-repo, every session starts blind. |
| `docs/**` | yes | The specification. Also demonstrates how the project was run. |
| `docs/worklog/**` | yes | **The handoff chain.** Uncommitted worklogs are worthless — the point is that the next agent, possibly a different tool, can read them. |
| `CHANGELOG.md` | yes | Release history. |
| `README.md` | yes | Public face. |
| `lib/**` | yes | Source, minus generated files. |
| `test/**` | yes | Including `test/fixtures/`. |
| `test/**/goldens/**` | yes | Golden baselines. Without them CI cannot detect visual regression — this is the one binary asset class that must be committed. |
| `assets/content/**` | yes | Site content. Version-controlled so a bad edit is one revert away. |
| `assets/fonts/**` | yes | Subset fonts. Committed so builds are reproducible without a download step. |
| `assets/img/**`, `assets/screens/**` | yes | Optimised WebP only. Never commit an unoptimised source image. |
| `web/index.html` | yes | Hand-authored shell. Not generated. |
| `web/robots.txt`, `web/sitemap.xml` | yes | Hand-maintained. |
| `web/cv/`, `web/brief/` | **no** | Generated by `tool/generate_static.dart` in CI. Committing them guarantees they drift from the content. |
| `tool/**` | yes | Build scripts. |
| `.github/workflows/**` | yes | Pipeline. |
| `analysis_options.yaml` | yes | Lint config. |
| `web/CNAME` | yes, once a domain exists | Tells Pages which custom domain to serve. |
| `wrangler.toml` | yes | Worker config. Secrets live in Cloudflare, never here. |
| `worker/**` | yes | Cloudflare Worker source for the analytics endpoint. |
| `*.g.dart`, `*.freezed.dart` | **no** | Regenerated in CI. Thousands of lines of generated code make the repo unreadable to a human reviewer — and a recruiter may be that reviewer. |
| `pubspec.lock` | **no** | SDK pinned via `.fvmrc`; package versions resolve from `pubspec.yaml` constraints. |
| Anything under §secrets above | **never** | |

Two rules that follow:

- **CI must run `build_runner` before analyze and test**, since generated files are absent from a fresh clone. If the pipeline skips this, nothing compiles.
- **A fresh clone must build with only `fvm install`, `fvm flutter pub get`, `build_runner` and `fvm flutter build`.** No manual asset downloads, no undocumented setup step. If it doesn't, something that should be committed isn't. Test this periodically by cloning into a clean directory.

---

## Pre-merge gate

All must pass:

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
fvm flutter build web --wasm
```

Plus: coverage ≥ 80%, all privacy tests passing, no new `TODO` without an issue reference.

---

## CI — `.github/workflows/ci.yml`

Jobs:

**verify** — on every push and PR
1. Checkout
2. Read the pinned version from `.fvmrc` with `kuhnroyal/flutter-fvm-config-action`
3. Install that exact version with `subosito/flutter-action`, using the action's cache
4. `flutter pub get`
5. `dart run build_runner build --delete-conflicting-outputs`
6. `dart format --set-exit-if-changed .`
7. `flutter analyze --fatal-infos`
8. `flutter test --coverage`
9. Coverage threshold check, fail below 80%
10. Upload coverage artefact

```yaml
- uses: actions/checkout@v4
- uses: kuhnroyal/flutter-fvm-config-action@v3
  id: fvm-config
- uses: subosito/flutter-action@v2
  with:
    flutter-version: ${{ steps.fvm-config.outputs.FLUTTER_VERSION }}
    channel: ${{ steps.fvm-config.outputs.FLUTTER_CHANNEL }}
    cache: true
```

CI reads `.fvmrc` and installs that version directly rather than installing FVM itself — FVM's job is managing several SDKs on one machine, and a CI runner is disposable and only ever needs one. The version still comes from `.fvmrc`, so local and CI cannot drift.

Because the action puts the pinned SDK on `PATH`, CI steps use bare `flutter` and `dart`. Local work uses `fvm flutter` and `fvm dart`. Both resolve to 3.47.2.

**build** — on `main` only, needs `verify`
1. Same `.fvmrc` → flutter-action setup as `verify`
2. `dart run tool/generate_static.dart`
3. `flutter build web --wasm --release`
4. Lighthouse CI against the built output, fail if performance < 85 on `/cv`
5. Upload build artefact

**deploy** — on `main` only, needs `build`
1. `actions/upload-pages-artifact` with the `build/web` directory
2. `actions/deploy-pages`
3. Comment the deployed URL on the commit

```yaml
permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false
```

No credentials or secrets are needed — GitHub Pages deploys through OIDC from within the repository.

### Build steps specific to GitHub Pages

The `build` job must, after `flutter build web --wasm --release`:

```bash
touch build/web/.nojekyll          # Jekyll strips _underscore paths; Flutter emits them
cp build/web/index.html build/web/404.html   # client-side routing for deep links
```

Both are explained in `03-ARCHITECTURE.md` §3. Skipping either produces a deploy that succeeds and a site that is broken — the worst failure mode, because nothing reports an error.

**Repository name matters.** Name the repository `asherbinyy.github.io` so Pages serves from the root and `--base-href` stays `/`. A project repo serves from `/<repo-name>/`, which means every asset path carries the repo name and the later move to a custom domain becomes a rebuild instead of a DNS change.

### Adding a custom domain later

No rebuild, no code change:
1. Add a `CNAME` file to `web/` containing the bare domain.
2. At the registrar, point four `A` records at GitHub's Pages IPs and a `CNAME` on `www` to `asherbinyy.github.io`.
3. In repository settings, set the custom domain and tick "Enforce HTTPS".

Certificate provisioning takes up to an hour. Because `--base-href` was already `/`, nothing else changes.

---

## CHANGELOG.md

Keep a Changelog format. Updated on every merge to `main`. Milestone releases tagged `v0.1.0`, `v0.2.0`, `v1.0.0`.

---

## Repository presentation

The README is a portfolio surface in its own right. It should carry: a screenshot, the live link, a two-paragraph statement of what the project is and the reasoning behind the main technical decisions, the architecture diagram, how to run it, and CI/coverage badges.

Someone evaluating the owner as an engineer may well read the README before the site. Write it accordingly.
