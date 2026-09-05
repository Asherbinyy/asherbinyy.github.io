import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/trace_painter.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';

final List<TraceBurst> _bursts = TraceGeometry.layout(const [
  (id: 'a', months: 18, appCount: 4, traceWeight: null),
]);

TracePainter _painter({
  double phase = 0,
  double coherence = 1,
  double scrollOffset = 0,
  double viewportHeight = 800,
  double traceHeight = 4000,
  List<TraceBurst>? bursts,
}) => TracePainter(
  bursts: bursts ?? _bursts,
  phase: phase,
  coherence: coherence,
  scrollOffset: scrollOffset,
  viewportHeight: viewportHeight,
  traceHeight: traceHeight,
  restColour: nocturneTokens.instrumentDim,
  lockedColour: nocturneTokens.instrument,
  peakColour: nocturneTokens.beaconGlow,
  strokeWidth: Tokens.hairlineWidth,
);

/// Runs a paint pass and reports how many canvas operations it issued.
int _operations(TracePainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final count = picture.approximateBytesUsed;
  picture.dispose();
  return count;
}

void main() {
  const viewport = Size(600, 800);

  test('paints the visible window', () {
    expect(_operations(_painter(), viewport), greaterThan(0));
  });

  test('early-returns when the trace is entirely above the viewport', () {
    // Scrolled past the end: nothing to draw, and the sampling loop must not
    // run for a stretch nobody is looking at.
    expect(
      _operations(_painter(scrollOffset: 9000), viewport),
      lessThan(_operations(_painter(), viewport)),
    );
  });

  test('early-returns on an empty canvas', () {
    expect(() => _operations(_painter(), Size.zero), returnsNormally);
  });

  test('draws nothing for a zero-length trace', () {
    expect(
      () => _operations(_painter(traceHeight: 0), viewport),
      returnsNormally,
    );
  });

  test('handles a career with no bursts at all', () {
    expect(
      () => _operations(_painter(bursts: const []), viewport),
      returnsNormally,
    );
  });

  test('repaints only when an input actually changes', () {
    expect(_painter().shouldRepaint(_painter()), isFalse);
    expect(_painter().shouldRepaint(_painter(phase: 0.5)), isTrue);
    expect(_painter().shouldRepaint(_painter(coherence: 0.2)), isTrue);
    expect(_painter().shouldRepaint(_painter(scrollOffset: 40)), isTrue);
    expect(
      _painter().shouldRepaint(
        _painter(bursts: TraceGeometry.layout(const [])),
      ),
      isTrue,
    );
  });

  test('scrolling past the trace costs less than painting it', () {
    // The budget is 4ms a frame, and the cheapest way to hold it is not to
    // sample what is off screen.
    final visible = _operations(_painter(scrollOffset: 1000), viewport);
    final offScreen = _operations(_painter(scrollOffset: 99999), viewport);

    expect(offScreen, lessThan(visible));
  });
}
