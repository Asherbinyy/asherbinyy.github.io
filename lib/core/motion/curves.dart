import 'package:nocturne/app/theme/tokens.dart';

/// Curve aliases, with no independent timing or physics values.
abstract final class MotionCurves {
  /// Entering elements.
  static const emphasized = Tokens.emphasized;

  /// Exiting elements.
  static const exit = Tokens.exit;

  /// Progress and scrub.
  static const linear = Tokens.linear;

  /// Physical elements only.
  static const spring = Tokens.spring;
}
