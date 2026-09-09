import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';

import '../support/chrome_harness.dart';
import '../support/pump.dart';
import '../support/content_readers.dart';
import '../support/station_harness.dart';

/// The title the document actually ends up with.
///
/// Two `Title` widgets can be mounted at once — the app's, which stands in
/// before content resolves, and the route's once it has. The innermost wins,
/// and `find.byType` walks depth-first, so that is the last match.
String? effectiveTitle(WidgetTester tester) {
  final found = find.byType(Title).evaluate();
  if (found.isEmpty) return null;
  return (found.last.widget as Title).title;
}

void main() {
  group('the browser tab title', () {
    testWidgets('names the route and the person once content resolves', (
      tester,
    ) async {
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        initialRoute: AppRoute.writing,
      );

      expect(effectiveTitle(tester), contains(_shownName()));
    });

    testWidgets('never blanks the shell title while content is unavailable', (
      tester,
    ) async {
      // This was live: `Title` writes document.title unconditionally, so
      // mounting one with an empty string erased the hand-authored title from
      // web/index.html and left the tab blank. The fix is to mount no Title at
      // all until there is something true to say.
      await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        reader: corruptContent,
      );

      // The app-level Title stands in, carrying the same words as the shell.
      expect(effectiveTitle(tester), shellTitle);
    });

    testWidgets('the app title matches the shell it replaces', (tester) async {
      // Read from the file rather than repeated here, so the two cannot drift.
      final shell = File('web/index.html').readAsStringSync();

      expect(shell, contains('<title>$shellTitle</title>'));
    });

    testWidgets('changes on client-side navigation, not just a reload', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
      final onStation = effectiveTitle(tester);

      // Navigate within the running app rather than pumping a second one —
      // the claim is that the tab updates without a reload.
      GoRouter.of(tester.element(find.byType(ChromeScaffold)))
          .goNamed(AppRoute.work.name);
      await pumpFrames(tester);

      expect(effectiveTitle(tester), isNot(onStation));
      expect(effectiveTitle(tester), contains(_shownName()));
    });
  });
}

/// The name a title is expected to carry, read from the content.
String _shownName() {
  final profile = bundledJson('assets/content/profile.json');
  final display = profile['displayName'] ?? profile['name'];
  return (display as Map<String, dynamic>)['en'] as String;
}
