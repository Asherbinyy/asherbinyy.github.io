import 'dart:math' as math;

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

      // Every in-app surface shows `profile.displayName`, whatever the owner
      // has set it to. It used to be "Sherbini", and this asserted the full
      // name was absent to prove the short one was being used. He has since
      // set the display name to the full name for consistency, so that second
      // assertion now contradicts the content it is meant to be reading.
      expect(find.text(_shownName()), findsOneWidget);
      // Read from the content rather than pinned to a sentence: the line is
      // the owner's own copy and he rewrites it, and a test that hard-codes it
      // fails every time he does.
      final positioning =
          (bundledJson('assets/content/profile.json')['positioning']
              as Map<String, dynamic>)['en'];
      expect(positioning, isNotEmpty);
      expect(find.text(positioning as String), findsOneWidget);
    });

    testWidgets('carries both calls to action', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.text(l10n.heroSeeTheWork), findsOneWidget);
      // The label names its outcome: "Download" now that profile.cvFile
      // supplies a PDF, "Read" where it does not and the static HTML page is
      // what opens. Asserted as one or the other rather than pinned to the
      // current content, so supplying or withdrawing the file is a content
      // decision and not a failing test.
      expect(
        find.text(l10n.heroDownloadTheCv).evaluate().length +
            find.text(l10n.heroReadTheCv).evaluate().length,
        1,
      );
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

      // With the stat panels present the actions sit just below the fold at
      // this breakpoint while the consent banner still holds its row, so the
      // button is scrolled into view rather than tapped at its laid-out offset.
      await tester.ensureVisible(find.text(l10n.heroSeeTheWork));
      await pumpFrames(tester);
      await tester.tap(find.text(l10n.heroSeeTheWork));
      await pumpFrames(tester);

      expect(find.byType(HeroContent), findsNothing);
      expect(find.text(l10n.navWork), findsWidgets);
    });

    testWidgets('renders no stat panels while the content declares none', (
      tester,
    ) async {
      // Section 3 forbids inventing the numbers, so a profile without a stats
      // block renders no panels rather than a guess.
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.expanded,
        reader: bundledContent(
          overrides: {
            'assets/content/profile.json': asAsset({
              'name': {'en': 'Fixture Name'},
              'positioning': {'en': 'Fixture positioning.'},
              'contact': {'email': 'fixture@example.com'},
            }),
          },
        ),
      );

      expect(find.byType(StatPanel), findsNothing);
    });

    testWidgets('renders the panels the shipped profile declares', (
      tester,
    ) async {
      // The hero used to lead with a scoreboard: 25+ shipped, six countries,
      // 4+ years. The owner's objection was that it introduced him as a
      // statistic, so the counts moved to where they are evidence rather than
      // a greeting, and two panels remain. Both are traceable: five years is
      // the span since October 2021, and the award is on his CV.
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);

      // Read from the shipped profile rather than written out. These were
      // literals, so correcting "5 years building" to "5+ years commercial
      // experience" failed the test on the spelling of a value it was not
      // about.
      final stats =
          bundledJson('assets/content/profile.json')['stats'] as List<dynamic>;
      expect(find.byType(StatPanel), findsNWidgets(stats.length));
      for (final stat in stats.cast<Map<String, dynamic>>()) {
        expect(
          find.text(stat['value'] as String),
          findsOneWidget,
          reason: stat['value'] as String,
        );
      }
      // The greeting must not be a count any more.
      expect(find.text('25+'), findsNothing);
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

    testWidgets('the footer carries no coordinate readout', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.expanded);

      // This test asserted the opposite until milestone 4. The footer derived
      // a latitude from the one career role with no end date -- Evri, which
      // career.json puts at 53.4808 -- and printed it at the trailing edge.
      // Task 4.9 removed it on the owner's instruction: being introduced by a
      // map reference is the opposite of what the site is now for.
      //
      // Inverted rather than deleted. A removed feature with no test is a
      // feature a future agent reinstates, having found the painter still
      // there and no record of why it went.
      expect(find.textContaining('lat '), findsNothing);
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

      // The fallback carries the owner's own name, so this is a hero, not an
      // error state. fallback.json has no displayName, so this also proves
      // shownName falls back to the legal name rather than rendering nothing.
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
      expect(find.text(_shownName()), findsOneWidget);
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
      expect(find.text(_shownName()), findsOneWidget);
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
    testWidgets('the hero aligns to a frame that is centred on a wide screen', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      final rail = tester.getRect(find.byType(AppRail));
      final scaffold = tester.getRect(find.byType(ChromeScaffold));
      final hero = tester.getRect(find.byType(HeroContent));

      // The design system said "everything left-aligned to the rail, nothing
      // centred", and the owner overruled it: on a wide monitor that left the
      // page pinned to one edge with a third of the screen empty beside it.
      //
      // Content is capped and centred now. The hero still aligns to the frame
      // rather than being centred within it -- the copy is left-aligned, as it
      // always was -- but the frame no longer starts at the rail.
      final available = scaffold.width - rail.width;
      final frame = math.min(available, Tokens.contentMaxWidth);
      final expected =
          rail.right + (available - frame) / 2 + Tokens.largeGutter;

      expect(hero.left, closeTo(expected, 1));
      expect(
        hero.left,
        greaterThan(rail.right),
        reason: 'the frame never reaches under the rail',
      );
    });

    testWidgets('the frame stops growing on a very wide monitor', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(2560, 1400);
      addTearDown(tester.view.reset);

      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      // Uncapped, a 2560px window stretched the page until it had no shape.
      final hero = tester.getRect(find.byType(HeroContent));
      expect(hero.width, lessThanOrEqualTo(Tokens.contentMaxWidth));
    });

    testWidgets('there is no rule under the name any more', (tester) async {
      // Removed on the owner's instruction. Asserted rather than deleted,
      // because the rule was a deliberate mark for several milestones and a
      // future reader would otherwise reasonably put it back.
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      expect(
        find.descendant(
          of: find.byType(HeroContent),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox && widget.width == Tokens.heroRuleWidth,
          ),
        ),
        findsNothing,
      );
    });
  });
}

/// The name the hero is expected to draw, from the content it draws it from.
///
/// The owner changed the shown name from "Sherbini" to his full name for
/// consistency across the site. Asserting the literal made that a test failure
/// rather than a content edit.
String _shownName() {
  final profile = bundledJson('assets/content/profile.json');
  final display = profile['displayName'] ?? profile['name'];
  return (display as Map<String, dynamic>)['en'] as String;
}
