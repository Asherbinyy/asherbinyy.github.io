import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/features/colophon/domain/collection_rules.dart';

void main() {
  group('the collection readout', () {
    // 06-ANALYTICS-AND-PRIVACY.md section 9 requires the readout to match
    // actual collection state. Comparing it against the client that enforces
    // the rules — rather than against a second written description of them —
    // is what makes that assertion mean anything.
    test('matches what the client actually permits at every tier', () {
      for (final rule in collectionRules()) {
        for (final tier in ConsentTier.values) {
          final client = AnalyticsClient((_) async {}, tier: tier);
          final readoutSaysAllowed = tier.level >= rule.requires.level;

          expect(
            client.permits(rule.event),
            readoutSaysAllowed,
            reason:
                'readout claims ${rule.event.name} needs '
                '${rule.requires.name}, but the client disagrees at '
                '${tier.name}',
          );
        }
      }
    });

    test('covers every event the site can record', () {
      expect(
        collectionRules().map((rule) => rule.event).toSet(),
        AnalyticsEvent.values.toSet(),
      );
    });

    test('puts the route view at the aggregate tier', () {
      // Section 3: a cookieless aggregate counter sits outside consent, so an
      // unanswered banner and "essential only" behave identically.
      final rule = collectionRules().firstWhere(
        (rule) => rule.event == AnalyticsEvent.routeView,
      );

      expect(rule.requires.allowsAggregate, isTrue);
      expect(rule.requires.allowsSessionEvents, isFalse);
    });

    test('puts every interaction event behind an opt-in', () {
      final tierOne = collectionRules().where(
        (rule) => rule.event != AnalyticsEvent.routeView,
      );

      expect(
        tierOne.every((rule) => rule.requires == ConsentTier.session),
        isTrue,
      );
    });
  });
}
