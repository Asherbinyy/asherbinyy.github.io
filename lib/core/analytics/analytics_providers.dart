import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/beacon_sender.dart';

/// Compile-time endpoint; an omitted or invalid value keeps transport disabled.
///
/// Without an endpoint there is no transport. Preview containers override this
/// provider to keep preview interactions unrecorded.
final analyticsEndpointProvider = Provider<Uri?>((ref) {
  const value = String.fromEnvironment('ANALYTICS_ENDPOINT');
  return parseAnalyticsEndpoint(value);
});

/// Owns the real sender only when a valid first-party endpoint was supplied.
final beaconSenderProvider = Provider<BeaconSender?>((ref) {
  final endpoint = ref.watch(analyticsEndpointProvider);
  if (endpoint == null) return null;
  final client = http.Client();
  ref.onDispose(client.close);
  return HttpBeaconSender(client: client, endpoint: endpoint).call;
});

/// Resolves the configured transport at the instant an event is attempted.
final analyticsClientProvider = Provider<AnalyticsClient?>((ref) {
  final sender = ref.watch(beaconSenderProvider);
  if (sender == null) return null;
  return AnalyticsClient(sender);
});

/// Whether this build collects anything at all.
///
/// Used by the dormant in-site console and campaign router.
final analyticsIsCollectingProvider = Provider<bool>(
  (ref) => ref.watch(analyticsClientProvider) != null,
);
