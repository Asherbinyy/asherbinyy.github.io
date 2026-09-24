import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/content/country_names.dart';
import 'package:nocturne/core/painting/wall_painter.dart';
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

  testWidgets('on a phone the wall is behind the whole page, faint', (
    tester,
  ) async {
    await pumpStation(
      tester,
      breakpoint: ChromeBreakpoint.compact,
      capabilities: touchBrowser,
    );

    // It used to keep a trailing strip that the page stopped short of, which
    // put everything against the left of a phone. The owner asked for the
    // phone centred, so the wall is the faint pattern behind the page there
    // too, and the copy has the whole width.
    final frame = tester.getRect(find.byType(ChromeScaffold));
    final painted = tester.getRect(_tracePaint);
    expect(painted.left, 0);
    expect(painted.width, frame.width);

    final wall = tester.widget<CustomPaint>(_tracePaint).painter;
    if (wall is! WallPainter) fail('Expected the wall painter');
    expect(wall.restAlpha, Tokens.wallPatternOpacity);
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

  testWidgets('on a desk the wall is the background of the whole page', (
    tester,
  ) async {
    await pumpStation(tester, breakpoint: ChromeBreakpoint.large);

    // The owner asked for the wall to stop filling the right-hand side of a
    // desk screen and to become the pattern behind everything, less visible,
    // with the right of the hero given to a picture. So it spans the window
    // rather than a column of it, and rests faint -- the torch still brings a
    // sign up to full gold.
    final scaffold = tester.getRect(find.byType(ChromeScaffold));
    final painted = tester.getRect(_tracePaint);
    expect(painted.left, 0);
    expect(painted.width, scaffold.width);

    final wall = tester.widget<CustomPaint>(_tracePaint).painter;
    if (wall is! WallPainter) fail('Expected the wall painter');
    expect(wall.restAlpha, Tokens.wallPatternOpacity);

    // No location cards: there is no clear ground beside the wall any more,
    // and each career card prints its own location.
    expect(find.byType(TraceBurstLabel), findsNothing);
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
      // The country is named, not coded: "Doha, Qatar", never "Doha, QA".
      expect(
        label.location,
        contains(CountryNames.of(stop['country'] as String, AppLocale.english)),
        reason: id,
      );
      expect(label.location, isNot(endsWith(stop['country'] as String)));
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

  testWidgets('reduced motion settles the trace', (tester) async {
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
  group('the wall covers the window at every desk width', () {
    // A background that stopped at the capped content frame left bare bands
    // down both sides of a wide monitor. Swept, because the frame is capped
    // and the widths either side of the cap behave differently.
    for (final width in [1024.0, 1280.0, 1440.0, 1600.0, 1920.0]) {
      testWidgets('at ${width.toInt()}px', (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);

        await pumpStation(tester, breakpoint: ChromeBreakpoint.large);
        await pumpFrames(tester);

        // Against the scaffold, which is the window the harness actually
        // laid out, rather than the number requested of it.
        final window = tester.getRect(find.byType(ChromeScaffold));
        final wall = tester.getRect(_tracePaint);
        expect(wall.left, window.left, reason: 'at ${width.toInt()}px');
        expect(wall.width, window.width, reason: 'at ${width.toInt()}px');
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

    // Off the page entirely. The wall is the whole background now, so the
    // only way to take the light off it is to leave the window.
    await hand.moveTo(const Offset(-50, -50));
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
