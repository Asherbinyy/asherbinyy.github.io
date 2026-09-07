import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/writing/data/feed_parser.dart';

const String _contentNs = 'http://purl.org/rss/1.0/modules/content/';

String feed(String items) =>
    '<?xml version="1.0" encoding="UTF-8"?> '
    '<rss version="2.0" xmlns:content="$_contentNs" '
    'xmlns:media="http://search.yahoo.com/mrss/"> '
    '<channel><title>Ahmed Elsherbini</title>$items</channel> '
    '</rss>';

String item({
  String title = 'A post',
  String link = 'https://sherbini.medium.com/a-post-1234',
  String? pubDate = 'Sat, 05 Sep 2026 08:30:00 GMT',
  List<String> categories = const [],
  String? encoded,
  String? mediaUrl,
}) {
  final date = pubDate == null ? '' : '<pubDate>$pubDate</pubDate>';
  final tags = categories.map((c) => '<category>$c</category>').join();
  // Whitespace between elements is insignificant in XML, which is what lets
  // these read as separate lines without the parser seeing a difference.
  final body = encoded == null
      ? ''
      : '<content:encoded><![CDATA[$encoded]]></content:encoded>';
  final media = mediaUrl == null ? '' : '<media:content url="$mediaUrl"/>';
  return '<item> '
      '<title>$title</title> '
      '<link>$link</link> '
      '$date $tags $body $media '
      '</item>';
}

void main() {
  group('parsing a Medium feed', () {
    const cdn = 'https://miro.medium.com/v2/resize:fit:1400/abc.jpeg';

    test('takes the cover from the media element when present', () {
      final articles = parseFeed(feed(item(mediaUrl: cdn)));
      expect(articles.single.cover, Uri.parse(cdn));
    });

    test('falls back to the first image in the encoded body', () {
      const second = 'https://miro.medium.com/second.png';
      const figure = '<figure><img alt="cover" src="$cdn" /></figure>';
      const rest = '<p>Body text</p><img src="$second">';
      final articles = parseFeed(feed(item(encoded: '$figure$rest')));
      expect(articles.single.cover, Uri.parse(cdn));
    });

    test('an item with no image has no cover', () {
      final articles = parseFeed(feed(item(encoded: '<p>Just words.</p>')));
      expect(articles.single.cover, isNull);
    });

    test('a non-https or relative image source is refused', () {
      // The relay allowlists the host, but the parser must not hand it a
      // javascript: or data: URL to begin with -- defence at both ends,
      // because the feed is third-party input.
      for (final src in [
        'javascript:alert(1)',
        '/relative/cover.png',
        'http://miro.medium.com/insecure.png',
        'data:image/png;base64,AAAA',
      ]) {
        final articles = parseFeed(feed(item(encoded: '<img src="$src">')));
        expect(articles.single.cover, isNull, reason: src);
      }
    });

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

    test('takes nothing but an image source from the encoded body', () {
      const script = '<script>bad()</script>';
      const prose = '<p>Prose that must not appear.</p>';
      const hostile = '<![CDATA[$script$prose]]>';
      final articles = parseFeed(
        feed(
          '<item><title>A post</title> '
          '<link>https://sherbini.medium.com/a</link> '
          '<content:encoded>$hostile</content:encoded> '
          '</item>',
        ),
      );

      // This asserted the body was ignored entirely, which stopped being true
      // in milestone 4: the cover is found by scanning it. The guarantee that
      // matters is unchanged and is what is asserted now -- the body is never
      // parsed as markup or rendered, and no field on the record can carry it.
      // Only an `img src` is lifted out, and only after passing _url.
      expect(articles.single.title, 'A post');
      expect(articles.single.cover, isNull);
      expect(articles.single.tags, isEmpty);
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
