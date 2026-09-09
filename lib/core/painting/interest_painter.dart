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

  /// A book, opening.
  reading,

  /// A screen, with a scene moving across it.
  television,

  /// A joystick, worked back and forth.
  gaming,

  /// Anything with no scene of its own.
  seal;

  /// The scene for an interest id.
  static InterestScene of(String id) => switch (id) {
    'gym' => InterestScene.gym,
    'football' => InterestScene.football,
    'padel' => InterestScene.padel,
    'reading' => InterestScene.reading,
    'television' => InterestScene.television,
    'gaming' => InterestScene.gaming,
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
      case InterestScene.gaming:
        _gaming(canvas, size, line, accent);
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
  /// A book opening, seen from above.
  ///
  /// It was a papyrus roll unrolling from a spindle, which is more Egyptian
  /// and, as the owner said, does not look like a book. Two leaves rising off
  /// a spine reads as one immediately.
  void _reading(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final spine = w * 0.5;
    final top = h * 0.30;
    final foot = h * 0.72;
    // Closed at rest, open at the end: the covers swing up from the spine.
    final open = (w * 0.34) * (0.12 + 0.88 * progress);
    // The leaves lift as they part, which is what stops it reading flat.
    final lift = h * 0.10 * progress;

    for (final side in [-1, 1]) {
      final edge = spine + side * open;
      canvas.drawPath(
        Path()
          ..moveTo(spine, top)
          ..lineTo(edge, top - lift)
          ..lineTo(edge, foot - lift)
          ..lineTo(spine, foot)
          ..close(),
        line,
      );

      // Pages, drawn only once there is width to hold them.
      if (open <= w * 0.08) continue;
      for (var i = 1; i <= 3; i++) {
        final y = top + (foot - top) * (i / 4);
        canvas.drawLine(
          Offset(spine + side * open * 0.18, y - lift * (i / 4)),
          Offset(spine + side * open * 0.82, y - lift * (i / 4)),
          line,
        );
      }
    }

    // The spine itself, which is the one part that never moves.
    canvas.drawLine(Offset(spine, top), Offset(spine, foot), accent);
  }

  /// A screen with something happening on it.
  ///
  /// It used to be a set of scales, on the reasoning that Better Call Saul is
  /// a lawyer's story and the weighing of the heart is the oldest courtroom
  /// there is. That is a good sentence and a bad drawing: nobody looking at
  /// scales thinks "television", and the owner said twice that this one was
  /// wrong.
  ///
  /// So it is a screen. The light inside it travels, which is the difference
  /// between a television and a box.
  void _television(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final screen = Rect.fromLTRB(w * 0.14, h * 0.22, w * 0.86, h * 0.68);
    final rounded = RRect.fromRectAndRadius(screen, Radius.circular(w * 0.05));

    canvas
      ..drawRRect(rounded, line)
      // The stand: a stem and a foot, which is what stops it reading as a
      // window.
      ..drawLine(
        Offset(w * 0.5, screen.bottom),
        Offset(w * 0.5, h * 0.80),
        line,
      )
      ..drawLine(Offset(w * 0.34, h * 0.80), Offset(w * 0.66, h * 0.80), line)
      ..save()
      ..clipRRect(rounded);

    // A band of light sweeping across, wrapping round. This is the whole
    // animation, and it is the only thing in the grid that suggests something
    // is playing rather than sitting still.
    final sweep = screen.left + screen.width * ((progress * 1.4) % 1.2 - 0.2);
    canvas.drawLine(
      Offset(sweep, screen.top),
      Offset(sweep + screen.width * 0.10, screen.bottom),
      accent,
    );

    // Two figures on the screen, because a lit rectangle is a lamp.
    for (final (x, scale) in [(0.36, 0.62), (0.60, 0.78)]) {
      final base = screen.bottom - screen.height * 0.14;
      final head = base - screen.height * scale * 0.52;
      canvas
        ..drawCircle(
          Offset(screen.left + screen.width * x, head),
          w * 0.035,
          line,
        )
        ..drawLine(
          Offset(screen.left + screen.width * x, head + w * 0.045),
          Offset(screen.left + screen.width * x, base),
          line,
        );
    }
    canvas.restore();
  }

  /// Two players facing off across a field, one advancing.
  /// A joystick, worked side to side.
  ///
  /// Was two figures facing off across a field, which read as football with
  /// extra steps. A stick and a ball on a base is the one shape everybody
  /// recognises as playing, and it has somewhere obvious to put the motion.
  void _gaming(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final pivot = Offset(w * 0.5, h * 0.68);

    // The base, in perspective: a flat slab rather than a rectangle.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.26, h * 0.72)
        ..lineTo(w * 0.74, h * 0.72)
        ..lineTo(w * 0.82, h * 0.84)
        ..lineTo(w * 0.18, h * 0.84)
        ..close(),
      line,
    );

    // A full sweep left and right across the run, easing at each end so it
    // reads as a hand rather than a metronome.
    final swing = math.sin(progress * math.pi * 2) * 0.42;
    final top = Offset(
      pivot.dx + math.sin(swing) * w * 0.30,
      pivot.dy - math.cos(swing) * h * 0.34,
    );
    canvas
      ..drawLine(pivot, top, line)
      ..drawCircle(top, w * 0.085, accent)
      // Two buttons on the base, the near one lit as the stick reaches.
      ..drawCircle(
        Offset(w * 0.36, h * 0.78),
        w * 0.035,
        swing < -0.2 ? accent : line,
      )
      ..drawCircle(
        Offset(w * 0.64, h * 0.78),
        w * 0.035,
        swing > 0.2 ? accent : line,
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
