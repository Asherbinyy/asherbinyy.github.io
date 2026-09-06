import 'package:flutter/rendering.dart';

/// Draws the panel signature from section 4: a hairline edge with corner ticks.
///
/// The ticks sit outside the edge, which is why every panel reserves an inset
/// for them rather than letting the painter overflow its own bounds.
class CornerTicksPainter extends CustomPainter {
  /// [inset] is the space reserved for the ticks on all four sides.
  const CornerTicksPainter({
    required this.edgeColour,
    required this.tickColour,
    required this.strokeWidth,
    required this.tickLength,
    required this.inset,
  });

  /// Colour of the 1px structural rule.
  final Color edgeColour;

  /// Colour of the corner marks.
  final Color tickColour;

  /// Hairline stroke width.
  final double strokeWidth;

  /// Length of each arm of a corner mark.
  final double tickLength;

  /// Space between the widget bounds and the panel edge.
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final edge = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    if (edge.width <= 0 || edge.height <= 0) return;

    canvas.drawRect(
      edge.deflate(strokeWidth / 2),
      Paint()
        ..color = edgeColour
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final tick = Paint()
      ..color = tickColour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    // Each corner is an L opening away from the panel, offset outside the edge.
    for (final corner in <(Offset, double, double)>[
      (edge.topLeft, -1, -1),
      (edge.topRight, 1, -1),
      (edge.bottomLeft, -1, 1),
      (edge.bottomRight, 1, 1),
    ]) {
      final (origin, dx, dy) = corner;
      final anchor = origin.translate(dx * inset, dy * inset);
      canvas
        ..drawLine(anchor, anchor.translate(-dx * tickLength, 0), tick)
        ..drawLine(anchor, anchor.translate(0, -dy * tickLength), tick);
    }
  }

  @override
  bool shouldRepaint(CornerTicksPainter oldDelegate) =>
      oldDelegate.edgeColour != edgeColour ||
      oldDelegate.tickColour != tickColour ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.tickLength != tickLength ||
      oldDelegate.inset != inset;
}
