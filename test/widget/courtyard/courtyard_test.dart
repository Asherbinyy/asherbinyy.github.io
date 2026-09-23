import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';

import '../../support/chrome_harness.dart';
import '../../support/station_harness.dart';

final Finder _still = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is AscentPainter,
);

void main() {
  testWidgets('the unfinished second game is off the shelf', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.courtyard,
    );

    // The owner agreed the placeholder for a game nobody had decided on
    // should go. Asserted on its old words, so it cannot quietly return.
    expect(find.textContaining('second game is coming'), findsNothing);
  });

  testWidgets('the climb says where it comes from', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.courtyard,
    );
    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

    expect(find.text(l10n.courtyardGameInspiration), findsOneWidget);
  });

  testWidgets('a wide courtyard shows a still of the climb', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.courtyard,
    );

    // One frame of a fresh run beside the offer, drawn by the game's own
    // painter -- nothing is started by visiting the page.
    expect(_still, findsOneWidget);
  });

  testWidgets('a phone gets the words and the buttons', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.compact,
      capabilities: touchBrowser,
      initialRoute: AppRoute.courtyard,
    );

    expect(_still, findsNothing);
  });
}
