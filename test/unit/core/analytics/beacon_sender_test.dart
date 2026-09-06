import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nocturne/core/analytics/beacon_sender.dart';
import 'package:nocturne/core/analytics/events.dart';

const _beacon = (
  event: AnalyticsEvent.routeView,
  route: '/work',
  deviceClass: 'pointer',
  referrerHost: 'example.com',
  campaign: 'graduate-role',
);

void main() {
  group('parseAnalyticsEndpoint', () {
    test('accepts a secure Worker endpoint', () {
      expect(
        parseAnalyticsEndpoint(
          'https://analytics.example.workers.dev/v1/beacon',
        ),
        Uri.https('analytics.example.workers.dev', '/v1/beacon'),
      );
    });

    test(
      'keeps transport disabled for empty, relative, or insecure values',
      () {
        expect(parseAnalyticsEndpoint(''), isNull);
        expect(parseAnalyticsEndpoint('/v1/beacon'), isNull);
        expect(
          parseAnalyticsEndpoint('http://analytics.example/v1/beacon'),
          isNull,
        );
      },
    );
  });

  test('serializes only the declared beacon fields', () async {
    late http.Request captured;
    final client = MockClient.streaming((request, bodyStream) async {
      captured = request as http.Request;
      return http.StreamedResponse(const Stream.empty(), 202);
    });
    final endpoint = Uri.https('analytics.example.workers.dev', '/v1/beacon');

    await HttpBeaconSender(client: client, endpoint: endpoint).call(_beacon);

    expect(captured.url, endpoint);
    expect(captured.headers['content-type'], 'application/json');
    expect(jsonDecode(captured.body), <String, Object?>{
      'event': 'route_view',
      'route': '/work',
      'deviceClass': 'pointer',
      'referrerHost': 'example.com',
      'campaign': 'graduate-role',
    });
  });

  test('reports a non-success status without retaining its body', () async {
    final client = MockClient((request) async => http.Response('private', 503));
    final sender = HttpBeaconSender(
      client: client,
      endpoint: Uri.https('analytics.example.workers.dev', '/v1/beacon'),
    );

    await expectLater(
      sender.call(_beacon),
      throwsA(
        isA<AnalyticsTransportException>()
            .having((error) => error.statusCode, 'status', 503)
            .having(
              (error) => error.toString(),
              'message',
              isNot(contains('private')),
            ),
      ),
    );
  });
}
