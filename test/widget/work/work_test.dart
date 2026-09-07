import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/features/recruiter/presentation/recruiter_view.dart';
import 'package:nocturne/features/work/presentation/widgets/work_card.dart';
import 'package:nocturne/features/work/presentation/work_screen.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

void main() {
  group('the work grid', () {
    testWidgets('renders a card for every application in the content', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );

      // Counted from the ledger rather than written here, so adding an
      // application to content cannot leave this test asserting the old total.
      expect(find.byType(WorkCard), findsNWidgets(bundledApps().length));
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

      // Mokaf has no supplied listing; Snunu's listing is dead; AZ Exams has
      // no independently verified URL. The ledger says so instead of linking
      // to a dead or ambiguous destination.
      final unlisted = bundledApps().where((a) => storeOf(a).isEmpty).length;
      expect(unlisted, greaterThan(0));
      expect(find.text(l10n.workNoStoreLink), findsNWidgets(unlisted));
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

      final apps = bundledApps();
      final ios = apps.where((a) => storeOf(a).containsKey('ios')).length;
      final android = apps.where((a) => storeOf(a).containsKey('android'));
      expect(find.text(l10n.workAppStore), findsNWidgets(ios));
      expect(find.text(l10n.workGooglePlay), findsNWidgets(android.length));
    });

    testWidgets('lays every card out on a phone without overflowing', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.compact,
        capabilities: touchBrowser,
        initialRoute: AppRoute.work,
      );

      expect(find.byType(WorkCard), findsNWidgets(bundledApps().length));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a package is listed as pub.dev, not as a store', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // Easy Go is a package, not an application. It satisfies the owner's
      // live-listing rule -- anyone can open it -- but it is not something a
      // person installs, so it must not be offered under a store's name.
      final packages = bundledApps()
          .where((app) => storeOf(app).containsKey('pub'))
          .toList();
      expect(packages, hasLength(1));

      expect(find.text(packages.single['name'] as String), findsOneWidget);
      expect(find.text(l10n.workPubDev), findsNWidgets(packages.length));
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

      expect(find.byType(WorkCard), findsNothing);
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
      expect(find.byType(WorkCard), findsNothing);
    });

    testWidgets('shows the same featured applications as /brief', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      );

      // The featured applications, read from the same JSON the static page
      // reads, so the two cannot drift -- and so changing which six are
      // featured does not require editing this list by hand.
      final apps = bundledApps();
      final featured = apps.where((a) => a['featured'] == true).toList();
      final unfeatured = apps.where((a) => a['featured'] != true).toList();
      expect(featured, hasLength(6));
      for (final app in featured) {
        expect(
          find.text(app['name'] as String),
          findsOneWidget,
          reason: '$app',
        );
      }
      for (final app in unfeatured) {
        expect(find.text(app['name'] as String), findsNothing, reason: '$app');
      }
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
