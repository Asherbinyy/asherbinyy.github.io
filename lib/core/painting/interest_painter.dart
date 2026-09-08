import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Which scene an interest plate draws.
///
/// Matched to the ids in `interests.json`. An id with no scene falls back to
/// the seal, so adding an interest never breaks the grid, and adding a scene
/// for it later is a one-line change here.
enum InterestScene {
  /// A figure raising a weight overhead.
  gym,

  /// A ball struck and arcing away.
  football,

  /// A rally between two walls.
  padel,

  /// A papyrus roll opening.
  reading,

  /// Scales, tipping. Better Call Saul is a lawyer's story, and the weighing
  /// of the heart against Ma'at's feather is the oldest courtroom there is.
  television,

  /// Two players facing off across a field.
  esports,

  /// Anything with no scene of its own.
  seal;

  /// The scene for an interest id.
  static InterestScene of(String id) => switch (id) {
    'gym' => InterestScene.gym,
    'football' => InterestScene.football,
    'padel' => InterestScene.padel,
    'reading' => InterestScene.reading,
    'television' => InterestScene.television,
    'esports' => InterestScene.esports,
    _ => InterestScene.seal,
  };
}

/// One interest, drawn as a small scene that moves when touched.
///
/// The owner's objection to the first version was that "gym" was the word
/// "gym". These are the same six facts doing something instead: the scenes
/// carry the meaning and the labels confirm it, rather than labels carrying
/// everything and the art being decoration.
///
/// Every scene is line work in the site's own vocabulary, animated by a single
/// `progress` value so the whole grid costs one controller and nothing here
/// allocates per frame.
class InterestPainter extends CustomPainter {
  /// Draws [scene] at [progress], 0 at rest and 1 fully played.
  const InterestPainter({
    required this.scene,
    required this.progress,
    required this.ink,
    required this.gold,
    required this.strokeWidth,
  });

  /// Which scene to draw.
  final InterestScene scene;

  /// The animation, 0 to 1.
  final double progress;

  /// Line colour.
  final Color ink;

  /// The one accent each scene is allowed.
  final Color gold;

  /// Line weight.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accent = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.4
      ..strokeCap = StrokeCap.round;

    switch (scene) {
      case InterestScene.gym:
        _gym(canvas, size, line, accent);
      case InterestScene.football:
        _football(canvas, size, line, accent);
      case InterestScene.padel:
        _padel(canvas, size, line, accent);
      case InterestScene.reading:
        _reading(canvas, size, line, accent);
      case InterestScene.television:
        _television(canvas, size, line, accent);
      case InterestScene.esports:
        _esports(canvas, size, line, accent);
      case InterestScene.seal:
        _seal(canvas, size, line);
    }
  }

  /// A standing figure pressing a bar overhead. The bar rises with progress.
  void _gym(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final centre = w / 2;
    final ground = h * 0.86;
    final headY = h * 0.34;

    canvas
      ..drawLine(Offset(w * 0.18, ground), Offset(w * 0.82, ground), line)
      ..drawCircle(Offset(centre, headY), h * 0.075, line)
      ..drawLine(
        Offset(centre, headY + h * 0.075),
        Offset(centre, h * 0.66),
        line,
      )
      // Legs, braced wider as the lift tops out.
      ..drawLine(
        Offset(centre, h * 0.66),
        Offset(centre - w * (0.1 + progress * 0.05), ground),
        line,
      )
      ..drawLine(
        Offset(centre, h * 0.66),
        Offset(centre + w * (0.1 + progress * 0.05), ground),
        line,
      );

    // The bar travels from the chest to locked out overhead.
    final barY = h * (0.5 - 0.32 * progress);
    canvas
      ..drawLine(
        Offset(centre - w * 0.26, barY),
        Offset(centre + w * 0.26, barY),
        accent,
      )
      ..drawLine(
        Offset(centre - w * 0.16, headY),
        Offset(centre - w * 0.2, barY),
        line,
      )
      ..drawLine(
        Offset(centre + w * 0.16, headY),
        Offset(centre + w * 0.2, barY),
        line,
      );

    for (final side in [-1, 1]) {
      canvas.drawCircle(
        Offset(centre + side * w * 0.26, barY),
        h * 0.055,
        line,
      );
    }
  }

  /// A ball struck from a foot, arcing across the plate.
  void _football(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final ground = h * 0.84;

    canvas.drawLine(Offset(w * 0.1, ground), Offset(w * 0.9, ground), line);

    // The arc it has travelled so far, drawn as the path rather than implied.
    final path = Path()..moveTo(w * 0.22, ground);
    const steps = 22;
    for (var i = 1; i <= steps; i++) {
      final t = (i / steps) * progress;
      final x = w * (0.22 + 0.56 * t);
      final y = ground - h * 0.62 * math.sin(t * math.pi);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, line);
    final ballX = w * (0.22 + 0.56 * progress);
    final ballY = ground - h * 0.62 * math.sin(progress * math.pi);
    canvas
      ..drawCircle(Offset(ballX, ballY), h * 0.09, accent)
      // The goal it is heading for.
      ..drawLine(Offset(w * 0.86, ground), Offset(w * 0.86, h * 0.42), line)
      ..drawLine(Offset(w * 0.86, h * 0.42), Offset(w * 0.98, h * 0.42), line);
  }

  /// A ball rallying between two walls, back and forth.
  void _padel(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;

    for (final x in [w * 0.14, w * 0.86]) {
      canvas.drawLine(Offset(x, h * 0.2), Offset(x, h * 0.8), line);
    }
    canvas.drawLine(Offset(w * 0.14, h * 0.8), Offset(w * 0.86, h * 0.8), line);

    // Two bounces across the plate, so the rally reads as a rally.
    final t = progress * 2;
    final leg = t.floor().clamp(0, 1);
    final within = t - leg;
    final from = leg == 0 ? 0.2 : 0.8;
    final to = leg == 0 ? 0.8 : 0.2;
    final x = w * (from + (to - from) * within);
    final y = h * (0.7 - 0.42 * math.sin(within * math.pi));
    canvas.drawCircle(Offset(x, y), h * 0.075, accent);
  }

  /// A roll opening from its spindle.
  void _reading(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final top = h * 0.26;
    final bottom = h * 0.74;
    final left = w * 0.16;
    final open = left + (w * 0.68) * (0.18 + 0.82 * progress);

    canvas
      ..drawLine(Offset(left, top), Offset(open, top), line)
      ..drawLine(Offset(left, bottom), Offset(open, bottom), line)
      // The spindle it unrolls from, and the roll still to come.
      ..drawLine(
        Offset(left, top - h * 0.06),
        Offset(left, bottom + h * 0.06),
        accent,
      )
      ..drawLine(Offset(open, top), Offset(open, bottom), line);

    // Lines of writing, appearing as the sheet opens.
    const rows = 4;
    for (var i = 0; i < rows; i++) {
      final y = top + (bottom - top) * ((i + 1) / (rows + 1));
      final reach = left + (open - left) * 0.86;
      if (reach <= left + w * 0.06) continue;
      canvas.drawLine(Offset(left + w * 0.05, y), Offset(reach, y), line);
    }
  }

  /// Scales, tipping. A lawyer's story, weighed the oldest way there is.
  void _television(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final centre = w / 2;
    final pivot = h * 0.3;
    // Tips one way and settles, rather than swinging forever.
    final tilt = math.sin(progress * math.pi) * 0.26;

    canvas
      ..drawLine(Offset(centre, pivot), Offset(centre, h * 0.82), line)
      ..drawLine(Offset(w * 0.28, h * 0.82), Offset(w * 0.72, h * 0.82), line);

    final arm = w * 0.3;
    final left = Offset(
      centre - arm * math.cos(tilt),
      pivot + arm * math.sin(tilt),
    );
    final right = Offset(
      centre + arm * math.cos(tilt),
      pivot - arm * math.sin(tilt),
    );
    canvas.drawLine(left, right, line);

    for (final (end, isHeavy) in [(left, true), (right, false)]) {
      final pan = end.translate(0, h * 0.12);
      canvas
        ..drawLine(end, pan, line)
        ..drawArc(
          Rect.fromCenter(center: pan, width: w * 0.2, height: h * 0.1),
          0,
          math.pi,
          false,
          isHeavy ? accent : line,
        );
    }

    // Ma'at's feather, on the lighter pan.
    canvas.drawLine(
      right.translate(0, h * 0.1),
      right.translate(0, -h * 0.02),
      accent,
    );
  }

  /// Two players facing off across a field, one advancing.
  void _esports(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final ground = h * 0.8;

    canvas
      ..drawLine(Offset(w * 0.1, ground), Offset(w * 0.9, ground), line)
      ..drawLine(Offset(w / 2, h * 0.24), Offset(w / 2, ground), line);

    for (final side in [-1, 1]) {
      // The near player advances on the halfway line; the far one holds.
      final advance = side < 0 ? progress * 0.1 : 0.0;
      final x = w * (0.5 + side * (0.28 - advance));
      canvas
        ..drawCircle(Offset(x, h * 0.44), h * 0.07, line)
        ..drawLine(Offset(x, h * 0.51), Offset(x, h * 0.68), line)
        ..drawLine(Offset(x, ground), Offset(x - w * 0.06, ground), line)
        ..drawLine(Offset(x, ground), Offset(x + w * 0.06, ground), line)
        ..drawLine(Offset(x, h * 0.68), Offset(x, ground), line);
    }

    // The contested point, travelling toward the player who is pressing.
    canvas.drawCircle(
      Offset(w * (0.5 - 0.16 * progress), h * 0.6),
      h * 0.05,
      accent,
    );
  }

  /// The fallback: a stamped ring, so an unknown interest still reads.
  void _seal(Canvas canvas, Size size, Paint line) {
    final inset = math.min(size.width, size.height) * 0.2;
    canvas.drawOval(
      Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset),
      line,
    );
  }

  @override
  bool shouldRepaint(InterestPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.scene != scene ||
      oldDelegate.ink != ink ||
      oldDelegate.gold != gold;
}
