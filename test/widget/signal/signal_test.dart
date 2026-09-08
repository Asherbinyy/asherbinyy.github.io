import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
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
      // Counted from the journey rather than written here. Milestone 4 added
      // the two study stops and removed Evri, and a literal would have had to
      // be edited for each.
      expect(map.stations, hasLength(bundledStops().length));
      expect(map.selectedIndex, -1);
    });

    testWidgets('a stop the content gives no weight is drawn minor', (
      tester,
    ) async {
      await _pumpSignal(tester);

      final map = tester.widget<PropagationMap>(find.byType(PropagationMap));

      // The rule, not one station: a stop carrying neither a burst weight nor
      // any shipped application is drawn small. This asserted Evri until
      // milestone 4 removed that role, which is exactly why it now checks
      // every stop against the content instead of naming one.
      for (final stop in bundledStops()) {
        final station = map.stations.firstWhere((s) => s.id == stop['id']);
        final hasWeight = stop['traceWeight'] != null;
        final hasApps = (stop['appIds'] as List<dynamic>? ?? []).isNotEmpty;
        expect(
          station.isMinor,
          !hasWeight && !hasApps,
          reason: '${stop['id']}',
        );
      }
    });

    testWidgets('carries the coordinates the content states', (tester) async {
      await _pumpSignal(tester);

      final map = tester.widget<PropagationMap>(find.byType(PropagationMap));

      // Every stop, against the coordinates the content states -- rather than
      // one station's pair copied into the test.
      for (final stop in bundledStops()) {
        final station = map.stations.firstWhere((s) => s.id == stop['id']);
        final coords = (stop['coords'] as List<dynamic>).cast<num>();
        expect(station.latitude, coords[0], reason: '${stop['id']}');
        expect(station.longitude, coords[1], reason: '${stop['id']}');
      }
    });

    testWidgets('renders bundled land outlines without a map request', (
      tester,
    ) async {
      await _pumpSignal(tester);

      final map = tester.widget<PropagationMap>(find.byType(PropagationMap));
      expect(map.coastlines.length, greaterThan(100));
    });

    testWidgets('supports direct pan and pointer scroll zoom', (tester) async {
      await _pumpSignal(tester);
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final before = viewer.transformationController!.value.getMaxScaleOnAxis();
      final centre = tester.getCenter(find.byType(InteractiveViewer));

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: centre,
          scrollDelta: const Offset(0, -100),
        ),
      );
      await tester.pump();

      expect(viewer.panEnabled, isTrue);
      expect(viewer.scaleEnabled, isTrue);
      expect(viewer.trackpadScrollCausesScale, isTrue);
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(before),
      );
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

      // The centre, not 20px from the left edge: milestone 4 put a step
      // button at each end, so the old point now lands on a control rather
      // than on the rail.
      final scrubber = tester.getRect(find.byType(ChronologyScrubber));
      await tester.tapAt(scrubber.center);
      await pumpFrames(tester);

      expect(
        tester
            .widget<PropagationMap>(find.byType(PropagationMap))
            .selectedIndex,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('the rail joins the stops into one line', (tester) async {
      await _pumpSignal(tester);

      // The rail is the whole point of the redesign and it is the one part
      // with no text to assert on, so it is checked by its geometry. It
      // rendered zero pixels wide on the first pass -- a SizedBox with only a
      // height inside a Stack -- and every stop floated unconnected, which is
      // precisely the appearance the owner reported.
      final scrubber = tester.getRect(find.byType(ChronologyScrubber));
      final rails = find.descendant(
        of: find.byType(ChronologyScrubber),
        matching: find.byType(ColoredBox),
      );

      final widest = tester
          .widgetList<ColoredBox>(rails)
          .indexed
          .map((entry) => tester.getSize(rails.at(entry.$1)).width)
          .fold<double>(0, (a, b) => a > b ? a : b);

      expect(
        widest,
        greaterThan(scrubber.width / 2),
        reason: 'the rail should span the control, not collapse to nothing',
      );
    });

    testWidgets('the selected stop name is not clipped', (tester) async {
      await _pumpSignal(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      await tester.tap(find.bySemanticsLabel(l10n.signalNextStop));
      await pumpFrames(tester);

      // The name sits in a reserved box so selecting a stop does not shove the
      // map upward. That box reserved the font size, which is about two thirds
      // of a line, so the name was cut through its descenders the moment it
      // appeared -- the clipped text the owner reported.
      final first = bundledStops().first;
      final name = (first['company'] ?? first['city']) as String;
      final label = find.descendant(
        of: find.byType(ChronologyScrubber),
        matching: find.text(name),
      );
      expect(label, findsOneWidget);

      final painted = tester.getRect(label);
      final box = tester.renderObject<RenderBox>(label);
      expect(
        painted.height,
        greaterThanOrEqualTo(box.size.height),
        reason: 'the stop name is being clipped by its reservation',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the step controls walk the journey in order', (tester) async {
      await _pumpSignal(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      int selected() => tester
          .widget<PropagationMap>(find.byType(PropagationMap))
          .selectedIndex;

      // Nothing is selected to begin with, so the first press must land on the
      // first stop rather than doing nothing.
      expect(selected(), -1);
      await tester.tap(find.bySemanticsLabel(l10n.signalNextStop));
      await pumpFrames(tester);
      expect(selected(), 0);

      await tester.tap(find.bySemanticsLabel(l10n.signalNextStop));
      await pumpFrames(tester);
      expect(selected(), 1);

      await tester.tap(find.bySemanticsLabel(l10n.signalPreviousStop));
      await pumpFrames(tester);
      expect(selected(), 0);
    });

    testWidgets('the scrubber names the stop it has selected', (tester) async {
      await _pumpSignal(tester);
      final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

      // Before anything is chosen it says so, rather than showing a blank
      // line the viewer has to interpret.
      expect(find.text(l10n.signalScrubberHint), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(l10n.signalNextStop));
      await pumpFrames(tester);

      // The first stop is Mansoura University, which the content names.
      final first = bundledStops().first;
      final expected = (first['company'] ?? first['city']) as String;
      expect(
        find.descendant(
          of: find.byType(ChronologyScrubber),
          matching: find.text(expected),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the scrubber marks the career years', (tester) async {
      await _pumpSignal(tester);

      final scrubber = tester.widget<ChronologyScrubber>(
        find.byType(ChronologyScrubber),
      );

      expect(
        scrubber.marks,
        bundledStops()
            .map((stop) => (stop['start'] as String).split('-').first)
            .toList(),
      );
    });
  });

  group('the panel', () {
    testWidgets('shows only what the content records', (tester) async {
      await _pumpSignal(tester);
      await tester.tap(find.byType(PropagationMap));

      // Walk to CI Company by its position in the content. Selection starts at
      // -1, so reaching index i takes i + 1 presses. This pressed once and
      // assumed CI Company sat first, which stopped being true when the
      // journey gained a study stop ahead of the first job.
      final index = bundledStops().indexWhere((s) => s['id'] == 'ci-company');
      expect(index, isNonNegative);
      for (var i = 0; i <= index; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await pumpFrames(tester);
      }

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
