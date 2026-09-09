import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/content/content_repository.dart';
import 'package:nocturne/core/net/relay.dart';

/// Reads content the owner has published, from the relay this site already
/// talks to.
///
/// `15-ADMIN-AND-MEDIA.md` §7.1. The panel writes documents into KV and this is
/// the path the site reads them back on, so the owner can correct a date or add
/// a project without a deploy.
///
/// **A 404 is the normal answer.** Only documents he has actually edited exist
/// remotely; everything else is the bundle, and asking for it must be cheap and
/// silent rather than an error anyone handles.
///
/// Nothing identifying is sent. This is a plain GET to the one origin the app
/// already uses for the writing feed, with no cookie, no header carrying viewer
/// state, and no body. `06-ANALYTICS-AND-PRIVACY.md` outranks this milestone
/// and the admin path is not allowed to become the way round it.
class PublishedContent {
  /// Reads from [endpoint], which is the relay's content path.
  const PublishedContent({required this.client, required this.endpoint});

  /// The client this repository owns for its lifetime.
  final http.Client client;

  /// The relay's `/v1/content` base.
  final Uri endpoint;

  /// The published override for [file], or null to use the shipped document.
  ///
  /// Throwing here would be handled identically by the repository, so this
  /// returns null on anything that is not a clean 200 rather than inventing a
  /// distinction the caller cannot act on.
  Future<String?> read(String file) async {
    final response = await client.get(
      endpoint.replace(path: '${endpoint.path}/$file'),
    );
    if (response.statusCode != 200) return null;
    final body = response.body;
    return body.isEmpty ? null : body;
  }
}

/// The relay's published-content path.
final publishedContentEndpointProvider = Provider<Uri?>((ref) {
  final relay = ref.watch(relayEndpointProvider);
  return relay?.replace(path: '/v1/content');
});

/// The real reader, installed over `publishedContentProvider` by
/// `bootstrap.dart`.
///
/// Null when there is no relay, rather than a no-op reader, so
/// `ContentRepository` skips the remote path entirely instead of awaiting a
/// call that was always going to fail.
final publishedContentReaderProvider = Provider<RemoteReader?>((ref) {
  final endpoint = ref.watch(publishedContentEndpointProvider);
  if (endpoint == null) return null;
  final client = http.Client();
  ref.onDispose(client.close);
  return PublishedContent(client: client, endpoint: endpoint).read;
});
