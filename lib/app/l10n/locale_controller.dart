import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/app/l10n/app_locale.dart';

part 'locale_controller.g.dart';

/// Holds the visitor's language choice in memory without browser storage.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  AppLocale build() => AppLocale.english;

  /// Current language for imperative callers; widgets watch the provider.
  AppLocale get locale => state;

  /// Updates content language and direction without resetting navigation.
  set locale(AppLocale value) => state = value;
}
