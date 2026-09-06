import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nocturne/content/content_repository.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/study.dart';
import 'package:nocturne/content/providers.dart';

class _AssetBundle extends Mock implements AssetBundle {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AssetBundle assets;
  late ContentRepository repository;

  setUp(() {
    assets = _AssetBundle();
    repository = ContentRepository(assets.loadString);
    when(() => assets.loadString(any())).thenAnswer(
      (invocation) =>
          rootBundle.loadString(invocation.positionalArguments.first as String),
    );
  });

  test('all bundled sections are ready through the repository', () async {
    expect(await repository.profile(), isA<ContentReady<Profile>>());
    expect(await repository.career(), isA<ContentReady<Career>>());
    expect(await repository.apps(), isA<ContentReady<Apps>>());
    expect(await repository.education(), isA<ContentReady<Education>>());
  });
  test('concurrent and repeated loads read each asset only once', () async {
    await Future.wait([repository.profile(), repository.profile()]);
    await repository.profile();

    verify(() => assets.loadString('assets/content/profile.json')).called(1);
  });
  for (final broken in ['{', '[]', '{}', '{"name": 7}']) {
    test('malformed primary data uses the bundled fallback: $broken', () async {
      when(() => assets.loadString('assets/content/profile.json'))
          .thenAnswer((_) async => broken);

      final result = await repository.profile();

      expect(result, isA<ContentFallback<Profile>>());
      expect(
        (result as ContentFallback<Profile>).profile.contact.email,
        isNotEmpty,
      );
    });
  }
  test(
    'missing sections return identity fallback rather than an exception',
    () async {
      when(() => assets.loadString('assets/content/career.json'))
          .thenThrow(StateError('fixture missing'));

      expect(await repository.career(), isA<ContentFallback<Career>>());
    },
  );
  test(
    'missing primary and corrupt fallback return an explicit unavailable state',
    () async {
      when(() => assets.loadString(any())).thenAnswer((_) async => '{}');

      expect(await repository.profile(), isA<ContentUnavailable<Profile>>());
    },
  );
  test('missing study uses identity fallback', () async {
    expect(await repository.study('fixture'), isA<ContentFallback<Study>>());
  });
  test('study slugs cannot escape the bundled content directory', () {
    expect(() => repository.study('../profile'), throwsArgumentError);
    verifyNever(() => assets.loadString(any()));
  });
  test('the generated provider retains its cache for the app scope', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = contentProvider(assets.loadString);

    expect(container.read(provider), same(container.read(provider)));
  });
}
