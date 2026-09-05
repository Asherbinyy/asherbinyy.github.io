import 'dart:math' as math;

import 'package:nocturne/app/theme/tokens.dart';

/// The single curve function behind every carrier on the site.
///
/// The telemetry trace (`01-DESIGN-SYSTEM.md` section 6), the indeterminate
/// loader (section 11) and the mark (section 12) are the same waveform at
/// different parameters. Section 12 requires the mark to be a frame lifted from
/// the trace rather than drawn independently, so the shape lives here once and
/// every consumer samples it.
abstract final class CarrierWave {
  /// Samples the travelling carrier, normalised to -1..1.
  ///
  /// [position] runs 0..1 across the container in the reading direction and
  /// [phase] runs 0..1 through one full cycle of travel. Callers scale the
  /// result to their own amplitude, so this function carries no pixel values.
  static double sample({
    required double position,
    required double phase,
    double cycles = Tokens.carrierRestCycles,
  }) => math.sin(2 * math.pi * (position * cycles - phase));

  /// The Gaussian window that turns a stretch of carrier into a burst.
  ///
  /// Peaks at 1 when [position] equals [centre] and decays symmetrically, so
  /// the burst has no hard edges to alias at small sizes. Career roles are
  /// bursts on the trace and the mark is this envelope frozen at its peak.
  static double burstEnvelope({
    required double position,
    required double centre,
    double width = Tokens.carrierBurstWidth,
  }) {
    if (width <= 0) return position == centre ? 1 : 0;
    final offset = position - centre;
    return math.exp(-(offset * offset) / (2 * width * width));
  }

  /// A carrier held at [restAmplitude] and swelling to full under a burst.
  ///
  /// This is the miniature the loader draws and the shape the trace scales up:
  /// a low baseline that rises where a burst is centred.
  static double burst({
    required double position,
    required double phase,
    required double centre,
    double cycles = Tokens.carrierRestCycles,
    double width = Tokens.carrierBurstWidth,
    double restAmplitude = Tokens.carrierRestAmplitude,
  }) {
    final envelope = burstEnvelope(
      position: position,
      centre: centre,
      width: width,
    );
    final amplitude = restAmplitude + (1 - restAmplitude) * envelope;
    return sample(position: position, phase: phase, cycles: cycles) * amplitude;
  }
}
