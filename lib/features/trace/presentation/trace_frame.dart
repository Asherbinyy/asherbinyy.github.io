import 'package:flutter/foundation.dart';

/// One frame's worth of trace state, published without rebuilding the page.
@immutable
class TraceFrame {
  /// Captures scroll and carrier state for one repaint.
  const TraceFrame({
    required this.offset,
    required this.velocity,
    required this.coherence,
    this.phase = 0,
  });

  /// Document scroll offset in logical pixels.
  final double offset;

  /// Scroll speed in logical pixels per second.
  final double velocity;

  /// Signal coherence, from noise to lock.
  final double coherence;

  /// Normalised position in the idle carrier cycle.
  final double phase;
}
