import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The wires of the life loop on `/about`: connectors between the nodes, the
/// dashed return from the last one to the first, and the run travelling
/// along them.
///
/// Drawn the way an automation tool draws a workflow -- the owner asked for
/// something that looks like n8n -- because that is the literal shape of the
/// thing it describes: a loop of steps that runs, finishes, and runs again.
/// The nodes themselves are widgets laid over this, so they can take hover
/// and focus; this only draws what connects them.
class LifeFlowPainter extends CustomPainter {
  /// Draws [count] nodes' worth of wiring with the run at [progress].
  const LifeFlowPainter({
    required this.count,
    required this.progress,
    required this.nodeSize,
    required this.wire,
    required this.done,
    required this.packet,
    required this.glow,
    required this.strokeWidth,
  });

  /// How many nodes the loop has.
  final int count;

  /// Where the run is, 0 to [count]: the whole part is the step, the rest
  /// how far through it. Each step executes its node, then carries the result
  /// down the next wire -- the last one back to the start.
  final double progress;

  /// A node's width and height.
  final double nodeSize;

  /// A wire the run has not reached.
  final Color wire;

  /// A wire the run has already travelled.
  final Color done;

  /// The run itself.
  final Color packet;

  /// The light around it.
  final Color glow;

  /// Hairline stroke width, from tokens.
  final double strokeWidth;

  /// How much of a step its node spends executing before the result leaves.
  static const double executing = 0.35;

  /// The centre of node [index] in a loop of [count] in [size].
  ///
  /// Down the column in a zigzag, which is how a tall workflow reads in an
  /// editor and leaves room for the wires to curve rather than stack.
  static Offset centreOf(int index, int count, Size size) {
    // Room above the first node for the return wire's lane, and below the
    // last for its name.
    final top = size.height * 0.12;
    final bottom = size.height * 0.88;
    final step = count > 1 ? (bottom - top) / (count - 1) : 0.0;
    final x = index.isEven ? size.width * 0.3 : size.width * 0.66;
    return Offset(x, top + index * step);
  }

  /// The wire from node [index] to the next, or back to the first.
  Path _wire(int index, Size size) {
    final from = centreOf(index, count, size);
    final isReturn = index == count - 1;
    if (isReturn) {
      // Out of the last node's side, up the edge, across above the first
      // node and down into its top: the first wire already leaves from its
      // side, and the two must not meet at one point.
      final to = centreOf(0, count, size);
      final edge = size.width * 0.95;
      final turn = nodeSize * 0.3;
      final lane = to.dy - nodeSize * 0.9;
      final start = from + Offset(nodeSize / 2, 0);
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(edge - turn, start.dy)
        ..quadraticBezierTo(edge, start.dy, edge, start.dy - turn)
        ..lineTo(edge, lane + turn)
        ..quadraticBezierTo(edge, lane, edge - turn, lane)
        ..lineTo(to.dx + turn, lane)
        ..quadraticBezierTo(to.dx, lane, to.dx, lane + turn)
        ..lineTo(to.dx, to.dy - nodeSize / 2);
    }
    // Out of the side that faces the next node, then down into its top. A
    // wire leaving from underneath ran straight through the node's own name.
    final to = centreOf(index + 1, count, size);
    final side = to.dx >= from.dx ? 1.0 : -1.0;
    final start = from + Offset(side * nodeSize / 2, 0);
    final end = to - Offset(0, nodeSize / 2);
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(end.dx, start.dy, end.dx, start.dy, end.dx, end.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || count < 2) return;
    final step = progress.floor().clamp(0, count - 1);
    final through = progress - step;

    for (var index = 0; index < count; index++) {
      final path = _wire(index, size);
      final travelled = index < step || (index == step && through >= 1);
      final paint = Paint()
        ..color = travelled ? done : wire
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round;
      if (index == count - 1) {
        _dashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
      _arrowhead(canvas, path, paint.color);
    }

    // The result in transit, once its node has finished.
    if (through < executing) return;
    final leg = (through - executing) / (1 - executing);
    final metric = _wire(step, size).computeMetrics().firstOrNull;
    if (metric == null) return;
    final tangent = metric.getTangentForOffset(metric.length * leg);
    if (tangent == null) return;
    final at = tangent.position;
    canvas
      ..drawCircle(
        at,
        nodeSize * 0.22,
        Paint()
          ..shader = RadialGradient(
            colors: [glow.withValues(alpha: 0.45), glow.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: at, radius: nodeSize * 0.22)),
      )
      ..drawCircle(at, strokeWidth * 3.2, Paint()..color = packet);
  }

  /// The return wire, dashed so it reads as "and again" rather than as a
  /// seventh step.
  void _dashed(Canvas canvas, Path path, Paint paint) {
    final dash = strokeWidth * 5;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash * 2) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  /// A small chevron where a wire enters its node.
  void _arrowhead(Canvas canvas, Path path, Color colour) {
    final metric = path.computeMetrics().lastOrNull;
    if (metric == null) return;
    final tip = metric.getTangentForOffset(metric.length);
    if (tip == null) return;
    final angle = tip.angle;
    final size = strokeWidth * 4;
    Offset rotate(double dx, double dy) => Offset(
      tip.position.dx + dx * math.cos(-angle) - dy * math.sin(-angle),
      tip.position.dy + dx * math.sin(-angle) + dy * math.cos(-angle),
    );
    canvas.drawPath(
      Path()
        ..moveTo(rotate(-size, -size * 0.7).dx, rotate(-size, -size * 0.7).dy)
        ..lineTo(tip.position.dx, tip.position.dy)
        ..lineTo(rotate(-size, size * 0.7).dx, rotate(-size, size * 0.7).dy),
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(LifeFlowPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.progress != progress ||
      oldDelegate.nodeSize != nodeSize ||
      oldDelegate.wire != wire ||
      oldDelegate.done != done ||
      oldDelegate.packet != packet ||
      oldDelegate.glow != glow ||
      oldDelegate.strokeWidth != strokeWidth;
}
