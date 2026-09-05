import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/message_controller.dart';
import 'package:nocturne/core/platform/platform_service.dart';

/// Presentation policy for transient feedback.
enum MessagePresentation {
  /// Safe-area bottom message, dismissible by swipe.
  snackbar,

  /// Upper trailing-corner message, persisting on hover.
  toast,
}

/// Capturable messenger handle; it does not retain a BuildContext.
class AppMessenger {
  /// Uses the same generated controller as AppMessengerHost.
  const AppMessenger(this._controller);

  /// Capture before an asynchronous action, then show the result afterwards.
  factory AppMessenger.of(BuildContext context) => AppMessenger(
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(messageControllerProvider(Tokens.messageLifetime).notifier),
  );

  final MessageController _controller;

  /// Resolves solely from the centralized interaction policy.
  static MessagePresentation resolve(PlatformService platform) =>
      switch (platform.inputMode) {
        InputMode.touch => MessagePresentation.snackbar,
        InputMode.pointer => MessagePresentation.toast,
      };

  /// Content and close copy must come from the caller's localization layer.
  void show(String text, {required String closeLabel}) =>
      _controller.show(text: text, closeLabel: closeLabel);

  /// Explicit dismissal, shared with all presentation modes.
  void dismiss() => _controller.dismiss();
}
