import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/carrier_wave.dart';

void main() {
  group('sample', () {
    test('stays within the normalised range across a full cycle', () {
      for (var step = 0; step <= 200; step++) {
        final value = CarrierWave.sample(
          position: step / 200,
          phase: step / 200,
        );

        expect(value, inInclusiveRange(-1, 1));
      }
    });

    test('completes one cycle per unit of phase', () {
      final start = CarrierWave.sample(position: 0.25, phase: 0);
      final wrapped = CarrierWave.sample(position: 0.25, phase: 1);

      expect(wrapped, closeTo(start, 1e-9));
    });

    test('advancing phase shifts the waveform along the container', () {
      final atRest = CarrierWave.sample(position: 0, phase: 0);
      final advanced = CarrierWave.sample(position: 0.25, phase: 0.25);

      // Position and phase move the argument in opposite directions, so equal
      // steps in both leave the sample where it started.
      expect(advanced, closeTo(atRest, 1e-9));
    });
  });

  group('burstEnvelope', () {
    test('peaks at the burst centre', () {
      expect(
        CarrierWave.burstEnvelope(position: 0.5, centre: 0.5),
        closeTo(1, 1e-9),
      );
    });

    test('decays symmetrically either side of the centre', () {
      final before = CarrierWave.burstEnvelope(position: 0.4, centre: 0.5);
      final after = CarrierWave.burstEnvelope(position: 0.6, centre: 0.5);

      expect(before, closeTo(after, 1e-9));
      expect(before, lessThan(1));
    });

    test('falls away rather than clipping at the edges', () {
      final far = CarrierWave.burstEnvelope(position: 0, centre: 0.5);

      // Gaussian, so it approaches zero without ever reaching it — that is
      // what keeps the burst from aliasing into a hard edge at loader scale.
      expect(far, greaterThan(0));
      expect(far, lessThan(0.05));
    });

    test('degenerates to a single point rather than dividing by zero', () {
      expect(
        CarrierWave.burstEnvelope(position: 0.5, centre: 0.5, width: 0),
        1,
      );
      expect(
        CarrierWave.burstEnvelope(position: 0.4, centre: 0.5, width: 0),
        0,
      );
    });
  });

  group('burst', () {
    test('never exceeds the normalised range', () {
      for (var step = 0; step <= 200; step++) {
        final value = CarrierWave.burst(
          position: step / 200,
          phase: 0.5,
          centre: 0.5,
        );

        expect(value, inInclusiveRange(-1, 1));
      }
    });

    test('holds the baseline amplitude far from any burst', () {
      // A quarter cycle from the origin is the carrier's own peak, so the
      // envelope is the only thing scaling it down.
      final value = CarrierWave.burst(
        position: 0.25 / Tokens.carrierRestCycles,
        phase: 0,
        centre: 10,
      );

      expect(value, closeTo(Tokens.carrierRestAmplitude, 1e-6));
    });

    test('swells to full amplitude under the burst centre', () {
      const quarter = 0.25 / Tokens.carrierRestCycles;
      final value = CarrierWave.burst(
        position: quarter,
        phase: 0,
        centre: quarter,
      );

      expect(value, closeTo(1, 1e-6));
      expect(value, greaterThan(Tokens.carrierRestAmplitude));
    });

    test('matches the carrier the mark is lifted from', () {
      // Section 12 requires the mark to be a frame of this function rather than
      // an independently drawn shape.
      final frozen = CarrierWave.burst(position: 0.5, phase: 0, centre: 0.5);
      final expected =
          math.sin(2 * math.pi * 0.5 * Tokens.carrierRestCycles) * 1;

      expect(frozen, closeTo(expected, 1e-9));
    });
  });
}
