import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// A light that runs round a panel's edge, the way a torch is carried round
/// a room.
///
/// The owner asked for the game's panel to have "some effect cool" on its
/// edges. A short arc of gold travels the border and a faint glow follows
/// it: the site's own gold, doing the job gold does here -- saying something
/// is live. Still, and simply a gold hairline, under reduced motion.
class GoldEdge extends StatefulWidget {
  /// Runs the light round [child].
  const GoldEdge({required this.child, this.radius = 0, this.inset, super.key});

  /// The panel.
  final Widget child;

  /// The corner radius of [child], so the light follows a rounded card.
  final double radius;

  /// How far inside [child]'s edge the light runs. Defaults to the corner
  /// ticks' offset, which is where an instrument panel's edge is drawn.
  final double? inset;

  @override
  State<GoldEdge> createState() => _GoldEdgeState();
}

class _GoldEdgeState extends State<GoldEdge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Tokens.goldEdgeLap,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReducedMotion.of(context)) {
      _run.stop();
    } else if (!_run.isAnimating) {
      _run.repeat();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isReduced = ReducedMotion.of(context);
    return CustomPaint(
      foregroundPainter: _EdgePainter(
        run: _run,
        gold: tokens.beacon,
        glow: tokens.beaconGlow,
        strokeWidth: tokens.hairlineWidth * 1.5,
        inset: widget.inset ?? tokens.cornerTickOffset,
        radius: widget.radius,
        isStill: isReduced,
      ),
      // Its own layer, so the light going round does not repaint the panel.
      child: RepaintBoundary(child: widget.child),
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.run,
    required this.gold,
    required this.glow,
    required this.strokeWidth,
    required this.inset,
    required this.radius,
    required this.isStill,
  }) : super(repaint: run);

  final Animation<double> run;
  final Color gold;
  final Color glow;
  final double strokeWidth;
  final double inset;
  final double radius;
  final bool isStill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(inset);
    if (rect.isEmpty) return;
    final edge = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (isStill) {
      canvas.drawRRect(
        edge,
        Paint()
          ..color = gold.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }
    final turn = run.value * math.pi * 2;
    final shader = SweepGradient(
      colors: [
        gold.withValues(alpha: 0),
        gold.withValues(alpha: 0),
        glow,
        gold.withValues(alpha: 0),
      ],
      stops: const [0, 0.72, 0.86, 1],
      transform: GradientRotation(turn),
    ).createShader(rect);
    canvas
      ..drawRRect(
        edge,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawRRect(
        edge,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.gold != gold ||
      oldDelegate.glow != glow ||
      oldDelegate.isStill != isStill ||
      oldDelegate.radius != radius ||
      oldDelegate.inset != inset ||
      oldDelegate.strokeWidth != strokeWidth;
}
