import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/beacon_sender.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';

/// Compile-time endpoint; an omitted or invalid value keeps transport disabled.
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

/// Resolves consent and transport at the instant an event is attempted.
final analyticsClientProvider = Provider<AnalyticsClient?>((ref) {
  final sender = ref.watch(beaconSenderProvider);
  if (sender == null) return null;
  return AnalyticsClient(sender, tier: ref.watch(consentControllerProvider));
});
