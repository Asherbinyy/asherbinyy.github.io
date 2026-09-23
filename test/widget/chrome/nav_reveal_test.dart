import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/app_nav.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';

/// The visible width of the phone nav row, as the viewer sees it.
Rect _navViewport(WidgetTester tester) {
  final scroller = find.ancestor(
    of: find.byType(AppNav),
    matching: find.byType(SingleChildScrollView),
  );
  return tester.getRect(scroller.first);
}

void main() {
  // On a phone the nav row is wider than the screen. On About and the
  // Courtyard the active link sat past the trailing edge, so the row showed no
  // page as current and a visitor lost their place.
  for (final path in ['/about', '/courtyard']) {
    testWidgets('the current link is in view on a phone at $path', (
      tester,
    ) async {
      await pumpChrome(tester, breakpoint: ChromeBreakpoint.compact);
      GoRouter.of(tester.element(find.byType(ChromeScaffold))).go(path);
      await pumpFrames(tester);

      final label = path == '/about' ? 'About' : 'Courtyard';
      final link = find.descendant(
        of: find.byType(AppNav),
        matching: find.text(label),
      );
      expect(link, findsOneWidget);

      final visible = _navViewport(tester);
      final rect = tester.getRect(link);
      expect(
        rect.left >= visible.left - 1 && rect.right <= visible.right + 1,
        isTrue,
        reason: '$label at $rect should sit inside the visible row $visible',
      );
    });
  }

  testWidgets('the first link is not scrolled away on Home', (tester) async {
    // Revealing the current link must not move a row that already shows it.
    await pumpChrome(tester, breakpoint: ChromeBreakpoint.compact);
    final visible = _navViewport(tester);
    final home = tester.getRect(
      find.descendant(of: find.byType(AppNav), matching: find.text('Home')),
    );
    expect(home.left >= visible.left - 1, isTrue);
  });
}
