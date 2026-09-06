/// Transient message state has no nullable payload combinations.
sealed class MessageState {
  /// Base state.
  const MessageState();
}

/// No overlay is present.
final class NoMessage extends MessageState {
  /// Empty state.
  const NoMessage();
}

/// Copy is supplied by the caller's localization layer.
final class VisibleMessage extends MessageState {
  /// Requires a localized close label as well as the message.
  const VisibleMessage({required this.text, required this.closeLabel});

  /// Localized message text, also announced by the live region.
  final String text;

  /// Localized visible close affordance and semantic label.
  final String closeLabel;
}
