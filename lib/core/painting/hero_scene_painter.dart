import 'dart:math' as math;

import 'package:flutter/widgets.dart';

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
/// * **A seated figure** (`Sign.seated`, the determinative for a person) works
///   at a laptop, with a phone beside it: a mobile developer at his desk.
/// * **Stars** at night, five-pointed like the ones painted on tomb ceilings.
///
/// No pyramid silhouette and no palm tree: `12-MOTIF-LIBRARY.md` rules both
/// out as travel-agency iconography, and the picture does not need them.
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
    final via = Offset(size.width * 0.9, size.height * 0.2);
    final to = Offset(size.width * 0.66, size.height * 0.2);
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

    _layer(canvas, 0.5, () => _paintObelisks(canvas, size, horizonY, sunUp));

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
      _paintFigure(canvas, size);
      _paintLaptop(canvas, size, night);
      _paintPhone(canvas, size);
      _paintCup(canvas, size);
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
    final pool = Offset(size.width * 0.56, top);
    final reach = size.width * 0.34;
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

  void _paintFigure(Canvas canvas, Size size) {
    // The climber from the courtyard, sat down at his desk: the same gold,
    // the same close nemes and kilt, drawn the Egyptian way -- head and legs
    // in profile, shoulders square to the viewer -- and reaching for the
    // keyboard. Gold because he is the person, which is gold's first job.
    final unit = size.height * 0.34;
    final hip = Offset(size.width * 0.25, size.height * deskTop);
    Offset p(double dx, double dy) => hip + Offset(dx * unit, dy * unit);

    final solid = Paint()..color = gold;
    final limb = Paint()
      ..color = gold
      ..strokeWidth = math.max(strokeWidth * 1.6, unit * 0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final far = Paint()
      ..color = goldDim
      ..strokeWidth = limb.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final typing = time == 0 ? 0.0 : math.sin(time * 9) * 0.012;

    canvas
      // The far arm, behind the body, a shade darker so it reads as behind.
      ..drawPath(
        Path()
          ..moveTo(p(0.07, -0.39).dx, p(0.07, -0.39).dy)
          ..lineTo(p(0.17, -0.21).dx, p(0.17, -0.21).dy)
          ..lineTo(p(0.36, -0.045 - typing).dx, p(0.36, -0.045 - typing).dy),
        far,
      )
      // Cross-legged: the thigh forward along the ground, the shin folded
      // back beneath it.
      ..drawLine(p(0.02, -0.04), p(0.3, -0.06), limb)
      ..drawLine(p(0.3, -0.06), p(0.13, -0.015), limb)
      // The shendyt.
      ..drawPath(
        Path()
          ..moveTo(p(-0.06, -0.13).dx, p(-0.06, -0.13).dy)
          ..lineTo(p(0.08, -0.13).dx, p(0.08, -0.13).dy)
          ..lineTo(p(0.2, 0).dx, p(0.2, 0).dy)
          ..lineTo(p(-0.07, 0).dx, p(-0.07, 0).dy)
          ..close(),
        solid,
      )
      // The torso, broad at the shoulder and drawn in at the waist.
      ..drawPath(
        Path()
          ..moveTo(p(-0.05, -0.12).dx, p(-0.05, -0.12).dy)
          ..lineTo(p(0.06, -0.12).dx, p(0.06, -0.12).dy)
          ..lineTo(p(0.13, -0.395).dx, p(0.13, -0.395).dy)
          ..quadraticBezierTo(
            p(0.03, -0.43).dx,
            p(0.03, -0.43).dy,
            p(-0.07, -0.395).dx,
            p(-0.07, -0.395).dy,
          )
          ..close(),
        solid,
      )
      // Neck.
      ..drawLine(p(0.035, -0.4), p(0.05, -0.45), limb)
      // The head, in profile, facing the work.
      ..drawOval(
        Rect.fromCenter(
          center: p(0.065, -0.5),
          width: unit * 0.11,
          height: unit * 0.125,
        ),
        solid,
      )
      // The nemes: over the crown and falling behind the neck, tight enough
      // to read as a headcloth rather than as hair.
      ..drawPath(
        Path()
          ..moveTo(p(0.115, -0.525).dx, p(0.115, -0.525).dy)
          ..quadraticBezierTo(
            p(0.07, -0.6).dx,
            p(0.07, -0.6).dy,
            p(0.005, -0.535).dx,
            p(0.005, -0.535).dy,
          )
          ..lineTo(p(-0.03, -0.41).dx, p(-0.03, -0.41).dy)
          ..lineTo(p(0.01, -0.43).dx, p(0.01, -0.43).dy)
          ..lineTo(p(0.035, -0.5).dx, p(0.035, -0.5).dy)
          ..lineTo(p(0.11, -0.505).dx, p(0.11, -0.505).dy)
          ..close(),
        Paint()..color = goldGlow,
      )
      // The near arm: shoulder, elbow, a hand on the keys.
      ..drawPath(
        Path()
          ..moveTo(p(0.11, -0.38).dx, p(0.11, -0.38).dy)
          ..lineTo(p(0.2, -0.22).dx, p(0.2, -0.22).dy)
          ..lineTo(p(0.4, -0.05 + typing).dx, p(0.4, -0.05 + typing).dy),
        limb,
      );
  }

  void _paintLaptop(Canvas canvas, Size size, double night) {
    final top = size.height * deskTop;
    final cx = size.width * 0.56;
    final screenW = size.width * 0.34;
    final screenH = size.height * 0.2;
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cx - screenW / 2,
        top - size.height * 0.012 - screenH,
        screenW,
        screenH,
      ),
      Radius.circular(size.shortestSide * 0.012),
    );

    // The base, seen almost edge-on.
    final baseW = screenW * 1.12;
    final base = Path()
      ..moveTo(cx - baseW / 2, top)
      ..lineTo(cx - screenW / 2, top - size.height * 0.012)
      ..lineTo(cx + screenW / 2, top - size.height * 0.012)
      ..lineTo(cx + baseW / 2, top)
      ..close();

    canvas
      ..drawPath(base, Paint()..color = lit)
      ..drawRRect(screen, Paint()..color = this.screen)
      ..drawRRect(
        screen,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      )
      ..drawRRect(
        screen,
        Paint()
          ..shader = RadialGradient(
            colors: [
              goldGlow.withValues(alpha: 0.08 + 0.08 * night),
              goldGlow.withValues(alpha: 0),
            ],
          ).createShader(screen.outerRect),
      );

    // Code: bars of different lengths at different indents, the gold ones
    // the words that matter. The last line is being typed.
    final seed = StationSeed('hero.code');
    final inner = screen.outerRect.deflate(size.shortestSide * 0.022);
    const lines = 7;
    final lineGap = inner.height / lines;
    final bar = lineGap * 0.42;
    const indents = [0, 1, 2, 2, 1, 2, 1];
    final typed = (time / 5) % 1;
    for (var i = 0; i < lines; i++) {
      final indent = indents[i] * inner.width * 0.07;
      final isLast = i == lines - 1;
      var length = inner.width * seed.nextRange(0.28, 0.72);
      if (isLast) length *= time == 0 ? 0.6 : typed;
      final y = inner.top + i * lineGap + (lineGap - bar) / 2;
      final firstWord = length * seed.nextRange(0.25, 0.45);
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(inner.left + indent, y, firstWord, bar),
            Radius.circular(bar / 2),
          ),
          Paint()..color = gold.withValues(alpha: 0.85),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              inner.left + indent + firstWord + bar,
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
            inner.left + indent + length + bar * 0.6,
            y - bar * 0.3,
            strokeWidth * 2,
            bar * 1.6,
          ),
          Paint()..color = gold,
        );
      }
    }
  }

  void _paintPhone(Canvas canvas, Size size) {
    final top = size.height * deskTop;
    final w = size.width * 0.085;
    final h = size.height * 0.16;
    final left = size.width * 0.8;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top - h, w, h),
      Radius.circular(w * 0.18),
    );
    final face = body.deflate(w * 0.07);
    canvas
      ..drawRRect(body, Paint()..color = lit)
      ..drawRRect(face, Paint()..color = screen);

    // An app on it: a header, two cards, a button -- what he builds.
    final pad = face.width * 0.12;
    final inner = face.outerRect.deflate(pad);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inner.left,
            inner.top,
            inner.width,
            inner.height * 0.12,
          ),
          Radius.circular(pad * 0.4),
        ),
        Paint()..color = goldDim,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inner.left,
            inner.top + inner.height * 0.2,
            inner.width,
            inner.height * 0.26,
          ),
          Radius.circular(pad * 0.4),
        ),
        Paint()..color = faint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inner.left,
            inner.top + inner.height * 0.52,
            inner.width,
            inner.height * 0.2,
          ),
          Radius.circular(pad * 0.4),
        ),
        Paint()..color = faint,
      )
      ..drawCircle(
        Offset(inner.right - pad * 0.9, inner.bottom - pad * 0.9),
        pad * 0.9,
        Paint()..color = gold,
      );
  }

  void _paintCup(Canvas canvas, Size size) {
    final top = size.height * deskTop;
    final w = size.width * 0.05;
    final h = size.height * 0.05;
    final left = size.width * 0.06;
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
      oldDelegate.strokeWidth != strokeWidth;
}
