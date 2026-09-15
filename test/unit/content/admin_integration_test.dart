import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/app/bootstrap.dart';
import 'package:nocturne/app/theme/app_theme.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_parser.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/content/providers.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/core/preview/preview_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> profile;
  setUp(() async {
    profile = jsonDecode(
      await rootBundle.loadString('assets/content/profile.json'),
    ) as Map<String, dynamic>;
  });

  test('uploaded media, flexible links and appearance survive parsing', () {
    const media = '/v1/media/0123456789abcdef0123456789abcdef';
    profile['portrait'] = {'src': media, 'isPlaceholder': false};
    profile['nameAudio'] = {'src': media, 'seconds': 2.5};
    profile['links'] = [
      {
        'id': 'website',
        'label': {'en': 'Example'},
        'url': 'https://example.com',
        'icon': media,
      },
    ];
    profile['appearance'] = {
      'theme': 'deshret',
      'headingFont': 'ibmPlexSans',
      'bodyFont': 'spaceGrotesk',
    };
    final parsed = ContentParser.profile(profile);
    expect(parsed.portrait!.src, media);
    expect(parsed.nameAudio!.seconds, 2.5);
    expect(parsed.links.single.icon, media);
    expect(Profile.fromJson(parsed.toJson()), parsed);
  });

  test(
    'unsafe uploaded references and unsupported appearances are rejected',
    () {
      for (final source in [
        'https://example.com/track.png',
        '/v1/media/../../secret',
      ]) {
        profile['portrait'] = {'src': source, 'isPlaceholder': false};
        expect(() => ContentParser.profile(profile), throwsFormatException);
      }
      profile.remove('portrait');
      profile['appearance'] = {'theme': 'invented'};
      expect(() => ContentParser.profile(profile), throwsFormatException);
    },
  );

  test(
    'preview drafts change the real repository without publishing or analytics',
    () async {
      final container = ProviderContainer(overrides: previewOverrides());
      addTearDown(container.dispose);
      final before =
          await container.read(profileProvider.future) as ContentReady<Profile>;
      profile['greeting'] = {'en': 'Private draft only'};
      container
          .read(previewDocumentsProvider.notifier)
          .state = checkedPreviewDocuments({
        'schemaVersion': 1,
        'requestId': 1,
        'locale': 'en',
        'file': 'profile.json',
        'document': profile,
      });
      final after =
          await container.read(profileProvider.future) as ContentReady<Profile>;
      expect(after.data.greeting!.en, 'Private draft only');
      expect(before.data.greeting!.en, isNot('Private draft only'));
      expect(container.read(publishedContentProvider), isNull);
      expect(container.read(analyticsClientProvider), isNull);
      expect(
        container.read(preferenceStoreProvider),
        isA<InMemoryPreferenceStore>(),
      );
    },
  );

  test(
    'a preview batch rejects an invalid dependency before applying any draft',
    () {
      expect(
        () => checkedPreviewDocuments({
          'schemaVersion': 1,
          'requestId': 1,
          'locale': 'en',
          'file': 'profile.json',
          'document': profile,
          'documents': {
            'career.json': {'roles': 'broken'},
          },
        }),
        throwsA(isA<Object>()),
      );
      expect(
        () => checkedPreviewDocuments({
          'schemaVersion': 1,
          'requestId': 1,
          'locale': 'en',
          'file': '../secret.json',
          'document': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'owner default theme applies and visitor can toggle it on first press',
    () async {
      profile['appearance'] = {'theme': 'deshret'};
      final store = InMemoryPreferenceStore();
      final container = ProviderContainer(
        overrides: [
          preferenceStoreProvider.overrideWithValue(store),
          defaultThemeProvider.overrideWith(publishedDefaultTheme),
          assetReaderProvider.overrideWithValue(
            (path) async => jsonEncode(profile),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(profileProvider.future);
      expect(container.read(themeControllerProvider), AppTheme.daybreak);
      container.read(themeControllerProvider.notifier).toggle();
      expect(container.read(themeControllerProvider), AppTheme.nocturne);
      expect(
        store.read(PreferenceKey.theme.storageKey),
        AppTheme.nocturne.storageKey,
      );
    },
  );
}
