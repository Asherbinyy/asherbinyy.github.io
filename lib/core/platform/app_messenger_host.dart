import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/app_messenger.dart';
import 'package:nocturne/core/platform/message_controller.dart';
import 'package:nocturne/core/platform/message_state.dart';
import 'package:nocturne/core/platform/message_surface.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// One transient-message overlay shared by all routes.
class AppMessengerHost extends ConsumerWidget {
  /// Wraps the routed content without inserting navigation or feature UI.
  const AppMessengerHost({required this.child, super.key});

  /// Routed app content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      messageControllerProvider(Tokens.messageLifetime),
    );
    return switch (message) {
      NoMessage() => child,
      VisibleMessage() => Stack(
        fit: StackFit.expand,
        children: [
          child,
          Align(
            alignment:
                AppMessenger.resolve(context.platform) ==
                    MessagePresentation.toast
                ? AlignmentDirectional.topEnd
                : AlignmentDirectional.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(Tokens.space16),
                child: Dismissible(
                  key: ObjectKey(message),
                  direction: context.platform.isTouch
                      ? DismissDirection.down
                      : DismissDirection.none,
                  movementDuration: ReducedMotion.duration(
                    context,
                    Tokens.standard,
                  ),
                  resizeDuration: null,
                  onDismissed: (_) => ref
                      .read(
                        messageControllerProvider(Tokens.messageLifetime)
                            .notifier,
                      )
                      .dismiss(),
                  child: MessageSurface(message: message),
                ),
              ),
            ),
          ),
        ],
      ),
    };
  }
}
