import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/core/platform/preference_store.dart';

part 'theme_controller.g.dart';

/// The store every preference controller writes through.
///
/// Defaults to in-memory so a test, a golden or a forgotten bootstrap degrades
/// to no persistence rather than to a crash. `main.dart` overrides it with the
/// browser-backed store.
@Riverpod(keepAlive: true)
PreferenceStore preferenceStore(PreferenceStoreRef ref) =>
    InMemoryPreferenceStore();

/// Holds the visitor's chosen artifact and persists it.
@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  @override
  AppTheme build() => AppTheme.fromStorage(
    ref.watch(preferenceStoreProvider).read(PreferenceKey.theme.storageKey),
  );

  /// Switches to the other artifact.
  void toggle() => select(state.opposite);

  /// Sets the artifact and writes it through.
  void select(AppTheme theme) {
    state = theme;
    // Fire and forget: the frame must not wait on storage, and a failed write
    // costs the viewer a preference on reload, not a broken page.
    unawaited(
      ref
          .read(preferenceStoreProvider)
          .write(PreferenceKey.theme.storageKey, theme.storageKey),
    );
  }
}

/// Whether the viewer has collapsed the site into Recruiter Mode.
///
/// The mode's content belongs to task 1.11; this owns only the state, so the
/// chrome that responds to it can be built and tested first.
@Riverpod(keepAlive: true)
class RecruiterMode extends _$RecruiterMode {
  @override
  bool build() =>
      ref
          .watch(preferenceStoreProvider)
          .read(PreferenceKey.recruiterMode.storageKey) ==
      _on;

  static const String _on = 'on';
  static const String _off = 'off';

  /// Flips the mode.
  void toggle() => setEnabled(enabled: !state);

  /// Sets the mode and writes it through.
  void setEnabled({required bool enabled}) {
    state = enabled;
    unawaited(
      ref
          .read(preferenceStoreProvider)
          .write(PreferenceKey.recruiterMode.storageKey, enabled ? _on : _off),
    );
  }
}
