# Ahmed Elsherbini — Portfolio

Flutter web portfolio with a Three.js intro. Built with Flutter 3.47 / Dart 3.13 (pinned via FVM).

[Website](https://asherbinyy.github.io/) · [CV](https://asherbinyy.github.io/cv/) · [Résumé](https://asherbinyy.github.io/brief/)

## Run

```bash
fvm install
fvm flutter pub get
fvm flutter gen-l10n
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run tool/generate_mark.dart
fvm dart run tool/generate_static.dart
fvm flutter run -d chrome --wasm --web-port 8332
```

## Verify

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter build web --wasm
```

