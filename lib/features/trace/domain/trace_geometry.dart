import 'dart:math' as math;

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/carrier_wave.dart';
import 'package:nocturne/core/painting/station_seed.dart';
import 'package:nocturne/features/trace/domain/trace_state.dart';

/// One career role's burst on the trace.
///
/// `anchor` is the burst's position down the whole trace, 0..1. `amplitude`
/// scales with how long the role lasted and `density` with how many
/// applications it shipped, which is what section 6 specifies.
typedef TraceBurst = ({
  String id,
  double anchor,
  double amplitude,
  double density,
});

/// The trace's maths, kept apart from the painter so it can be tested directly.
///
/// Section 6 makes this the signature element of the site, and the amplitude
/// and coherence functions are the part a reader cannot check by looking. They
/// are pure functions here for exactly that reason.
abstract final class TraceGeometry {
  /// Months between two `YYYY-MM` marks, or null if either is unreadable.
  ///
  /// [end] being null means the role is current, which is measured against
  /// [now] rather than treated as zero length.
  static int? durationInMonths({
    required String start,
    required String? end,
    required DateTime now,
  }) {
    final from = _parseMonth(start);
    if (from == null) return null;
    final to = end == null ? DateTime(now.year, now.month) : _parseMonth(end);
    if (to == null) return null;
    final months = (to.year - from.year) * 12 + (to.month - from.month);
    return months < 0 ? null : months;
  }

  static DateTime? _parseMonth(String value) {
    final parts = value.split('-');
    if (parts.length < 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month);
  }

  /// Burst amplitude for a role, 0..1.
  ///
  /// An explicit `traceWeight` in the content wins — the schema documents it as
  /// the burst amplitude and the owner set it deliberately. Otherwise a role's
  /// duration relative to the longest role supplies it, which is what section
  /// 6 describes. A role with no readable dates gets the floor rather than
  /// vanishing from the trace.
  static double amplitudeFor({
    required int? months,
    required int? longestMonths,
    double? traceWeight,
  }) {
    if (traceWeight != null) return traceWeight.clamp(0.0, 1.0);
    if (months == null || longestMonths == null || longestMonths <= 0) {
      return _minimumAmplitude;
    }
    final ratio = months / longestMonths;
    return (_minimumAmplitude + ratio * (1 - _minimumAmplitude)).clamp(
      _minimumAmplitude,
      1.0,
    );
  }

  /// The floor keeps a short role visible as a burst rather than losing it in
  /// the carrier. Evri is the case that matters: present and factual, but not
  /// competing with the engineering roles.
  static const double _minimumAmplitude = 0.2;

  /// Burst density for a role, 0..1, from how many applications it shipped.
  static double densityFor({required int appCount, required int mostApps}) {
    if (mostApps <= 0) return 0;
    return (appCount / mostApps).clamp(0.0, 1.0);
  }

  /// How coherent the signal is at [velocity] pixels per second, 0..1.
  ///
  /// Section 6: above the threshold the waveform degrades toward noise, and as
  /// velocity falls it resolves and locks. Between the two thresholds it
  /// interpolates, so the transition is continuous rather than a snap.
  static double coherenceFor(double velocity) {
    final speed = velocity.abs();
    if (speed <= Tokens.traceLockVelocity) return 1;
    if (speed >= Tokens.traceScanningVelocity) return 0;
    const span = Tokens.traceScanningVelocity - Tokens.traceLockVelocity;
    return 1 - (speed - Tokens.traceLockVelocity) / span;
  }

  /// Resolves the trace's state from scroll and proximity.
  ///
  /// [nearestBurstDistance] is in pixels, or null when there is no burst to
  /// lock onto. Lock is the reward for slowing down, so it requires both a low
  /// velocity and something worth reading nearby.
  static TraceState stateFor({
    required double velocity,
    required Duration sinceLastScroll,
    required double? nearestBurstDistance,
  }) {
    if (velocity.abs() >= Tokens.traceScanningVelocity) {
      return TraceState.scanning;
    }
    if (velocity.abs() < Tokens.traceLockVelocity &&
        nearestBurstDistance != null &&
        nearestBurstDistance <= Tokens.traceLockDistance) {
      return TraceState.lock;
    }
    if (sinceLastScroll >= Tokens.traceRestDelay) return TraceState.standby;
    return velocity.abs() >= Tokens.traceLockVelocity
        ? TraceState.scanning
        : TraceState.standby;
  }

  /// Samples the trace at [position] down its length, normalised to -1..1.
  ///
  /// The carrier runs the whole length; each burst swells it locally. As
  /// [coherence] falls the phase breaks and jitter is added, so the waveform
  /// degrades rather than simply fading — which is what makes scrolling fast
  /// look like losing the signal instead of like a disabled animation.
  static double sampleAt({
    required double position,
    required double phase,
    required double coherence,
    required List<TraceBurst> bursts,
    double cycles = Tokens.traceCycles,
    double burstWidth = Tokens.traceBurstWidth,
  }) {
    var envelope = 0.0;
    for (final burst in bursts) {
      final lobe = CarrierWave.burstEnvelope(
        position: position,
        centre: burst.anchor,
        width: burstWidth,
      );
      envelope = math.max(envelope, lobe * burst.amplitude);
    }

    // Density raises the local frequency, so a role that shipped more
    // applications reads as a busier burst rather than merely a taller one.
    final density = _densityAt(position, bursts, burstWidth);
    final broken = coherence >= 1
        ? phase
        : phase + (1 - coherence) * _phaseBreak(position);
    final carrier = CarrierWave.sample(
      position: position,
      phase: broken,
      cycles: cycles * (1 + density),
    );

    final amplitude =
        Tokens.carrierRestAmplitude +
        (1 - Tokens.carrierRestAmplitude) * envelope;
    final jitter =
        (1 - coherence) * Tokens.traceNoiseAmplitude * _noiseAt(position);

    return (carrier * amplitude + jitter).clamp(-1.0, 1.0);
  }

  static double _densityAt(
    double position,
    List<TraceBurst> bursts,
    double burstWidth,
  ) {
    var density = 0.0;
    for (final burst in bursts) {
      final lobe = CarrierWave.burstEnvelope(
        position: position,
        centre: burst.anchor,
        width: burstWidth,
      );
      density = math.max(density, lobe * burst.density);
    }
    return density;
  }

  /// Deterministic pseudo-noise, so a given position always jitters the same
  /// way and the degraded trace can be asserted in a test.
  static double _noiseAt(double position) {
    final seed = StationSeed('trace:${(position * 4096).round()}');
    return seed.nextDouble() * 2 - 1;
  }

  static double _phaseBreak(double position) => _noiseAt(position + 0.5);

  /// Confines [bursts] to the stretch of trace beginning at [start].
  ///
  /// Section 6 anchors each role to where it appears in the career sequence,
  /// which begins below the hero. Without this the first burst sits under the
  /// hero and the page loads already locked onto a role the viewer cannot see.
  static List<TraceBurst> withinRange(
    List<TraceBurst> bursts, {
    required double start,
  }) {
    final from = start.clamp(0.0, 0.9);
    final span = 1 - from;
    return [
      for (final burst in bursts)
        (
          id: burst.id,
          anchor: from + burst.anchor * span,
          amplitude: burst.amplitude,
          density: burst.density,
        ),
    ];
  }

  /// Lays out one burst per role, evenly spaced down the trace.
  ///
  /// Roles arrive in the content's own order, which the schema states is
  /// chronological ascending, so the trace reads top to bottom as the career
  /// ran. Spacing is even rather than proportional to dates: the trace is
  /// anchored to the page's scroll, not to a calendar axis.
  static List<TraceBurst> layout(List<TraceRoleInput> roles) {
    if (roles.isEmpty) return const [];
    final longest = roles
        .map((role) => role.months ?? 0)
        .fold<int>(0, math.max);
    final mostApps = roles.map((role) => role.appCount).fold<int>(0, math.max);
    final spacing = 1 / (roles.length + 1);

    return [
      for (var i = 0; i < roles.length; i++)
        (
          id: roles[i].id,
          anchor: spacing * (i + 1),
          amplitude: amplitudeFor(
            months: roles[i].months,
            longestMonths: longest,
            traceWeight: roles[i].traceWeight,
          ),
          density: densityFor(appCount: roles[i].appCount, mostApps: mostApps),
        ),
    ];
  }
}

/// What the layout needs to know about one role.
typedef TraceRoleInput = ({
  String id,
  int? months,
  int appCount,
  double? traceWeight,
});
