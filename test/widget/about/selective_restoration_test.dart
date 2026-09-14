import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nocturne/app/app_route.dart';

import '../../support/chrome_harness.dart';

import 'package:nocturne/core/painting/interest_painter.dart';
import 'package:nocturne/features/about/presentation/widgets/education_table.dart';
import 'package:nocturne/features/writing/data/writing_providers.dart';

import '../../support/station_harness.dart';

void main() {
  testWidgets('education details collapse and reopen without losing evidence', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.about,
      reducedMotion: true,
      overrides: [articlesProvider.overrideWith((_) async => [])],
    );
    // Entries arrive closed now, so the cycle this covers starts by opening
    // one rather than by collapsing an entry the page had opened by itself.
    final open = find.text('Show coursework & highlights').first;
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byKey(EducationTable.modulesKey), findsOneWidget);

    final collapse = find.text('Hide details').first;
    await tester.ensureVisible(collapse);
    await tester.tap(collapse);
    await tester.pumpAndSettle();
    expect(find.byKey(EducationTable.modulesKey), findsNothing);

    await tester.tap(find.text('Show coursework & highlights').first);
    await tester.pumpAndSettle();
    expect(find.byKey(EducationTable.modulesKey), findsOneWidget);
    expect(find.textContaining('Edumundo'), findsOneWidget);
  });

  testWidgets('football tap honors reduced motion and can be replayed', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      initialRoute: AppRoute.courtyard,
      reducedMotion: true,
    );
    final scene = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter is InterestPainter &&
          (w.painter! as InterestPainter).scene == InterestScene.football,
    );
    await tester.ensureVisible(scene);
    await tester.tap(scene);
    await tester.pump();
    expect(
      (tester.widget<CustomPaint>(scene).painter! as InterestPainter).progress,
      1,
    );
    final shout = find
        .ancestor(of: find.text('G O A L'), matching: find.byType(Opacity))
        .first;
    expect(tester.widget<Opacity>(shout).opacity, 1);
    await tester.tap(scene);
    await tester.pump();
    expect(
      (tester.widget<CustomPaint>(scene).painter! as InterestPainter).progress,
      1,
    );
  });
}
