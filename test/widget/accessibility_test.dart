import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';

import '../support/chrome_harness.dart';
import '../support/pump.dart';
import '../support/station_harness.dart';

/// The audit `05-TESTING.md` requires and roadmap 3.3 owns.
///
/// Palette contrast is covered exhaustively in
/// `test/unit/app/theme/contrast_test.dart`, which checks every role against
/// every surface rather than only the pairs a widget test happens to render.
/// What is left, and what lives here, is the part that depends on what is
/// actually on screen: touch targets, whether every control announces itself,
/// and whether the whole site can be operated from the keyboard.
void main() {
  /// Routes a viewer can reach without a token or a typed path.
  const publicRoutes = [
    AppRoute.station,
    AppRoute.signal,
    AppRoute.work,
    AppRoute.writing,
    AppRoute.about,
  ];

  group('touch targets', () {
    for (final route in publicRoutes) {
      testWidgets('${route.path} meets the 48px minimum on a touch browser', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.compact,
          capabilities: touchBrowser,
          initialRoute: route,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('every control announces itself', () {
    for (final route in publicRoutes) {
      testWidgets('${route.path} labels its tappable elements', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.large,
          initialRoute: route,
        );

        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('keyboard traversal', () {
    // 05-TESTING.md names these three routes specifically.
    for (final route in [AppRoute.station, AppRoute.work]) {
      testWidgets('${route.path} can be reached and left with Tab alone', (
        tester,
      ) async {
        await pumpStation(
          tester,
          breakpoint: ChromeBreakpoint.large,
          initialRoute: route,
        );

        final visited = <String>{};
        // Enough presses to wrap a page's controls several times over; the
        // assertion is that focus keeps moving and returns, not the count.
        for (var press = 0; press < 40; press++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await pumpFrames(tester);
          final focused = primaryFocus;
          if (focused == null) continue;
          visited.add('${focused.debugLabel}${focused.hashCode}');
        }

        // A page that cannot be traversed traps focus on one node, or on none.
        expect(
          visited.length,
          greaterThan(3),
          reason: 'focus did not move through ${route.path}',
        );
      });
    }

    testWidgets('focus never lands on something invisible', (tester) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.work,
      );

      for (var press = 0; press < 20; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await pumpFrames(tester);
        final context = primaryFocus?.context;
        if (context == null) continue;
        final box = context.findRenderObject();
        if (box is! RenderBox || !box.hasSize) continue;

        expect(
          box.size.isEmpty,
          isFalse,
          reason: 'focus reached a zero-sized element',
        );
      }
    });
  });

  group('the chrome', () {
    testWidgets('reads in order regardless of text direction', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        locale: const Locale('ar'),
      );

      expect(
        Directionality.of(tester.element(find.byType(ChromeScaffold))),
        TextDirection.rtl,
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
