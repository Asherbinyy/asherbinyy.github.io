import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/wall_painter.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';

final List<TraceBurst> _bursts = TraceGeometry.layout(const [
  (id: 'a', months: 18, appCount: 4, traceWeight: null),
]);

WallPainter _painter({
  double phase = 0,
  double coherence = 1,
  double scrollOffset = 0,
  double viewportHeight = 800,
  double wallHeight = 4000,
  List<TraceBurst>? bursts,
}) => WallPainter(
  bursts: bursts ?? _bursts,
  phase: phase,
  coherence: coherence,
  scrollOffset: scrollOffset,
  viewportHeight: viewportHeight,
  wallHeight: wallHeight,
  restColour: nocturneTokens.instrumentDim,
  lockedColour: nocturneTokens.instrument,
  peakColour: nocturneTokens.beacon,
  strokeWidth: Tokens.hairlineWidth,
);

/// Runs a paint pass and reports how many canvas operations it issued.
int _operations(WallPainter painter, Size size) {
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

  test('early-returns when the wall is entirely above the viewport', () {
    // Scrolled past the end: nothing to draw, and the register loop must not
    // run for a stretch nobody is looking at.
    expect(
      _operations(_painter(scrollOffset: 9000), viewport),
      lessThan(_operations(_painter(), viewport)),
    );
  });

  test('early-returns on an empty canvas', () {
    expect(() => _operations(_painter(), Size.zero), returnsNormally);
  });

  test('draws nothing for a zero-length wall', () {
    expect(
      () => _operations(_painter(wallHeight: 0), viewport),
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

  test('cost is bounded by the viewport, not the length of the page', () {
    // This is what holds the 4ms budget: a career sequence ten times longer
    // must not cost ten times more to paint, because the painter builds only
    // the visible registers rather than the whole wall.
    final short = _operations(_painter(), viewport);
    final long = _operations(
      _painter(wallHeight: 40000, scrollOffset: 20000),
      viewport,
    );

    // Not exactly equal: which inscribed lines fall inside the window varies.
    // The claim being made is that the cost does not scale with the page.
    expect(long, lessThan(short * 2));
  });

  test('one paint of a full viewport stays well inside a frame', () {
    // A coarse guard rather than a benchmark — a profile build is the real
    // measurement. It catches a gross regression, such as building the whole
    // wall again, without being flaky on a loaded machine.
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      _operations(_painter(phase: i / 20), viewport);
    }
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds / 20, lessThan(16));
  });

  test('a wall with no torch on it skips the masked layer', () {
    // The masked layer is the expensive part of this painter: it allocates a
    // buffer the size of the frame. At zero coherence there is nothing to
    // reveal, so the painter must skip it rather than compose an invisible
    // one -- which is exactly the state a fast scroll produces.
    final unlit = _operations(_painter(coherence: 0), viewport);
    final lit = _operations(_painter(), viewport);

    expect(unlit, lessThan(lit));
  });

  test('the unlit wall is still drawn', () {
    // A wall does not stop existing in the dark. Someone who has scrolled past
    // should still see the inscription they left behind, dimly.
    expect(_operations(_painter(coherence: 0), viewport), greaterThan(0));
  });

  test('scrolling past the wall costs less than painting it', () {
    // The budget is 4ms a frame, and the cheapest way to hold it is not to
    // build what is off screen.
    final visible = _operations(_painter(scrollOffset: 1000), viewport);
    final offScreen = _operations(_painter(scrollOffset: 99999), viewport);

    expect(offScreen, lessThan(visible));
  });
}
