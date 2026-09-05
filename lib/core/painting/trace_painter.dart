import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';

/// Paints the telemetry trace down the page.
///
/// One painted path, not a widget per point: section 6 is explicit about that,
/// and the budget is 4ms a frame. The painter samples only the visible window
/// and early-returns when the trace is entirely off-screen, so scrolling past
/// it costs nothing.
class TracePainter extends CustomPainter {
  /// [scrollOffset] and [viewportHeight] describe what is currently on screen;
  /// [traceHeight] is the whole trace's length in the same pixels.
  const TracePainter({
    required this.bursts,
    required this.phase,
    required this.coherence,
    required this.scrollOffset,
    required this.viewportHeight,
    required this.traceHeight,
    required this.restColour,
    required this.lockedColour,
    required this.peakColour,
    required this.strokeWidth,
  });

  /// Career bursts, already laid out.
  final List<TraceBurst> bursts;

  /// Carrier travel, 0..1 of a cycle.
  final double phase;

  /// How resolved the signal is, 0..1.
  final double coherence;

  /// Current scroll position in pixels.
  final double scrollOffset;

  /// Visible height in pixels.
  final double viewportHeight;

  /// The trace's whole length in pixels.
  final double traceHeight;

  /// Colour at rest and while scanning.
  final Color restColour;

  /// Colour under lock.
  final Color lockedColour;

  /// Burst peak colour under lock.
  final Color peakColour;

  /// Stroke width.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || traceHeight <= 0) return;

    // Off-screen entirely: nothing to draw, and the sampling loop would run
    // for a stretch nobody is looking at.
    final visibleTop = scrollOffset;
    final visibleBottom = scrollOffset + viewportHeight;
    if (visibleBottom <= 0 || visibleTop >= traceHeight) return;

    final centreX = size.width / 2;
    final amplitude = size.width * Tokens.traceAmplitude;
    // One sample per logical pixel of visible trace. Denser costs frames for a
    // curve nobody can see the extra detail in.
    final from = visibleTop.clamp(0.0, traceHeight);
    final to = visibleBottom.clamp(0.0, traceHeight);
    final samples = (to - from).ceil();
    if (samples <= 0) return;

    // Cycles are specified per screen, so the visible frequency is the same on
    // a short page and a long one.
    final cycles = viewportHeight <= 0
        ? Tokens.traceCycles
        : traceHeight / viewportHeight * Tokens.traceCycles;

    final path = Path();
    for (var i = 0; i <= samples; i++) {
      final y = from + i;
      final position = y / traceHeight;
      final value = TraceGeometry.sampleAt(
        position: position,
        phase: phase,
        coherence: coherence,
        bursts: bursts,
        cycles: cycles,
      );
      final point = Offset(centreX + value * amplitude, y - scrollOffset);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    // Section 6: the trace drifts to instrument-dim as it degrades and resolves
    // to instrument as it locks. One lerp carries the whole transition.
    final colour =
        Color.lerp(restColour, lockedColour, coherence) ?? restColour;
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (coherence < 1) return;
    // Under lock the burst peaks pick up the glow, which is the only place the
    // trace itself carries chroma.
    final peak = Paint()..color = peakColour;
    for (final burst in bursts) {
      final y = burst.anchor * traceHeight;
      if (y < from || y > to) continue;
      final value = TraceGeometry.sampleAt(
        position: burst.anchor,
        phase: phase,
        coherence: coherence,
        bursts: bursts,
        cycles: cycles,
      );
      canvas.drawCircle(
        Offset(centreX + value * amplitude, y - scrollOffset),
        strokeWidth,
        peak,
      );
    }
  }

  @override
  bool shouldRepaint(TracePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.coherence != coherence ||
      oldDelegate.scrollOffset != scrollOffset ||
      oldDelegate.viewportHeight != viewportHeight ||
      oldDelegate.traceHeight != traceHeight ||
      oldDelegate.restColour != restColour ||
      oldDelegate.lockedColour != lockedColour ||
      oldDelegate.peakColour != peakColour ||
      oldDelegate.strokeWidth != strokeWidth ||
      !identical(oldDelegate.bursts, bursts);
}
