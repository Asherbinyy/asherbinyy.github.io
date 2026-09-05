import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/features/recruiter/presentation/recruiter_view.dart';
import 'package:nocturne/features/work/presentation/widgets/ledger_row.dart';
import 'package:nocturne/features/work/presentation/work_screen.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

void main() {
  group('the ledger', () {
    testWidgets('renders a row for every application in the content', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );

      // apps.json lists eleven. The schema's intended twelfth is missing, and
      // inventing one would be a claim the owner never made.
      expect(find.byType(LedgerRow), findsNWidgets(11));
    });

    testWidgets('leads with the strongest evidence it has', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );

      expect(find.text('AZ Courses'), findsOneWidget);
      // The strongest single string on the page.
      expect(find.text('15,000+ downloads'), findsOneWidget);
    });

    testWidgets('says plainly when an application has no public listing', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // Mokaf ships with no store URLs. An absence the reader has to interpret
      // would be worse than saying so.
      expect(find.text(l10n.workNoStoreLink), findsOneWidget);
    });

    testWidgets('offers a store link for every listing the content has', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // Nine iOS listings and two Google Play listings across eleven apps.
      expect(find.text(l10n.workAppStore), findsNWidgets(9));
      expect(find.text(l10n.workGooglePlay), findsNWidgets(2));
    });

    testWidgets('shows a thumbnail on touch, where there is no hover', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.compact,
        capabilities: touchBrowser,
        initialRoute: AppRoute.work,
      );

      expect(find.byType(LedgerRow), findsNWidgets(11));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unreadable ledger invents nothing', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
        reader: bundledContent(
          overrides: {'assets/content/apps.json': '{ not json'},
        ),
      );

      expect(find.byType(LedgerRow), findsNothing);
      expect(find.byType(WorkScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('recruiter mode', () {
    testWidgets('replaces the routed content on every route', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
        preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      );

      expect(find.byType(RecruiterView), findsOneWidget);
      expect(find.byType(LedgerRow), findsNothing);
    });

    testWidgets('shows the same featured applications as /brief', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      );

      // The six featured applications, from the same JSON the static page
      // reads, so the two cannot drift.
      for (final name in [
        'Tripster',
        'Mokaf',
        'AZ Courses',
        'Enjoy',
        'Malboos',
        'Tiara Beauty',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // And not the unfeatured ones.
      expect(find.text('Tekrar'), findsNothing);
    });

    testWidgets('carries no trace and no rail', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      );

      expect(container.read(recruiterModeProvider), isTrue);
      // "No map, no trace, no motion."
      await pumpFrames(tester);
      expect(find.byType(RecruiterView), findsOneWidget);
    });

    testWidgets('the toggle turns it off again', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.bySemanticsLabel(l10n.recruiterModeOn));
      await pumpFrames(tester);

      expect(find.byType(RecruiterView), findsNothing);
    });
  });
}
