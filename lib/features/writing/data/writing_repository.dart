import 'package:http/http.dart' as http;

import 'package:nocturne/features/writing/data/feed_parser.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// Reads the owner's Medium feed through the first-party relay.
///
/// The relay exists because Medium sends no `access-control-allow-origin`, so
/// a browser on this origin cannot fetch the feed itself. It also means the
/// request carries the Worker's identity rather than the viewer's, so nothing
/// about the viewer reaches Medium and this needs no consent — it is content,
/// not analytics.
class WritingRepository {
  /// The caller owns [client] and closes it with the provider that made it.
  const WritingRepository({required this.client, required this.endpoint});

  /// HTTP client, injected so no test reaches the network.
  final http.Client client;

  /// The relay's `/v1/writing` URL.
  final Uri endpoint;

  /// The articles, newest first, or an empty list if anything went wrong.
  ///
  /// `03-ARCHITECTURE.md` §5: "Medium RSS failure hides the writing section
  /// silently rather than showing an error. It is not core content." So every
  /// failure — offline, relay down, feed malformed — resolves to the same
  /// empty list, and the screen renders nothing rather than an apology. This
  /// swallows deliberately; it is the one place in the codebase that should.
  Future<List<Article>> articles() async {
    try {
      final result = await client.get(endpoint);
      if (result.statusCode != 200) return const [];

      final articles = parseFeed(result.body)
        ..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
      return List.unmodifiable(articles);
    } on Object {
      return const [];
    }
  }

  /// Undated articles sort last rather than first, which `DateTime(0)` would
  /// not achieve if the feed ever carried a pre-epoch date.
  DateTime _sortKey(Article article) =>
      article.published ?? DateTime.utc(-271821, 4, 20);
}
