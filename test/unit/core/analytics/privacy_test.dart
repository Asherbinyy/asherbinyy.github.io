import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/preference_store.dart';

class _RecordingSender {
  final List<AnalyticsBeacon> sent = [];

  Future<void> call(AnalyticsBeacon beacon) async => sent.add(beacon);
}

void main() {
  test('configured analytics records without a decision state', () async {
    final sender = _RecordingSender();
    final client = AnalyticsClient(sender.call);

    expect(
      await client.record(
        beacon(
          event: AnalyticsEvent.routeView,
          route: '/work',
          deviceClass: 'pointer',
        ),
      ),
      isTrue,
    );
    expect(
      await client.record(
        beacon(
          event: AnalyticsEvent.outboundClick,
          route: '/work',
          deviceClass: 'pointer',
          target: 'app:sample',
          destination: 'https://example.com/app',
        ),
      ),
      isTrue,
    );

    expect(sender.sent.map((event) => event.event), [
      AnalyticsEvent.routeView,
      AnalyticsEvent.outboundClick,
    ]);
  });

  test('analytics has no persistent browser preference', () {
    expect(
      PreferenceKey.values.map((key) => key.storageKey),
      isNot(contains('nocturne.analyticsConsent.v2')),
    );
  });

  test('the beacon has no field for raw request identity or form input', () {
    final event = beacon(
      event: AnalyticsEvent.routeView,
      route: '/about',
      deviceClass: 'touch',
    );

    expect(event.route, '/about');
    expect(event.referrerHost, isNull);
    expect(event.campaign, isNull);
    expect(event.target, isNull);
    expect(event.destination, isNull);
  });
}
