import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/sign_paths.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// The sign that says what kind of stop this was.
///
/// The owner asked for something at the left of each career entry that tells
/// study, employment and freelance apart at a glance. It is a carved sign
/// rather than a logo or a stock icon: the page already reads as a wall of
/// them, an employer's actual mark is not ours to draw, and a generic
/// briefcase would be the kind of stock filler he has asked to keep out.
///
/// Three signs, each of which already means the thing it is standing for:
///
/// - **The seated scribe** for study. The determinative for a person, and the
///   sign that accompanies writing.
/// - **The djed pillar** for employment. Stability; a thing you stand inside.
/// - **The falcon** for freelance. It stands on its own.
class StopMark extends StatelessWidget {
  /// Draws the sign for [role].
  const StopMark({required this.role, super.key});

  /// The stop this marks.
  final CareerRole role;

  /// Which sign a role gets.
  ///
  /// Freelance is checked by id because the content gives it no separate kind:
  /// it is a role like the others, with no company and no office.
  static Sign signFor(CareerRole role) {
    if (role.id == 'freelance') return Sign.falcon;
    return switch (role.kind) {
      StopKind.study => Sign.seated,
      StopKind.role => Sign.djed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final sign = signFor(role);
    // A pointer lights these by hovering the row they sit on. A phone has no
    // hover, so on touch they light as they pass the middle of the screen
    // instead -- the same "this one, now" the cursor gives, from the only
    // gesture a phone actually has. Drawn dim everywhere else.
    if (!context.platform.isTouch) {
      return _Sign(sign: sign, lit: 0, tokens: tokens);
    }
    return _ScrollLit(
      builder: (lit) => _Sign(sign: sign, lit: lit, tokens: tokens),
    );
  }
}

/// The sign itself, at a given amount of lit.
class _Sign extends StatelessWidget {
  const _Sign({required this.sign, required this.lit, required this.tokens});

  final Sign sign;
  final double lit;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: Tokens.stopMarkSize,
    height: Tokens.stopMarkSize,
    child: CustomPaint(
      painter: _StopMarkPainter(
        sign: sign,
        colour: Color.lerp(tokens.instrumentDim, tokens.beacon, lit)!,
        shadow: tokens.void_,
        light: tokens.ornamentField,
        glow: tokens.beaconGlow,
        lit: lit,
      ),
    ),
  );
}

/// Reports how near the middle of the viewport its child is, as the page moves.
///
/// The page's own controller, not a `ScrollNotification`: this sits *inside*
/// the scroll view and notifications travel outward from the scrollable, so a
/// listener under it never sees them. `ChromeScrollScope` says so in as many
/// words, and `RevealOnScroll` learned it the hard way.
class _ScrollLit extends StatefulWidget {
  const _ScrollLit({required this.builder});

  final Widget Function(double lit) builder;

  @override
  State<_ScrollLit> createState() => _ScrollLitState();
}

class _ScrollLitState extends State<_ScrollLit> {
  double _lit = 0;
  ScrollController? _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ChromeScrollScope.maybeOf(context)?.controller;
    // `_resolved`, not a null check. On the first pass both are null outside
    // the chrome, and comparing them would skip the no-scroll case entirely.
    if (_resolved && identical(next, _controller)) return;
    _resolved = true;
    _controller?.removeListener(_measure);
    _controller = next;
    next?.addListener(_measure);
  }

  @override
  void dispose() {
    _controller?.removeListener(_measure);
    super.dispose();
  }

  void _measure() {
    if (!mounted || ReducedMotion.of(context)) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return;

    final centre =
        box.localToGlobal(Offset.zero, ancestor: viewport).dy +
        box.size.height / 2;
    final distance = (centre - viewport.size.height / 2).abs();
    // A band rather than a point, so a mark is lit for a moment of scrolling
    // instead of flashing as it crosses one line.
    final next = (1 - distance / (viewport.size.height * _band)).clamp(
      0.0,
      1.0,
    );
    // Only when it has actually moved. A scroll fires many times a second and
    // a rebuild per pixel would repaint every sign on the page for a change
    // nobody can see.
    if ((next - _lit).abs() < 0.02) return;
    setState(() => _lit = next);
  }

  /// How much of the viewport height counts as "near the middle".
  static const double _band = 0.22;

  @override
  Widget build(BuildContext context) => widget.builder(_lit);
}

class _StopMarkPainter extends CustomPainter {
  const _StopMarkPainter({
    required this.sign,
    required this.colour,
    required this.shadow,
    required this.light,
    required this.glow,
    required this.lit,
  });

  final Sign sign;
  final Color colour;
  final Color shadow;
  final Color light;
  final Color glow;

  /// How lit this sign is, 0 to 1.
  final double lit;

  @override
  void paint(Canvas canvas, Size size) {
    final box = size.shortestSide;
    final path = SignPaths.of(sign, box);
    // Cut, not printed: the same shadow-below, lip-above pass the wall uses,
    // so a sign beside the copy belongs to the same surface as the ones on
    // the stone rather than looking like an icon dropped onto the page.
    final relief = box * Tokens.wallSignRelief;
    canvas
      ..save()
      ..translate((size.width - box) / 2, (size.height - box) / 2)
      ..drawPath(
        path.shift(Offset(0, relief)),
        Paint()..color = shadow.withValues(alpha: Tokens.stopMarkReliefAlpha),
      )
      ..drawPath(
        path.shift(Offset(0, -relief)),
        Paint()..color = light.withValues(alpha: Tokens.stopMarkReliefAlpha),
      )
      ..drawPath(path, Paint()..color = colour);
    // A halo under the sign, not a brighter sign. The relief pass above is
    // what makes it read as cut stone, and raising its colour alone turns a
    // carving into a sticker.
    if (lit > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = glow.withValues(alpha: lit * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, box * 0.2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StopMarkPainter oldDelegate) =>
      oldDelegate.sign != sign ||
      oldDelegate.colour != colour ||
      oldDelegate.shadow != shadow ||
      oldDelegate.light != light ||
      oldDelegate.glow != glow ||
      oldDelegate.lit != lit;
}
