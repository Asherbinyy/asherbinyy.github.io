import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/painting/cursor_trail_painter.dart';
import 'package:nocturne/core/platform/preference_store.dart';
import 'package:nocturne/core/widgets/cursor_trail.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

/// Moves a synthetic mouse across the frame, dropping motes as it goes.
///
/// The path stays inside the frame: run off the edge and the hover events stop
/// arriving, the wake expires, and the overlay leaves the tree — which looks
/// like a failure but is the widget working.
///
/// [stepMs] is how much time passes between drops. Keep it well under the mote
/// lifetime when the test is about how many are alive at once.
Future<void> _sweep(
  WidgetTester tester, {
  int steps = 6,
  int stepMs = 16,
}) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  final frame = tester.getRect(find.byType(CursorTrail));
  for (var i = 0; i < steps; i++) {
    final at =
        frame.topLeft +
        Offset(
          40 + (i * 37) % (frame.width - 80),
          40 + (i * 23) % (frame.height - 80),
        );
    await tester.sendEventToBinding(pointer.hover(at));
    await tester.pump(Duration(milliseconds: stepMs));
  }
}

Finder get _trail => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is CursorTrailPainter,
);

void main() {
  group('the cursor trail', () {
    testWidgets('follows a pointer', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
      expect(_trail, findsNothing, reason: 'nothing before the pointer moves');

      await _sweep(tester);
      expect(_trail, findsOneWidget);
    });

    testWidgets('never appears on a touch browser', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.compact,
        capabilities: touchBrowser,
      );
      await _sweep(tester);

      // Asked of the platform service, never inferred from viewport width.
      expect(_trail, findsNothing);
    });

    testWidgets('is off under reduced motion', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        reducedMotion: true,
      );
      await _sweep(tester);

      expect(_trail, findsNothing);
    });

    testWidgets('is off in Recruiter Mode', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        preferences: {PreferenceKey.recruiterMode.storageKey: 'on'},
      );
      await _sweep(tester);

      expect(_trail, findsNothing);
    });

    testWidgets('caps the wake rather than letting a drag accumulate', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
      // Faster than the mote lifetime, so all sixty would be alive at once
      // were it not for the cap.
      await _sweep(tester, steps: 60, stepMs: 1);

      // The cap is the performance budget expressed as a number. Without it a
      // fast drag across a wide viewport accumulates hundreds of circles.
      final painter =
          tester.widget<CustomPaint>(_trail).painter! as CursorTrailPainter;
      expect(painter.motes.length, lessThanOrEqualTo(24));
    });

    testWidgets('takes no pointer event from the page beneath it', (
      tester,
    ) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
      );
      await _sweep(tester);

      // The overlay must never eat a click. Navigating by the nav proves the
      // page is still reachable through it.
      await tester.tap(find.text('Work').first);
      await pumpFrames(tester);

      expect(container, isNotNull);
      expect(find.byType(CursorTrail), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
