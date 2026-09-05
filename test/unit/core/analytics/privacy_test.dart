import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/platform/preference_store.dart';

// These are the tests 06-ANALYTICS-AND-PRIVACY.md section 9 requires and
// 05-TESTING.md restates so they are never deleted. A failure here blocks
// merge unconditionally.

const AnalyticsBeacon _routeView = (
  event: AnalyticsEvent.routeView,
  route: '/work',
  deviceClass: 'pointer',
  referrerHost: null,
  campaign: null,
);

const AnalyticsBeacon _click = (
  event: AnalyticsEvent.mapNodeOpened,
  route: '/signal',
  deviceClass: 'pointer',
  referrerHost: null,
  campaign: null,
);

/// A transport that records every call, so silence can be asserted directly.
class _RecordingSender {
  final List<AnalyticsBeacon> sent = [];

  Future<void> call(AnalyticsBeacon beacon) async => sent.add(beacon);
}

ProviderContainer _container(PreferenceStore store) {
  final container = ProviderContainer(
    overrides: [preferenceStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('no collection before consent resolves', () {
    test('a session event is not sent while consent is unresolved', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call);

      expect(client.tier, ConsentTier.unresolved);
      expect(await client.record(_click), isFalse);
      expect(sender.sent, isEmpty);
    });

    test('the client no-ops rather than buffering', () async {
      // Section 4 is explicit: not a queue that flushes later. A buffer that
      // drains on consent has still collected from someone who had not agreed.
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call);

      await client.record(_click);
      await client.record(_click);
      client.tier = ConsentTier.session;

      expect(sender.sent, isEmpty);
    });
  });

  group('tier boundaries', () {
    test('aggregate counting needs no grant, being cookieless', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call);

      expect(await client.record(_routeView), isTrue);
      expect(sender.sent, hasLength(1));
    });

    test('an explicit refusal stops even aggregate counting', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.none);

      expect(await client.record(_routeView), isFalse);
      expect(await client.record(_click), isFalse);
      expect(sender.sent, isEmpty);
    });

    test('session events need an affirmative grant', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.aggregate);

      expect(await client.record(_click), isFalse);
      client.tier = ConsentTier.session;
      expect(await client.record(_click), isTrue);
    });
  });

  group('withdrawal', () {
    test('takes effect immediately, within the same session', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.session);

      expect(await client.record(_click), isTrue);
      client.tier = ConsentTier.aggregate;
      expect(await client.record(_click), isFalse);

      expect(sender.sent, hasLength(1));
    });

    test('collecting nothing halts everything at once', () async {
      final sender = _RecordingSender();
      final client = AnalyticsClient(sender.call, tier: ConsentTier.session);

      await client.record(_routeView);
      client.tier = ConsentTier.none;
      await client.record(_routeView);
      await client.record(_click);

      expect(sender.sent, hasLength(1));
    });
  });

  group('what is never stored', () {
    test('no session identifier is written to the device', () async {
      final store = InMemoryPreferenceStore();
      final container = _container(store);

      container.read(consentControllerProvider.notifier).grantSession();
      await Future<void>.delayed(Duration.zero);

      // The consent decision itself is the only thing consent writes, and the
      // storage surface is a closed enum of three preferences plus it.
      expect(
        store.read(PreferenceKey.consent.storageKey),
        ConsentTier.session.storageKey,
      );
      for (final key in PreferenceKey.values) {
        final value = store.read(key.storageKey);
        if (value == null) continue;
        expect(value, isNot(matches(RegExp(r'^[0-9a-f]{16,}$'))));
      }
    });

    test('the beacon carries no field from the never-collected list', () {
      // Section 2: no identifier, no demographic, no referrer path, no address.
      // The record type is the enforcement — there is nowhere to put one.
      const beacon = _routeView;

      expect(beacon.referrerHost, isNull);
      expect(beacon.campaign, isNull);
      expect(beacon.deviceClass, anyOf('touch', 'pointer'));
    });
  });

  group('the decision persists', () {
    test('a refusal survives a reload, so it is not asked again', () {
      final store = InMemoryPreferenceStore({
        PreferenceKey.consent.storageKey: ConsentTier.none.storageKey,
      });

      expect(
        _container(store).read(consentControllerProvider),
        ConsentTier.none,
      );
    });

    test('an unrecognised stored value falls back to unresolved', () {
      final store = InMemoryPreferenceStore({
        PreferenceKey.consent.storageKey: 'everything',
      });

      expect(
        _container(store).read(consentControllerProvider),
        ConsentTier.unresolved,
      );
    });

    test('nothing is stored until the viewer decides', () {
      final store = InMemoryPreferenceStore();

      _container(store).read(consentControllerProvider);

      expect(store.read(PreferenceKey.consent.storageKey), isNull);
    });
  });
}
