import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/app/theme/appearance_contract.dart';

/// Holds the app's allowlist to the same fixture the Worker is held to.
///
/// The admin panel stores an appearance and the app reads it back, and the two
/// ship separately. A list that agrees only with itself proves nothing about
/// the program on the other side of the wire.
void main() {
  final fixture = jsonDecode(
    File('worker/contracts/fixtures/appearance-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the allowlist is the one the fixture records', () {
    expect(AppearanceContract.version, fixture['version']);
    expect(
      AppearanceContract.supported.keys.toList(),
      fixture['supported'],
      reason: 'the app and the Worker disagree about what can be drawn',
    );
  });

  test('every id resolves the way the fixture says', () {
    for (final row in fixture['resolutions'] as List<dynamic>) {
      final entry = row as Map<String, dynamic>;
      final id = entry['id'] as String?;
      final resolution = AppearanceContract.resolve(id);
      final state = switch (resolution) {
        AppearanceUnset() => 'unset',
        AppearanceSupported() => 'supported',
        AppearanceUnsupported() => 'unsupported',
      };
      expect(state, entry['state'], reason: 'id ${jsonEncode(id)}');
    }
  });

  test('an unknown id is reported, never quietly defaulted', () {
    // The whole point of the contract. Falling back to the default makes an
    // unsupported appearance indistinguishable from the supported one: the
    // owner picks something, sees the site unchanged, and cannot tell whether
    // it failed or whether that is how it looks.
    final resolution = AppearanceContract.resolve('papyrus-v2');
    expect(resolution, isA<AppearanceUnsupported>());
    expect((resolution as AppearanceUnsupported).id, 'papyrus-v2');
  });

  test('a supported id carries the renderer to draw with', () {
    final resolution = AppearanceContract.resolve('daybreak');
    expect(resolution, isA<AppearanceSupported>());
    expect((resolution as AppearanceSupported).theme, AppTheme.daybreak);
  });

  test('an id is matched exactly, not loosely', () {
    // A stored id is a key, and a key that matches approximately is a key that
    // will one day match the wrong thing.
    expect(AppearanceContract.supports('nocturne'), isTrue);
    expect(AppearanceContract.supports('Nocturne'), isFalse);
    expect(AppearanceContract.supports(' nocturne'), isFalse);
    expect(AppearanceContract.supports(null), isFalse);
  });

  test('every stored theme id is on the list', () {
    // The two enums must not drift apart: a theme the app can draw but the
    // contract does not list is one the panel can never select.
    for (final theme in AppTheme.values) {
      expect(
        AppearanceContract.supports(theme.storageKey),
        isTrue,
        reason: '${theme.storageKey} is drawable but not on the allowlist',
      );
    }
  });
}
