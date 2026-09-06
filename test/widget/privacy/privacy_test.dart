import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/features/privacy/presentation/privacy_screen.dart';
import 'package:nocturne/features/privacy/presentation/widgets/consent_banner.dart';
import 'package:nocturne/features/privacy/presentation/widgets/consent_controls.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

/// The consent machinery is dormant in this build: production supplies no
/// analytics endpoint, so no client exists and the banner never appears.
///
/// It is dormant, not deleted, and it has to keep working for the day
/// collection is switched back on — so these tests pump a build that *is*
/// collecting. The tests that the banner stays away when nothing is collected
/// live in `the dormant build` at the foot of this file.
final List<Override> collecting = [
  analyticsIsCollectingProvider.overrideWithValue(true),
];

void main() {
  group('the banner', () {
    testWidgets('greets a first visit, before any choice is made', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.byType(ConsentBanner), findsOneWidget);
      expect(find.text(l10n.consentBannerBody), findsOneWidget);
    });

    testWidgets('offers exactly three options', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.consentAcceptAll), findsOneWidget);
      expect(find.text(l10n.consentEssentialOnly), findsOneWidget);
      expect(find.text(l10n.consentReject), findsOneWidget);
    });

    testWidgets('does not return once a choice is made', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.consentEssentialOnly));
      await pumpFrames(tester);

      expect(container.read(consentControllerProvider), ConsentTier.aggregate);
      expect(find.byType(ConsentControls), findsNothing);
    });

    testWidgets('is absent for a viewer who has already decided', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        preferences: {
          PreferenceKey.consent.storageKey: ConsentTier.none.storageKey,
        },
        overrides: collecting,
      );

      // Asking again every visit is the dark pattern the decision is stored to
      // avoid.
      expect(find.byType(ConsentControls), findsNothing);
    });

    testWidgets('does not block the page behind it', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        overrides: collecting,
      );

      // No scrim, no modal: the site is readable while the choice is open.
      expect(find.text('Ahmed Elsherbini'), findsOneWidget);
    });
  });

  group('each option maps to the tier it names', () {
    for (final option in [
      (label: 'accept all', expected: ConsentTier.session),
      (label: 'essential only', expected: ConsentTier.aggregate),
      (label: 'reject', expected: ConsentTier.none),
    ]) {
      testWidgets('${option.label} selects ${option.expected.name}', (
        tester,
      ) async {
        final container = await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.expanded,
          overrides: collecting,
        );
        final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
        final text = switch (option.expected) {
          ConsentTier.session => l10n.consentAcceptAll,
          ConsentTier.aggregate => l10n.consentEssentialOnly,
          ConsentTier.none => l10n.consentReject,
          ConsentTier.unresolved => '',
        };

        await tester.tap(find.text(text));
        await pumpFrames(tester);

        expect(container.read(consentControllerProvider), option.expected);
      });
    }
  });

  group('the privacy notice', () {
    testWidgets('states plainly what happens, in prose', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
        preferences: {
          PreferenceKey.consent.storageKey: ConsentTier.aggregate.storageKey,
        },
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(find.text(l10n.privacyBody), findsOneWidget);
      expect(find.text(l10n.privacyRetention), findsOneWidget);
    });

    testWidgets('names the setting currently in force', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
        preferences: {
          PreferenceKey.consent.storageKey: ConsentTier.none.storageKey,
        },
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.privacyCurrentRejected), findsOneWidget);
    });

    testWidgets('lets a decision be changed at any time', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
        preferences: {
          PreferenceKey.consent.storageKey: ConsentTier.session.storageKey,
        },
        overrides: collecting,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.consentReject));
      await pumpFrames(tester);

      // Withdrawal is as easy as granting, and takes effect immediately.
      expect(container.read(consentControllerProvider), ConsentTier.none);
    });

    testWidgets('says how to ask for erasure', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
        preferences: {
          PreferenceKey.consent.storageKey: ConsentTier.aggregate.storageKey,
        },
        overrides: collecting,
      );

      expect(
        find.textContaining('ahmed.elsherbini.tech@gmail.com'),
        findsOneWidget,
      );
    });
  });

  group('the dormant build', () {
    // What production actually ships: no analytics endpoint, so no client, so
    // nothing is collected. These are the tests that describe the live site.
    testWidgets('shows no consent banner at all', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);

      // Asking permission for collection that cannot happen implies tracking
      // the site is not doing.
      expect(find.byType(ConsentBanner), findsOneWidget);
      expect(find.byType(ConsentControls), findsNothing);
    });

    testWidgets('says the site collects nothing, and offers no controls', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.privacyCollectsNothing), findsOneWidget);
      // A control that changes nothing is theatre.
      expect(find.byType(ConsentControls), findsNothing);
      expect(find.text(l10n.privacyBody), findsNothing);
    });

    testWidgets('still names the controller and the erasure route', (
      tester,
    ) async {
      // Collecting nothing does not remove the obligation to say who is
      // responsible and how to reach them.
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );

      expect(find.textContaining('@'), findsWidgets);
    });

    testWidgets('records nothing when a route is viewed', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
      );

      // No endpoint means no sender, which means no client at all.
      expect(container.read(analyticsClientProvider), isNull);
      expect(container.read(analyticsIsCollectingProvider), isFalse);
    });
  });
}
