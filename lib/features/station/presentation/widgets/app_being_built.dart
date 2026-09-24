import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// A phone whose app is being put together, a block at a time.
///
/// It stands beside "Got an app in mind?" at the end of Home, where the owner
/// found the panel's left side empty. It says what the question is offering
/// without another sentence: the screen starts as a plan -- dashed outlines,
/// the way the pyramid in the hero picture has its unbuilt top -- and each
/// part of the app drops into its place until the last one, the button,
/// lands in gold and the screen comes on. Then it clears and starts again.
///
/// It runs only while it can be seen. Under reduced motion it is the finished
/// app, still.
class AppBeingBuilt extends StatefulWidget {
  /// Draws the phone.
  const AppBeingBuilt({super.key});

  @override
  State<AppBeingBuilt> createState() => _AppBeingBuiltState();
}

class _AppBeingBuiltState extends State<AppBeingBuilt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _build = AnimationController(
    vsync: this,
    duration: Tokens.appBuildCycle,
  );
  final GlobalKey _key = GlobalKey(debugLabel: 'app-being-built');
  ScrollController? _scroll;
  bool _isReduced = false;
  bool _isOnScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnScreen());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = ChromeScrollScope.maybeOf(context)?.controller;
    if (scroll != _scroll) {
      _scroll?.removeListener(_checkOnScreen);
      _scroll = scroll?..addListener(_checkOnScreen);
      // Nothing to scroll -- a test, a page without the chrome -- so there
      // is no fold to wait for.
      if (scroll == null) _isOnScreen = true;
    }
    _isReduced = ReducedMotion.of(context);
    _updateRun();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_checkOnScreen);
    _build.dispose();
    super.dispose();
  }

  void _updateRun() {
    if (_isReduced) {
      _build
        ..stop()
        ..value = _AppPainter.finished;
      return;
    }
    if (_isOnScreen && !_build.isAnimating) {
      _build.repeat();
    } else if (!_isOnScreen && _build.isAnimating) {
      _build.stop();
    }
  }

  void _checkOnScreen() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject();
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box is! RenderBox || !box.hasSize || viewport == null) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final onScreen = top + box.size.height > 0 && top < viewport.size.height;
    if (onScreen == _isOnScreen) return;
    _isOnScreen = onScreen;
    _updateRun();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: SizedBox(
        key: _key,
        width: Tokens.appBuildWidth,
        height: Tokens.appBuildWidth * Tokens.appBuildAspect,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _build,
            builder: (context, _) => CustomPaint(
              painter: _AppPainter(
                t: _build.value,
                frame: tokens.hairlineStrong,
                plan: tokens.hairline,
                block: tokens.surfaceRaised,
                edge: tokens.hairlineStrong,
                ink: tokens.instrumentDim,
                gold: tokens.beacon,
                glow: tokens.beaconGlow,
                strokeWidth: tokens.hairlineWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One part of the app: where it sits on the screen, as fractions of the
/// screen, and whether it is the part that lights up.
typedef _Part = ({Rect at, bool isAction});

class _AppPainter extends CustomPainter {
  const _AppPainter({
    required this.t,
    required this.frame,
    required this.plan,
    required this.block,
    required this.edge,
    required this.ink,
    required this.gold,
    required this.glow,
    required this.strokeWidth,
  });

  /// Where the cycle is, 0 to 1.
  final double t;
  final Color frame;
  final Color plan;
  final Color block;
  final Color edge;
  final Color ink;
  final Color gold;
  final Color glow;
  final double strokeWidth;

  /// The app, top to bottom, in the order it is built.
  static const List<_Part> _parts = [
    (at: Rect.fromLTRB(0.08, 0.07, 0.92, 0.15), isAction: false),
    (at: Rect.fromLTRB(0.08, 0.19, 0.92, 0.45), isAction: false),
    (at: Rect.fromLTRB(0.08, 0.49, 0.92, 0.57), isAction: false),
    (at: Rect.fromLTRB(0.08, 0.61, 0.92, 0.69), isAction: false),
    (at: Rect.fromLTRB(0.08, 0.73, 0.6, 0.79), isAction: false),
    (at: Rect.fromLTRB(0.08, 0.85, 0.92, 0.93), isAction: true),
  ];

  /// When each part starts to drop, and how long a drop takes, as shares of
  /// the cycle; then the screen comes on, holds, and clears.
  static const double _dropStart = 0.04;
  static const double _dropGap = 0.075;
  static const double _drop = 0.11;
  static const double _lightAt = 0.53;
  static const double _clearAt = 0.86;

  /// The moment the app is whole and lit: what reduced motion shows.
  static const double finished = 0.7;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.16),
    ).deflate(strokeWidth);
    final screen = body.deflate(size.width * 0.06);
    final area = screen.outerRect;
    final clearing = ((t - _clearAt) / (1 - _clearAt)).clamp(0.0, 1.0);
    final lit = ((t - _lightAt) / 0.08).clamp(0.0, 1.0) * (1 - clearing);

    // The screen coming on: a warm light from inside once the app is whole.
    if (lit > 0) {
      canvas.drawRRect(
        screen,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.withValues(alpha: 0.16 * lit),
              glow.withValues(alpha: 0),
            ],
          ).createShader(area),
      );
    }
    canvas
      ..drawRRect(
        body,
        Paint()
          ..color = frame
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.5,
      )
      // The speaker slot at the top.
      ..drawLine(
        Offset(size.width * 0.42, size.width * 0.035),
        Offset(size.width * 0.58, size.width * 0.035),
        Paint()
          ..color = frame
          ..strokeWidth = strokeWidth * 2
          ..strokeCap = StrokeCap.round,
      );

    for (final (index, part) in _parts.indexed) {
      final slot = Rect.fromLTRB(
        area.left + part.at.left * area.width,
        area.top + part.at.top * area.height,
        area.left + part.at.right * area.width,
        area.top + part.at.bottom * area.height,
      );
      final radius = Radius.circular(size.width * 0.03);

      // The plan: every part's place, dashed, before anything is built.
      _dashed(
        canvas,
        Path()..addRRect(RRect.fromRectAndRadius(slot, radius)),
        Paint()
          ..color = plan
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );

      final start = _dropStart + index * _dropGap;
      final landed = ((t - start) / _drop).clamp(0.0, 1.0);
      if (landed <= 0) continue;
      // Dropped in from above the phone, settling with a little give, and
      // fading away again when the cycle clears.
      final fall = 1 - Curves.easeOutBack.transform(landed);
      final placed = slot.shift(Offset(0, -fall * size.height * 0.35));
      final opacity = math.min(landed * 3, 1) * (1 - clearing);
      if (opacity <= 0) continue;
      final shape = RRect.fromRectAndRadius(placed, radius);
      final isGold = part.isAction;
      canvas
        ..drawRRect(
          shape,
          Paint()..color = (isGold ? gold : block).withValues(alpha: opacity),
        )
        ..drawRRect(
          shape,
          Paint()
            ..color = (isGold ? gold : edge).withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth,
        );
      // A line of text on each row, and a picture's horizon on the card, so
      // the parts read as an app rather than as grey bars.
      final detail = Paint()
        ..color = ink.withValues(alpha: opacity)
        ..strokeWidth = strokeWidth * 2
        ..strokeCap = StrokeCap.round;
      if (index == 1) {
        final hill = Path()
          ..moveTo(placed.left, placed.bottom - placed.height * 0.25)
          ..quadraticBezierTo(
            placed.left + placed.width * 0.35,
            placed.top + placed.height * 0.3,
            placed.left + placed.width * 0.6,
            placed.bottom - placed.height * 0.35,
          )
          ..lineTo(placed.right, placed.bottom - placed.height * 0.2);
        canvas
          ..drawPath(
            hill,
            Paint()
              ..color = ink.withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth * 1.5,
          )
          ..drawCircle(
            Offset(
              placed.right - placed.width * 0.2,
              placed.top + placed.height * 0.3,
            ),
            placed.height * 0.1,
            Paint()..color = gold.withValues(alpha: opacity * lit),
          );
      } else if (!isGold) {
        final y = placed.center.dy;
        canvas.drawLine(
          Offset(placed.left + placed.width * 0.08, y),
          Offset(placed.left + placed.width * 0.55, y),
          detail,
        );
      }
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    final dash = strokeWidth * 4;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash * 2) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AppPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.frame != frame ||
      oldDelegate.plan != plan ||
      oldDelegate.block != block ||
      oldDelegate.edge != edge ||
      oldDelegate.ink != ink ||
      oldDelegate.gold != gold ||
      oldDelegate.glow != glow ||
      oldDelegate.strokeWidth != strokeWidth;
}
