import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// One readable shot: wind-up, boot contact, flight, then net impact.
abstract final class FootballScene {
  /// The instant the boot reaches the stationary ball.
  static const contact = 0.28;

  /// The instant the ball enters the net; also starts the GOAL caption.
  static const impact = 0.68;

  /// Draws in normalized plate coordinates; the floor anchors both feet.
  static void paint(
    Canvas canvas,
    Size size,
    double progress,
    Paint ink,
    Paint accent,
  ) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(w * x, h * y);
    final flight = ((progress - contact) / (impact - contact)).clamp(0.0, 1.0);
    final after = ((progress - impact) / (1 - impact)).clamp(0.0, 1.0);
    final ripple = math.sin(after * math.pi * 4) * (1 - after) * 0.045;
    final net = Paint()
      ..color = ink.color.withValues(alpha: 0.45)
      ..strokeWidth = ink.strokeWidth * 0.65
      ..style = PaintingStyle.stroke;
    final front = Rect.fromLTRB(w * 0.64, h * 0.25, w * 0.86, h * 0.77);
    final back = Rect.fromLTRB(w * 0.74, h * 0.32, w * 0.96, h * 0.77);
    canvas
      ..drawLine(p(0.07, 0.79), p(0.97, 0.79), net)
      ..drawRect(back, net)
      ..drawLine(front.topLeft, back.topLeft, net)
      ..drawLine(front.topRight, back.topRight, net)
      ..drawLine(front.bottomLeft, back.bottomLeft, net);
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      canvas
        ..drawPath(
          Path()
            ..moveTo(back.left + back.width * t, back.top)
            ..quadraticBezierTo(
              back.left + back.width * t + w * ripple,
              h * 0.58,
              back.left + back.width * t,
              back.bottom,
            ),
          net,
        )
        ..drawLine(
          Offset.lerp(back.topLeft, back.bottomLeft, t)!,
          Offset.lerp(back.topRight, back.bottomRight, t)!,
          net,
        );
    }
    canvas.drawPath(
      Path()
        ..moveTo(front.left, front.bottom)
        ..lineTo(front.left, front.top)
        ..lineTo(front.right, front.top)
        ..lineTo(front.right, front.bottom),
      ink,
    );

    final wind = (progress / contact).clamp(0.0, 1.0);
    final recover = ((progress - contact) / 0.55).clamp(0.0, 1.0);
    final hip = p(0.22, 0.53);
    final body = Paint()
      ..color = ink.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = ink.strokeWidth * 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ankle = Offset.lerp(p(0.09, 0.64), p(0.32, 0.73), wind)!;
    final leg = Offset.lerp(ankle, p(0.26, 0.72), recover)!;
    canvas
      ..drawCircle(p(0.23, 0.26), h * 0.047, body)
      ..drawLine(p(0.23, 0.32), hip, body)
      ..drawPath(
        Path()
          ..moveTo(w * 0.23, h * 0.37)
          ..lineTo(w * 0.15, h * 0.42)
          ..lineTo(w * 0.10, h * 0.35),
        body,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.23, h * 0.37)
          ..lineTo(w * 0.30, h * 0.41)
          ..lineTo(w * 0.33, h * 0.35),
        body,
      )
      ..drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..lineTo(w * 0.19, h * 0.66)
          ..lineTo(w * 0.17, h * 0.76)
          ..lineTo(w * 0.22, h * 0.76),
        body,
      )
      ..drawLine(hip, leg, body)
      ..drawLine(leg, leg + p(0.052, 0.015), body);

    final ball = progress <= impact
        ? p(
            0.403 + 0.42 * flight,
            0.74 - 0.17 * flight - 0.19 * math.sin(flight * math.pi),
          )
        : p(
            0.823 + 0.025 * math.sin(after * math.pi),
            0.57 + 0.17 * after - 0.06 * math.sin(after * math.pi * 2).abs(),
          );
    final radius = h * 0.042;
    canvas.drawCircle(ball, radius, accent);
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 + flight * math.pi * 2;
      canvas.drawLine(
        ball,
        ball + Offset(math.cos(angle), math.sin(angle)) * radius * 0.7,
        net,
      );
    }
  }
}
