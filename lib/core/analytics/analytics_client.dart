import 'package:nocturne/core/analytics/events.dart';

/// Sends one beacon. Injected so no test ever reaches the network.
typedef BeaconSender = Future<void> Function(AnalyticsBeacon beacon);

/// The only thing on the site that may talk to the analytics endpoint.
class AnalyticsClient {
  /// The transport is positional so it can stay private: a named parameter
  /// cannot be, and a public transport would let callers bypass this boundary.
  AnalyticsClient(this._send);

  final BeaconSender _send;

  /// Records an event through the configured first-party transport.
  Future<bool> record(AnalyticsBeacon event) async {
    await _send(event);
    return true;
  }
}
