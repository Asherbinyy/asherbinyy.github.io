import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/about/presentation/widgets/contact_links.dart';
import 'package:nocturne/features/station/presentation/widgets/career_sequence.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/station_harness.dart';

void main() {
  for (final breakpoint in [ChromeBreakpoint.large, ChromeBreakpoint.compact]) {
    testWidgets('every career entry sits on a card (${breakpoint.name})', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: breakpoint,
        capabilities: breakpoint == ChromeBreakpoint.compact
            ? touchBrowser
            : pointerBrowser,
        reducedMotion: true,
      );

      // They were bare text over the wall; with the wall behind the whole
      // page, the owner asked for them to have a ground of their own.
      expect(
        find.descendant(
          of: find.byType(CareerSequence),
          matching: find.byType(InstrumentPanel),
        ),
        findsNWidgets(bundledStops().length),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home ends on one panel: the ask and the ways to reach him', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

    final panel = find.ancestor(
      of: find.text(l10n.homeServicesAction),
      matching: find.byType(InstrumentPanel),
    );
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.byType(ContactLinks)),
      findsOneWidget,
    );
  });
}
