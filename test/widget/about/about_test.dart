import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/features/about/presentation/widgets/education_table.dart';
import 'package:nocturne/features/about/presentation/widgets/interests_grid.dart';
import 'package:nocturne/features/about/presentation/widgets/portrait_frame.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/station_harness.dart';

void main() {
  group('the about page', () {
    testWidgets('lists MSc modules highest mark first', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      // The screen spec wants the strongest result to read first.
      final marks = <int>[];
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(EducationTable.modulesKey),
          matching: find.byType(Text),
        ),
      )) {
        final value = text.data;
        final mark = value == null ? null : int.tryParse(value);
        if (mark != null) marks.add(mark);
      }

      final descending = [...marks]..sort((a, b) => b.compareTo(a));
      expect(marks, isNotEmpty);
      expect(marks, orderedEquals(descending));
      expect(marks.first, 94);
    });

    testWidgets('publishes only modules at or above the threshold', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      // education.json keeps all seven marks, because that file is the record.
      // The owner asked for the page to carry his strongest results only, so
      // the filter is here rather than in the content -- and the three below
      // the line must genuinely not render, not merely be pushed down.
      for (final withheld in ['75', '72', '70']) {
        expect(
          find.descendant(
            of: find.byKey(EducationTable.modulesKey),
            matching: find.text(withheld),
          ),
          findsNothing,
          reason: '$withheld is below EducationTable.publishableMark',
        );
      }

      for (final published in ['94', '86', '81', '80']) {
        expect(
          find.descendant(
            of: find.byKey(EducationTable.modulesKey),
            matching: find.text(published),
          ),
          findsOneWidget,
          reason: '$published is at or above EducationTable.publishableMark',
        );
      }
    });

    testWidgets(
      'withholds the overall average while the award is unconfirmed',
      (tester) async {
        await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.large,
          initialRoute: AppRoute.about,
        );

        // education.json carries overallMark 79 with status "In progress". The
        // spec says no overall average until the award is confirmed, so the
        // value stays in the model and out of the page.
        expect(find.text('79'), findsNothing);
      },
    );

    testWidgets('states the status the content supplies', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      expect(find.textContaining('Distinction'), findsWidgets);
    });

    testWidgets('carries the Edumundo simulation line', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      expect(find.textContaining('Edumundo'), findsOneWidget);
    });

    testWidgets('reserves the portrait rather than inventing one', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      expect(find.byType(PortraitFrame), findsOneWidget);
    });

    testWidgets('renders the supplied portrait rather than the empty frame', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      // The owner supplied the photograph on 2026-09-07, closing an item open
      // since milestone 1. Asserting the pending label is gone is the half of
      // this that would catch a regression in the content path: the frame
      // itself renders either way, which is the point of the design, and so
      // its presence proves nothing.
      expect(find.byType(PortraitFrame), findsOneWidget);
      expect(find.text('Portrait pending'), findsNothing);
    });

    testWidgets('shows the coursework behind a mark, and opens it', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      // Only the modules the owner supplied an artefact for carry one, and
      // both of those are above the publish threshold, so both should render.
      final evidence = find.text('Power BI dashboard built for the module');
      expect(evidence, findsOneWidget);
      expect(
        find.text('Research poster: the AI e-waste crisis'),
        findsOneWidget,
      );

      // The evidence row sits below the fold on this page, so it has to be
      // scrolled to before it can be tapped. Tapped by its accessible name
      // rather than its caption: the card is one control and the caption is a
      // line inside it, so the label is what a person -- and a screen reader
      // -- actually activates.
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
      final card = find.bySemanticsLabel(
        l10n.aboutEvidenceOpen('Power BI dashboard built for the module'),
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      // The dialog carries the artefact and a way out of it.
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
    });

    testWidgets('a module with no artefact renders its mark alone', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      final withEvidence = bundledJson('assets/content/education.json');
      final modules =
          ((withEvidence['entries'] as List<dynamic>).first
                  as Map<String, dynamic>)['modules']
              as List<dynamic>;
      final bare = modules
          .cast<Map<String, dynamic>>()
          .where((m) => m['evidence'] == null && (m['mark'] as num) >= 80)
          .toList();

      // Cybersecurity at 81 publishes but has no artefact: the row must be
      // exactly as it was, not a gap where a thumbnail would go.
      expect(bare, isNotEmpty);
      for (final module in bare) {
        final name = (module['name'] as Map<String, dynamic>)['en'] as String;
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('lists every interest the content records', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      final interests =
          (bundledJson('assets/content/interests.json')['interests']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(interests, isNotEmpty);

      expect(find.byType(InterestsGrid), findsOneWidget);
      for (final interest in interests) {
        final label = (interest['label'] as Map<String, dynamic>)['en'];
        expect(
          find.descendant(
            of: find.byType(InterestsGrid),
            matching: find.text(label as String),
          ),
          findsOneWidget,
          reason: '${interest['id']}',
        );
      }
    });

    testWidgets('shows the specifics without needing a hover', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      // A fact worth putting on the page is worth a touch user and a screen
      // reader getting it. Hover adds emphasis here, never information -- so
      // the note must be on screen with no pointer anywhere near the tile.
      expect(find.text('Better Call Saul'), findsOneWidget);
      expect(find.text('FIFA and Valorant'), findsOneWidget);
    });

    testWidgets('keeps the interests out of the tab order', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.about,
      );

      // Nowhere for a tile to go, so it must not become six stops a keyboard
      // user has to pass through on the way to the contact links.
      expect(
        find.descendant(
          of: find.byType(InterestsGrid),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });

    testWidgets('stacks the portrait above the text on a narrow viewport', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.compact,
        initialRoute: AppRoute.about,
      );

      final portrait = tester.getRect(find.byType(PortraitFrame));
      final positioning = tester.getRect(
        find.textContaining('Mobile engineer'),
      );

      expect(portrait.bottom, lessThanOrEqualTo(positioning.top));
    });
  });
}
