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
  /// A boot striking a ball into a net that takes it.
  ///
  /// Was a ball arcing away from nothing, which is a diagram of a parabola.
  /// The owner asked for a foot, a net that reads as a net, the net moving on
  /// impact, and the word. All four are what makes it a goal rather than a
  /// trajectory.
  void _football(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;

    // The strike lands a third of the way in; everything after is the net.
    const contact = 0.34;
    final struck = (progress - contact) / (1 - contact);
    final flight = struck.clamp(0.0, 1.0);

    final mouth = Rect.fromLTRB(w * 0.44, h * 0.20, w * 0.94, h * 0.66);

    // The net: posts, bar, and a mesh drawn as two crossing families of lines.
    // The mesh is what makes it a net rather than a rectangle, and it is the
    // part that moves.
    final shake = flight <= 0 || flight >= 1
        ? 0.0
        : math.sin(flight * math.pi * 7) * (1 - flight) * w * 0.035;

    canvas
      ..save()
      ..clipRect(mouth.inflate(w * 0.02));
    const mesh = 5;
    for (var i = 1; i < mesh; i++) {
      final t = i / mesh;
      // Only the lines past the ball's entry point are disturbed.
      final give = shake * math.sin(t * math.pi);
      canvas
        ..drawLine(
          Offset(mouth.left + mouth.width * t, mouth.top),
          Offset(mouth.left + mouth.width * t + give, mouth.bottom),
          line,
        )
        ..drawLine(
          Offset(mouth.left, mouth.top + mouth.height * t),
          Offset(mouth.right + give, mouth.top + mouth.height * t),
          line,
        );
    }
    canvas
      ..restore()
      ..drawRect(mouth, accent);

    // The boot: a shin swinging through, and a foot at the end of it. Thicker
    // than the rest of the scene, because at this size a foot drawn in the
    // same weight as the net reads as one more line.
    final swing = (progress / contact).clamp(0.0, 1.0);
    final angle = -1.15 + 1.5 * swing;
    final hip = Offset(w * 0.10, h * 0.30);
    final ankle = hip + Offset(math.cos(angle), math.sin(angle)) * (h * 0.32);
    final leg = Paint()
      ..color = line.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = line.strokeWidth * 2.2
      ..strokeCap = StrokeCap.round;
    // The foot points along the swing, so it follows through rather than
    // hanging off the shin at a fixed angle.
    final toe = Offset(math.cos(angle + 0.9), math.sin(angle + 0.9));
    canvas
      ..drawLine(hip, ankle, leg)
      ..drawPath(
        Path()
          ..moveTo(ankle.dx, ankle.dy)
          ..lineTo(ankle.dx + toe.dx * w * 0.16, ankle.dy + toe.dy * h * 0.16)
          ..lineTo(
            ankle.dx + toe.dx * w * 0.15 - toe.dy * w * 0.07,
            ankle.dy + toe.dy * h * 0.15 + toe.dx * h * 0.07,
          )
          ..lineTo(ankle.dx - toe.dy * w * 0.07, ankle.dy + toe.dx * h * 0.07)
          ..close(),
        Paint()..color = line.color,
      );

    // The ball, from the boot into the net.
    final ball = Offset.lerp(
      ankle + Offset(w * 0.16, h * 0.02),
      Offset(mouth.left + mouth.width * 0.62, mouth.top + mouth.height * 0.58),
      // Ease out: fast off the boot, slowing into the net.
      1 - (1 - flight) * (1 - flight),
    );
    if (ball != null) canvas.drawCircle(ball, w * 0.055, accent);

    // The word, once it is in. Drawn as a line of blocks rather than as text:
    // this painter has no access to a text style, and a shape that reads as a
    // shout at 24 pixels does the job the word was asked to do.
    if (flight < 0.72) return;
    final shout = ((flight - 0.72) / 0.28).clamp(0.0, 1.0);
    final letters = [0.16, 0.26, 0.36, 0.46];
    for (final (index, at) in letters.indexed) {
      final rise = (shout * 4 - index).clamp(0.0, 1.0);
      if (rise <= 0) continue;
      final top = h * 0.86 - h * 0.06 * rise;
      canvas.drawRect(
        Rect.fromLTWH(w * at, top, w * 0.06, h * 0.05 * rise),
        accent,
      );
    }
  }

  /// Two players, one serving.
  ///
  /// Was a ball rallying between two walls, which is padel's defining rule and
  /// reads as a dot in a box. The owner asked for people: two figures with
  /// rackets, one of them serving.
  void _padel(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final floor = h * 0.82;

    // The court: a net between them, and the back glass padel is played off.
    canvas
      ..drawLine(Offset(w * 0.5, floor), Offset(w * 0.5, h * 0.52), line)
      ..drawLine(Offset(w * 0.08, floor), Offset(w * 0.92, floor), line);

    void figure({
      required double x,
      required double swing,
      required bool serving,
    }) {
      final hip = Offset(w * x, floor - h * 0.20);
      final head = hip - Offset(0, h * 0.16);
      canvas
        ..drawCircle(head, w * 0.045, line)
        ..drawLine(head + Offset(0, w * 0.045), hip, line)
        // Legs, planted apart.
        ..drawLine(hip, hip + Offset(-w * 0.06, h * 0.20), line)
        ..drawLine(hip, hip + Offset(w * 0.06, h * 0.20), line);

      // The racket arm, and the free arm counterbalancing it. The first pass
      // swung the arm across the head, so at the start of the serve the
      // racket sat on the player's face.
      final shoulder = hip - Offset(0, h * 0.12);
      final reach = Offset(math.cos(swing), math.sin(swing));
      final hand = shoulder + reach * h * 0.15;
      final face = hand + reach * h * 0.075;
      canvas
        ..drawLine(shoulder, hand, line)
        ..drawLine(
          shoulder,
          shoulder + Offset(-reach.dx * 0.8, 0.6) * h * 0.12,
          line,
        )
        // The head of the racket, with strings across it.
        ..drawOval(
          Rect.fromCenter(center: face, width: w * 0.09, height: h * 0.12),
          serving ? accent : line,
        )
        ..drawLine(
          face - Offset(w * 0.042, 0),
          face + Offset(w * 0.042, 0),
          serving ? accent : line,
        );
    }

    // The server winds up and strikes; the receiver waits, then reacts.
    final strike = progress.clamp(0.0, 1.0);
    figure(
      x: 0.22,
      // Overhead to forward, which keeps the racket clear of the head at
      // every point in the swing.
      swing: -1.85 + 1.65 * strike,
      serving: true,
    );
    figure(
      x: 0.78,
      swing: -0.55 - 0.45 * math.sin(strike * math.pi),
      serving: false,
    );

    // The ball, tossed and then sent over.
    if (strike < 0.45) {
      final toss = strike / 0.45;
      canvas.drawCircle(
        Offset(
          w * 0.27,
          floor - h * 0.34 - h * 0.14 * math.sin(toss * math.pi),
        ),
        w * 0.035,
        accent,
      );
      return;
    }
    final over = (strike - 0.45) / 0.55;
    canvas.drawCircle(
      Offset(
        w * (0.30 + 0.42 * over),
        floor - h * 0.30 - h * 0.16 * math.sin(over * math.pi),
      ),
      w * 0.035,
      accent,
    );
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
  /// A controller, from above.
  ///
  /// The first pass was an arcade stick on a base, which the owner said looks
  /// nothing like a real one. This is the shape everybody actually holds: two
  /// shoulders, a d-pad, four face buttons and two thumbsticks. The sticks
  /// move and the buttons light in sequence, so it is a controller being used
  /// rather than a controller sitting there.
  void _gaming(Canvas canvas, Size size, Paint line, Paint accent) {
    final w = size.width;
    final h = size.height;
    final mid = h * 0.52;

    // The body: two grips under a bar, drawn as one path so it reads as one
    // moulded object.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, mid)
        ..quadraticBezierTo(w * 0.14, h * 0.34, w * 0.34, h * 0.36)
        ..lineTo(w * 0.66, h * 0.36)
        ..quadraticBezierTo(w * 0.86, h * 0.34, w * 0.90, mid)
        ..quadraticBezierTo(w * 0.94, h * 0.76, w * 0.76, h * 0.74)
        ..quadraticBezierTo(w * 0.66, h * 0.70, w * 0.58, h * 0.60)
        ..lineTo(w * 0.42, h * 0.60)
        ..quadraticBezierTo(w * 0.34, h * 0.70, w * 0.24, h * 0.74)
        ..quadraticBezierTo(w * 0.06, h * 0.76, w * 0.10, mid)
        ..close(),
      line,
    );

    // Shoulders.
    for (final x in [0.20, 0.72]) {
      canvas.drawLine(
        Offset(w * x, h * 0.33),
        Offset(w * (x + 0.08), h * 0.33),
        line,
      );
    }

    // The d-pad: a cross, with the arm under the travelling thumb lit.
    final pad = Offset(w * 0.28, h * 0.46);
    final arm = w * 0.055;
    final live = (progress * 4).floor() % 4;
    for (final (index, delta) in const <Offset>[
      Offset(0, -1),
      Offset(1, 0),
      Offset(0, 1),
      Offset(-1, 0),
    ].indexed) {
      canvas.drawLine(pad, pad + delta * arm, index == live ? accent : line);
    }

    // Face buttons: triangle, circle, cross, square, in the usual diamond.
    final face = Offset(w * 0.70, h * 0.46);
    final reach = w * 0.058;
    final radius = w * 0.026;
    final lit = (progress * 4).floor() % 4;

    final top = face + const Offset(0, -1) * reach;
    final right = face + const Offset(1, 0) * reach;
    final bottom = face + const Offset(0, 1) * reach;
    final leftFace = face + const Offset(-1, 0) * reach;

    // Triangle.
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy - radius)
        ..lineTo(top.dx + radius, top.dy + radius * 0.8)
        ..lineTo(top.dx - radius, top.dy + radius * 0.8)
        ..close(),
      lit == 0 ? accent : line,
    );
    final cross = lit == 2 ? accent : line;
    canvas
      // Circle.
      ..drawCircle(right, radius, lit == 1 ? accent : line)
      // Cross.
      ..drawLine(
        bottom + Offset(-radius, -radius),
        bottom + Offset(radius, radius),
        cross,
      )
      ..drawLine(
        bottom + Offset(radius, -radius),
        bottom + Offset(-radius, radius),
        cross,
      )
      // Square.
      ..drawRect(
        Rect.fromCenter(
          center: leftFace,
          width: radius * 1.8,
          height: radius * 1.8,
        ),
        lit == 3 ? accent : line,
      );

    // Thumbsticks, each leaning on its own phase so they do not move as one.
    for (final (index, x) in [0.42, 0.58].indexed) {
      final phase = progress * math.pi * 2 + index * math.pi * 0.7;
      final home = Offset(w * x, h * 0.63);
      canvas
        ..drawCircle(home, w * 0.05, line)
        ..drawCircle(
          home + Offset(math.cos(phase), math.sin(phase)) * w * 0.018,
          w * 0.028,
          accent,
        );
    }
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
