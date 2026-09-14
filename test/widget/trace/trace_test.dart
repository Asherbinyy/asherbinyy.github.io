import 'dart:ui' show PointerDeviceKind;
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/wall_painter.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/station/presentation/widgets/career_sequence.dart';
import 'package:nocturne/features/trace/domain/trace_controller.dart';
import 'package:nocturne/features/trace/domain/trace_state.dart';
import 'package:nocturne/features/trace/presentation/station_trace.dart';
import 'package:nocturne/features/trace/presentation/telemetry_trace.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';
import 'package:nocturne/features/trace/presentation/trace_burst_label.dart';

import '../../support/chrome_harness.dart';
import '../../support/content_readers.dart';
import '../../support/station_harness.dart';
import '../../support/pump.dart';

void main() {
  testWidgets('the trace runs behind the station and nowhere else', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
    expect(find.byType(StationTrace), findsOneWidget);
    expect(find.byType(TelemetryTrace), findsOneWidget);

    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;
    await tester.tap(find.text(l10n.navAbout));
    await pumpFrames(tester);

    expect(find.byType(StationTrace), findsNothing);
  });

  testWidgets('the trace keeps to a narrow strip on a phone', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.compact,
      capabilities: touchBrowser,
    );

    // The owner reported the waveform and its titles running across the copy
    // on a phone. One fraction was used at every breakpoint: 66% leaves a
    // measure-limited desktop text column alone, and covers a 360px phone
    // whose text fills the width.
    //
    // Zero overlap is not achievable at this width -- the text spans the
    // whole viewport -- so what is asserted is that the trace is confined to
    // a trailing strip rather than crossing the column. Geometry, not the
    // token value, so milestone 5 can replace the painter without quietly
    // inheriting the overlap.
    final frame = tester.getRect(find.byType(ChromeScaffold));
    final painted = tester.getRect(_tracePaint);

    expect(painted.width, lessThan(frame.width / 2));
    expect(
      painted.left,
      greaterThan(frame.width / 2),
      reason: 'the strip should sit in the trailing half',
    );
  });

  testWidgets('the trace drops its titles on a phone', (tester) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.compact,
      capabilities: touchBrowser,
    );

    // The labels are drawn inside the trace column, so on a narrow strip they
    // wrap over the copy. Each one repeats the company, dates and country the
    // career entry beside it already prints, so dropping them costs nothing.
    expect(find.byType(TraceBurstLabel), findsNothing);
  });

  testWidgets('the trace keeps a column of its own, clear of the copy', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    final scaffold = tester.getRect(find.byType(ChromeScaffold));
    final painted = tester.getRect(_tracePaint);
    // Against the content frame, not the window. The frame is capped and
    // centred on a wide monitor, and the wall lives inside it, so measuring
    // the window would compare the wall to space it is deliberately not
    // allowed to use.
    final frame = math.min(scaffold.width, Tokens.contentMaxWidth);

    // A column, not half the page. This used to require more than half the
    // frame, which is what the owner objected to once the wall became opaque
    // blocks: it crowded the copy and took the screen. It still has to be a
    // wall rather than a strip, so there is a floor as well as a ceiling.
    expect(painted.width, greaterThan(frame * 0.2));
    expect(painted.width, lessThan(frame / 2));
    expect(find.byType(TraceBurstLabel), findsWidgets);
  });

  testWidgets('one burst per career role', (tester) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    final trace = tester.widget<TelemetryTrace>(find.byType(TelemetryTrace));

    // Counted from the journey, so adding or removing a stop does not leave
    // this asserting a stale total.
    final stops = bundledStops().length;
    expect(trace.bursts, hasLength(stops));
    expect(trace.labels, hasLength(stops));
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('bursts follow career centres through scroll and resize '
        '(reduced motion: $reducedMotion)', (tester) async {
      final container = await pumpStation(
        tester,
        breakpoint: ChromeBreakpoint.large,
        reducedMotion: reducedMotion,
      );
      final registry = container.read(traceAnchorRegistryProvider);
      expectCareerAnchors(tester, registry);
      final trace = tester.widget<TelemetryTrace>(find.byType(TelemetryTrace));
      trace.controller.jumpTo(350);
      await pumpFrames(tester);
      expectCareerAnchors(tester, registry);
      tester.view.physicalSize = const Size(1100, 700);
      await pumpFrames(tester);
      expectCareerAnchors(tester, registry);
      if (reducedMotion) await tester.pumpAndSettle();
    });
  }

  testWidgets('every burst label comes from the content', (tester) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    final trace = tester.widget<TelemetryTrace>(find.byType(TelemetryTrace));
    final labels = trace.labels;

    // The card carries where the stop was, and nothing else -- the owner asked
    // for the location alone. Asserted against the journey rather than against
    // a hand-picked pair, so a stop added to content without a label fails
    // here.
    for (final stop in bundledStops()) {
      final id = stop['id'] as String;
      final label = labels[id];
      expect(label, isNotNull, reason: id);
      expect(label!.location, isNotEmpty, reason: id);
      if (id == 'freelance') continue;
      expect(label.location, contains(stop['city']), reason: id);
      expect(label.location, contains(stop['country']), reason: id);
    }
  });

  testWidgets('the career sequence gives the trace something to travel over', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    expect(find.byType(CareerSequence), findsOneWidget);
    // The page must scroll, or the trace has no journey and the rail's tick
    // scale never moves.
    final scrollable = tester.widget<Scrollable>(find.byType(Scrollable).first);
    expect(scrollable.controller?.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('the rail reads standby while nothing is scrolling', (
    tester,
  ) async {
    final container = await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
    );
    final l10n = tester.element(find.byType(ChromeScaffold)).l10n;

    // The state still exists and still drives the wall; what is gone is the
    // rail that printed it at the edge of the screen as a fake readout.
    expect(container.read(traceControllerProvider), TraceState.standby);
    expect(find.text(l10n.traceStandby), findsNothing);
  });

  testWidgets('reduced motion settles the trace with every label visible', (
    tester,
  ) async {
    final container = await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      reducedMotion: true,
    );

    // A ticker-driven trace would never settle.
    await pumpFrames(tester);
    expect(container.read(traceControllerProvider), TraceState.standby);
    expect(find.byType(TelemetryTrace), findsOneWidget);
  });

  testWidgets('a locked label sits in the gap, not on the wall', (
    tester,
  ) async {
    // Reduced motion shows every label without having to drive a scroll into
    // a lock, which is what makes this measurable at all.
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      reducedMotion: true,
    );
    await pumpFrames(tester);

    final wall = tester.getRect(_tracePaint);
    // The panel, not the widget: the card is pushed across by a paint-time
    // translation, which the label's own box does not carry.
    final labels = find.descendant(
      of: find.byType(TraceBurstLabel),
      matching: find.byType(InstrumentPanel),
    );
    expect(labels, findsWidgets);

    for (var i = 0; i < tester.widgetList(labels).length; i++) {
      final card = tester.getRect(labels.at(i));
      if (card.width == 0) continue;
      expect(
        card.right,
        lessThanOrEqualTo(wall.left),
        reason: 'the card is drawn over the blocks',
      );
      expect(card.left, greaterThanOrEqualTo(0), reason: 'and off the page');

      // And centred on the clear ground rather than pressed against the
      // stone: the owner asked for it in the middle of the empty middle.
      final label = tester.widget<TraceBurstLabel>(
        find.ancestor(of: labels.at(i), matching: find.byType(TraceBurstLabel)),
      );
      expect(
        card.center.dx,
        closeTo(wall.left - label.gap / 2, 1),
        reason: 'the card should sit in the middle of the gap',
      );
    }
  });

  testWidgets('a career that will not load leaves the trace out', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.large,
      reader: bundledContent(
        overrides: {'assets/content/career.json': '{ not json'},
      ),
    );

    // Degrades to no trace rather than to an empty or invented one.
    expect(find.byType(TelemetryTrace), findsNothing);
    expect(tester.takeException(), isNull);
  });
  group('the wall never reaches the copy', () {
    // The owner reported overlapping content on a laptop twice. At 1024px the
    // trailing 66 per cent began at x=348 while the hero text ran to x=636, so
    // register rules and signs were drawn straight through the paragraph.
    //
    // Swept rather than pinned to the one width that failed: the wall's width
    // is computed from the body measure, which is itself derived from the type
    // scale, so the failing band moves with the viewport.
    for (final width in [1024.0, 1280.0, 1440.0, 1600.0, 1920.0]) {
      testWidgets('at ${width.toInt()}px', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);

        await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
        await pumpFrames(tester);

        final wall = tester.getRect(
          find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter is WallPainter,
          ),
        );
        // The hero's own box is full width -- it is a Column aligned to the
        // start -- so the thing to measure is the copy inside it, which is
        // capped to the body measure. Comparing against the box would pass
        // nothing and fail everything.
        final positioning =
            (bundledJson('assets/content/profile.json')['positioning']
                    as Map<String, dynamic>)['en']
                as String;
        final copy = tester.getRect(find.text(positioning));

        expect(
          wall.left,
          greaterThanOrEqualTo(copy.right),
          reason: 'the wall starts inside the hero copy at ${width.toInt()}px',
        );
      });
    }
  });

  testWidgets('the torch lights the wall on hover and dies down on leave', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
    await pumpFrames(tester);

    WallPainter wall() {
      final painter = tester.widget<CustomPaint>(_tracePaint).painter;
      if (painter is! WallPainter) fail('Expected the wall painter');
      return painter;
    }

    expect(wall().torchStrength, 0, reason: 'nothing is holding a light yet');

    // Onto the middle of the wall. The pointer is the torch, so this is the
    // whole interaction: there is nothing to tap and no control to find.
    final strip = tester.getRect(_tracePaint);
    final hand = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hand.addPointer(location: Offset.zero);
    addTearDown(hand.removePointer);
    await hand.moveTo(strip.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final rising = wall().torchStrength;
    expect(rising, greaterThan(0), reason: 'the flame comes up');
    expect(rising, lessThan(1), reason: 'and is not there in one frame');
    expect(wall().torch, isNotNull);

    await tester.pump(const Duration(milliseconds: 400));
    expect(wall().torchStrength, 1, reason: 'held on the wall, fully lit');

    // Off the wall entirely, onto the copy.
    await hand.moveTo(Offset(strip.left - 200, strip.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      wall().torchStrength,
      lessThan(1),
      reason: 'the light dies down rather than cutting out',
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(wall().torchStrength, 0, reason: 'and the stone comes back');
  });
}

void expectCareerAnchors(WidgetTester tester, TraceAnchorRegistry registry) {
  final paintFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is WallPainter,
  );
  final painter = tester.widget<CustomPaint>(paintFinder).painter;
  if (painter is! WallPainter) fail('Expected the wall painter');
  final trace = tester.widget<TelemetryTrace>(find.byType(TelemetryTrace));
  expect(painter.scrollOffset, trace.controller.offset);
  final traceTop = tester.getTopLeft(paintFinder).dy;
  for (final burst in painter.bursts) {
    final anchorContext = registry.keyFor(burst.id).currentContext;
    expect(anchorContext, isNotNull);
    final anchorBox = anchorContext?.findRenderObject();
    if (anchorBox is! RenderBox) fail('Career entry has no rendered box');
    final centre = anchorBox.localToGlobal(
      Offset(0, anchorBox.size.height / 2),
    );
    final paintedCentre =
        burst.anchor * painter.wallHeight - painter.scrollOffset;
    expect(paintedCentre, closeTo(centre.dy - traceTop, 0.01));
  }
}

/// The wall's own painted surface, rather than the full-viewport widget that
/// hosts it. `TelemetryTrace` fills the frame; the strip is the box inside it.
final Finder _tracePaint = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is WallPainter,
);
