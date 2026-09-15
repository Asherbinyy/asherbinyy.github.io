import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/painting/sign_paths.dart';

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
    return SizedBox(
      width: Tokens.stopMarkSize,
      height: Tokens.stopMarkSize,
      child: CustomPaint(
        painter: _StopMarkPainter(
          sign: signFor(role),
          colour: tokens.instrumentDim,
          shadow: tokens.void_,
          light: tokens.ornamentField,
        ),
      ),
    );
  }
}

class _StopMarkPainter extends CustomPainter {
  const _StopMarkPainter({
    required this.sign,
    required this.colour,
    required this.shadow,
    required this.light,
  });

  final Sign sign;
  final Color colour;
  final Color shadow;
  final Color light;

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
      ..drawPath(path, Paint()..color = colour)
      ..restore();
  }

  @override
  bool shouldRepaint(_StopMarkPainter oldDelegate) =>
      oldDelegate.sign != sign ||
      oldDelegate.colour != colour ||
      oldDelegate.shadow != shadow ||
      oldDelegate.light != light;
}
