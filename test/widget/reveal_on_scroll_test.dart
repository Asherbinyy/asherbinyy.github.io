import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/core/widgets/reveal_on_scroll.dart';

import '../support/pump.dart';

/// Things that unroll into view must actually arrive.
///
/// The first version of `RevealOnScroll` listened for `ScrollNotification`.
/// It sits inside the scroll view, and notifications travel outward from the
/// scrollable, so the listener never fired, the clip never opened, and every
/// career entry below the fold rendered as blank page. Every test passed —
/// none of them scrolled.
void main() {
  /// A page with [count] revealing blocks, each a screen tall.
  Future<ScrollController> pumpPage(
    WidgetTester tester, {
    int count = 6,
  }) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final progress = ValueNotifier<double>(0);
    addTearDown(progress.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ChromeScrollScope(
          progress: progress,
          controller: controller,
          child: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                for (var i = 0; i < count; i++)
                  RevealOnScroll(
                    child: SizedBox(
                      key: ValueKey('block$i'),
                      height: 500,
                      child: Text('block $i'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
    return controller;
  }

  /// How far the block with [key] has been unrolled, 0 to 1.
  ///
  /// Read from the `Opacity` the reveal drives rather than from the clip: a
  /// clipped child keeps its size and paints nothing, so layout says nothing
  /// about whether it is on screen.
  double revealed(WidgetTester tester, String key) {
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(ValueKey(key), skipOffstage: false),
            matching: find.byType(Opacity),
          )
          .first,
    );
    return opacity.opacity;
  }

  testWidgets('what is already on screen is already revealed', (tester) async {
    await pumpPage(tester);
    // No animation on arrival: a page that unrolls its own first screen looks
    // like it is still loading when it is not.
    expect(revealed(tester, 'block0'), 1);
  });

  testWidgets('a block below the fold reveals once it is scrolled to', (
    tester,
  ) async {
    final controller = await pumpPage(tester);

    // A ListView builds lazily, so the block does not exist until the scroll
    // brings it close. Scrolling is the point of the test anyway.
    controller.jumpTo(2000);
    await pumpFrames(tester);
    expect(find.byKey(const ValueKey('block4')), findsOneWidget);

    expect(
      revealed(tester, 'block4'),
      greaterThan(0),
      reason: 'a block scrolled into view stayed clipped to nothing',
    );
  });

  testWidgets('outside the chrome it is simply there', (tester) async {
    // `/cv` and `/brief` have no scroll scope. Waiting for a scroll that can
    // never come would leave those pages blank.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RevealOnScroll(
            child: SizedBox(key: ValueKey('loose'), height: 100),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
    expect(revealed(tester, 'loose'), 1);
  });
}
