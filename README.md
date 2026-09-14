# Ahmed Elsherbini

[asherbinyy.github.io](https://asherbinyy.github.io/)

## What I built

### Portfolio

A personal portfolio website.

**Stack:** Flutter · Dart · WebAssembly · GitHub Pages

![Portfolio](screenshots/portfolio.png)

### Intro

A 3D Egyptian temple scene that greets visitors before the portfolio loads.

**Stack:** Three.js · GLSL · JavaScript

![Intro](screenshots/intro.png)

### Admin Panel

A content management dashboard for publishing and editing portfolio data.

**Stack:** Cloudflare Workers · JavaScript · KV Storage

## Run

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart run tool/generate_mark.dart
dart run tool/generate_static.dart
flutter run -d chrome --wasm
```
