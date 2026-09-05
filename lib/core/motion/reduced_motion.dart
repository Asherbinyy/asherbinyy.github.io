import 'package:flutter/widgets.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// The single read point for the browser's reduced-motion preference.
abstract final class ReducedMotion {
  /// Registers a dependency so changes are observed while the app runs.
  static bool of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Settles ordinary motion immediately when requested.
  static Duration duration(BuildContext context, Duration normal) =>
      resolve(disableAnimations: of(context), normal: normal);

  /// Pure policy for ordinary animations; acquisition has its own minimal fade.
  static Duration resolve({
    required bool disableAnimations,
    required Duration normal,
  }) => disableAnimations ? Tokens.noMotion : normal;

  /// The specification's explicit reduced-motion exception.
  static Duration acquisition(BuildContext context) =>
      of(context) ? Tokens.reducedAcquisition : Tokens.sequence;
}
