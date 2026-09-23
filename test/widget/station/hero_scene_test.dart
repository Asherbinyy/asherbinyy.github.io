import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/core/painting/hero_scene_painter.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_content.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_scene.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

final Finder _scenePaint = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is HeroScenePainter,
);

void main() {
  testWidgets('a desk-wide hero has its picture beside the copy', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    // The owner asked for the right of the hero to hold a picture that stands
    // for him, where the wall used to be.
    final copy = tester.getRect(find.byType(HeroContent));
    final picture = tester.getRect(find.byType(HeroScene));
    expect(picture.left, greaterThanOrEqualTo(copy.right));
    expect(picture.top, lessThan(copy.bottom), reason: 'on the same row');
  });

  testWidgets('a phone keeps the hero it had', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.compact,
      capabilities: touchBrowser,
    );

    // "On phone it looks fine": the copy keeps the width.
    expect(find.byType(HeroScene), findsNothing);
  });

  testWidgets('the light in the sky changes the theme', (tester) async {
    final container = await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      reducedMotion: true,
    );
    final before = container.read(themeControllerProvider);

    // The sun by day, the moon by night: either way, the one control in the
    // picture, and it does what the header's brazier does.
    await tester.tap(
      find.descendant(
        of: find.byType(HeroScene),
        matching: find.byType(InkWell),
      ),
    );
    await pumpFrames(tester);

    expect(container.read(themeControllerProvider), before.opposite);
  });

  testWidgets('under reduced motion the picture holds still', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      reducedMotion: true,
    );
    await tester.pump(const Duration(seconds: 2));

    final painter = tester.widget<CustomPaint>(_scenePaint).painter;
    if (painter is! HeroScenePainter) fail('Expected the scene painter');
    expect(painter.time, 0, reason: 'no stars, river or cursor moving');
    expect(painter.parallax, Offset.zero, reason: 'no depth following a hand');
  });
}
