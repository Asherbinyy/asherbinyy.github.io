import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/features/writing/data/writing_repository.dart';
import 'package:nocturne/features/writing/domain/article.dart';

/// The relay's writing path, derived from the analytics endpoint.
///
/// Both live on the same Worker, so deriving one from the other means there is
/// a single `--dart-define` to get right and a single place a local build can
/// be silent. A build with no endpoint reads no feed and makes no request at
/// all, which is the same posture the beacon takes.
final writingEndpointProvider = Provider<Uri?>((ref) {
  final analytics = ref.watch(analyticsEndpointProvider);
  return analytics?.replace(path: '/v1/writing');
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
