import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nocturne/features/writing/data/writing_repository.dart';

final Uri endpoint = Uri.parse('https://worker.example/v1/writing');

String feed(String items) =>
    '<?xml version="1.0"?><rss version="2.0"><channel>$items</channel></rss>';

String item(String title, String? date) =>
    '<item><title>$title</title>'
    '<link>https://sherbini.medium.com/${title.toLowerCase()}</link>'
    '${date == null ? '' : '<pubDate>$date</pubDate>'}</item>';

WritingRepository repositoryReturning(
  http.Response Function(http.Request request) handler,
) => WritingRepository(
  client: MockClient((r) async => handler(r)),
  endpoint: endpoint,
);

void main() {
  group('reading the feed', () {
    test('returns articles newest first', () async {
      final repository = repositoryReturning(
        (_) => http.Response(
          feed(
            item('Older', 'Sat, 01 Aug 2026 08:00:00 GMT') +
                item('Newer', 'Sat, 05 Sep 2026 08:00:00 GMT'),
          ),
          200,
        ),
      );

      final articles = await repository.articles();

      expect(articles.map((a) => a.title), ['Newer', 'Older']);
    });

    test('sorts undated articles last', () async {
      final repository = repositoryReturning(
        (_) => http.Response(
          feed(
            item('Undated', null) +
                item('Dated', 'Sat, 01 Aug 2026 08:00:00 GMT'),
          ),
          200,
        ),
      );

      final articles = await repository.articles();

      expect(articles.map((a) => a.title), ['Dated', 'Undated']);
    });

    test('requests the relay rather than Medium directly', () async {
      late Uri requested;
      final repository = repositoryReturning((request) {
        requested = request.url;
        return http.Response(feed(''), 200);
      });

      await repository.articles();

      expect(requested, endpoint);
    });
  });

  group('failing silently', () {
    // 03-ARCHITECTURE.md section 5: a feed failure hides the writing section
    // rather than showing an error. Every failure mode resolves to the same
    // empty list so the screen has one case to render.
    test('returns nothing when the relay reports an error', () async {
      final repository = repositoryReturning((_) => http.Response('{}', 502));

      expect(await repository.articles(), isEmpty);
    });

    test('returns nothing when the body is not a feed', () async {
      final repository = repositoryReturning(
        (_) => http.Response('<html>nope</html>', 200),
      );

      expect(await repository.articles(), isEmpty);
    });

    test('returns nothing when the request throws', () async {
      final repository = WritingRepository(
        client: MockClient((_) async => throw const SocketExceptionStub()),
        endpoint: endpoint,
      );

      expect(await repository.articles(), isEmpty);
    });
  });
}

/// Stands in for a transport failure without importing `dart:io`, which this
/// web-only project bans.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
