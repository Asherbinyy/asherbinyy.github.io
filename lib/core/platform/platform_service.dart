import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/pointer_capabilities.dart';

/// Interaction category, resolved from the primary pointer first.
enum InputMode {
  /// Coarse pointer, with generous hit targets.
  touch,

  /// Hover-capable, precise pointer.
  pointer,
}

/// Layout categories are secondary to interaction capability.
enum ViewportClass {
  /// Below the medium breakpoint.
  compact,

  /// Single column with a wider gutter.
  medium,

  /// Twelve-column layout.
  expanded,

  /// Widest documented layout.
  large,
}

/// The only resolution point for input, density, and viewport categories.
class PlatformService {
  /// Takes injectable media-query results for deterministic tests.
  const PlatformService({
    required this.capabilities,
    required this.viewportWidth,
  });

  /// Current capability snapshot.
  final PointerCapabilities capabilities;

  /// LayoutBuilder's available width, used only as a secondary signal.
  final double viewportWidth;

  /// Capability precedence is independent of the viewport size.
  InputMode get inputMode {
    if (capabilities.canHover && capabilities.hasFinePointer) {
      return InputMode.pointer;
    }
    if (capabilities.hasCoarsePointer) return InputMode.touch;
    return viewportWidth >= Tokens.expandedBreakpoint
        ? InputMode.pointer
        : InputMode.touch;
  }

  /// Whether touch interaction conventions apply.
  bool get isTouch => inputMode == InputMode.touch;

  /// Whether pointer interaction conventions apply.
  bool get isPointer => inputMode == InputMode.pointer;

  /// Minimum target dimension for the active input category.
  double get minimumTarget => switch (inputMode) {
    InputMode.touch => Tokens.touchTarget,
    InputMode.pointer => Tokens.pointerTarget,
  };

  /// Centralized responsive layout resolution.
  ViewportClass get viewport => switch (viewportWidth) {
    < Tokens.mediumBreakpoint => ViewportClass.compact,
    < Tokens.expandedBreakpoint => ViewportClass.medium,
    < Tokens.largeBreakpoint => ViewportClass.expanded,
    _ => ViewportClass.large,
  };

  /// Horizontal content gutter for this viewport.
  double get gutter => switch (viewport) {
    ViewportClass.compact => Tokens.compactGutter,
    ViewportClass.medium => Tokens.mediumGutter,
    ViewportClass.expanded => Tokens.expandedGutter,
    ViewportClass.large => Tokens.largeGutter,
  };

  /// The vertical gap between one section of a long page and the next.
  ///
  /// It was a flat 96 everywhere, which the owner said made the desktop page
  /// too spread out — and he is right about why: a gap is read against the
  /// width beside it, so the same 96 points that separate two sections on a
  /// phone read as a hole on a 1440 monitor with a measure-capped column in the
  /// middle of it. It gets *smaller* as the frame grows, which is the opposite
  /// of the usual rule and the correct one here.
  double get sectionGap => switch (viewport) {
    ViewportClass.compact => Tokens.space64,
    ViewportClass.medium => Tokens.space64,
    ViewportClass.expanded => Tokens.space48,
    ViewportClass.large => Tokens.space48,
  };
}
