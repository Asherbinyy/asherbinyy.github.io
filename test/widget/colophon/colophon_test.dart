import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/analytics/events.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/station_harness.dart';

Future<void> pumpColophon(
  WidgetTester tester, {
  Map<String, Object?>? facts,
  String? rawFacts,
  ChromeBreakpoint breakpoint = ChromeBreakpoint.large,
}) => pumpStation(
  tester,
  breakpoint: breakpoint,
  initialRoute: AppRoute.howItWasBuilt,
  reader: bundledContent(
    overrides: {
      if (facts != null)
        'assets/build_facts.json': asAsset(facts)
      else if (rawFacts != null)
        'assets/build_facts.json': rawFacts,
    },
  ),
);

const Map<String, Object?> _facts = {
  'generatedAt': '2026-09-06',
  'coveragePercent': 89.39,
  'dartTests': 523,
  'workerTests': 25,
  'lighthousePerformanceFloor': 0.85,
  'lighthouseAccessibilityFloor': 0.9,
};

void main() {
  group('the measurements', () {
    testWidgets('shows the generated figures', (tester) async {
      await pumpColophon(tester, facts: _facts);

      expect(find.text('89.4%'), findsOneWidget);
      expect(find.text('523'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('states the Lighthouse floors CI enforces', (tester) async {
      await pumpColophon(tester, facts: _facts);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.colophonLighthouse('0.85', '0.9')), findsOneWidget);
    });

    testWidgets('omits a figure it does not have', (tester) async {
      await pumpColophon(
        tester,
        facts: const {'generatedAt': '2026-09-06', 'dartTests': 10},
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // No coverage tile, and no confident 0%.
      expect(find.text(l10n.colophonCoverage), findsNothing);
      expect(find.text('0.0%'), findsNothing);
    });

    testWidgets('says so when the generated file cannot be read', (
      tester,
    ) async {
      // The file is generated, so it can be missing or malformed on a clean
      // checkout. The page has to survive that rather than crash.
      await pumpColophon(tester, rawFacts: 'not json at all');
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.colophonUnavailable), findsOneWidget);
    });
  });

  group('the collection readout', () {
    testWidgets('lists every event the site can record', (tester) async {
      await pumpColophon(tester, facts: _facts);

      for (final event in AnalyticsEvent.values) {
        expect(
          find.text(event.name),
          findsOneWidget,
          reason: '${event.name} is missing from the readout',
        );
      }
    });

    testWidgets('marks the route view as anonymous counting', (tester) async {
      await pumpColophon(tester, facts: _facts);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.colophonTierAggregate), findsOneWidget);
    });

    testWidgets('marks interaction events as opt-in', (tester) async {
      await pumpColophon(tester, facts: _facts);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(
        find.text(l10n.colophonTierSession),
        findsNWidgets(AnalyticsEvent.values.length - 1),
      );
    });
  });
}
