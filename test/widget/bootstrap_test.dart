import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/bootstrap.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/education.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/providers.dart';
import 'package:nocturne/core/platform/preference_store.dart';

/// The gap every other test had, and the reason the live site was empty.
///
/// Every widget test injects its own asset reader, so the production path —
/// the reader `main.dart` is supposed to install — was never once executed.
/// `assetReaderProvider` defaults to a reader that fails every read, that
/// default shipped, and the deployed site rendered "Profile content did not
/// load" on every page from Milestone 1 until this was found.
///
/// These tests use `productionOverrides` and nothing else, so the bootstrap is
/// exercised exactly as the real application runs it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer production() {
    final container = ProviderContainer(
      overrides: productionOverrides(
        preferences: InMemoryPreferenceStore(const {}),
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the production bootstrap', () {
    test('installs an asset reader that is not the failing default', () async {
      final reader = production().read(assetReaderProvider);

      // The default throws StateError('No asset reader is installed.') for any
      // path. Reading a real bundled asset proves a real reader is in place.
      await expectLater(
        reader('assets/content/profile.json'),
        completes,
        reason: 'main.dart shipped without installing a bundle reader',
      );
    });

    test('resolves real profile content, not the fallback', () async {
      final result = await production().read(profileProvider.future);

      // ContentFallback or ContentUnavailable both mean the read failed. Only
      // ContentReady means the site will actually show anything.
      expect(result, isA<ContentReady<Profile>>());
    });

    test('resolves every content file the site renders', () async {
      final container = production();

      expect(
        await container.read(careerProvider.future),
        isA<ContentReady<Career>>(),
      );
      expect(
        await container.read(appsProvider.future),
        isA<ContentReady<Apps>>(),
      );
      expect(
        await container.read(educationProvider.future),
        isA<ContentReady<Education>>(),
      );
    });

    test('installs a reader for content published from the panel', () {
      // The same gap this file exists for, one milestone later: the content
      // layer declares `publishedContentProvider` and defaults it to null, so
      // forgetting the override here would silently ship a site that ignores
      // everything the owner publishes, with every test still green.
      expect(
        production().read(publishedContentProvider),
        isNotNull,
        reason: 'bootstrap did not install the published-content reader',
      );
    });

    test('every page still resolves with the relay unreachable', () async {
      // This is the milestone's first non-negotiable, exercised against the
      // real bootstrap rather than a hand-built repository. The test
      // environment refuses outbound HTTP, so the remote read fails exactly as
      // it would with the Worker down, and every document must still come back
      // ready from the bundle.
      final container = production();

      expect(
        await container.read(profileProvider.future),
        isA<ContentReady<Profile>>(),
      );
      expect(
        await container.read(careerProvider.future),
        isA<ContentReady<Career>>(),
      );
      expect(
        await container.read(appsProvider.future),
        isA<ContentReady<Apps>>(),
      );
    });
  });
}
