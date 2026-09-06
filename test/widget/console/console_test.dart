import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/app_nav.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/features/console/data/console_providers.dart';
import 'package:nocturne/features/console/domain/console_summary.dart';
import 'package:nocturne/features/console/presentation/console_screen.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

/// Traffic that is partly attributed to a campaign and partly not, so a tile
/// total and a campaign row never carry the same number by accident.
ConsoleSummary summaryWith({
  int views = 0,
  int cvOpens = 0,
  int campaignViews = 0,
  int campaignCvOpens = 0,
}) => ConsoleSummary.from(
  counters: [
    if (views - campaignViews > 0)
      (
        dimensions: const [
          '2026-09-30',
          'route_view',
          '/',
          'GB',
          'pointer',
          '-',
          '-',
        ],
        count: views - campaignViews,
      ),
    if (campaignViews > 0)
      (
        dimensions: const [
          '2026-09-30',
          'route_view',
          '/',
          'GB',
          'pointer',
          '-',
          'deloitte',
        ],
        count: campaignViews,
      ),
    if (cvOpens - campaignCvOpens > 0)
      (
        dimensions: const [
          '2026-09-30',
          'cv_opened',
          '/',
          'GB',
          'pointer',
          '-',
          '-',
        ],
        count: cvOpens - campaignCvOpens,
      ),
    if (campaignCvOpens > 0)
      (
        dimensions: const [
          '2026-09-30',
          'cv_opened',
          '/',
          'GB',
          'pointer',
          '-',
          'deloitte',
        ],
        count: campaignCvOpens,
      ),
  ],
  totals: const [],
  today: DateTime.utc(2026, 9, 30),
);

/// The console only has anything to show when the build is collecting, which
/// production is not. These pump a collecting build; the dormant behaviour has
/// its own group at the foot of the file.
final List<Override> collecting = [
  analyticsIsCollectingProvider.overrideWithValue(true),
];

void main() {
  group('the gate', () {
    testWidgets('asks for a token before showing anything', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.consoleTokenPrompt), findsOneWidget);
      expect(find.text(l10n.consoleHeading), findsNothing);
    });

    testWidgets('obscures the token as it is typed', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
        overrides: collecting,
      );

      final field = tester.widget<TextField>(find.byType(TextField));

      expect(field.obscureText, isTrue);
    });

    testWidgets('is not linked from the public navigation', (tester) async {
      // The screen spec: auth-gated, and not linked from anywhere on the
      // public site. It is reachable only by typing the path.
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      expect(
        NavDestination.values.map((d) => d.route),
        isNot(contains(AppRoute.console)),
      );
    });
  });

  group('the dashboard', () {
    testWidgets('shows the tiles once a token resolves', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
        overrides: [
          ...collecting,
          consoleTokenProvider.overrideWith((ref) => 'a-token'),
          consoleSummaryProvider.overrideWith(
            (ref) async => summaryWith(
              views: 412,
              cvOpens: 34,
              campaignViews: 18,
              campaignCvOpens: 3,
            ),
          ),
        ],
      );
      await pumpFrames(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.consoleHeading), findsOneWidget);
      expect(find.text('412'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
    });

    testWidgets('lists the campaign that produced the traffic', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
        overrides: [
          ...collecting,
          consoleTokenProvider.overrideWith((ref) => 'a-token'),
          consoleSummaryProvider.overrideWith(
            (ref) async => summaryWith(
              views: 40,
              cvOpens: 3,
              campaignViews: 18,
              campaignCvOpens: 3,
            ),
          ),
        ],
      );
      await pumpFrames(tester);

      expect(find.text('deloitte'), findsOneWidget);
    });

    testWidgets('says so when the window collected nothing', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
        overrides: [
          ...collecting,
          consoleTokenProvider.overrideWith((ref) => 'a-token'),
          consoleSummaryProvider.overrideWith((ref) async => summaryWith()),
        ],
      );
      await pumpFrames(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // An empty dashboard must not read as a broken one.
      expect(find.text(l10n.consoleNothingYet), findsOneWidget);
    });
  });

  group('the console screen', () {
    testWidgets('resolves on its own route', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
      );

      expect(find.byType(ConsoleScreen), findsOneWidget);
    });
  });

  group('the dormant build', () {
    testWidgets('says the console is off rather than asking for a token', (
      tester,
    ) async {
      // What production ships. A gate that takes a token and then shows
      // nothing is worse than no gate at all.
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.console,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.consoleDormant), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
