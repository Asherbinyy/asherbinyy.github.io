import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/message_controller.dart';
import 'package:nocturne/core/platform/message_state.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// A localized close control with a visible keyboard focus border.
class MessageCloseButton extends ConsumerWidget {
  /// Uses the same message payload as the live region.
  const MessageCloseButton({required this.message, super.key});

  /// Localized close label.
  final VisibleMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    style: ButtonStyle(
      animationDuration: ReducedMotion.duration(context, Tokens.quick),
      minimumSize: WidgetStatePropertyAll(
        Size.square(context.platform.minimumTarget),
      ),
      foregroundColor: WidgetStatePropertyAll(context.tokens.beacon),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.controlRadius),
        ),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused)
              ? context.tokens.beacon
              : context.tokens.hairlineStrong,
        ),
      ),
    ),
    onPressed: () => ref
        .read(messageControllerProvider(Tokens.messageLifetime).notifier)
        .dismiss(),
    child: Text(message.closeLabel),
  );
}
