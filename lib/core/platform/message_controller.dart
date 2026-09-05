import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nocturne/core/platform/message_state.dart';

part 'message_controller.g.dart';

/// Owns the timer so no widget timer survives disposal or message replacement.
@riverpod
class MessageController extends _$MessageController {
  Timer? _timer;
  bool _isHovered = false;
  bool _isFocused = false;

  /// Starts empty and cancels timers with the provider scope.
  @override
  MessageState build(Duration lifetime) {
    ref.onDispose(() => _timer?.cancel());
    return const NoMessage();
  }

  /// Replaces an older message and starts a fresh display interval.
  void show({required String text, required String closeLabel}) {
    _isHovered = false;
    _isFocused = false;
    state = VisibleMessage(text: text, closeLabel: closeLabel);
    _schedule();
  }

  /// Dismisses by timeout, close button, or touch swipe.
  void dismiss() {
    _timer?.cancel();
    state = const NoMessage();
  }

  /// Pointer hover keeps a message available until the viewer leaves it.
  void setHovered({required bool value}) {
    _isHovered = value;
    _schedule();
  }

  /// Keyboard focus receives the same persistence as pointer hover.
  void setFocused({required bool value}) {
    _isFocused = value;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (state is VisibleMessage && !_isHovered && !_isFocused) {
      _timer = Timer(lifetime, dismiss);
    }
  }
}
