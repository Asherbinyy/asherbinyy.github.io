import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// One mote in the cursor's wake.
@immutable
class TrailMote {
  /// [born] is the tick count when the mote was dropped.
  const TrailMote({required this.position, required this.born});

  /// Where the pointer was.
  final Offset position;

  /// Elapsed milliseconds at the moment it was dropped.
  final int born;
}

/// The pointer's wake.
///
/// `12-MOTIF-LIBRARY.md` §5. The owner asked for a cursor that "sparks some
/// magic"; what ships is a trail, and the distinction is the whole design.
///
/// **The system cursor is never replaced or hidden.** People run their own
/// pointer at their own size, with their own high-contrast and pointer-size
/// settings, and a drawn cursor silently breaks all of it. This draws beside
/// the real pointer and never instead of it.
class CursorTrailPainter extends CustomPainter {
  /// [now] is the elapsed milliseconds of the driving ticker.
  const CursorTrailPainter({
    required this.motes,
    required this.now,
    required this.colour,
    required this.lifetimeMs,
    required this.radius,
  });

  /// Live motes, oldest first.
  final List<TrailMote> motes;

  /// Current tick, in elapsed milliseconds.
  final int now;

  /// Mote colour before its own fade.
  final Color colour;

  /// How long a mote lives.
  final int lifetimeMs;

  /// A mote's radius at birth.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (motes.isEmpty) return;

    for (final mote in motes) {
      final age = (now - mote.born) / lifetimeMs;
      if (age < 0 || age >= 1) continue;
      // Quadratic rather than linear: a linear fade reads as a hard-edged
      // comet, and the tail should thin out rather than stop.
      final remaining = (1 - age) * (1 - age);
      canvas.drawCircle(
        mote.position,
        radius * remaining,
        Paint()..color = colour.withValues(alpha: remaining),
      );
    }
  }

  @override
  bool shouldRepaint(CursorTrailPainter oldDelegate) =>
      oldDelegate.now != now || oldDelegate.motes != motes;
}
