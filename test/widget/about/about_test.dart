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

      expect(find.text('In progress — predicted Distinction'), findsOneWidget);
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
