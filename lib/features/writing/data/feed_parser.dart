import 'package:xml/xml.dart';

import 'package:nocturne/features/writing/domain/article.dart';

/// Turns an RSS 2.0 body into articles, skipping items it cannot trust.
///
/// Medium's feed is RSS 2.0 with a `content:encoded` body and `category`
/// elements for tags. Only the fields this site displays are read; the encoded
/// body is ignored entirely rather than parsed and discarded, because the one
/// thing a feed reader must never do with third-party HTML is render it.
///
/// An item without a title or a usable absolute link is dropped rather than
/// shown with a placeholder: a writing list that links nowhere is worse than a
/// shorter list. A body that is not XML at all throws, so the caller can tell
/// "the feed is broken" from "the feed is empty".
List<Article> parseFeed(String body) {
  final document = XmlDocument.parse(body);
  final items = document.findAllElements('item');

  final articles = <Article>[];
  for (final item in items) {
    final title = _text(item, 'title');
    final url = _url(_text(item, 'link'));
    if (title == null || url == null) continue;

    articles.add((
      title: title,
      url: url,
      published: _date(_text(item, 'pubDate')),
      tags: item
          .findElements('category')
          .map((element) => element.innerText.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    ));
  }
  return articles;
}

String? _text(XmlElement item, String name) {
  final value = item.findElements(name).firstOrNull?.innerText.trim();
  return value == null || value.isEmpty ? null : value;
}

/// Accepts only an absolute HTTPS link, so a relative or `javascript:` href in
/// a third-party feed can never become something the viewer can click.
Uri? _url(String? value) {
  if (value == null) return null;
  final url = Uri.tryParse(value);
  if (url == null || url.scheme != 'https' || !url.hasAuthority) return null;
  return url;
}

/// RFC 822, which is what RSS specifies and Medium emits.
///
/// Returns null rather than throwing on an unreadable date: a dateless article
/// is still worth listing, so the date is the only field allowed to be absent.
DateTime? _date(String? value) {
  if (value == null) return null;

  final match = _rfc822.firstMatch(value);
  if (match == null) return DateTime.tryParse(value)?.toUtc();

  final month = _months[match.group(2)!.toLowerCase()];
  if (month == null) return null;

  final offset = match.group(7);
  final parsed = DateTime.utc(
    int.parse(match.group(3)!),
    month,
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6) ?? '0'),
  );
  return offset == null ? parsed : parsed.subtract(_offset(offset));
}

Duration _offset(String value) {
  if (value == 'GMT' || value == 'UT' || value == 'Z') return Duration.zero;
  final sign = value.startsWith('-') ? -1 : 1;
  final digits = value.substring(1);
  return Duration(
    hours: sign * int.parse(digits.substring(0, 2)),
    minutes: sign * int.parse(digits.substring(2, 4)),
  );
}

final RegExp _rfc822 = RegExp(
  r'^(?:\w{3},\s*)?(\d{1,2})\s+(\w{3})\s+(\d{4})\s+'
  r'(\d{2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|GMT|UT|Z)?$',
);

const Map<String, int> _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};
