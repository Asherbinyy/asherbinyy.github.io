import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/core/net/relay.dart';
import 'package:nocturne/features/writing/data/feed_parser.dart';
import 'package:nocturne/features/writing/data/writing_repository.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// The relay's writing path.
final writingEndpointProvider = Provider<Uri?>((ref) {
  final relay = ref.watch(relayEndpointProvider);
  return relay?.replace(path: '/v1/writing');
});

/// Turns a Medium cover URL into one this origin serves.
///
/// The browser never requests Medium directly. Visiting `/writing` would
/// otherwise issue one third-party request per article, each carrying the
/// viewer's IP and referrer to Medium's CDN — which is precisely the data flow
/// this site's argument says it does not have, and `AGENTS.md` §6 puts that
/// constraint above any feature.
///
/// Returns null when there is no relay, so a build with no endpoint falls back
/// to the procedural card rather than reaching the network anyway.
final coverProxyProvider = Provider<Uri? Function(Uri?)>((ref) {
  final relay = ref.watch(relayEndpointProvider);
  return (Uri? cover) {
    if (relay == null || cover == null) return null;
    return relay.replace(
      path: '/v1/cover',
      queryParameters: {'src': cover.toString()},
    );
  };
});

/// Owns the repository only when an endpoint was supplied at build time.
final writingRepositoryProvider = Provider<WritingRepository?>((ref) {
  final endpoint = ref.watch(writingEndpointProvider);
  if (endpoint == null) return null;
  final client = http.Client();
  ref.onDispose(client.close);
  return WritingRepository(client: client, endpoint: endpoint);
});

/// The published articles, newest first.
///
/// Resolves to an empty list when there is no endpoint or the feed could not
/// be read, so every caller has one case to render and the section simply is
/// not there rather than apologising for itself.
final articlesProvider = FutureProvider<List<Article>>((ref) async {
  final repository = ref.watch(writingRepositoryProvider);
  final readAsset = ref.watch(assetReaderProvider);
  final live = await repository?.articles();
  if (live != null && live.isNotEmpty) return live;
  try {
    // Public title/link/date metadata only. No stale article bodies, tracking
    // URLs or third-party covers are loaded when the relay is unavailable.
    return List.unmodifiable(
      parseFeed(await readAsset('assets/content/writing.xml')),
    );
  } on Object {
    return const [];
  }
});

/// Bundled covers keyed by article identity, never by feed position.
final bundledWritingCoversProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    final raw = jsonDecode(
      await ref.watch(assetReaderProvider)(
        'assets/content/writing-covers.json',
      ),
    ) as Map<String, dynamic>;
    return {
      for (final entry in raw.entries)
        if (entry.value case {'asset': final String asset}
            when asset.startsWith('assets/media/article-'))
          entry.key: asset,
    };
  } on Object {
    return const {};
  }
});

/// Ignores RSS tracking parameters without conflating articles or publishers.
String articleCoverKey(Uri url) => url
    .replace(query: '', fragment: '')
    .toString()
    .split('?')
    .first
    .split('#')
    .first;
