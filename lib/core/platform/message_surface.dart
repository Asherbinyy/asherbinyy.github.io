import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/message_controller.dart';
import 'package:nocturne/core/platform/message_close_button.dart';
import 'package:nocturne/core/platform/message_state.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// Minimal token-styled transient feedback, with no invented copy or icons.
class MessageSurface extends ConsumerWidget {
  /// Copy is owned by the future feature calling the messenger.
  const MessageSurface({required this.message, super.key});

  /// The visible message.
  final VisibleMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      messageControllerProvider(Tokens.messageLifetime).notifier,
    );
    return MouseRegion(
      onEnter: (_) => controller.setHovered(value: context.platform.isPointer),
      onExit: (_) => controller.setHovered(value: false),
      child: Focus(
        skipTraversal: true,
        onFocusChange: (value) => controller.setFocused(value: value),
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: context.tokens.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Tokens.controlRadius),
              side: BorderSide(color: context.tokens.hairlineStrong),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Tokens.space12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(message.text)),
                  const SizedBox(width: Tokens.space12),
                  MessageCloseButton(message: message),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
