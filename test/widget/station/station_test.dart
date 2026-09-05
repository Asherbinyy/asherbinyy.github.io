import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/app_footer.dart';
import 'package:nocturne/app/chrome/app_header.dart';
import 'package:nocturne/app/chrome/app_rail.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/features/station/domain/acquisition_controller.dart';
import 'package:nocturne/features/station/presentation/station_screen.dart';
import 'package:nocturne/features/station/presentation/widgets/acquisition_sequence.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_content.dart';
import 'package:nocturne/features/station/presentation/widgets/stat_panel.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/station_harness.dart';
import '../../support/pump.dart';

void main() {
  group('settled hero', () {
    testWidgets('renders the owner name and positioning from content', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);

      expect(find.text('Ahmed Elsherbini'), findsOneWidget);
      expect(
        find.text(
          'Mobile engineer. 25+ applications shipped across six countries.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('carries both calls to action', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.heroSeeTheWork), findsOneWidget);
      expect(find.text(l10n.heroReadTheCv), findsOneWidget);
      // Scoped to the hero: the consent banner carries three of its own.
      expect(
        find.descendant(
          of: find.byType(HeroContent),
          matching: find.byType(BeaconButton),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('the primary action navigates to the work ledger', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.heroSeeTheWork));
      await pumpFrames(tester);

      expect(find.byType(HeroContent), findsNothing);
      expect(find.text(l10n.navWork), findsWidgets);
    });

    testWidgets('renders no stat panels while the content declares none', (
      tester,
    ) async {
      // profile.json carries no stats block yet, and section 3 forbids
      // inventing the numbers, so the panels are absent rather than guessed.
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);

      expect(find.byType(StatPanel), findsNothing);
    });

    testWidgets('renders a panel for every stat the content declares', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        reader: bundledContent(
          overrides: {
            'assets/content/profile.json': asAsset({
              'name': {'en': 'Fixture Name'},
              'positioning': {'en': 'Fixture positioning.'},
              'contact': {'email': 'fixture@example.com'},
              'stats': [
                {
                  'value': '25+',
                  'label': {'en': 'shipped'},
                },
                {
                  'value': '6',
                  'label': {'en': 'countries'},
                },
              ],
            }),
          },
        ),
      );

      expect(find.byType(StatPanel), findsNWidgets(2));
      expect(find.text('25+'), findsOneWidget);
      expect(find.text('shipped'), findsOneWidget);
    });

    testWidgets('the footer reads the current station coordinate', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);

      // Evri is the one career role with no end date, and career.json puts
      // Manchester at 53.4808.
      expect(find.text('lat 53.4808'), findsOneWidget);
      expect(find.byType(AppFooter), findsOneWidget);
    });
  });

  group('degraded content', () {
    testWidgets('an unreadable profile still renders the bundled identity', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        reader: bundledContent(
          overrides: {'assets/content/profile.json': '{ not json'},
        ),
      );

      // The fallback carries the owner's real name, so this is a hero, not an
      // error state.
      expect(find.byType(HeroContent), findsOneWidget);
      expect(find.text('Ahmed Elsherbini'), findsOneWidget);
      expect(find.byType(CarrierEmptyState), findsNothing);
    });

    testWidgets('a corrupt fallback degrades to a direction, not a crash', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        reader: corruptContent,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.byType(CarrierEmptyState), findsOneWidget);
      expect(find.text(l10n.heroContentUnavailable), findsOneWidget);
      // The CV route works without any of this, and the error says so.
      expect(find.text(l10n.heroReadTheCv), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('acquisition sequence', () {
    testWidgets('runs on the station route and settles without shifting', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
      );

      expect(find.byType(AcquisitionSequence), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not run again once it has played', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
      );

      expect(container.read(acquisitionPlayedProvider), isTrue);
    });

    testWidgets('any key press skips it before it finishes', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
        settle: false,
      );

      // A third of the way through the 2400ms sequence.
      await tester.pump(Tokens.acquisition ~/ 3);
      expect(container.read(acquisitionPlayedProvider), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpFrames(tester);

      expect(container.read(acquisitionPlayedProvider), isTrue);
      expect(find.text('Ahmed Elsherbini'), findsOneWidget);
    });

    testWidgets('a pointer press skips it too', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
        settle: false,
      );

      await tester.pump(Tokens.acquisition ~/ 3);
      await tester.tapAt(const Offset(20, 300));
      await pumpFrames(tester);

      expect(container.read(acquisitionPlayedProvider), isTrue);
    });

    testWidgets('beat three reveals content before beat four reveals chrome', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
        settle: false,
      );
      final beatThreeMidpoint = Duration(
        microseconds:
            (Tokens.acquisition.inMicroseconds *
                    (Tokens.acquisitionBeatTwo + Tokens.acquisitionBeatThree) /
                    2)
                .round(),
      );

      await tester.pump(beatThreeMidpoint);

      final contentFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byType(StationScreen),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      final headerFade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byType(AppHeader),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(contentFade.opacity.value, greaterThan(Tokens.zero));
      expect(headerFade.opacity.value, Tokens.zero);
    });

    testWidgets('reduced motion uses the specified 200ms fade', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
        reducedMotion: true,
        settle: false,
      );

      expect(container.read(acquisitionPlayedProvider), isFalse);
      await tester.pump(Tokens.reducedAcquisition ~/ 2);
      expect(container.read(acquisitionPlayedProvider), isFalse);
      await tester.pump(Tokens.reducedAcquisition ~/ 2);
      await tester.pump(Tokens.instant);

      expect(container.read(acquisitionPlayedProvider), isTrue);
      expect(find.text('Ahmed Elsherbini'), findsOneWidget);
    });

    testWidgets('no other route carries the sequence', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        hasPlayedSequence: false,
      );
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.text(l10n.navAbout));
      await pumpFrames(tester);

      expect(find.byType(AcquisitionSequence), findsNothing);
    });
  });

  group('composition', () {
    testWidgets('the hero aligns to the rail, never centred', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      final rail = tester.getRect(find.byType(AppRail));
      final hero = tester.getRect(find.byType(HeroContent));

      // "Everything left-aligned to the rail." Its leading edge is the rail's
      // trailing edge plus the gutter, with nothing centred about it.
      expect(hero.left, closeTo(rail.right + Tokens.largeGutter, 1));
    });

    testWidgets('the amber rule is short of the column, not a divider', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      final rule = find.descendant(
        of: find.byType(HeroContent),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == Tokens.heroRuleWidth,
        ),
      );
      expect(tester.getSize(rule.first).width, Tokens.heroRuleWidth);
      expect(tester.getSize(rule.first).height, Tokens.heroRuleHeight);
    });
  });
}
