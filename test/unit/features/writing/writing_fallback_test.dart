import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';
import 'package:nocturne/features/writing/data/writing_repository.dart';

const cached =
    '<rss><channel><item><title>Published article</title> '
    '<link>https://example.com/published</link></item></channel></rss>';
const live =
    '<rss><channel><item><title>New article</title> '
    '<link>https://example.com/new</link></item></channel></rss>';

void main() {
  test(
    'every bundled article cover is keyed to its article and exists',
    () async {
      final container = ProviderContainer(
        overrides: [
          assetReaderProvider.overrideWithValue(
            (path) => File(path).readAsString(),
          ),
          writingRepositoryProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      final covers = await container.read(bundledWritingCoversProvider.future);
      final articles = await container.read(articlesProvider.future);
      expect(covers, hasLength(articles.length));
      for (final article in articles.reversed) {
        final asset = covers[articleCoverKey(article.url)];
        expect(asset, isNotNull);
        expect(await File(asset!).length(), greaterThan(0));
      }
    },
  );

  test('tracking changes preserve identity without matching another host', () {
    expect(
      articleCoverKey(Uri.parse('https://example.com/one?source=rss#top')),
      'https://example.com/one',
    );
    expect(
      articleCoverKey(Uri.parse('https://different.com/one')),
      isNot('https://example.com/one'),
    );
  });

  test(
    'cover metadata never creates a direct third-party image request',
    () async {
      final container = ProviderContainer(
        overrides: [
          assetReaderProvider.overrideWithValue(
            (_) async => jsonEncode({
              'https://example.com/one': {
                'asset': 'https://third-party.test/pixel',
              },
            }),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        await container.read(bundledWritingCoversProvider.future),
        isEmpty,
      );
    },
  );

  for (final status in [403, 502]) {
    test(
      'a $status relay response preserves the bundled published index',
      () async {
        final client = MockClient((_) async => http.Response('{}', status));
        final container = ProviderContainer(
          overrides: [
            writingRepositoryProvider.overrideWithValue(
              WritingRepository(
                client: client,
                endpoint: Uri.parse('https://example.com/feed'),
              ),
            ),
            assetReaderProvider.overrideWithValue((_) async => cached),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(client.close);
        final articles = await container.read(articlesProvider.future);
        expect(articles.single.title, 'Published article');
        expect(articles.single.cover, isNull);
      },
    );
  }
  test('fresh live articles replace the bundled index', () async {
    final client = MockClient((_) async => http.Response(live, 200));
    final container = ProviderContainer(
      overrides: [
        writingRepositoryProvider.overrideWithValue(
          WritingRepository(
            client: client,
            endpoint: Uri.parse('https://example.com/feed'),
          ),
        ),
        assetReaderProvider.overrideWithValue(
          (_) => throw StateError('Should not read fallback'),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.close);
    expect(
      (await container.read(articlesProvider.future)).single.title,
      'New article',
    );
  });
  test('a disabled relay still has a useful offline article index', () async {
    final container = ProviderContainer(
      overrides: [
        writingRepositoryProvider.overrideWithValue(null),
        assetReaderProvider.overrideWithValue((_) async => cached),
      ],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(articlesProvider.future)).single.title,
      'Published article',
    );
  });
  test(
    'unavailable live and bundled content does not fabricate articles',
    () async {
      final container = ProviderContainer(
        overrides: [
          writingRepositoryProvider.overrideWithValue(null),
          assetReaderProvider.overrideWithValue(
            (_) => throw StateError('Missing'),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(await container.read(articlesProvider.future), isEmpty);
    },
  );
}
