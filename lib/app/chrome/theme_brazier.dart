import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// The theme control: a brazier that is lit or has been put out.
///
/// It used to be a half-filled circle, which is the standard glyph and says
/// nothing about this site. A temple is lit by fire, so the switch between
/// night and day is a bowl of it catching or going out, and the flame keeps
/// moving while it burns so the control is alive rather than a state icon.
///
/// Under reduced motion the flame is drawn at rest instead: still legible as
/// fire, with nothing flickering.
class ThemeBrazier extends StatefulWidget {
  /// [isLit] is true in the daylight theme.
  const ThemeBrazier({required this.isLit, required this.colour, super.key});

  /// Whether the fire is burning.
  final bool isLit;

  /// The ink the bowl is drawn in.
  final Color colour;

  @override
  State<ThemeBrazier> createState() => _ThemeBrazierState();
}

class _ThemeBrazierState extends State<ThemeBrazier>
    with TickerProviderStateMixin {
  /// Runs forever while lit: the flicker.
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Runs once per change: the catching or the going out.
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: widget.isLit ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isLit) _flicker.repeat();
  }

  @override
  void didUpdateWidget(ThemeBrazier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLit == oldWidget.isLit) return;
    if (widget.isLit) {
      _flicker.repeat();
      _strike.forward();
    } else {
      // The flame collapses first and the flicker stops with it, so a dying
      // fire is not still dancing on its way out.
      _strike.reverse().whenComplete(_flicker.stop);
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    _strike.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isReduced = ReducedMotion.of(context);

    return SizedBox(
      width: tokens.space24,
      height: tokens.space24,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flicker, _strike]),
        builder: (context, _) => CustomPaint(
          painter: _BrazierPainter(
            // Held at rest rather than stopped at zero: an unlit-looking
            // flame under reduced motion would read as the wrong state.
            flicker: isReduced ? 0.5 : _flicker.value,
            lit: _strike.value,
            bowl: widget.colour,
            flame: tokens.beacon,
            core: tokens.beaconGlow,
            strokeWidth: Tokens.hairlineWidth * 1.6,
          ),
        ),
      ),
    );
  }
}

class _BrazierPainter extends CustomPainter {
  const _BrazierPainter({
    required this.flicker,
    required this.lit,
    required this.bowl,
    required this.flame,
    required this.core,
    required this.strokeWidth,
  });

  /// The endless loop, 0 to 1.
  final double flicker;

  /// How lit the fire is, 0 to 1.
  final double lit;

  final Color bowl;
  final Color flame;
  final Color core;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ink = Paint()
      ..color = bowl
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rim = h * 0.62;

    // The bowl: a shallow cup on a stem and a foot.
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.22, rim)
          ..quadraticBezierTo(w * 0.5, rim + h * 0.22, w * 0.78, rim)
          ..close(),
        ink,
      )
      ..drawLine(Offset(w * 0.5, rim + h * 0.16), Offset(w * 0.5, h * 0.9), ink)
      ..drawLine(Offset(w * 0.3, h * 0.9), Offset(w * 0.7, h * 0.9), ink);

    if (lit <= 0.01) {
      // Out: a thread of smoke leaving the bowl.
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.5, rim - h * 0.02)
          ..quadraticBezierTo(
            w * 0.62,
            rim - h * 0.18,
            w * 0.46,
            rim - h * 0.3,
          ),
        Paint()
          ..color = bowl.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.7
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Two sine waves at unrelated speeds: irregular enough that the eye does
    // not find the loop, and far cheaper than noise.
    final wobble =
        math.sin(flicker * math.pi * 2) * 0.5 +
        math.sin(flicker * math.pi * 6.3 + 1.1) * 0.5;
    final reach = h * (0.30 + 0.10 * wobble) * lit;
    final lean = w * 0.06 * wobble;
    final base = Offset(w * 0.5, rim + h * 0.02);

    Path tongue(double scale) => Path()
      ..moveTo(base.dx - w * 0.16 * scale, base.dy)
      ..quadraticBezierTo(
        base.dx - w * 0.14 * scale + lean,
        base.dy - reach * 0.62 * scale,
        base.dx + lean * 1.4,
        base.dy - reach * scale,
      )
      ..quadraticBezierTo(
        base.dx + w * 0.14 * scale + lean,
        base.dy - reach * 0.62 * scale,
        base.dx + w * 0.16 * scale,
        base.dy,
      )
      ..close();

    canvas
      ..drawPath(tongue(1), Paint()..color = flame.withValues(alpha: lit))
      ..drawPath(
        tongue(0.52),
        Paint()..color = core.withValues(alpha: lit * 0.9),
      );
  }

  @override
  bool shouldRepaint(_BrazierPainter oldDelegate) =>
      oldDelegate.flicker != flicker ||
      oldDelegate.lit != lit ||
      oldDelegate.bowl != bowl;
}
