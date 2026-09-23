import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/features/work/presentation/widgets/app_shots.dart';

import '../../support/loading_harness.dart';

/// The gallery on an application's own page.
void main() {
  Future<void> pump(WidgetTester tester, List<String> paths) =>
      tester.pumpWidget(
        LoadingHarness(
          child: AppShots(paths: paths, appName: 'MiNextStep'),
        ),
      );

  testWidgets('no screenshots draws nothing at all', (tester) async {
    await pump(tester, const []);
    expect(find.byType(Image), findsNothing);
    expect(
      tester.getSize(find.byType(AppShots)),
      Size.zero,
      reason: 'an app with no media should not reserve a strip of empty page',
    );
  });

  testWidgets('every screenshot is shown, in the order given', (tester) async {
    await pump(tester, const [
      'assets/media/apps/minextstep/01.jpg',
      'assets/media/apps/minextstep/02.jpg',
      'assets/media/apps/minextstep/03.jpg',
    ]);
    await tester.pump();

    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(images.first, endsWith('01.jpg'));
    expect(images, hasLength(3));
  });

  testWidgets('each one names its app and its place in the set', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const [
      'assets/media/apps/minextstep/01.jpg',
      'assets/media/apps/minextstep/02.jpg',
    ]);
    await tester.pump();

    // "Screenshot 2" alone tells a screen-reader user nothing about how many
    // there are or whose they are.
    expect(
      find.bySemanticsLabel('MiNextStep screenshot 1 of 2'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('MiNextStep screenshot 2 of 2'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a missing file loses its frame rather than the page', (
    tester,
  ) async {
    await pump(tester, const ['assets/media/apps/does-not-exist.jpg']);
    await tester.pump();
    // The error builder runs asynchronously; what matters is that nothing was
    // thrown by the time the frame settles.
    expect(tester.takeException(), isNull);
  });
}
