import 'package:flutter/widgets.dart';

import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// An [AnimatedSize] that is simply its child under reduced motion.
///
/// Reduced motion hands `AnimatedSize` a zero duration, and a zero-length
/// animation completes inside the layout that started it: the moment its box
/// changed size -- a window resize is enough -- it re-dirtied its own layout
/// and tripped Flutter's assertion. That only surfaced once the skills panels
/// ran the full width of the page and started changing size with the window.
/// With no motion to show there is nothing to animate, so there is no
/// animation.
class SettlingSize extends StatelessWidget {
  /// Animates [child]'s size changes over [duration], unless motion is off.
  const SettlingSize({
    required this.duration,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    super.key,
  });

  /// How long a change of size takes when motion is on.
  final Duration duration;

  /// Where the child sits while the box is between sizes.
  final AlignmentGeometry alignment;

  /// What changes size.
  final Widget child;

  @override
  Widget build(BuildContext context) => ReducedMotion.of(context)
      ? child
      : AnimatedSize(
          duration: duration,
          curve: MotionCurves.emphasized,
          alignment: alignment,
          child: child,
        );
}
