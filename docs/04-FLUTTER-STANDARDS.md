# Flutter and Dart Standards — NOCTURNE

> Scope note, 2026-09-11: these standards apply to retained Flutter code; a possible HTML frontend is still only a proposal in [R1](19-REINNOVATION-ROADMAP.md). The “second chroma” ban at the end is obsolete; existing palette roles are in `01-DESIGN-SYSTEM.md`. Current user requirements and approved milestone decisions take precedence over old creative constraints. The audit makes no SDK, package or token change.

Target: **Flutter 3.47.2 / Dart 3.13.2.**

These are enforceable rules, not preferences. Code that breaks them does not get merged, regardless of whether it runs.

The reason this file exists: an AI agent writes plausible Flutter by default, and plausible Flutter is not good Flutter. Left unconstrained it will produce helper functions that return widgets, `Color(0xFF...)` inline, string constants where enums belong, and a 400-line `build`. Each is individually harmless and collectively fatal. Every rule below has the *reason* attached, because an agent that understands the reason will follow it in cases this document did not anticipate.

---

## 1. Imports

```dart
// Correct — standalone package, Flutter 3.47+
import 'package:material_ui/material_ui.dart';

// Deprecated — never in this repository
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Not a dependency — this is a web-only target
import 'package:cupertino_ui/cupertino_ui.dart';
```

This project targets **web only**. There is no iOS or Android build, so there is no Cupertino, no platform channels, no `dart:io`, and no plugin that requires a native implementation.

`package:flutter/widgets.dart`, `foundation.dart`, `services.dart` and `rendering.dart` remain in the SDK and are used normally.

Order, separated by blank lines:
1. `dart:` 
2. `package:flutter/…` and `package:material_ui` / `package:cupertino_ui`
3. Third-party packages
4. `package:nocturne/…` — always absolute, never relative

Relative imports (`../../core/theme.dart`) are banned. They break silently on file moves and make the dependency direction invisible.

---

## 2. Widgets are classes. Never functions.

```dart
// Banned
Widget _buildHeader(BuildContext context) => Row(children: [...]);

// Required
class StationHeader extends StatelessWidget {
  const StationHeader({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Row(children: [...]);
}
```

Not style. A function returning a widget does not create an element, so:
- it cannot be `const`, so it rebuilds every time the parent does
- its subtree cannot be skipped during rebuild — Flutter has no node to compare
- it does not appear in the widget inspector or DevTools, so performance work becomes guesswork
- it cannot hold a `RepaintBoundary` meaningfully

On this project the trace and map painters run every frame. A stray builder function above them in the tree forces repaints and blows the 4ms budget. This rule is load-bearing.

**Exception:** a callback passed to a builder API (`itemBuilder`, `ValueListenableBuilder`) is not a widget function. That's the framework's own pattern and is fine.

---

## 3. `const` is the default

Every widget constructor that can be `const` must be. Every constructor that can be `const` must declare it. `very_good_analysis` flags this; the flags are not advisory.

Reason: `const` widgets are canonicalised and skipped entirely during rebuild. On an animation-heavy page this is the single cheapest performance win available.

Field declarations that never change use `static const`. Values computed once at first access use `late final`. Never `var` at class scope.

---

## 4. File and folder organisation

- **One public widget per file.** File name is the widget name in `snake_case`: `StationHeader` lives in `station_header.dart`.
- A private sub-widget may share the file **only if** it is under ~40 lines and used exactly once by the public widget. Otherwise it gets its own file.
- Widgets local to a feature live in `features/<name>/presentation/widgets/`. A widget used by two or more features moves to `core/widgets/` — and that move is a decision worth recording in the worklog, because it means the widget is now part of the shared vocabulary.
- No file over 300 lines. Painters may reach 400. Past that, split.
- No `build` method over 50 lines. If it is longer, sub-widgets are missing.
- Barrel files (`widgets.dart` re-exporting the folder) are allowed at folder level only, never at feature or `lib/` level. A single top-level barrel destroys tree-shaking and makes every file depend on every other.

---

## 5. Enums, not strings

Any value drawn from a fixed set is an enum. String and `int` constants standing in for a closed set are banned — the compiler cannot check them, `switch` cannot be exhaustive, and typos become runtime bugs.

Use Dart 3 enhanced enums so the data lives with the enum rather than in a lookup map somewhere else:

```dart
enum ConsentTier {
  none('none', 0),
  aggregate('aggregate', 1),
  session('session', 2);

  const ConsentTier(this.storageKey, this.level);
  final String storageKey;
  final int level;

  bool get allowsSessionEvents => level >= session.level;

  static ConsentTier fromStorage(String? value) =>
      values.firstWhere((t) => t.storageKey == value, orElse: () => none);
}
```

Applies to: consent tier, theme mode, locale, platform class, trace state, route names, work domains, employment type, app platform.

**Never write a `default:` clause in a `switch` over an enum.** Exhaustive switches are a compile-time error when a case is added, and that error is the feature — it tells you every place that needs updating. A `default` silently swallows the new case and produces a bug at runtime instead.

---

## 6. Sealed classes and pattern matching for state

Dart 3 sealed classes with exhaustive switching. Not nullable fields, not boolean flags.

```dart
sealed class ContentState {
  const ContentState();
}

final class ContentLoading extends ContentState {
  const ContentLoading();
}

final class ContentReady extends ContentState {
  const ContentReady(this.profile, this.roles);
  final Profile profile;
  final List<Role> roles;
}

final class ContentFailed extends ContentState {
  const ContentFailed(this.reason);
  final ContentFailure reason;
}
```

Consumed with an exhaustive switch expression:

```dart
Widget build(BuildContext context) => switch (ref.watch(contentProvider)) {
      ContentLoading() => const AcquisitionSequence(),
      ContentReady(:final profile) => StationView(profile: profile),
      ContentFailed(:final reason) => FallbackView(reason: reason),
    };
```

This makes an unhandled state impossible to compile, which is a stronger guarantee than any test.

Use **records** for lightweight multi-value returns — `(double amplitude, double phase) sample(...)`. Do not create a class for a two-field return that is never stored.

---

## 7. Null safety and typing

- `dynamic` is banned outside JSON decoding boundaries, and even there the raw map is converted to a typed model within the same function.
- The `!` bang operator is banned except immediately after an explicit null check in the same scope, with a comment giving the reason. Every other case uses `?.`, `??`, or an early return.
- Every public API has explicit types. Type inference is fine for locals.
- No `late` without `final` unless a genuine two-phase init exists, and then it is commented.

---

## 8. Async and BuildContext

Never use a `BuildContext` across an async gap without guarding:

```dart
Future<void> _download() async {
  final messenger = AppMessenger.of(context);   // capture before awaiting
  await ref.read(cvProvider).download();
  if (!context.mounted) return;                 // guard after
  messenger.show(context, l10n.cvDownloaded);
}
```

This is the most common real crash in Flutter apps and the analyzer only catches some cases.

- No `async` in `build`. Ever.
- No unawaited futures without an explicit `unawaited()` and a comment.
- Every `StreamSubscription`, `AnimationController`, `ScrollController`, `TextEditingController` and `Ticker` is disposed. A missing `dispose` on this project means the trace controller keeps running after navigation and burns frames on a page nobody is looking at.

---

## 9. State

Riverpod only. `setState` is banned in this codebase — one state pattern, not two.

- Providers are generated with `@riverpod`. No manual `StateNotifierProvider`.
- Widgets are `ConsumerWidget` or `ConsumerStatefulWidget`.
- `ref.watch` in `build`. `ref.read` in callbacks. Never the reverse.
- Watch the narrowest thing: `ref.watch(profileProvider.select((p) => p.name))`, not the whole object, so an unrelated field change does not rebuild the subtree.
- No business logic in a widget. A widget reads state and emits events. Anything else lives in a provider or a repository.

---

## 10. Theming

**No raw values in feature code. None.** Not a hex, not a pixel number, not a duration, not a curve, not a radius.

```dart
// Banned
Container(color: const Color(0xFF05070A), padding: const EdgeInsets.all(16))
AnimatedOpacity(duration: const Duration(milliseconds: 300), ...)

// Required
Container(color: context.tokens.void_, padding: EdgeInsets.all(context.tokens.space16))
AnimatedOpacity(duration: Motion.standard, ...)
```

Tokens are reached through a `BuildContext` extension backed by `ThemeExtension`, so both themes resolve without a conditional anywhere in feature code.

If a needed value does not exist in `tokens.dart`, add it there with a name and record it in the worklog. Do not inline it "just this once" — that is how a design system dies.

---

## 11. Platform behaviour

Never branch on `kIsWeb`, `Platform.isIOS`, or `defaultTargetPlatform` in feature code. Ask `PlatformService`:

```dart
// Banned
if (kIsWeb) { showDialog(...); } else { showModalBottomSheet(...); }

// Required
context.platform.presentSecondary(child: const TransmissionPanel());
```

Reason: platform checks scattered through features cannot be tested, cannot be overridden for goldens, and drift apart. One resolution point, tested once. See `01-DESIGN-SYSTEM.md` §7 for the behaviour matrix.

---

## 12. Animation

- One `AnimationController` per animated widget. Composed animations use `Interval` and `CurvedAnimation`, not multiple controllers running in parallel.
- Every controller disposed.
- `AnimatedBuilder` or `ListenableBuilder` scoped to the smallest possible subtree. Never rebuild a whole page from a controller.
- `RepaintBoundary` around anything that repaints per frame — the trace, the map, the grain.
- Every animation reads `MediaQuery.disableAnimationsOf(context)` via `core/motion/reduced_motion.dart` and has a defined settled state. **A widget with an animation and no reduced-motion path is incomplete and will be rejected.**
- Painters implement `shouldRepaint` properly. Returning `true` unconditionally is a bug, not a shortcut.

---

## 13. Localisation

Arabic ships in Milestone 1, so bilingual discipline applies from the first line of UI code.

- **No hardcoded user-facing string anywhere.** All copy comes from ARB via generated `l10n`. This includes semantic labels, tooltips, error text and `/console` labels.
- Use `EdgeInsetsDirectional` and `AlignmentDirectional`. `EdgeInsets.only(left:)` is banned — it does not flip under RTL. `start` and `end`, never `left` and `right`.
- No `Row` with manually reversed children. Let the directionality handle it.
- Icons that imply direction get `Transform.flip` under RTL. Icons that do not imply direction must not flip.
- Numbers and dates go through `intl` with the active locale.
- Every golden test runs in both `TextDirection.ltr` and `rtl`. RTL breakage is invisible until someone looks, and goldens are how we look automatically.

Building bilingual from the start is much cheaper than retrofitting. Retrofitting RTL means auditing every padding, every alignment and every icon in the codebase.

---

## 14. Naming

| Thing | Convention | Example |
|---|---|---|
| File | `snake_case` | `transmission_panel.dart` |
| Class / enum | `PascalCase` | `TransmissionPanel`, `ConsentTier` |
| Member / variable | `camelCase` | `traceAmplitude` |
| Private | leading underscore | `_controller` |
| Constant | `camelCase` | `maxTraceAmplitude` — not `MAX_TRACE_AMPLITUDE` |
| Boolean | `is` / `has` / `can` / `should` | `isLocked`, `hasConsent` |
| Provider | noun + `Provider` | `contentProvider` |
| Test | behaviour sentence | `returns fallback when profile json is malformed` |

Name things after what they are in the product, not what they are in the framework. `TransmissionPanel`, not `NodeDetailContainer`.

---

## 15. Comments

Comment *why*, never *what*. `// increment counter` above `counter++` is noise.

Comment is required for: non-obvious maths (the trace amplitude and projection functions), any workaround with a linked issue, any `!` operator, any deliberate deviation from this document.

Public APIs in `core/` get `///` doc comments. Feature-internal widgets do not need them if the name is honest.

---

## 16. Banned outright

- `print` — use a logger, or nothing
- `TODO` without an issue reference
- Commented-out code — git has it
- `// ignore:` without a comment giving the reason
- `Expanded` inside an unbounded parent
- `MediaQuery.of(context).size` for layout — use `LayoutBuilder`
- `dart:io` — web target, it does not exist here
- `100vh` in any CSS — use `100dvh`, or the address bar collapsing on mobile browsers clips the layout
- `Opacity` where `AnimatedOpacity` or a painter would do — it forces a save layer
- `setState`
- `dynamic` outside a decode boundary
- Business logic in `build`
- Any second state management library
- Any second chroma in the palette

---

## 17. Before reporting finished

```bash
fvm dart format --set-exit-if-changed .
fvm flutter analyze --fatal-infos
fvm flutter test
fvm flutter build web --wasm
```

All four. Every time. See `AGENTS.md` §2.
