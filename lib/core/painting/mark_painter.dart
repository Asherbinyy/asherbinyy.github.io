import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/ankh_geometry.dart';

/// The mark: an ankh.
///
/// Design-system section 12 and `12-MOTIF-LIBRARY.md` #4. It was a frame
/// lifted from the telemetry trace's own curve while the concept was signal;
/// milestone 5 replaces the concept, so the mark changes with it.
///
/// The geometry is [AnkhGeometry], shared with `tool/generate_mark.dart` so
/// the rendered mark, `assets/brand/mark.svg` and the favicon set cannot
/// disagree. The old mark wrote its curve out twice, in the painter and in the
/// generator, with nothing to catch a drift between them.
class MarkPainter extends CustomPainter {
  /// [strokeWidth] normally comes from [strokeFor] so the mark keeps its
  /// specified weight at whatever size it is drawn.
  const MarkPainter({required this.colour, required this.strokeWidth});

  /// The specified stroke, scaled from the mark's native square.
  ///
  /// Section 12 fixes it at 2px on a 32px mark; the header draws it at 24px,
  /// and the favicon set at four more sizes, all from this one ratio.
  static double strokeFor(double size) =>
      size / Tokens.markNativeSize * Tokens.markStroke;

  /// The mark is the one place gold appears with no content around it.
  final Color colour;

  /// Stroke width at the rendered size.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Square, centred: the sign has a fixed aspect and stretching it to a
    // non-square box would thicken one axis of the stroke and not the other.
    final extent = math.min(size.width, size.height);
    final origin = Offset(
      (size.width - extent) / 2,
      (size.height - extent) / 2,
    );

    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (final stroke in AnkhGeometry.strokes(
      size: extent,
      strokeWidth: strokeWidth,
    )) {
      path.moveTo(origin.dx + stroke.first.x, origin.dy + stroke.first.y);
      for (final point in stroke.skip(1)) {
        path.lineTo(origin.dx + point.x, origin.dy + point.y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MarkPainter oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.strokeWidth != strokeWidth;
}
