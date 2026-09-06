import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/browser_analytics_context.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/events.dart';

/// A transport that records every call, so silence can be asserted directly.
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
  group('the session identifier', () {
    test('is attached to Tier 1 events once consent allows them', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(
        sender.call,
        tier: ConsentTier.session,
        sessionId: () => 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
      );

      await client.record(_interaction(AnalyticsEvent.mapNodeOpened));

      expect(sender.sent.single.sessionId, 'a1b2c3d4e5f60718293a4b5c6d7e8f90');
    });

    test('is never attached to a Tier 0 route view', () async {
      // Section 3: Tier 0 creates no per-person record. An identifier on it
      // would be exactly that, and would put it inside PECR consent.
      final sender = _RecordingSender();
      final client = AnalyticsClient(
        sender.call,
        tier: ConsentTier.session,
        sessionId: () => 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
      );

      await client.record(
        beacon(
          event: AnalyticsEvent.routeView,
          route: '/work',
          deviceClass: 'pointer',
        ),
      );

      expect(sender.sent.single.sessionId, isNull);
    });

    test('is never minted below Tier 1', () async {
      // The only path to an identifier runs through a tier check, so an
      // aggregate-only viewer cannot cause one to exist.
      var minted = 0;
      final sender = _RecordingSender();
      final client = AnalyticsClient(
        sender.call,
        tier: ConsentTier.aggregate,
        sessionId: () {
          minted++;
          return 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
        },
      );

      await client.record(_interaction(AnalyticsEvent.mapNodeOpened));
      await client.record(
        beacon(
          event: AnalyticsEvent.routeView,
          route: '/work',
          deviceClass: 'pointer',
        ),
      );

      expect(minted, 0);
    });

    test('is 32 hex characters of randomness', () {
      final id = sessionIdForTab(random: Random(1));

      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
    });
  });

  group('withdrawal', () {
    test('stops session events within the same session', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.session);

      await client.record(_interaction(AnalyticsEvent.themeChanged));
      // Assigning the tier applies the decision immediately.
      client.tier = ConsentTier.aggregate;
      final second = await client.record(
        _interaction(AnalyticsEvent.themeChanged),
      );
      expect(second, isFalse);

      // There is no buffer to drain, so the second is simply never sent.
      expect(sender.sent, hasLength(1));
    });

    test('an explicit refusal stops even the aggregate counter', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.session);

      await (client..tier = ConsentTier.none).record(
        beacon(
          event: AnalyticsEvent.routeView,
          route: '/work',
          deviceClass: 'pointer',
        ),
      );

      expect(sender.sent, isEmpty);
    });
  });

  group('the engagement events', () {
    test('carry their measurement as the beacon value', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.session);

      await client.record(_interaction(AnalyticsEvent.scrollDepth, value: 3));
      await client.record(_interaction(AnalyticsEvent.sectionDwell, value: 47));

      expect(sender.sent.map((b) => b.value), [3, 47]);
    });

    test('are refused entirely below Tier 1', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.aggregate);

      final scroll = await client.record(
        _interaction(AnalyticsEvent.scrollDepth, value: 4),
      );
      final dwell = await client.record(
        _interaction(AnalyticsEvent.sectionDwell, value: 30),
      );

      expect([scroll, dwell], [false, false]);
      expect(sender.sent, isEmpty);
    });
  });
}
