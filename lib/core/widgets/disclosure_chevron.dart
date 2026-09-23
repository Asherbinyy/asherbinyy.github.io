import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// The one mark that says "this opens".
///
/// There were three. The Home skills list turned a rounded arrow with the
/// emphasised curve and lit on hover; the education rows turned a different,
/// square-cornered arrow on a shorter duration and never lit; and the About
/// skill groups had no mark at all, only a hairline that grew from 16 to 32
/// pixels. That last one read as two headings with nothing under them -- a
/// visitor had no way to know they opened.
///
/// Decorative on its own: whatever it sits in owns the label and the expanded
/// state, so it is excluded from semantics rather than announced twice.
class DisclosureChevron extends StatelessWidget {
  /// [isOpen] turns it; [isLit] is hover or focus on whatever it belongs to.
  const DisclosureChevron({
    required this.isOpen,
    this.isLit = false,
    super.key,
  });

  /// Whether the thing it belongs to is showing its contents.
  final bool isOpen;

  /// Whether the pointer or keyboard focus is on the thing it belongs to.
  final bool isLit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: AnimatedRotation(
        turns: isOpen ? 0.5 : 0,
        duration: ReducedMotion.duration(context, Motion.standard),
        curve: MotionCurves.emphasized,
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: Tokens.contactIconSize,
          color: isLit ? tokens.beaconGlow : tokens.beacon,
        ),
      ),
    );
  }
}
