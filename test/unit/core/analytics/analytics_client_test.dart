import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/events.dart';

class _RecordingSender {
  final List<AnalyticsBeacon> sent = [];

  Future<void> call(AnalyticsBeacon beacon) async => sent.add(beacon);
}

AnalyticsBeacon _interaction(AnalyticsEvent event, {int? value}) => beacon(
  event: event,
  route: '/signal',
  deviceClass: 'pointer',
  value: value,
);

void main() {
  test('route views and interactions are recorded immediately', () async {
    final sender = _RecordingSender();
    final client = AnalyticsClient(sender.call);

    await client.record(
      beacon(
        event: AnalyticsEvent.routeView,
        route: '/work',
        deviceClass: 'pointer',
      ),
    );
    await client.record(_interaction(AnalyticsEvent.mapNodeOpened));

    expect(sender.sent, hasLength(2));
    expect(sender.sent.first.event, AnalyticsEvent.routeView);
    expect(sender.sent.last.event, AnalyticsEvent.mapNodeOpened);
  });

  test('engagement events carry their bounded measurement', () async {
    final sender = _RecordingSender();
    final client = AnalyticsClient(sender.call);

    await client.record(_interaction(AnalyticsEvent.scrollDepth, value: 3));
    await client.record(_interaction(AnalyticsEvent.sectionDwell, value: 47));

    expect(sender.sent.map((event) => event.value), [3, 47]);
  });

  test('transport failures remain visible to the caller', () async {
    final client = AnalyticsClient((_) async => throw StateError('offline'));

    await expectLater(
      client.record(_interaction(AnalyticsEvent.themeChanged)),
      throwsStateError,
    );
  });
}
