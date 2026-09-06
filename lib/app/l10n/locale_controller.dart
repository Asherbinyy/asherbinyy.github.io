import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/platform/preference_store.dart';

part 'locale_controller.g.dart';

/// Holds the visitor's language choice and persists it.
///
/// A language the viewer selected is a preference they asked for, so it is
/// written without a consent gate. See [PreferenceKey] for the reasoning.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  AppLocale build() => _fromStorage(
    ref.watch(preferenceStoreProvider).read(PreferenceKey.language.storageKey),
  );

  /// Current language for imperative callers; widgets watch the provider.
  AppLocale get locale => state;

  /// Updates content language and direction without resetting navigation.
  set locale(AppLocale value) {
    state = value;
    // Fire and forget: the frame must not wait on storage.
    unawaited(
      ref
          .read(preferenceStoreProvider)
          .write(PreferenceKey.language.storageKey, value.languageCode),
    );
  }

  /// Switches to the other channel.
  void toggle() => locale = state == AppLocale.english
      ? AppLocale.arabic
      : AppLocale.english;

  static AppLocale _fromStorage(String? value) => AppLocale.values.firstWhere(
    (locale) => locale.languageCode == value,
    orElse: () => AppLocale.english,
  );
}
