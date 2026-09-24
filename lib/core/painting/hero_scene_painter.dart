import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/sign_paths.dart';
import 'package:nocturne/core/painting/station_seed.dart';

/// The picture beside the hero: a desk on the bank of the Nile, under a sky
/// that follows the site's theme.
///
/// The owner asked for the right of the hero to hold an image that stands for
/// him -- a laptop, code, the culture -- different by night and by day, with a
/// sun that rises and sets. Everything here is drawn from signs and pigments
/// the site already has, so the picture belongs to the same building as the
/// wall behind it:
///
/// * **Ra's disc** is the sun (`Sign.sun`), and it is a control: the widget
///   puts a button on it that sets the theme, which is why it may be gold.
/// * **Khepri** (`Sign.scarab`) rolls it over the horizon while it is low --
///   the morning sun, becoming, which is what the scarab means (motif #7).
/// * **A pair of obelisks** stands on the far bank (motif #6), their
///   pyramidions gilded the way the real ones were, to catch the first light.
/// * **The owner at his desk**: two curved screens, one mirroring the phone
///   beside them while he codes, the other running the automation that is
///   building the pyramid outside -- in step with the crane.
/// * **A pyramid going up**, its top courses set a block at a time by a tower
///   crane. `12-MOTIF-LIBRARY.md` excludes the pyramid silhouette as
///   travel-agency iconography; the owner asked for this one by name, and it
///   is under construction, which is the point: it is a thing being built,
///   not a postcard.
/// * **Stars** at night, five-pointed like the ones painted on tomb ceilings.
///
/// Still no palm tree.
///
/// Every colour is handed in from the active palette, so the same drawing is
/// a night scene on the dark theme and a day scene on the light one. Every
/// motion is a function of [sun] and [time], and both are held still under
/// reduced motion by the caller.
class HeroScenePainter extends CustomPainter {
  /// Draws the scene with the sun at [sun] and the idle motion at [time].
  const HeroScenePainter({
    required this.sun,
    required this.time,
    required this.parallax,
    required this.skyTop,
    required this.skyHorizon,
    required this.water,
    required this.ground,
    required this.stone,
    required this.edge,
    required this.lit,
    required this.ink,
    required this.faint,
    required this.gold,
    required this.goldDim,
    required this.goldGlow,
    required this.halo,
    required this.screen,
    required this.strokeWidth,
    this.skin = Tokens.figureSkin,
    this.skinShade = Tokens.figureSkinShade,
  });

  /// Where the sun is: 0 set below the horizon, 1 high in the sky.
  final double sun;

  /// Seconds of idle motion -- stars, the river, the cursor, the steam. Zero
  /// holds the picture still.
  final double time;

  /// Where the viewer's pointer is over the picture, each axis -1 to 1. Near
  /// things move more than far ones, which is all the depth this needs.
  final Offset parallax;

  /// The top of the sky.
  final Color skyTop;

  /// The sky where it meets the far bank.
  final Color skyHorizon;

  /// The river.
  final Color water;

  /// The near bank.
  final Color ground;

  /// Stone: the obelisks, the desk.
  final Color stone;

  /// The edge of anything drawn in outline.
  final Color edge;

  /// Stone where light catches it.
  final Color lit;

  /// The strongest limestone: the moon, the figure.
  final Color ink;

  /// The faintest limestone: stars, code that is not being typed.
  final Color faint;

  /// The sun, the pyramidions, the work on the screen.
  final Color gold;

  /// Gold at rest.
  final Color goldDim;

  /// Gold at its peak, for glows.
  final Color goldGlow;

  /// The light around the sun and along the horizon at dawn: warm gold at
  /// night, near-white by day, where a darker glow would read as a shadow.
  final Color halo;

  /// The face of a screen.
  final Color screen;

  /// Hairline stroke width, from tokens.
  final double strokeWidth;

  /// The figure's skin, and its shadowed side.
  final Color skin;

  /// See [skin].
  final Color skinShade;

  /// Where the far bank meets the sky, as a share of the height.
  static const double horizon = 0.6;

  /// Where the top of the desk is, as a share of the height.
  static const double deskTop = 0.79;

  /// The sun's radius, as a share of the picture's shorter side.
  static const double _sunRadius = 0.07;

  /// The moon's radius, as a share of the picture's shorter side.
  static const double _moonRadius = 0.05;

  /// How far, in pixels, the nearest layer moves under the pointer.
  static const double _parallaxReach = 10;

  /// The sun's centre for [sun] in a picture of [size].
  ///
  /// A curve from below the right-hand horizon up to high over the river, so
  /// setting reads as sinking behind the far bank and rising as climbing back
  /// over it. Public so the widget can put its button exactly on the disc.
  static Offset sunCentre(Size size, double sun) {
    final t = sun.clamp(0.0, 1.0);
    final from = Offset(size.width * 0.9, size.height * (horizon + 0.12));
    // The bend at the height it finishes at, so the climb never overshoots
    // and settles back: a sun that rises past its place and sinks into it
    // reads as a bounce.
    final via = Offset(size.width * 0.9, size.height * 0.1);
    final to = Offset(size.width * 0.7, size.height * 0.1);
    final a = Offset.lerp(from, via, t)!;
    final b = Offset.lerp(via, to, t)!;
    return Offset.lerp(a, b, t)!;
  }

  /// The sun's radius in a picture of [size].
  static double sunRadiusIn(Size size) => size.shortestSide * _sunRadius;

  /// The moon's centre in a picture of [size].
  static Offset moonCentre(Size size) =>
      Offset(size.width * 0.44, size.height * 0.15);

  /// The moon's radius in a picture of [size].
  static double moonRadiusIn(Size size) => size.shortestSide * _moonRadius;

  /// How much of the night is showing: stars and moon at 1, none at 0.
  static double nightFor(double sun) => (1 - sun * 1.8).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final horizonY = h * horizon;
    final night = nightFor(sun);
    final sunUp = (sun * 3).clamp(0.0, 1.0);

    // Near the horizon, on the way up or down: the dawn and dusk glow.
    final glow = (1 - (sun - 0.24).abs() / 0.24).clamp(0.0, 1.0);

    // Drawn a little larger than the picture, so a layer moved by the pointer
    // never uncovers an edge.
    const bleed = _parallaxReach * 2;

    _layer(canvas, 0.25, () {
      final sky = Rect.fromLTRB(-bleed, -bleed, w + bleed, horizonY);
      canvas.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyTop, skyHorizon],
          ).createShader(sky),
      );
      _paintStars(canvas, size, night);
      if (glow > 0) {
        final band = Rect.fromLTRB(
          -bleed,
          horizonY - h * 0.24,
          w + bleed,
          horizonY,
        );
        canvas.drawRect(
          band,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                halo.withValues(alpha: 0),
                halo.withValues(alpha: 0.22 * glow),
              ],
            ).createShader(band),
        );
      }
      _paintMoon(canvas, size, night);
      _paintSun(canvas, size, horizonY);
    });

    _layer(canvas, 0.5, () {
      _paintObelisks(canvas, size, horizonY, sunUp);
      _paintPyramid(canvas, size, horizonY, sunUp);
      _paintCrane(canvas, size, horizonY);
    });

    _layer(canvas, 0.7, () {
      final river = Rect.fromLTRB(-bleed, horizonY, w + bleed, h * 0.68);
      canvas
        ..drawRect(river, Paint()..color = water)
        ..drawLine(
          Offset(-bleed, horizonY),
          Offset(w + bleed, horizonY),
          Paint()
            ..color = edge
            ..strokeWidth = strokeWidth,
        );
      _paintRipples(canvas, size, river);
      _paintReflection(canvas, size, river, sunUp);
      canvas.drawRect(
        Rect.fromLTRB(-bleed, h * 0.68, w + bleed, h * deskTop),
        Paint()..color = ground,
      );
    });

    _layer(canvas, 1, () {
      _paintDesk(canvas, size, bleed, night);
      _paintDesktop(canvas, size, night);
      _paintPhone(canvas, size);
      _paintCup(canvas, size);
      _paintFigure(canvas, size);
    });
  }

  /// Runs [draw] shifted by the pointer, [depth] of the way to the nearest.
  void _layer(Canvas canvas, double depth, VoidCallback draw) {
    canvas
      ..save()
      ..translate(
        parallax.dx * _parallaxReach * depth,
        parallax.dy * _parallaxReach * depth * 0.5,
      );
    draw();
    canvas.restore();
  }

  void _paintStars(Canvas canvas, Size size, double night) {
    if (night <= 0) return;
    final seed = StationSeed('hero.stars');
    final dot = Paint()..color = faint;
    for (var i = 0; i < 44; i++) {
      final x = seed.nextRange(0.03, 0.97) * size.width;
      final y = seed.nextRange(0.03, horizon - 0.1) * size.height;
      final phase = seed.nextDouble() * math.pi * 2;
      final isLarge = seed.nextInt(7) == 0;
      final twinkle = 0.55 + 0.45 * math.sin(time * 1.3 + phase);
      final alpha = night * twinkle;
      if (isLarge) {
        _paintStar(
          canvas,
          Offset(x, y),
          size.shortestSide * 0.012,
          Paint()..color = ink.withValues(alpha: alpha * 0.85),
        );
      } else {
        canvas.drawCircle(
          Offset(x, y),
          strokeWidth * seed.nextRange(0.6, 1.3),
          dot..color = faint.withValues(alpha: alpha),
        );
      }
    }
  }

  /// A five-pointed star, the way tomb ceilings drew them.
  void _paintStar(Canvas canvas, Offset centre, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = centre + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  void _paintMoon(Canvas canvas, Size size, double night) {
    if (night <= 0) return;
    final centre = moonCentre(size);
    final radius = moonRadiusIn(size);
    canvas.drawCircle(
      centre,
      radius * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            ink.withValues(alpha: 0.12 * night),
            ink.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius * 2.4)),
    );
    // A crescent: the disc, less the same disc moved toward the sun's side.
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius)),
      Path()..addOval(
        Rect.fromCircle(
          center: centre + Offset(radius * 0.45, -radius * 0.2),
          radius: radius * 0.92,
        ),
      ),
    );
    canvas.drawPath(crescent, Paint()..color = ink.withValues(alpha: night));
  }

  void _paintSun(Canvas canvas, Size size, double horizonY) {
    final centre = sunCentre(size, sun);
    final radius = sunRadiusIn(size);
    if (centre.dy - radius * 3 > horizonY) return;

    canvas
      ..save()
      // Clipped at the far bank, so a setting sun sinks behind it rather than
      // sliding down the front of the river.
      ..clipRect(
        Rect.fromLTRB(-size.width, -size.height, size.width * 2, horizonY),
      )
      ..drawCircle(
        centre,
        radius * 3,
        Paint()
          ..shader = RadialGradient(
            colors: [halo.withValues(alpha: 0.45), halo.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius * 3)),
      );

    // Ra's disc and its ring, the site's own sign for the sun.
    final disc = SignPaths.of(Sign.sun, radius / 0.3);
    final box = radius / 0.3;
    canvas
      ..drawCircle(centre, radius * 0.93, Paint()..color = gold)
      ..save()
      ..translate(centre.dx - box / 2, centre.dy - box / 2)
      ..drawPath(disc, Paint()..color = goldGlow)
      ..restore();

    // Khepri under the disc while it is low: the beetle that rolls the
    // morning sun over the horizon, fading as the sun clears it.
    final khepri = (1 - sun / 0.45).clamp(0.0, 1.0);
    if (khepri > 0) {
      final beetle = radius * 1.7;
      canvas
        ..save()
        ..translate(centre.dx - beetle / 2, centre.dy + radius * 0.55)
        ..drawPath(
          SignPaths.of(Sign.scarab, beetle),
          Paint()..color = goldDim.withValues(alpha: khepri),
        )
        ..restore();
    }
    canvas.restore();
  }

  void _paintObelisks(Canvas canvas, Size size, double horizonY, double sunUp) {
    for (final (x, height) in const [(0.15, 0.4), (0.27, 0.32)]) {
      final base = size.width * 0.052;
      final top = base * 0.66;
      final shaftHeight = size.height * height;
      final cx = size.width * x;
      final capHeight = top * 0.95;
      final shaftTop = horizonY - shaftHeight + capHeight;

      final shaft = Path()
        ..moveTo(cx - base / 2, horizonY)
        ..lineTo(cx - top / 2, shaftTop)
        ..lineTo(cx + top / 2, shaftTop)
        ..lineTo(cx + base / 2, horizonY)
        ..close();
      canvas
        ..drawPath(shaft, Paint()..color = stone)
        ..drawPath(
          shaft,
          Paint()
            ..color = edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth,
        );

      // The face toward the sun, catching its light.
      final face = Path()
        ..moveTo(cx, horizonY)
        ..lineTo(cx, shaftTop)
        ..lineTo(cx + top / 2, shaftTop)
        ..lineTo(cx + base / 2, horizonY)
        ..close();
      canvas.drawPath(face, Paint()..color = lit.withValues(alpha: 0.35));

      // A column of incised marks down the face: an inscription, too small
      // to read and not pretending to be one.
      final marks = Paint()
        ..color = edge
        ..strokeWidth = strokeWidth;
      final rows = (shaftHeight / (size.height * 0.03)).floor();
      for (var i = 1; i < rows; i++) {
        final y = shaftTop + i * size.height * 0.03;
        if (y > horizonY - size.height * 0.02) break;
        canvas.drawLine(
          Offset(cx - top * 0.14, y),
          Offset(cx + top * 0.14, y),
          marks,
        );
      }

      // The pyramidion, gilded to catch the sun. At night it keeps a little
      // of the gold, the way metal holds the last of the light.
      final cap = Path()
        ..moveTo(cx - top / 2, shaftTop)
        ..lineTo(cx, shaftTop - capHeight)
        ..lineTo(cx + top / 2, shaftTop)
        ..close();
      canvas.drawPath(cap, Paint()..color = Color.lerp(goldDim, gold, sunUp)!);
    }
  }

  void _paintRipples(Canvas canvas, Size size, Rect river) {
    final ripple = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final drift = (time * 6) % (size.width * 0.18);
    for (var row = 0; row < 3; row++) {
      final y = river.top + river.height * (0.3 + row * 0.24);
      final path = Path();
      final step = size.width * 0.09;
      for (
        var x = -step * 2 + drift + row * step / 3;
        x < size.width + step;
        x += step * 2
      ) {
        path
          ..moveTo(x, y)
          ..quadraticBezierTo(
            x + step / 2,
            y - river.height * 0.08,
            x + step,
            y,
          );
      }
      canvas.drawPath(path, ripple);
    }
  }

  void _paintReflection(Canvas canvas, Size size, Rect river, double sunUp) {
    final centre = sunCentre(size, sun);
    if (sunUp <= 0 || centre.dy > river.top) return;
    final dash = Paint()
      ..color = gold.withValues(alpha: 0.5 * sunUp)
      ..strokeWidth = strokeWidth * 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = river.top + river.height * (0.2 + i * 0.2);
      final half = size.width * (0.03 - i * 0.005);
      final wobble = math.sin(time * 1.6 + i) * size.width * 0.004;
      canvas.drawLine(
        Offset(centre.dx - half + wobble, y),
        Offset(centre.dx + half + wobble, y),
        dash,
      );
    }
  }

  void _paintDesk(Canvas canvas, Size size, double bleed, double night) {
    final top = size.height * deskTop;
    final desk = Rect.fromLTRB(
      -bleed,
      top,
      size.width + bleed,
      size.height + bleed,
    );
    canvas
      ..drawRect(desk, Paint()..color = stone)
      ..drawLine(
        Offset(-bleed, top),
        Offset(size.width + bleed, top),
        Paint()
          ..color = lit
          ..strokeWidth = strokeWidth,
      );

    // The laptop's light on the stone, strongest at night.
    final pool = Offset(size.width * 0.64, top);
    final reach = size.width * 0.4;
    canvas.drawOval(
      Rect.fromCenter(center: pool, width: reach * 2, height: reach * 0.5),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                goldGlow.withValues(alpha: 0.1 + 0.18 * night),
                goldGlow.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCenter(
                center: pool,
                width: reach * 2,
                height: reach * 0.5,
              ),
            ),
    );

    // A register along the desk's face: two rules and the ticks between
    // them, the site's own way of marking a band (motifs #2 and #10).
    final rule = Paint()
      ..color = edge
      ..strokeWidth = strokeWidth;
    final upper = top + size.height * 0.055;
    final lower = top + size.height * 0.16;
    canvas
      ..drawLine(Offset(-bleed, upper), Offset(size.width + bleed, upper), rule)
      ..drawLine(
        Offset(-bleed, lower),
        Offset(size.width + bleed, lower),
        rule,
      );
    final tick = size.width * 0.04;
    for (var x = tick / 2; x < size.width; x += tick) {
      canvas.drawLine(
        Offset(x, upper),
        Offset(x, upper + (lower - upper) * 0.28),
        rule,
      );
    }
  }

  /// Where the crane is in placing the current block, 0..1, and how many
  /// blocks have been set. A new block every [_blockPeriod] seconds; the
  /// pyramid starts part-built and, once finished, starts its last courses
  /// again.
  ///
  /// Held still, it is caught mid-lift: more than half the top laid and the
  /// next block on its way down, which is the one frame that says "being
  /// built" rather than "finished" or "not started".
  ({double phase, int placed}) _build() {
    const loop = _blockPeriod * _animatedBlocks;
    final t = time == 0 ? _blockPeriod * 5.62 : time % loop;
    final block = (t / _blockPeriod).floor();
    final phase = (t % _blockPeriod) / _blockPeriod;
    return (phase: phase, placed: block + (phase >= _releaseAt ? 1 : 0));
  }

  /// Seconds for the crane to set one block.
  static const double _blockPeriod = 5;

  /// Courses of the pyramid, and how many are standing before the crane
  /// begins; the rest are laid in front of the viewer, one block at a time.
  static const int _courses = 12;

  /// See [_courses].
  static const int _builtCourses = 8;

  /// Blocks the crane lays before the loop starts over: the last four courses
  /// are four, three, two and one blocks wide.
  static const int _animatedBlocks = 10;

  /// Where in a block's cycle the crane lets it go.
  static const double _releaseAt = 0.72;

  /// The pyramid's centre and base width, as shares of the picture's width.
  static const double _pyramidX = 0.6;

  /// See [_pyramidX].
  static const double _pyramidBase = 0.46;

  /// The pyramid's height, as a share of the picture's height. Tall enough
  /// that the courses being laid stand clear above the screens.
  static const double _pyramidHeight = 0.3;

  /// The crane's mast, as a share of the width, and its jib, as a share of
  /// the height.
  static const double _mastX = 0.885;

  /// See [_mastX].
  static const double _jibY = 0.235;

  /// Where the crane picks a block up: behind the right-hand screen, so each
  /// block rises into view from below it.
  static const double _pickupX = 0.848;

  /// Course [course]'s left and right edges, its foot and its head.
  (double left, double right, double foot, double head) _course(
    Size size,
    double horizonY,
    int course,
  ) {
    final base = size.width * _pyramidBase;
    final centre = size.width * _pyramidX;
    final height = size.height * _pyramidHeight / _courses;
    final width = base * (1 - course / _courses);
    final foot = horizonY - course * height;
    return (centre - width / 2, centre + width / 2, foot, foot - height);
  }

  /// The centre of slot [slot] in course [course], where a block is set.
  Offset _slot(Size size, double horizonY, int course, int slot) {
    final (left, right, foot, head) = _course(size, horizonY, course);
    final blocks = _courses - course;
    final width = (right - left) / blocks;
    return Offset(left + width * (slot + 0.5), (foot + head) / 2);
  }

  /// Which course and slot the [n]th animated block goes into.
  (int course, int slot) _slotOf(int n) {
    var remaining = n;
    for (var course = _builtCourses; course < _courses; course++) {
      final blocks = _courses - course;
      if (remaining < blocks) return (course, remaining);
      remaining -= blocks;
    }
    return (_courses - 1, 0);
  }

  void _paintPyramid(Canvas canvas, Size size, double horizonY, double sunUp) {
    final placed = _build().placed;
    final cx = size.width * _pyramidX;
    final base = size.width * _pyramidBase;
    final apex = Offset(cx, horizonY - size.height * _pyramidHeight);

    // The plan: where the finished faces will run, dashed, so the unbuilt top
    // reads as a pyramid still going up rather than as a ruin coming down.
    _dashed(
      canvas,
      Path()
        ..moveTo(cx - base / 2, horizonY)
        ..lineTo(apex.dx, apex.dy)
        ..lineTo(cx + base / 2, horizonY),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final fill = Paint()..color = stone;
    // The face toward the sun, paler than the shadowed one, which is what
    // makes it a solid and not a flat. By night that is the lit stone; by
    // day the stone is already pale and the lit tone is darker than it, so
    // the sky's own light is laid over the face instead.
    final face = Paint()
      ..color = Color.lerp(
        lit.withValues(alpha: 0.3),
        skyHorizon.withValues(alpha: 0.75),
        sunUp,
      )!;
    final mortar = Paint()
      ..color = edge
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (var course = 0; course < _courses; course++) {
      final (left, right, foot, head) = _course(size, horizonY, course);
      final blocks = _courses - course;
      final width = (right - left) / blocks;
      // The courses the crane is laying show only the blocks it has set.
      var shown = blocks;
      if (course >= _builtCourses) {
        var before = 0;
        for (var c = _builtCourses; c < course; c++) {
          before += _courses - c;
        }
        shown = (placed - before).clamp(0, blocks);
      }
      for (var b = 0; b < shown; b++) {
        final block = Rect.fromLTRB(
          left + b * width,
          head,
          left + (b + 1) * width,
          foot,
        );
        canvas.drawRect(block, fill);
        final sunlit = Rect.fromLTRB(
          math.max(block.left, cx),
          head,
          block.right,
          foot,
        );
        if (sunlit.width > 0) canvas.drawRect(sunlit, face);
        canvas.drawRect(block, mortar);
      }
    }
  }

  /// A dashed stroke along [path].
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

  /// A tower crane beside the pyramid, setting its top courses a block at a
  /// time. The right-hand screen runs the automation that drives it, in step.
  void _paintCrane(Canvas canvas, Size size, double horizonY) {
    final (:phase, :placed) = _build();
    final mastX = size.width * _mastX;
    final jibY = size.height * _jibY;
    final depth = size.height * 0.016;
    final peak = jibY - size.height * 0.06;
    final jibEnd = size.width * 0.5;
    final tail = size.width * 1.02;
    final pickupX = size.width * _pickupX;
    final half = size.width * 0.011;
    final brace = Paint()
      ..color = edge
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final chord = Paint()
      ..color = lit
      ..strokeWidth = strokeWidth * 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // The mast: two chords and the zigzag between them, down behind the
    // screens to the ground.
    canvas
      ..drawLine(
        Offset(mastX - half, horizonY),
        Offset(mastX - half, jibY),
        chord,
      )
      ..drawLine(
        Offset(mastX + half, horizonY),
        Offset(mastX + half, jibY),
        chord,
      );
    final panel = half * 2.2;
    var flip = false;
    for (var y = horizonY; y > jibY + panel * 0.5; y -= panel) {
      canvas.drawLine(
        Offset(mastX + (flip ? half : -half), y),
        Offset(mastX + (flip ? -half : half), math.max(y - panel, jibY)),
        brace,
      );
      flip = !flip;
    }

    // The jib and the counter-jib: a truss of two chords, braced.
    canvas
      ..drawLine(Offset(jibEnd, jibY), Offset(tail, jibY), chord)
      ..drawLine(
        Offset(jibEnd + depth, jibY - depth),
        Offset(tail, jibY - depth),
        brace,
      );
    flip = false;
    for (var x = jibEnd; x < tail - depth; x += depth) {
      canvas.drawLine(
        Offset(x, flip ? jibY - depth : jibY),
        Offset(x + depth, flip ? jibY : jibY - depth),
        brace,
      );
      flip = !flip;
    }
    // The peak above the mast, and the ties that hold both arms from it.
    canvas
      ..drawLine(Offset(mastX - half, jibY - depth), Offset(mastX, peak), chord)
      ..drawLine(Offset(mastX + half, jibY - depth), Offset(mastX, peak), chord)
      ..drawLine(
        Offset(mastX, peak),
        Offset(jibEnd + depth * 4, jibY - depth),
        brace,
      )
      ..drawLine(Offset(mastX, peak), Offset(tail, jibY - depth), brace)
      // The counterweight, and the cab under the jib with its lit window.
      ..drawRect(
        Rect.fromLTWH(size.width * 0.955, jibY, size.width * 0.04, depth * 2.2),
        Paint()..color = lit,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            mastX - half * 3.2,
            jibY + strokeWidth,
            half * 2.2,
            depth * 1.8,
          ),
          Radius.circular(depth * 0.3),
        ),
        Paint()..color = lit,
      )
      ..drawRect(
        Rect.fromLTWH(
          mastX - half * 2.9,
          jibY + depth * 0.4,
          half * 1.1,
          depth * 0.8,
        ),
        Paint()..color = goldDim,
      );

    // Where the trolley and hook are in this block's cycle.
    final (sl, sr, sf, sh) = _course(size, horizonY, _courses - 1);
    final blockW = sr - sl;
    final blockH = sf - sh;
    final next = _slotOf(placed.clamp(0, _animatedBlocks - 1));
    final target = _slot(size, horizonY, next.$1, next.$2);
    // Below the top of the right-hand screen, so a block is picked up out of
    // sight and rises into view.
    final ground = horizonY - blockH;
    final carry = jibY + blockH * 1.6;
    final setAt = target.dy - blockH / 2;
    double ease(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    double x;
    double hookY;
    var carrying = true;
    if (phase < 0.15) {
      x = pickupX;
      hookY = carry + (ground - carry) * ease(phase / 0.15);
      carrying = phase > 0.12;
    } else if (phase < 0.3) {
      x = pickupX;
      hookY = ground + (carry - ground) * ease((phase - 0.15) / 0.15);
    } else if (phase < 0.55) {
      x = pickupX + (target.dx - pickupX) * ease((phase - 0.3) / 0.25);
      hookY = carry;
    } else if (phase < _releaseAt) {
      x = target.dx;
      hookY =
          carry + (setAt - carry) * ease((phase - 0.55) / (_releaseAt - 0.55));
    } else if (phase < 0.85) {
      x = target.dx;
      hookY =
          setAt +
          (carry - setAt) * ease((phase - _releaseAt) / (0.85 - _releaseAt));
      carrying = false;
    } else {
      x = target.dx + (pickupX - target.dx) * ease((phase - 0.85) / 0.15);
      hookY = carry;
      carrying = false;
    }
    // A block swings a little as it travels, and hangs still once lowered.
    final sway = time == 0 || phase < 0.3 || phase > 0.6
        ? 0.0
        : math.sin(phase * math.pi * 6) * blockW * 0.06;

    canvas
      ..drawRect(
        Rect.fromCenter(
          center: Offset(x, jibY + strokeWidth * 2),
          width: half * 2.2,
          height: strokeWidth * 3,
        ),
        Paint()..color = lit,
      )
      ..drawLine(Offset(x, jibY), Offset(x + sway, hookY), brace)
      ..drawCircle(
        Offset(x + sway, hookY),
        strokeWidth * 1.8,
        Paint()..color = gold,
      );
    if (!carrying) return;
    final block = Rect.fromLTWH(
      x + sway - blockW / 2,
      hookY + blockH * 0.7,
      blockW,
      blockH,
    );
    // The slings, from the hook to the block's top corners, which is what
    // makes it read as a weight being carried rather than a box floating.
    canvas
      ..drawLine(Offset(x + sway, hookY), block.topLeft, brace)
      ..drawLine(Offset(x + sway, hookY), block.topRight, brace)
      ..drawRect(block, Paint()..color = stone)
      ..drawRect(
        Rect.fromLTRB(block.center.dx, block.top, block.right, block.bottom),
        Paint()..color = lit.withValues(alpha: 0.35),
      )
      ..drawRect(
        block,
        Paint()
          ..color = edge
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
  }

  /// The owner at his desk, in profile, sat on a chair behind it and reaching
  /// for the keyboard.
  ///
  /// The climber from the courtyard with the close nemes and a broad collar,
  /// drawn big enough to be a person rather than a sign: a head that is a
  /// head, a shoulder the arm grows out of, and the arm bent at the elbow the
  /// way arms at a keyboard are. His skin is skin, at the owner's request;
  /// the gold he wears is the person, which is gold's first job.
  void _paintFigure(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final desk = h * deskTop;
    Offset p(double x, double y) => Offset(w * x, desk - h * y);
    Path shape(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path..close();
    }

    final typing = time == 0 ? 0.0 : math.sin(time * 9) * 0.004;
    final typingFar = time == 0 ? 0.0 : math.sin(time * 9 + 1.7) * 0.004;
    final armWidth = w * 0.026;
    final contour = strokeWidth * 1.6;
    Paint stroke(Color colour, double width) => Paint()
      ..color = colour
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    Path limb(Offset shoulder, Offset elbow, Offset hand) => Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(hand.dx, hand.dy);
    final stripe = stroke(goldDim, strokeWidth * 1.2);

    // The chair's back, behind him and leaning back a little.
    final chair = RRect.fromRectAndCorners(
      Rect.fromLTRB(w * 0.1, desk - h * 0.17, w * 0.16, desk + h * 0.01),
      topLeft: Radius.circular(w * 0.018),
      topRight: Radius.circular(w * 0.018),
    );
    final nearArm = limb(
      p(0.205, 0.138),
      p(0.232, 0.048),
      p(0.36, 0.022 + typing),
    );
    canvas
      ..save()
      ..translate(chair.center.dx, chair.bottom)
      ..rotate(-0.08)
      ..translate(-chair.center.dx, -chair.bottom)
      ..drawRRect(chair, Paint()..color = lit)
      ..drawLine(
        Offset(chair.left + w * 0.012, chair.top + w * 0.02),
        Offset(chair.left + w * 0.012, chair.bottom - h * 0.03),
        stroke(edge, strokeWidth),
      )
      ..restore()
      // The far arm, behind the body and a shade darker.
      ..drawPath(
        limb(p(0.2, 0.14), p(0.25, 0.05), p(0.4, 0.02 + typingFar)),
        stroke(skinShade, armWidth),
      )
      // The torso: the back straight against the chair, the chest leaning
      // to the work.
      ..drawPath(
        Path()
          ..moveTo(p(0.15, -0.01).dx, p(0.15, -0.01).dy)
          ..quadraticBezierTo(
            p(0.137, 0.08).dx,
            p(0.137, 0.08).dy,
            p(0.162, 0.148).dx,
            p(0.162, 0.148).dy,
          )
          ..quadraticBezierTo(
            p(0.185, 0.166).dx,
            p(0.185, 0.166).dy,
            p(0.215, 0.156).dx,
            p(0.215, 0.156).dy,
          )
          ..quadraticBezierTo(
            p(0.245, 0.14).dx,
            p(0.245, 0.14).dy,
            p(0.24, 0.1).dx,
            p(0.24, 0.1).dy,
          )
          ..quadraticBezierTo(
            p(0.232, 0.04).dx,
            p(0.232, 0.04).dy,
            p(0.224, -0.01).dx,
            p(0.224, -0.01).dy,
          )
          ..close(),
        Paint()..color = skin,
      )
      // The neck, down into the collar.
      ..drawLine(p(0.2, 0.15), p(0.206, 0.2), stroke(skin, w * 0.032))
      // The near arm, with a contour so it reads in front of the chest it
      // is the same colour as: shoulder, elbow, and the forearm along to
      // the keys.
      ..drawPath(nearArm, stroke(skinShade, armWidth + contour * 2))
      ..drawPath(nearArm, stroke(skin, armWidth))
      // The broad collar over both shoulders: it is also what joins the arm
      // to the body, which is where the shoulder kept going wrong.
      ..drawPath(
        Path()
          ..moveTo(p(0.16, 0.152).dx, p(0.16, 0.152).dy)
          ..quadraticBezierTo(
            p(0.2, 0.178).dx,
            p(0.2, 0.178).dy,
            p(0.24, 0.135).dx,
            p(0.24, 0.135).dy,
          )
          ..quadraticBezierTo(
            p(0.232, 0.112).dx,
            p(0.232, 0.112).dy,
            p(0.214, 0.112).dx,
            p(0.214, 0.112).dy,
          )
          ..quadraticBezierTo(
            p(0.19, 0.12).dx,
            p(0.19, 0.12).dy,
            p(0.168, 0.128).dx,
            p(0.168, 0.128).dy,
          )
          ..close(),
        Paint()..color = gold,
      )
      ..drawPath(
        Path()
          ..moveTo(p(0.17, 0.142).dx, p(0.17, 0.142).dy)
          ..quadraticBezierTo(
            p(0.2, 0.135).dx,
            p(0.2, 0.135).dy,
            p(0.234, 0.132).dx,
            p(0.234, 0.132).dy,
          ),
        stripe,
      )
      // The head, in profile and facing the screens: skull, jaw and nose.
      ..drawOval(
        Rect.fromCenter(
          center: p(0.213, 0.236),
          width: w * 0.064,
          height: h * 0.074,
        ),
        Paint()..color = skin,
      )
      ..drawPath(
        shape([
          p(0.236, 0.252),
          p(0.245, 0.243),
          p(0.253, 0.225),
          p(0.242, 0.221),
          p(0.245, 0.212),
          p(0.241, 0.206),
          p(0.238, 0.198),
          p(0.222, 0.194),
          p(0.212, 0.206),
        ]),
        Paint()..color = skin,
      )
      // The eye, drawn the way the tomb painters drew it: long, with the
      // line of kohl carried back towards the ear.
      ..drawOval(
        Rect.fromCenter(
          center: p(0.233, 0.238),
          width: w * 0.012,
          height: h * 0.006,
        ),
        Paint()..color = screen,
      )
      ..drawLine(p(0.227, 0.238), p(0.216, 0.235), stroke(screen, strokeWidth))
      // The nemes: a cap over the crown held by a band at the brow, flaring
      // behind the head and falling to the shoulders.
      ..drawPath(
        Path()
          ..moveTo(p(0.244, 0.254).dx, p(0.244, 0.254).dy)
          ..quadraticBezierTo(
            p(0.222, 0.292).dx,
            p(0.222, 0.292).dy,
            p(0.186, 0.27).dx,
            p(0.186, 0.27).dy,
          )
          ..quadraticBezierTo(
            p(0.17, 0.235).dx,
            p(0.17, 0.235).dy,
            p(0.163, 0.17).dx,
            p(0.163, 0.17).dy,
          )
          ..lineTo(p(0.2, 0.162).dx, p(0.2, 0.162).dy)
          ..lineTo(p(0.201, 0.228).dx, p(0.201, 0.228).dy)
          ..lineTo(p(0.214, 0.246).dx, p(0.214, 0.246).dy)
          ..quadraticBezierTo(
            p(0.23, 0.25).dx,
            p(0.23, 0.25).dy,
            p(0.244, 0.254).dx,
            p(0.244, 0.254).dy,
          )
          ..close(),
        Paint()..color = gold,
      )
      // The lappet, down in front of the ear and over the collar: the one
      // shape that says nemes and not hair.
      ..drawPath(
        shape([
          p(0.197, 0.236),
          p(0.214, 0.244),
          p(0.222, 0.13),
          p(0.199, 0.13),
        ]),
        Paint()..color = gold,
      );
    for (final y in const [0.21, 0.185, 0.16]) {
      canvas.drawLine(p(0.2025, y + 0.003), p(0.2175, y), stripe);
    }
    for (final (x, y) in const [(0.176, 0.25), (0.172, 0.222), (0.17, 0.195)]) {
      canvas.drawLine(p(x, y), p(x + 0.018, y - 0.004), stripe);
    }
    canvas.drawLine(
      p(0.215, 0.249),
      p(0.243, 0.255),
      stroke(goldDim, w * 0.005),
    );
  }

  /// Two curved screens on stands, and the keyboard in front of them.
  void _paintDesktop(Canvas canvas, Size size, double night) {
    final top = size.height * deskTop;
    final line = Paint()
      ..color = edge
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // The keyboard, seen almost edge-on.
    final keys = RRect.fromLTRBR(
      size.width * 0.33,
      top - size.height * 0.014,
      size.width * 0.56,
      top,
      Radius.circular(size.height * 0.004),
    );
    canvas
      ..drawRRect(keys, Paint()..color = lit)
      ..drawLine(
        Offset(keys.left + keys.width * 0.04, keys.top + keys.height * 0.45),
        Offset(keys.right - keys.width * 0.04, keys.top + keys.height * 0.45),
        line,
      );

    final screenW = size.width * 0.3;
    final screenH = size.height * 0.18;
    final screenBottom = top - size.height * 0.055;
    for (final (index, cx) in [size.width * 0.5, size.width * 0.81].indexed) {
      final left = cx - screenW / 2;
      final right = cx + screenW / 2;
      final screenTop = screenBottom - screenH;
      final bow = size.height * 0.012;

      // The stand: a neck and a foot.
      canvas
        ..drawRect(
          Rect.fromLTRB(
            cx - size.width * 0.008,
            screenBottom,
            cx + size.width * 0.008,
            top - size.height * 0.006,
          ),
          Paint()..color = lit,
        )
        ..drawRRect(
          RRect.fromLTRBR(
            cx - size.width * 0.05,
            top - size.height * 0.008,
            cx + size.width * 0.05,
            top,
            Radius.circular(size.height * 0.004),
          ),
          Paint()..color = lit,
        );

      // Curved: taller at the ends than in the middle, the way a curved
      // screen reads from in front of it.
      Path screenPath(double inset) => Path()
        ..moveTo(left + inset, screenTop + inset)
        ..quadraticBezierTo(
          cx,
          screenTop + bow + inset,
          right - inset,
          screenTop + inset,
        )
        ..lineTo(right - inset, screenBottom - inset)
        ..quadraticBezierTo(
          cx,
          screenBottom - bow - inset,
          left + inset,
          screenBottom - inset,
        )
        ..close();
      final bezel = screenPath(0);
      final glass = screenPath(size.width * 0.006);
      canvas
        ..drawPath(bezel, Paint()..color = lit)
        ..drawPath(glass, Paint()..color = screen)
        ..drawPath(
          glass,
          Paint()
            ..shader = RadialGradient(
              colors: [
                goldGlow.withValues(alpha: 0.06 + 0.08 * night),
                goldGlow.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromLTRB(left, screenTop, right, screenBottom)),
        );

      final inner = Rect.fromLTRB(
        left + screenW * 0.06,
        screenTop + screenH * 0.14,
        right - screenW * 0.06,
        screenBottom - screenH * 0.12,
      );
      canvas
        ..save()
        ..clipPath(glass);
      if (index == 0) {
        _paintCoding(canvas, size, inner);
      } else {
        _paintAutomation(canvas, size, inner);
      }
      canvas.restore();
    }
  }

  /// The left screen: the phone's app mirrored beside the code for it.
  void _paintCoding(Canvas canvas, Size size, Rect inner) {
    // The app, as the phone on the desk is showing it.
    final phoneW = inner.height * 0.5;
    final phone = RRect.fromRectAndRadius(
      Rect.fromLTWH(inner.left, inner.top, phoneW, inner.height),
      Radius.circular(phoneW * 0.14),
    );
    canvas.drawRRect(phone, Paint()..color = lit.withValues(alpha: 0.5));
    final app = phone.outerRect.deflate(phoneW * 0.1);
    final pad = app.height * 0.04;
    canvas
      ..drawRect(
        Rect.fromLTWH(app.left, app.top, app.width, app.height * 0.12),
        Paint()..color = goldDim,
      )
      ..drawRect(
        Rect.fromLTWH(
          app.left,
          app.top + app.height * 0.2,
          app.width,
          app.height * 0.28,
        ),
        Paint()..color = faint,
      )
      ..drawRect(
        Rect.fromLTWH(
          app.left,
          app.top + app.height * 0.54,
          app.width,
          app.height * 0.2,
        ),
        Paint()..color = faint,
      )
      ..drawCircle(
        Offset(app.right - pad * 2, app.bottom - pad * 2),
        pad * 1.6,
        Paint()..color = gold,
      );

    // The code for it, the last line being typed.
    final seed = StationSeed('hero.code');
    final code = Rect.fromLTRB(
      phone.right + inner.width * 0.06,
      inner.top,
      inner.right,
      inner.bottom,
    );
    const lines = 7;
    final lineGap = code.height / lines;
    final bar = lineGap * 0.42;
    const indents = [0, 1, 2, 2, 1, 2, 1];
    final typed = (time / 5) % 1;
    for (var i = 0; i < lines; i++) {
      final indent = indents[i] * code.width * 0.07;
      final isLast = i == lines - 1;
      var length = code.width * seed.nextRange(0.3, 0.8);
      if (isLast) length *= time == 0 ? 0.6 : typed;
      final y = code.top + i * lineGap + (lineGap - bar) / 2;
      final firstWord = length * seed.nextRange(0.25, 0.45);
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(code.left + indent, y, firstWord, bar),
            Radius.circular(bar / 2),
          ),
          Paint()..color = gold.withValues(alpha: 0.85),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              code.left + indent + firstWord + bar,
              y,
              math.max(0, length - firstWord - bar),
              bar,
            ),
            Radius.circular(bar / 2),
          ),
          Paint()..color = faint,
        );
      if (isLast && (time == 0 || (time * 1.6) % 1 < 0.55)) {
        canvas.drawRect(
          Rect.fromLTWH(
            code.left + indent + length + bar * 0.6,
            y - bar * 0.3,
            strokeWidth * 2,
            bar * 1.6,
          ),
          Paint()..color = gold,
        );
      }
    }
  }

  /// The right screen: the automation that is building the pyramid outside,
  /// lit in step with the crane.
  void _paintAutomation(Canvas canvas, Size size, Rect inner) {
    final (:phase, :placed) = _build();
    final step = phase < 0.3
        ? 0
        : phase < 0.55
        ? 1
        : 2;
    final node = inner.height * 0.34;
    final y = inner.top + inner.height * 0.3;
    final xs = [
      inner.left + node * 0.6,
      inner.left + inner.width * 0.36,
      inner.left + inner.width * 0.66,
    ];
    final wire = Paint()
      ..color = faint
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < xs.length - 1; i++) {
      canvas.drawLine(
        Offset(xs[i] + node / 2, y),
        Offset(xs[i + 1] - node / 2, y),
        wire,
      );
    }
    // The run on its way from one step to the next.
    final leg = step < 2 ? (phase - [0, 0.3][step]) / [0.3, 0.25][step] : 1.0;
    if (step < 2) {
      final from = xs[step] + node / 2;
      final to = xs[step + 1] - node / 2;
      canvas.drawCircle(
        Offset(from + (to - from) * leg.clamp(0.0, 1.0), y),
        strokeWidth * 2.4,
        Paint()..color = gold,
      );
    }
    for (var i = 0; i < xs.length; i++) {
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(xs[i], y), width: node, height: node),
        Radius.circular(node * 0.22),
      );
      canvas
        ..drawRRect(box, Paint()..color = lit.withValues(alpha: 0.35))
        ..drawRRect(
          box,
          Paint()
            ..color = i == step ? gold : edge
            ..strokeWidth = strokeWidth * (i == step ? 2 : 1)
            ..style = PaintingStyle.stroke,
        );
    }

    // Progress: the same pyramid, drawn small, filling as the crane works.
    const total = _animatedBlocks;
    final done = (placed / total).clamp(0.0, 1.0);
    final bar = Rect.fromLTWH(
      inner.left,
      inner.bottom - inner.height * 0.12,
      inner.width,
      inner.height * 0.06,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2)),
        Paint()..color = lit.withValues(alpha: 0.4),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bar.left, bar.top, bar.width * done, bar.height),
          Radius.circular(bar.height / 2),
        ),
        Paint()..color = gold,
      );
    final apex = Offset(
      inner.right - inner.width * 0.1,
      inner.top + inner.height * 0.52,
    );
    final mini = inner.height * 0.2;
    canvas.drawPath(
      Path()
        ..moveTo(apex.dx, apex.dy - mini)
        ..lineTo(apex.dx + mini * 0.8, apex.dy + mini * 0.2)
        ..lineTo(apex.dx - mini * 0.8, apex.dy + mini * 0.2)
        ..close(),
      Paint()
        ..color = Color.lerp(faint, gold, done)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.4,
    );
  }

  void _paintPhone(Canvas canvas, Size size) {
    final top = size.height * deskTop;
    final w = size.width * 0.045;
    final h = size.height * 0.085;
    final left = size.width * 0.575;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top - h, w, h),
      Radius.circular(w * 0.2),
    );
    final face = body.deflate(w * 0.08);
    canvas
      ..drawRRect(body, Paint()..color = lit)
      ..drawRRect(face, Paint()..color = screen);

    // The same app the left screen mirrors.
    final app = face.outerRect.deflate(w * 0.1);
    canvas
      ..drawRect(
        Rect.fromLTWH(app.left, app.top, app.width, app.height * 0.14),
        Paint()..color = goldDim,
      )
      ..drawRect(
        Rect.fromLTWH(
          app.left,
          app.top + app.height * 0.22,
          app.width,
          app.height * 0.26,
        ),
        Paint()..color = faint,
      )
      ..drawCircle(
        Offset(app.right - app.width * 0.2, app.bottom - app.width * 0.2),
        app.width * 0.16,
        Paint()..color = gold,
      );

    // The cable from the phone to the screen it is mirrored on.
    final plug = Offset(left + w * 0.5, top);
    final stand = Offset(size.width * 0.5, top - size.height * 0.006);
    canvas.drawPath(
      Path()
        ..moveTo(plug.dx, plug.dy)
        ..cubicTo(
          plug.dx - size.width * 0.02,
          top + size.height * 0.03,
          stand.dx + size.width * 0.04,
          top + size.height * 0.03,
          stand.dx + size.width * 0.02,
          stand.dy,
        ),
      Paint()
        ..color = edge
        ..strokeWidth = strokeWidth * 1.4
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintCup(Canvas canvas, Size size) {
    final top = size.height * deskTop;
    final w = size.width * 0.05;
    final h = size.height * 0.05;
    final left = size.width * 0.635;
    final cup = Path()
      ..moveTo(left, top - h)
      ..lineTo(left + w, top - h)
      ..lineTo(left + w * 0.86, top)
      ..lineTo(left + w * 0.14, top)
      ..close();
    canvas
      ..drawPath(cup, Paint()..color = lit)
      ..drawArc(
        Rect.fromLTWH(left + w * 0.82, top - h * 0.82, w * 0.4, h * 0.5),
        -math.pi / 2,
        math.pi,
        false,
        Paint()
          ..color = lit
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2,
      );

    // Steam, rising and thinning.
    final steam = Paint()
      ..color = faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final x = left + w * (0.35 + i * 0.3);
      final sway = math.sin(time * 1.2 + i * 1.7) * w * 0.12;
      final path = Path()
        ..moveTo(x, top - h * 1.1)
        ..cubicTo(
          x - w * 0.2 + sway,
          top - h * 1.5,
          x + w * 0.2 + sway,
          top - h * 1.8,
          x + sway,
          top - h * 2.3,
        );
      canvas.drawPath(path, steam);
    }
  }

  @override
  bool shouldRepaint(HeroScenePainter oldDelegate) =>
      oldDelegate.sun != sun ||
      oldDelegate.time != time ||
      oldDelegate.parallax != parallax ||
      oldDelegate.skyTop != skyTop ||
      oldDelegate.skyHorizon != skyHorizon ||
      oldDelegate.water != water ||
      oldDelegate.ground != ground ||
      oldDelegate.stone != stone ||
      oldDelegate.edge != edge ||
      oldDelegate.lit != lit ||
      oldDelegate.ink != ink ||
      oldDelegate.faint != faint ||
      oldDelegate.gold != gold ||
      oldDelegate.goldDim != goldDim ||
      oldDelegate.goldGlow != goldGlow ||
      oldDelegate.halo != halo ||
      oldDelegate.screen != screen ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.skin != skin ||
      oldDelegate.skinShade != skinShade;
}
