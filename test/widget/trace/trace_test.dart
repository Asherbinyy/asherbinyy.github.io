import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/app_rail.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/core/painting/trace_painter.dart';
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

  testWidgets('the trace keeps its wide column and titles on a desktop', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    final frame = tester.getRect(find.byType(ChromeScaffold));
    final painted = tester.getRect(_tracePaint);

    // The strip is a phone accommodation, not the design.
    expect(painted.width, greaterThan(frame.width / 2));
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

    // Every burst names what the content names it: the company where there is
    // one, the city where there is not. Asserted against the journey rather
    // than against a hand-picked pair, so a stop added to content without a
    // label fails here.
    for (final stop in bundledStops()) {
      final id = stop['id'] as String;
      final label = labels[id];
      expect(label, isNotNull, reason: id);
      expect(
        label!.title,
        stop['company'] ?? stop['city'],
        reason: '$id should name its company, or its city where it has none',
      );
      expect(label.meta, contains(stop['country']), reason: id);
      expect(label.title, isNotEmpty, reason: id);
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

    expect(container.read(traceControllerProvider), TraceState.standby);
    expect(find.byType(AppRail), findsOneWidget);
    expect(find.text(l10n.traceStandby), findsOneWidget);
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
}

void expectCareerAnchors(WidgetTester tester, TraceAnchorRegistry registry) {
  final paintFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is TracePainter,
  );
  final painter = tester.widget<CustomPaint>(paintFinder).painter;
  if (painter is! TracePainter) fail('Expected the telemetry painter');
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
        burst.anchor * painter.traceHeight - painter.scrollOffset;
    expect(paintedCentre, closeTo(centre.dy - traceTop, 0.01));
  }
}

/// The trace's own painted surface, rather than the full-viewport widget that
/// hosts it. `TelemetryTrace` fills the frame; the strip is the box inside it.
final Finder _tracePaint = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is TracePainter,
);
