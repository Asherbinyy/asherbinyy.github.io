import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/writing/data/feed_parser.dart';

const String _contentNs = 'http://purl.org/rss/1.0/modules/content/';

String feed(String items) =>
    '<?xml version="1.0" encoding="UTF-8"?> '
    '<rss version="2.0" xmlns:content="$_contentNs"> '
    '<channel><title>Ahmed Elsherbini</title>$items</channel> '
    '</rss>';

String item({
  String title = 'A post',
  String link = 'https://sherbini.medium.com/a-post-1234',
  String? pubDate = 'Sat, 05 Sep 2026 08:30:00 GMT',
  List<String> categories = const [],
}) {
  final date = pubDate == null ? '' : '<pubDate>$pubDate</pubDate>';
  final tags = categories.map((c) => '<category>$c</category>').join();
  // Whitespace between elements is insignificant in XML, which is what lets
  // these read as separate lines without the parser seeing a difference.
  return '<item> '
      '<title>$title</title> '
      '<link>$link</link> '
      '$date $tags '
      '</item>';
}

void main() {
  group('parsing a Medium feed', () {
    test('reads title, link, date and tags from an item', () {
      final articles = parseFeed(
        feed(item(categories: const ['flutter', 'testing'])),
      );

      expect(articles, hasLength(1));
      expect(articles.single.title, 'A post');
      expect(
        articles.single.url,
        Uri.parse('https://sherbini.medium.com/a-post-1234'),
      );
      expect(articles.single.published, DateTime.utc(2026, 9, 5, 8, 30));
      expect(articles.single.tags, ['flutter', 'testing']);
    });

    test('applies a numeric timezone offset', () {
      final articles = parseFeed(
        feed(item(pubDate: 'Sat, 05 Sep 2026 08:30:00 +0200')),
      );

      // 08:30 at +0200 is 06:30 UTC.
      expect(articles.single.published, DateTime.utc(2026, 9, 5, 6, 30));
    });

    test('keeps an article whose date cannot be read', () {
      final articles = parseFeed(feed(item(pubDate: 'sometime last autumn')));

      expect(articles, hasLength(1));
      expect(articles.single.published, isNull);
    });

    test('drops an item with no title', () {
      final articles = parseFeed(
        feed('<item><link>https://a.example/b</link></item>'),
      );

      expect(articles, isEmpty);
    });

    test('drops an item whose link is not absolute HTTPS', () {
      // A relative or javascript: href in a third-party feed must never become
      // something the viewer can click.
      final articles = parseFeed(
        feed(item(link: 'javascript:alert(1)') + item(link: '/relative/path')),
      );

      expect(articles, isEmpty);
    });

    test('ignores the encoded body entirely', () {
      final articles = parseFeed(
        feed(
          '<item><title>A post</title> '
          '<link>https://sherbini.medium.com/a</link> '
          '<content:encoded>'
          '<![CDATA[<script>bad()</script>]]>'
          '</content:encoded> '
          '</item>',
        ),
      );

      // The record has no field that could carry it, which is the point.
      expect(articles.single.title, 'A post');
    });

    test('returns nothing for a feed with no items', () {
      expect(parseFeed(feed('')), isEmpty);
    });

    test('yields nothing for well-formed XML that is not a feed', () {
      // An HTML error page that happens to parse is not a feed. It resolves to
      // empty rather than throwing, and the repository hides the section
      // either way.
      expect(parseFeed('<html><body>404</body></html>'), isEmpty);
    });

    test('throws on a body that is not well-formed XML', () {
      // The caller needs to tell "the feed is broken" from "the feed is empty".
      expect(() => parseFeed('not xml <<< at all'), throwsA(isA<Exception>()));
    });
  });
}
