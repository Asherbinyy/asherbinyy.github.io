import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/features/about/presentation/widgets/education_table.dart';
import 'package:nocturne/features/about/presentation/widgets/portrait_frame.dart';

import '../../support/chrome_harness.dart';
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
          of: find.byType(EducationTable),
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
            of: find.byType(EducationTable),
            matching: find.text(withheld),
          ),
          findsNothing,
          reason: '$withheld is below EducationTable.publishableMark',
        );
      }

      for (final published in ['94', '86', '81', '80']) {
        expect(
          find.descendant(
            of: find.byType(EducationTable),
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
