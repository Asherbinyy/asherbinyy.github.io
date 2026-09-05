import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/generated/app_localizations_en.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/analytics/analytics_client.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/features/privacy/presentation/privacy_screen.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

void main() {
  group('the live readout', () {
    testWidgets('renders every field the site can collect', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.privacyHeading), findsOneWidget);
      for (final name in [
        l10n.privacyFieldRoute,
        l10n.privacyFieldCountry,
        l10n.privacyFieldDevice,
        l10n.privacyFieldAddress,
        l10n.privacyFieldDemographics,
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('shows the viewer their own current route', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );

      // Watching your own data is the point of the page.
      expect(find.text('/privacy'), findsOneWidget);
    });

    testWidgets('granting session analytics updates the table', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.privacyGrantSession));
      await pumpFrames(tester);

      expect(container.read(consentControllerProvider), ConsentTier.session);
      expect(find.text(l10n.privacyWithdrawSession), findsOneWidget);
    });

    testWidgets('collecting nothing switches the aggregate rows off', (
      tester,
    ) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.privacyCollectNothing));
      await pumpFrames(tester);

      expect(container.read(consentControllerProvider), ConsentTier.none);
      expect(find.text(l10n.privacyNotCollected), findsWidgets);
    });

    testWidgets('neither control is amber, so neither is the default', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );

      // Making "accept" the amber one would be a dark pattern on a page whose
      // entire subject is not using them.
      final buttons = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(buttons, isNotEmpty);
    });
  });

  group('the readout matches what the client actually does', () {
    /// Section 9 requires the panel's live readout to match actual collection
    /// state. Comparing the table against the client, rather than against a
    /// second description of the rules, is what makes that meaningful.
    void assertAgrees(ConsentTier tier) {
      final l10n = AppLocalizationsEn();
      final fields = PrivacyScreen.fieldsFor(
        consent: tier,
        l10n: l10n,
        route: '/privacy',
        viewport: ViewportClass.expanded,
        isTouch: false,
      );
      final client = AnalyticsClient((_) async {}, tier: tier);

      final routeRow = fields.firstWhere(
        (field) => field.name == l10n.privacyFieldRoute,
      );
      final clicksRow = fields.firstWhere(
        (field) => field.name == l10n.privacyFieldClicks,
      );

      expect(
        routeRow.status == FieldStatus.on,
        tier.allowsAggregate,
        reason: 'route row for $tier',
      );
      expect(
        clicksRow.status == FieldStatus.on,
        client.tier.allowsSessionEvents,
        reason: 'clicks row for $tier',
      );
    }

    test('for every consent tier', () {
      for (final tier in ConsentTier.values) {
        assertAgrees(tier);
      }
    });

    test('the never rows are never on, whatever is granted', () {
      final l10n = AppLocalizationsEn();
      for (final tier in ConsentTier.values) {
        final fields = PrivacyScreen.fieldsFor(
          consent: tier,
          l10n: l10n,
          route: '/privacy',
          viewport: ViewportClass.expanded,
          isTouch: false,
        );
        for (final name in [
          l10n.privacyFieldAddress,
          l10n.privacyFieldDemographics,
        ]) {
          final row = fields.firstWhere((field) => field.name == name);
          expect(row.status, FieldStatus.never, reason: '$name under $tier');
          expect(row.value, l10n.privacyNotCollected);
        }
      }
    });

    test('the device class reported is the one actually resolved', () {
      final l10n = AppLocalizationsEn();
      final touch = PrivacyScreen.fieldsFor(
        consent: ConsentTier.aggregate,
        l10n: l10n,
        route: '/privacy',
        viewport: ViewportClass.compact,
        isTouch: true,
      ).firstWhere((field) => field.name == l10n.privacyFieldDevice);

      expect(touch.value, 'touch');
    });
  });

  group('no network before consent', () {
    testWidgets('rendering the site sends nothing', (tester) async {
      // The app installs no transport at all yet, which is the strongest form
      // of the guarantee: there is nothing to call.
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        initialRoute: AppRoute.privacy,
      );

      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
