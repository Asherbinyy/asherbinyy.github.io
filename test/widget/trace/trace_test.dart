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

  testWidgets('one burst per career role', (tester) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    final trace = tester.widget<TelemetryTrace>(find.byType(TelemetryTrace));

    // career.json carries six stations.
    expect(trace.bursts, hasLength(6));
    expect(trace.labels, hasLength(6));
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

    // CI Company is the one role with a company name; the rest fall back to
    // their city rather than to an invented employer.
    expect(labels['ci-company']?.title, 'CI Company');
    expect(labels['hwzn-tech']?.title, 'Riyadh');
    expect(labels['evri']?.meta, contains('GB'));
    for (final label in labels.values) {
      expect(label.title, isNotEmpty);
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
