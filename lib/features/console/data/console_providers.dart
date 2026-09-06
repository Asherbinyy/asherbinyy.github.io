import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/features/console/data/console_repository.dart';
import 'package:nocturne/features/console/domain/console_summary.dart';

/// The owner's console token, held in memory for this tab only.
///
/// Deliberately never written to `localStorage` or `sessionStorage`. It is a
/// bearer credential for the analytics store, and a site whose whole argument
/// is about not writing things to visitors' devices should not make an
/// exception for the one secret it has. Re-entering it once per tab is the
/// cost, and the owner is the only person who ever pays it.
final consoleTokenProvider = StateProvider<String?>((ref) => null);

/// The aggregates endpoint, derived from the analytics one.
final consoleEndpointProvider = Provider<Uri?>((ref) {
  final analytics = ref.watch(analyticsEndpointProvider);
  return analytics?.replace(path: '/v1/aggregates');
});

/// Owns the repository only when an endpoint was supplied at build time.
final consoleRepositoryProvider = Provider<ConsoleRepository?>((ref) {
  final endpoint = ref.watch(consoleEndpointProvider);
  if (endpoint == null) return null;
  final client = http.Client();
  ref.onDispose(client.close);
  return ConsoleRepository(client: client, endpoint: endpoint);
});

/// The dashboard's data, once a token has been entered.
final consoleSummaryProvider = FutureProvider<ConsoleSummary?>((ref) async {
  final token = ref.watch(consoleTokenProvider);
  final repository = ref.watch(consoleRepositoryProvider);
  if (token == null || token.isEmpty || repository == null) return null;
  return repository.summary(token: token, today: DateTime.now());
});
