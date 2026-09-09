import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/features/writing/data/writing_repository.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// Where the relay lives.
///
/// **This is content, not analytics, and it must not share a switch with it.**
/// The writing endpoint used to be derived from `ANALYTICS_ENDPOINT`, and the
/// release build deliberately supplies none, because the site collects
/// nothing. The consequence was that turning collection off also turned the
/// owner's articles off, and `/writing` shipped empty for weeks.
///
/// The two were conflated because they happen to live on the same Worker. That
/// is a deployment detail, not a reason to couple them: a request to
/// `/v1/writing` carries nothing about the viewer, because the Worker fetches
/// Medium itself, which is exactly why it needs no consent and no opt-in.
///
/// The default is the deployed relay. An override exists for a different
/// deployment, and an explicitly empty value silences the feed, but a build
/// that says nothing gets the articles.
const String _relayDefault =
    'https://nocturne-analytics.asherbinyy.workers.dev';

/// The relay's origin, overridable at build time.
final relayEndpointProvider = Provider<Uri?>((ref) {
  const value = String.fromEnvironment(
    'WRITING_RELAY',
    defaultValue: _relayDefault,
  );
  if (value.isEmpty) return null;
  final parsed = Uri.tryParse(value);
  // https only, and a host: this is the one outbound origin the app talks to.
  if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
    return null;
  }
  return parsed;
});

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
  if (repository == null) return const [];
  return repository.articles();
});
