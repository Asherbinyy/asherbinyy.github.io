import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:nocturne/core/analytics/events.dart';

/// Sends consent-approved beacons to the first-party Worker endpoint.
class HttpBeaconSender {
  /// The caller owns [client] and closes it with the provider that created it.
  const HttpBeaconSender({required this.client, required this.endpoint});

  /// HTTP client kept injectable so tests cannot reach the network.
  final http.Client client;

  /// Deployed first-party Worker endpoint.
  final Uri endpoint;

  /// Sends one compact JSON beacon. There is deliberately no retry queue.
  ///
  /// **Absent fields are omitted rather than sent as null.** The Worker
  /// rejects a beacon carrying a field it does not know, which is the right
  /// posture for a public endpoint — but it also means the client and the
  /// Worker deploy independently and a client that always names every field
  /// breaks the moment it learns a new one. Omitting nulls keeps a newer
  /// client working against an older Worker, and the Worker reads an absent
  /// field and a null one identically.
  Future<void> call(AnalyticsBeacon beacon) async {
    final result = await client.post(
      endpoint,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'event': beacon.event.name,
        'route': beacon.route,
        'deviceClass': beacon.deviceClass,
        if (beacon.referrerHost != null) 'referrerHost': beacon.referrerHost,
        if (beacon.campaign != null) 'campaign': beacon.campaign,
        if (beacon.sessionId != null) 'sessionId': beacon.sessionId,
        if (beacon.value != null) 'value': beacon.value,
      }),
    );
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw AnalyticsTransportException(result.statusCode);
    }
  }
}

/// A failed beacon must never break navigation or the page being measured.
class AnalyticsTransportException implements Exception {
  /// Records the response without retaining its potentially identifying body.
  const AnalyticsTransportException(this.statusCode);

  /// Worker response status.
  final int statusCode;

  @override
  String toString() => 'Analytics transport failed ($statusCode).';
}

/// Accepts only an HTTPS endpoint with an authority component.
Uri? parseAnalyticsEndpoint(String value) {
  final endpoint = Uri.tryParse(value);
  if (endpoint == null ||
      endpoint.scheme != 'https' ||
      !endpoint.hasAuthority) {
    return null;
  }
  return endpoint;
}
