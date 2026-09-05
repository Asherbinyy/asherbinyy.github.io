import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';

void main() {
  test('language selection remains in memory until its app scope ends', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), AppLocale.english);
    container.read(localeControllerProvider.notifier).locale = AppLocale.arabic;

    expect(container.read(localeControllerProvider).languageCode, 'ar');
    expect(
      container.read(localeControllerProvider.notifier).locale,
      AppLocale.arabic,
    );
    container.read(localeControllerProvider.notifier).locale =
        AppLocale.english;
    expect(container.read(localeControllerProvider).languageCode, 'en');
  });

  test('language selections do not leak between app scopes', () {
    final first = ProviderContainer();
    final second = ProviderContainer();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    first.read(localeControllerProvider.notifier).locale = AppLocale.arabic;

    expect(second.read(localeControllerProvider), AppLocale.english);
  });
}
