import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/platform/preference_store.dart';

ProviderContainer _container(PreferenceStore store) {
  final container = ProviderContainer(
    overrides: [preferenceStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('theme', () {
    test('starts on the identity theme when nothing is stored', () {
      final container = _container(InMemoryPreferenceStore());

      expect(container.read(themeControllerProvider), AppTheme.nocturne);
    });

    test('restores the stored theme', () {
      final container = _container(
        InMemoryPreferenceStore({
          PreferenceKey.theme.storageKey: AppTheme.daybreak.storageKey,
        }),
      );

      expect(container.read(themeControllerProvider), AppTheme.daybreak);
    });

    test('falls back to the identity theme on an unrecognised value', () {
      final container = _container(
        InMemoryPreferenceStore({PreferenceKey.theme.storageKey: 'sepia'}),
      );

      expect(container.read(themeControllerProvider), AppTheme.nocturne);
    });

    test('toggling writes the choice through', () async {
      final store = InMemoryPreferenceStore();
      final container = _container(store);

      container.read(themeControllerProvider.notifier).toggle();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeControllerProvider), AppTheme.daybreak);
      expect(
        store.read(PreferenceKey.theme.storageKey),
        AppTheme.daybreak.storageKey,
      );
    });

    test('toggling twice returns to the identity theme', () {
      final container = _container(InMemoryPreferenceStore());
      final controller = container.read(themeControllerProvider.notifier)
        ..toggle()
        ..toggle();

      expect(controller.state, AppTheme.nocturne);
    });
  });

  group('recruiter mode', () {
    test('is off until the viewer turns it on', () {
      final container = _container(InMemoryPreferenceStore());

      expect(container.read(recruiterModeProvider), isFalse);
    });

    test('restores an enabled mode', () {
      final container = _container(
        InMemoryPreferenceStore({PreferenceKey.recruiterMode.storageKey: 'on'}),
      );

      expect(container.read(recruiterModeProvider), isTrue);
    });

    test('toggling writes the choice through', () async {
      final store = InMemoryPreferenceStore();
      final container = _container(store);

      container.read(recruiterModeProvider.notifier).toggle();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(recruiterModeProvider), isTrue);
      expect(store.read(PreferenceKey.recruiterMode.storageKey), 'on');
    });
  });

  group('language', () {
    test('starts on English when nothing is stored', () {
      final container = _container(InMemoryPreferenceStore());

      expect(container.read(localeControllerProvider), AppLocale.english);
    });

    test('restores the stored channel', () {
      final container = _container(
        InMemoryPreferenceStore({PreferenceKey.language.storageKey: 'ar'}),
      );

      expect(container.read(localeControllerProvider), AppLocale.arabic);
    });

    test('toggling writes the choice through', () async {
      final store = InMemoryPreferenceStore();
      final container = _container(store);

      container.read(localeControllerProvider.notifier).toggle();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeControllerProvider), AppLocale.arabic);
      expect(store.read(PreferenceKey.language.storageKey), 'ar');
    });
  });

  group('preference storage', () {
    test('writes nothing until the viewer changes something', () {
      final store = InMemoryPreferenceStore();
      _container(store)
        ..read(themeControllerProvider)
        ..read(localeControllerProvider)
        ..read(recruiterModeProvider);

      // Reading a preference must not create one: a visitor who never touches
      // a control leaves nothing behind on their device.
      for (final key in PreferenceKey.values) {
        expect(store.read(key.storageKey), isNull, reason: key.name);
      }
    });

    test('the interface toggles write only their own keys', () async {
      final store = InMemoryPreferenceStore();
      _container(store)
        ..read(themeControllerProvider.notifier).toggle()
        ..read(localeControllerProvider.notifier).toggle()
        ..read(recruiterModeProvider.notifier).toggle();
      await Future<void>.delayed(Duration.zero);

      // No identifier, no session key, nothing analytics-shaped. The consent
      // key exists but only the consent controller may write it, so toggling
      // the interface preferences must leave it untouched.
      final written = {
        for (final key in PreferenceKey.values)
          if (store.read(key.storageKey) != null) key,
      };
      expect(written, {
        PreferenceKey.theme,
        PreferenceKey.language,
        PreferenceKey.recruiterMode,
      });
      expect(store.read(PreferenceKey.consent.storageKey), isNull);
    });
  });
}
