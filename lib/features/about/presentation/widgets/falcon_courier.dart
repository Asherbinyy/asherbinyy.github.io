import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/sign_paths.dart';

/// A falcon carrying a letter, beside the ways to reach him.
///
/// The owner found the contact panel plain beside everything else and asked
/// for something on its right. Horus's falcon is already the site's sign for
/// working on your own account, and a bird carrying a message is the oldest
/// picture of getting in touch there is: it flies an arc from the sender's
/// seal to the reader's, drops the letter, and goes round again. Only while
/// it can be seen; still, mid-flight, under reduced motion.
class FalconCourier extends StatefulWidget {
  /// Draws the courier.
  const FalconCourier({super.key});

  @override
  State<FalconCourier> createState() => _FalconCourierState();
}

class _FalconCourierState extends State<FalconCourier>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: Tokens.courierFlight,
  );
  final GlobalKey _key = GlobalKey(debugLabel: 'falcon-courier');
  ScrollController? _scroll;
  bool _isOnScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = ChromeScrollScope.maybeOf(context)?.controller;
    if (scroll != _scroll) {
      _scroll?.removeListener(_check);
      _scroll = scroll?..addListener(_check);
      if (scroll == null) _isOnScreen = true;
    }
    _update();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_check);
    _flight.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject();
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box is! RenderBox || !box.hasSize || viewport == null) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final onScreen = top + box.size.height > 0 && top < viewport.size.height;
    if (onScreen == _isOnScreen) return;
    _isOnScreen = onScreen;
    _update();
  }

  void _update() {
    if (ReducedMotion.of(context)) {
      _flight
        ..stop()
        ..value = 0.55;
      return;
    }
    if (_isOnScreen && !_flight.isAnimating) {
      _flight.repeat();
    } else if (!_isOnScreen && _flight.isAnimating) {
      _flight.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: SizedBox(
        key: _key,
        width: Tokens.courierWidth,
        height: Tokens.courierHeight,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _flight,
            builder: (context, _) => CustomPaint(
              painter: _CourierPainter(
                t: _flight.value,
                path: tokens.hairlineStrong,
                bird: tokens.beacon,
                glow: tokens.beaconGlow,
                seal: tokens.surfaceRaised,
                edge: tokens.hairlineStrong,
                strokeWidth: tokens.hairlineWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CourierPainter extends CustomPainter {
  const _CourierPainter({
    required this.t,
    required this.path,
    required this.bird,
    required this.glow,
    required this.seal,
    required this.edge,
    required this.strokeWidth,
  });

  /// Where the flight is, 0 to 1.
  final double t;
  final Color path;
  final Color bird;
  final Color glow;
  final Color seal;
  final Color edge;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final from = Offset(w * 0.14, h * 0.8);
    final to = Offset(w * 0.86, h * 0.8);
    final top = Offset(w * 0.5, h * 0.02);
    Offset at(double u) {
      final a = Offset.lerp(from, top, u)!;
      final b = Offset.lerp(top, to, u)!;
      return Offset.lerp(a, b, u)!;
    }

    // The two seals: where a message leaves and where it lands.
    for (final (centre, lit) in [(from, t < 0.12), (to, t > 0.86)]) {
      canvas
        ..drawCircle(centre, w * 0.07, Paint()..color = seal)
        ..drawCircle(
          centre,
          w * 0.07,
          Paint()
            ..color = lit ? bird : edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth * 1.5,
        );
      // An envelope in each.
      final env = Rect.fromCenter(
        center: centre,
        width: w * 0.07,
        height: w * 0.05,
      );
      final ink = Paint()
        ..color = lit ? bird : edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.2
        ..strokeJoin = StrokeJoin.round;
      canvas
        ..drawRect(env, ink)
        ..drawPath(
          Path()
            ..moveTo(env.left, env.top)
            ..lineTo(env.center.dx, env.center.dy)
            ..lineTo(env.right, env.top),
          ink,
        );
    }

    // The way, dotted, and the part already flown drawn stronger.
    final flight = t.clamp(0.08, 0.92);
    final u = (flight - 0.08) / 0.84;
    for (var i = 0; i <= 40; i++) {
      final v = i / 40;
      canvas.drawCircle(
        at(v),
        strokeWidth * (v <= u ? 1.6 : 1),
        Paint()..color = v <= u ? bird.withValues(alpha: 0.7) : path,
      );
    }

    // The falcon, banking along the arc, the letter under it.
    final here = at(u);
    final ahead = at(math.min(1, u + 0.02)) - at(math.max(0, u - 0.02));
    final angle = math.atan2(ahead.dy, ahead.dx) * 0.4;
    final box = w * 0.2;
    final flap = math.sin(t * math.pi * 16) * 0.08;
    canvas
      ..drawCircle(
        here,
        box * 0.7,
        Paint()
          ..shader = RadialGradient(
            colors: [glow.withValues(alpha: 0.25), glow.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: here, radius: box * 0.7)),
      )
      ..save()
      ..translate(here.dx, here.dy)
      ..rotate(angle)
      ..scale(1, 1 - flap)
      ..translate(-box / 2, -box / 2)
      ..drawPath(SignPaths.of(Sign.falcon, box), Paint()..color = bird)
      ..restore()
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: here + Offset(0, box * 0.55),
            width: box * 0.34,
            height: box * 0.22,
          ),
          Radius.circular(box * 0.03),
        ),
        Paint()..color = glow,
      );
  }

  @override
  bool shouldRepaint(_CourierPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.path != path ||
      oldDelegate.bird != bird ||
      oldDelegate.glow != glow ||
      oldDelegate.seal != seal ||
      oldDelegate.edge != edge ||
      oldDelegate.strokeWidth != strokeWidth;
}
