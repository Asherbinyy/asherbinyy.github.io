import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/beacon_sender.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';

/// Compile-time endpoint; an omitted or invalid value keeps transport disabled.
///
/// **This is the site's analytics switch.** With no endpoint supplied at build
/// time there is no sender, so there is no client, so nothing is recorded,
/// nothing is stored on the device and no consent is needed — which is why the
/// banner does not appear and `/privacy` says the site collects nothing.
///
/// Production currently supplies no endpoint. Restoring collection means
/// passing `--dart-define=ANALYTICS_ENDPOINT=...` in the release build again;
/// the tiers, the consent model and the Worker are all still here and tested.
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

/// Whether this build collects anything at all.
///
/// The honest question for the interface to ask. A consent prompt for
/// collection that cannot happen is worse than no prompt: it implies tracking
/// the site is not doing, and it asks the viewer to make a decision that has
/// no effect.
final analyticsIsCollectingProvider = Provider<bool>(
  (ref) => ref.watch(analyticsClientProvider) != null,
);
