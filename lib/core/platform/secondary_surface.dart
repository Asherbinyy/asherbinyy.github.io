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
        builder: (_) => child,
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
        child: child,
      ),
    );
  }
}
