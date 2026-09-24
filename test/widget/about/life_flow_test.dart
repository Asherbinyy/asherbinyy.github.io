import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/painting/life_flow_painter.dart';
import 'package:nocturne/features/about/presentation/widgets/life_flow.dart';
import 'package:nocturne/features/about/presentation/widgets/portrait_frame.dart';

import '../../support/chrome_harness.dart';
import '../../support/station_harness.dart';

void main() {
  testWidgets('the loop sits beside the portrait on a wide screen', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
    );

    // The third of the page held open for "something that describes him".
    final portrait = tester.getRect(find.byType(PortraitFrame));
    final loop = tester.getRect(find.byType(LifeFlow));
    expect(loop.left, greaterThan(portrait.right));
    expect(loop.top, closeTo(portrait.top, 1));
  });

  testWidgets("every step is named, and only in the owner's words", (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
    );
    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

    for (final label in [
      l10n.aboutFlowWake,
      l10n.aboutFlowStudy,
      l10n.aboutFlowCode,
      l10n.aboutFlowApps,
      l10n.aboutFlowAutomate,
      l10n.aboutFlowGym,
    ]) {
      expect(
        find.descendant(of: find.byType(LifeFlow), matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('under reduced motion the loop is a finished run, still', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
    );
    await tester.pump(const Duration(seconds: 3));

    final painter = tester
        .widget<CustomPaint>(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint && widget.painter is LifeFlowPainter,
          ),
        )
        .painter;
    if (painter is! LifeFlowPainter) fail('Expected the loop painter');
    expect(painter.progress, painter.count, reason: 'every wire travelled');
    expect(
      find.descendant(
        of: find.byType(LifeFlow),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNWidgets(painter.count),
      reason: 'every node ticked',
    );
  });

  testWidgets('carries no caption on the ankh (the owner cut it)', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
    );

    expect(
      find.descendant(
        of: find.byType(LifeFlow),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').toLowerCase().contains('ankh'),
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('a screen reader hears the loop as one sentence', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
    );
    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

    expect(find.bySemanticsLabel(l10n.aboutFlowLabel), findsOneWidget);
    handle.dispose();
  });
}
