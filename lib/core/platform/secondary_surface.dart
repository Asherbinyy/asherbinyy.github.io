import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// Platform-specific presentation without feature-level capability branches.
extension SecondarySurfaceContext on BuildContext {
  /// Touch gets a draggable sheet; pointer gets a dialog with Escape handling.
  Future<T?> presentSecondary<T>({required Widget child}) {
    final duration = ReducedMotion.duration(this, Tokens.standard);
    if (platform.isTouch) {
      return showModalBottomSheet<T>(
        context: this,
        useSafeArea: true,
        showDragHandle: true,
        // Without this a sheet is capped at half the screen and simply clips
        // whatever does not fit, which is what a long career summary always
        // does on a phone. The owner reported the timeline sheets as broken
        // and this is why: the content was never allowed to be tall, and was
        // never allowed to scroll either.
        isScrollControlled: true,
        backgroundColor: tokens.surfaceRaised,
        elevation: Tokens.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.modalRadius),
          side: BorderSide(color: tokens.hairlineStrong),
        ),
        sheetAnimationStyle: AnimationStyle(
          duration: duration,
          reverseDuration: duration,
          curve: Tokens.emphasized,
          reverseCurve: Tokens.exit,
        ),
        builder: (_) => _Scrollable(
          maxHeightFraction: Tokens.sheetMaxHeightFraction,
          child: child,
        ),
      );
    }
    return showDialog<T>(
      context: this,
      animationStyle: AnimationStyle(
        duration: duration,
        reverseDuration: duration,
        curve: Tokens.emphasized,
        reverseCurve: Tokens.exit,
      ),
      builder: (_) => Dialog(
        backgroundColor: tokens.surfaceRaised,
        elevation: Tokens.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.modalRadius),
          side: BorderSide(color: tokens.hairlineStrong),
        ),
        // A dialog clips too, on a short laptop window with a long summary in
        // it. The same treatment, at a slightly taller ceiling because a
        // dialog is centred rather than anchored to an edge.
        child: _Scrollable(
          maxHeightFraction: Tokens.dialogMaxHeightFraction,
          child: child,
        ),
      ),
    );
  }
}

/// Caps a secondary surface and lets its content scroll inside the cap.
///
/// Both surfaces handed their child straight through, so anything taller than
/// the surface was simply cut off, with no way to reach the rest of it. A
/// career summary on a phone is reliably taller than half a screen, which is
/// what a bottom sheet gives you by default.
///
/// The cap is a maximum, not a height. A short panel still renders short,
/// because the scroll view takes its child's height inside the constraint:
/// filling the screen with a mostly empty sheet to show three lines would be
/// the opposite fault to the one being fixed.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.maxHeightFraction, required this.child});

  final double maxHeightFraction;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
    ),
    child: SingleChildScrollView(child: child),
  );
}
