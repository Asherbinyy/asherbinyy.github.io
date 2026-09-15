import 'package:material_ui/material_ui.dart';

/// Where the pointer is on the page, for anything drawn behind the content.
///
/// The wall down the trailing edge is a background layer: the scrolling
/// content sits on top of it and fills the frame, so a `MouseRegion` inside
/// the wall never sees a hover — the scroll view is hit first and the wall is
/// its sibling, not its ancestor.
///
/// So the pointer is captured once, above both, and published here in global
/// coordinates. A layer that wants it converts to its own space through its own
/// render box, which is the only place that knows where it ended up.
///
/// Null whenever the pointer has left, and on touch, where there is nothing to
/// follow.
class PointerBeacon extends InheritedNotifier<ValueNotifier<Offset?>> {
  /// Publishes [position] to everything below it.
  const PointerBeacon({
    required ValueNotifier<Offset?> position,
    required super.child,
    super.key,
  }) : super(notifier: position);

  /// The current global pointer position, or null.
  ///
  /// Subscribes: a caller rebuilds when the pointer moves, which is the point.
  static Offset? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PointerBeacon>()
      ?.notifier
      ?.value;

  /// The notifier itself, without subscribing to it.
  ///
  /// For a listener that has to act the moment the pointer moves rather than
  /// on the next build. Hover is delivered after a frame is laid out, so a
  /// layer that reads [of] during its build learns about the pointer one
  /// frame late -- which is one frame of an animation lost every time the
  /// hand arrives.
  static ValueNotifier<Offset?>? notifierOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PointerBeacon>()?.notifier;
}
