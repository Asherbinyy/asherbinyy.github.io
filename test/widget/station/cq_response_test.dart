import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/features/station/presentation/widgets/cq_response.dart';

import '../../support/chrome_harness.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

Future<void> type(WidgetTester tester, List<LogicalKeyboardKey> keys) async {
  for (final key in keys) {
    await tester.sendKeyEvent(key);
    await pumpFrames(tester);
  }
}

/// Lets the answer's dwell timer expire, so no test ends with one pending.
Future<void> settleAnswer(WidgetTester tester) async {
  await tester.pump(CqResponse.dwell);
  await pumpFrames(tester);
}

/// Opacity of the response, 0 when the station is quiet.
double answerOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(CqResponse),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  group('the station answers CQ', () {
    testWidgets('stays quiet until it is called', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      expect(find.byType(CqResponse), findsOneWidget);
      expect(answerOpacity(tester), 0);
    });

    testWidgets('answers when a viewer types CQ', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      await type(tester, [LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyQ]);

      expect(answerOpacity(tester), 1);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
      expect(find.text(l10n.stationCqResponse), findsOneWidget);

      await settleAnswer(tester);
    });

    testWidgets('ignores the letters apart', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      await type(tester, [
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyQ,
      ]);

      expect(answerOpacity(tester), 0);
    });

    testWidgets('restarts the call on a second C', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      // "ccq" still answers: the second C begins a fresh call rather than
      // poisoning the sequence.
      await type(tester, [
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyQ,
      ]);

      expect(answerOpacity(tester), 1);

      await settleAnswer(tester);
    });

    testWidgets('reserves its space so an answer reflows nothing', (
      tester,
    ) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
      final before = tester.getRect(find.byType(CqResponse));

      await type(tester, [LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyQ]);

      expect(tester.getRect(find.byType(CqResponse)), before);

      await settleAnswer(tester);
    });

    testWidgets('is not a stop on the keyboard tour', (tester) async {
      // The egg listens; it is not a control anyone should tab onto.
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

      for (var press = 0; press < 12; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await pumpFrames(tester);
        expect(primaryFocus?.debugLabel, isNot('cq listener'));
      }
    });

    testWidgets('goes quiet again on its own', (tester) async {
      await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
      await type(tester, [LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyQ]);
      expect(answerOpacity(tester), 1);

      await tester.pump(CqResponse.dwell);
      await pumpFrames(tester);

      expect(answerOpacity(tester), 0);
    });
  });
}
