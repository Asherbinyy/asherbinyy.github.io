import 'package:nocturne/app/theme/tokens.dart';

/// Motion names alias the single token source.
abstract final class Motion {
  /// Small state flips.
  static const instant = Tokens.instant;

  /// Hover and focus.
  static const quick = Tokens.quick;

  /// Routes and panels.
  static const standard = Tokens.standard;

  /// Deliberate selection.
  static const considered = Tokens.considered;

  /// Acquisition beats.
  static const sequence = Tokens.sequence;

  /// Reduced acquisition fade.
  static const reducedAcquisition = Tokens.reducedAcquisition;
}
