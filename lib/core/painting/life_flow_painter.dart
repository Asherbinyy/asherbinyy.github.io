import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The wires of the life loop on `/about`, laid out as an ankh, and the run
/// travelling along them.
///
/// Drawn the way an automation tool draws a workflow -- the owner asked for
/// something that looks like n8n -- and then, at his request, bent into the
/// ankh, the sign for life: the loop of it at the top, the crossbar, and the
/// stem. The run starts at the foot of the stem, where the day starts, and
/// goes up, out along the bar, round the loop, out along the bar again and
/// back down to the foot.
///
/// The nodes themselves are widgets laid over this, so they can take hover
/// and focus; this only draws the sign they sit on and what moves along it.
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

  /// How many nodes the loop has. The ankh has places for six.
  final int count;

  /// Where the run is, 0 to [count]: the whole part is the step, the rest
  /// how far through it. Each step executes its node, then carries the result
  /// along the sign to the next -- the last one back to the start.
  final double progress;

  /// A node's width and height.
  final double nodeSize;

  /// The sign where the run has not been.
  final Color wire;

  /// The sign where the run has already been.
  final Color done;

  /// The run itself.
  final Color packet;

  /// The light around it.
  final Color glow;

  /// Hairline stroke width, from tokens.
  final double strokeWidth;

  /// How much of a step its node spends executing before the result leaves.
  static const double executing = 0.35;

  /// The ankh's parts in a box of [size]: the loop's centre and radii, the
  /// crossbar's height and its two ends, and the foot of the stem.
  ///
  /// Drawn in a box of the sign's own proportions, centred, so a wide column
  /// gets a wider margin rather than a squashed ankh.
  static ({
    Offset loop,
    double rx,
    double ry,
    double bar,
    double left,
    double right,
    double foot,
  })
  ankhIn(Size size) {
    final width = math.min(size.width, size.height * 0.74);
    final x0 = (size.width - width) / 2;
    // High enough that the top node's edge meets the top of the box, level
    // with the first line of the words beside it: the owner asked for the
    // two to line up.
    final bar = size.height * 0.46;
    final ry = size.height * 0.2;
    return (
      loop: Offset(x0 + width * 0.5, bar - ry),
      rx: width * 0.24,
      ry: ry,
      bar: bar,
      left: x0 + width * 0.14,
      right: x0 + width * 0.86,
      foot: size.height * 0.81,
    );
  }

  /// The centre of node [index] in a loop of [count] in [size].
  ///
  /// Six places on the sign, in the order the run reaches them: the foot of
  /// the stem, the left end of the bar, the loop's left side, its top, its
  /// right side, the right end of the bar.
  static Offset centreOf(int index, int count, Size size) {
    final a = ankhIn(size);
    return switch (index % 6) {
      0 => Offset(a.loop.dx, a.foot),
      1 => Offset(a.left, a.bar),
      2 => Offset(a.loop.dx - a.rx, a.loop.dy),
      3 => Offset(a.loop.dx, a.loop.dy - a.ry),
      4 => Offset(a.loop.dx + a.rx, a.loop.dy),
      _ => Offset(a.right, a.bar),
    };
  }

  /// The way from node [index] to the next, along the sign.
  Path _wire(int index, Size size) {
    final a = ankhIn(size);
    final junction = Offset(a.loop.dx, a.bar);
    final loop = Rect.fromCenter(
      center: a.loop,
      width: a.rx * 2,
      height: a.ry * 2,
    );
    // Angles on the loop: its foot, where it meets the bar, is a quarter
    // turn; round clockwise from there to its left side, top and right.
    const quarter = math.pi / 2;
    return switch (index % 6) {
      // Up the stem, and out along the bar to the left.
      0 =>
        Path()
          ..moveTo(a.loop.dx, a.foot)
          ..lineTo(junction.dx, junction.dy)
          ..lineTo(a.left, a.bar),
      // Back along the bar and up into the loop.
      1 =>
        Path()
          ..moveTo(a.left, a.bar)
          ..lineTo(junction.dx, junction.dy)
          ..arcTo(loop, quarter, quarter, false),
      // Round the loop, a quarter at a time.
      2 => Path()..addArc(loop, math.pi, quarter),
      3 => Path()..addArc(loop, math.pi * 1.5, quarter),
      // Down the loop's right side, and out along the bar to the right.
      4 =>
        Path()
          ..addArc(loop, 0, quarter)
          ..lineTo(a.right, a.bar),
      // Back along the bar and down the stem to where the day starts.
      _ =>
        Path()
          ..moveTo(a.right, a.bar)
          ..lineTo(junction.dx, junction.dy)
          ..lineTo(a.loop.dx, a.foot),
    };
  }

  /// The whole sign, drawn once, as the ground the run travels on.
  Path _sign(Size size) {
    final a = ankhIn(size);
    return Path()
      ..addOval(
        Rect.fromCenter(center: a.loop, width: a.rx * 2, height: a.ry * 2),
      )
      ..moveTo(a.left, a.bar)
      ..lineTo(a.right, a.bar)
      ..moveTo(a.loop.dx, a.bar)
      ..lineTo(a.loop.dx, a.foot);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || count < 2) return;
    final step = progress.floor().clamp(0, count - 1);
    final through = progress - step;
    final isFinished = progress >= count;

    // The sign itself: a broad, faint band -- the ankh as a shape -- with
    // the wire running down its middle.
    final sign = _sign(size);
    canvas
      ..drawPath(
        sign,
        Paint()
          ..color = wire.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = nodeSize * 0.22
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        sign,
        Paint()
          ..color = isFinished ? done : wire
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.5
          ..strokeCap = StrokeCap.round,
      );
    if (isFinished) return;

    final travelled = Paint()
      ..color = done
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < step; index++) {
      canvas.drawPath(_wire(index, size), travelled);
    }

    // The result in transit, once its node has finished, with the wire lit
    // behind it as far as it has gone.
    if (through < executing) return;
    final leg = (through - executing) / (1 - executing);
    final metric = _wire(step, size).computeMetrics().firstOrNull;
    if (metric == null) return;
    final along = metric.length * leg;
    canvas.drawPath(metric.extractPath(0, along), travelled);
    final tangent = metric.getTangentForOffset(along);
    if (tangent == null) return;
    final at = tangent.position;
    canvas
      ..drawCircle(
        at,
        nodeSize * 0.24,
        Paint()
          ..shader = RadialGradient(
            colors: [glow.withValues(alpha: 0.5), glow.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: at, radius: nodeSize * 0.24)),
      )
      ..drawCircle(at, strokeWidth * 3.4, Paint()..color = packet);
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
