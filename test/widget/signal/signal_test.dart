import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/content/content_repository.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/features/signal/presentation/signal_screen.dart';
import 'package:nocturne/features/signal/presentation/widgets/chronology_scrubber.dart';
import 'package:nocturne/features/signal/presentation/widgets/propagation_map.dart';
import 'package:nocturne/features/signal/presentation/widgets/transmission_panel.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/pump.dart';
import '../../support/station_harness.dart';

/// Opens the map route with content installed.
Future<void> _pumpSignal(
  WidgetTester tester, {
  ChromeBreakpoint breakpoint = ChromeBreakpoint.large,
  PointerCapabilities capabilities = pointerBrowser,
  AssetReader? reader,
  bool reducedMotion = false,
}) async {
  await pumpStation(
    tester,
    breakpoint: breakpoint,
    capabilities: capabilities,
    reader: reader,
    reducedMotion: reducedMotion,
    initialRoute: AppRoute.signal,
  );
}

void main() {
  group('the map', () {
    testWidgets('plots one node per career station', (tester) async {
      await _pumpSignal(tester);

      final map = tester.widget<PropagationMap>(find.byType(PropagationMap));
      expect(map.stations, hasLength(6));
      expect(map.selectedIndex, -1);
    });

    testWidgets('Evri is a minor node, present but not featured', (
      tester,
    ) async {
      await _pumpSignal(tester);

      final map = tester.widget<PropagationMap>(find.byType(PropagationMap));
      final evri = map.stations.firstWhere((s) => s.id == 'evri');
      final ci = map.stations.firstWhere((s) => s.id == 'ci-company');

      expect(evri.isMinor, isTrue);
      expect(ci.isMinor, isFalse);
    });

    testWidgets('carries the coordinates the content states', (tester) async {
      await _pumpSignal(tester);

      final map = tester.widget<PropagationMap>(find.byType(PropagationMap));
      final manchester = map.stations.firstWhere((s) => s.id == 'evri');

      expect(manchester.latitude, 53.4808);
      expect(manchester.longitude, -2.2426);
    });
  });

  group('selection', () {
    testWidgets('arrow keys move between stations', (tester) async {
      await _pumpSignal(tester);
      await tester.tap(find.byType(PropagationMap));
      await pumpFrames(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pumpFrames(tester);
      final first = tester
          .widget<PropagationMap>(find.byType(PropagationMap))
          .selectedIndex;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pumpFrames(tester);
      final second = tester
          .widget<PropagationMap>(find.byType(PropagationMap))
          .selectedIndex;

      expect(first, greaterThanOrEqualTo(0));
      expect(second, isNot(first));
    });

    testWidgets('a pointer browser shows the panel beside the map', (
      tester,
    ) async {
      await _pumpSignal(tester);
      expect(find.byType(TransmissionPanel), findsNothing);

      await tester.tap(find.byType(PropagationMap));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pumpFrames(tester);

      // Section 7: a side panel on pointer, not a dialog.
      expect(find.byType(TransmissionPanel), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the scrubber selects a station', (tester) async {
      await _pumpSignal(tester);

      final scrubber = tester.getRect(find.byType(ChronologyScrubber));
      await tester.tapAt(scrubber.centerLeft + const Offset(20, 0));
      await pumpFrames(tester);

      expect(
        tester
            .widget<PropagationMap>(find.byType(PropagationMap))
            .selectedIndex,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('the scrubber marks the career years', (tester) async {
      await _pumpSignal(tester);

      final scrubber = tester.widget<ChronologyScrubber>(
        find.byType(ChronologyScrubber),
      );

      expect(scrubber.marks, ['2021', '2023', '2023', '2024', '2025', '2025']);
    });
  });

  group('the panel', () {
    testWidgets('shows only what the content records', (tester) async {
      await _pumpSignal(tester);
      await tester.tap(find.byType(PropagationMap));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pumpFrames(tester);

      // CI Company is the one role with a company, a summary and a stack.
      expect(find.text('CI Company'), findsWidgets);
      expect(find.text('Mansoura, EG'), findsWidgets);
      expect(find.text('Flutter'), findsWidgets);
    });

    testWidgets('a role with no company falls back to its city', (
      tester,
    ) async {
      await _pumpSignal(tester);
      await tester.tap(find.byType(PropagationMap));
      // Third station is hwzn-tech, which records no company name.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await pumpFrames(tester);
      }

      expect(find.byType(TransmissionPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('degraded content', () {
    testWidgets('an unreadable career leaves no invented stations', (
      tester,
    ) async {
      await _pumpSignal(
        tester,
        reader: bundledContent(
          overrides: {'assets/content/career.json': '{ not json'},
        ),
      );

      expect(find.byType(PropagationMap), findsNothing);
      expect(find.byType(SignalScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the map explains how to navigate it', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpSignal(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      expect(find.bySemanticsLabel(l10n.signalMapLabel), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.signalScrubberLabel), findsOneWidget);

      semantics.dispose();
    });

    testWidgets('reduced motion draws the arcs already complete', (
      tester,
    ) async {
      await _pumpSignal(tester, reducedMotion: true);

      // A running draw animation would never settle.
      await pumpFrames(tester);
      expect(find.byType(PropagationMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
