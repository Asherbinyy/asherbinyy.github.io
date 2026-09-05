import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/features/trace/domain/trace_geometry.dart';
import 'package:nocturne/features/trace/domain/trace_state.dart';

final DateTime _now = DateTime(2026, 9);

List<TraceBurst> _bursts() => TraceGeometry.layout(const [
  (id: 'a', months: 18, appCount: 4, traceWeight: null),
  (id: 'b', months: 6, appCount: 0, traceWeight: null),
]);

void main() {
  group('duration', () {
    test('measures whole months between two marks', () {
      expect(
        TraceGeometry.durationInMonths(
          start: '2021-10',
          end: '2023-04',
          now: _now,
        ),
        18,
      );
    });

    test('measures a current role against today', () {
      expect(
        TraceGeometry.durationInMonths(start: '2025-11', end: null, now: _now),
        10,
      );
    });

    test('rejects an unreadable or reversed range', () {
      expect(
        TraceGeometry.durationInMonths(start: 'soon', end: null, now: _now),
        isNull,
      );
      expect(
        TraceGeometry.durationInMonths(start: '2024-13', end: null, now: _now),
        isNull,
      );
      expect(
        TraceGeometry.durationInMonths(
          start: '2025-01',
          end: '2024-01',
          now: _now,
        ),
        isNull,
      );
    });
  });

  group('amplitude', () {
    test('an explicit trace weight from the content wins', () {
      expect(
        TraceGeometry.amplitudeFor(
          months: 1,
          longestMonths: 100,
          traceWeight: 0.9,
        ),
        0.9,
      );
    });

    test('scales with duration against the longest role', () {
      final longest = TraceGeometry.amplitudeFor(months: 24, longestMonths: 24);
      final middle = TraceGeometry.amplitudeFor(months: 12, longestMonths: 24);
      final short = TraceGeometry.amplitudeFor(months: 2, longestMonths: 24);

      expect(longest, 1);
      expect(middle, greaterThan(short));
      expect(longest, greaterThan(middle));
    });

    test('a short role keeps a floor rather than vanishing', () {
      // Evri is the case: present and factual, not featured, and it must still
      // read as a burst rather than disappear into the carrier.
      expect(
        TraceGeometry.amplitudeFor(months: 1, longestMonths: 240),
        greaterThan(0.1),
      );
    });

    test('unreadable dates fall back to the floor', () {
      expect(
        TraceGeometry.amplitudeFor(months: null, longestMonths: 24),
        TraceGeometry.amplitudeFor(months: 0, longestMonths: 24),
      );
    });

    test('never leaves the normalised range', () {
      expect(
        TraceGeometry.amplitudeFor(
          months: 999,
          longestMonths: 1,
          traceWeight: 4,
        ),
        1,
      );
      expect(
        TraceGeometry.amplitudeFor(months: 1, longestMonths: 0),
        inInclusiveRange(0, 1),
      );
    });
  });

  group('density', () {
    test('scales with applications shipped', () {
      expect(TraceGeometry.densityFor(appCount: 4, mostApps: 4), 1);
      expect(TraceGeometry.densityFor(appCount: 2, mostApps: 4), 0.5);
      expect(TraceGeometry.densityFor(appCount: 0, mostApps: 4), 0);
    });

    test('is zero when no role shipped anything', () {
      expect(TraceGeometry.densityFor(appCount: 0, mostApps: 0), 0);
    });
  });

  group('coherence', () {
    test('is total below the lock threshold', () {
      expect(TraceGeometry.coherenceFor(0), 1);
      expect(TraceGeometry.coherenceFor(Tokens.traceLockVelocity - 1), 1);
    });

    test('is lost above the scanning threshold', () {
      expect(TraceGeometry.coherenceFor(Tokens.traceScanningVelocity), 0);
      expect(TraceGeometry.coherenceFor(5000), 0);
    });

    test('degrades continuously between the thresholds', () {
      const midpoint =
          (Tokens.traceLockVelocity + Tokens.traceScanningVelocity) / 2;

      expect(TraceGeometry.coherenceFor(midpoint), closeTo(0.5, 0.01));
    });

    test('ignores scroll direction', () {
      expect(TraceGeometry.coherenceFor(-600), TraceGeometry.coherenceFor(600));
    });
  });

  group('state', () {
    test('scanning above the velocity threshold', () {
      expect(
        TraceGeometry.stateFor(
          velocity: Tokens.traceScanningVelocity + 1,
          sinceLastScroll: Duration.zero,
          nearestBurstDistance: 0,
        ),
        TraceState.scanning,
      );
    });

    test('locks when slow and near a burst', () {
      expect(
        TraceGeometry.stateFor(
          velocity: 10,
          sinceLastScroll: Duration.zero,
          nearestBurstDistance: Tokens.traceLockDistance - 1,
        ),
        TraceState.lock,
      );
    });

    test('does not lock onto a burst that is too far away', () {
      expect(
        TraceGeometry.stateFor(
          velocity: 10,
          sinceLastScroll: Duration.zero,
          nearestBurstDistance: Tokens.traceLockDistance + 1,
        ),
        isNot(TraceState.lock),
      );
    });

    test('does not lock with no burst to lock onto', () {
      expect(
        TraceGeometry.stateFor(
          velocity: 0,
          sinceLastScroll: Duration.zero,
          nearestBurstDistance: null,
        ),
        isNot(TraceState.lock),
      );
    });

    test('rests after the idle delay', () {
      expect(
        TraceGeometry.stateFor(
          velocity: 0,
          sinceLastScroll: Tokens.traceRestDelay,
          nearestBurstDistance: null,
        ),
        TraceState.standby,
      );
    });

    test('only lock is highlighted', () {
      expect(TraceState.lock.isHighlighted, isTrue);
      expect(TraceState.standby.isHighlighted, isFalse);
      expect(TraceState.scanning.isHighlighted, isFalse);
    });
  });

  group('layout', () {
    test('places one burst per role, in content order', () {
      final bursts = _bursts();

      expect(bursts.map((burst) => burst.id), ['a', 'b']);
      expect(bursts.first.anchor, lessThan(bursts.last.anchor));
    });

    test('keeps every burst inside the trace', () {
      for (final burst in _bursts()) {
        expect(burst.anchor, inExclusiveRange(0, 1));
      }
    });

    test('an empty career lays out nothing', () {
      expect(TraceGeometry.layout(const []), isEmpty);
    });

    test('confining to a range keeps every burst below the start', () {
      final confined = TraceGeometry.withinRange(_bursts(), start: 0.25);

      for (final burst in confined) {
        expect(burst.anchor, greaterThan(0.25));
        expect(burst.anchor, lessThan(1));
      }
    });

    test('confining preserves order, amplitude and density', () {
      final original = _bursts();
      final confined = TraceGeometry.withinRange(original, start: 0.3);

      expect(confined.map((b) => b.id), original.map((b) => b.id));
      expect(
        confined.map((b) => b.amplitude),
        original.map((b) => b.amplitude),
      );
      expect(confined.map((b) => b.density), original.map((b) => b.density));
    });

    test('an absurd start still leaves room for the bursts', () {
      // A very short page must not collapse every burst onto the last pixel.
      for (final burst in TraceGeometry.withinRange(_bursts(), start: 5)) {
        expect(burst.anchor, lessThan(1));
      }
    });
  });

  group('sampling', () {
    test('never leaves the normalised range, coherent or not', () {
      final bursts = _bursts();
      for (var i = 0; i <= 400; i++) {
        for (final coherence in [0.0, 0.5, 1.0]) {
          final value = TraceGeometry.sampleAt(
            position: i / 400,
            phase: 0.3,
            coherence: coherence,
            bursts: bursts,
          );

          expect(value, inInclusiveRange(-1, 1));
        }
      }
    });

    test('is deterministic, so a degraded trace is still reproducible', () {
      final bursts = _bursts();
      double sample() => TraceGeometry.sampleAt(
        position: 0.37,
        phase: 0.2,
        coherence: 0.4,
        bursts: bursts,
      );

      expect(sample(), sample());
    });

    test('swells at a burst relative to the carrier between bursts', () {
      final bursts = _bursts();
      var peak = 0.0;
      var between = 0.0;
      // The carrier oscillates, so compare the envelope each region reaches
      // rather than any single sample.
      for (var i = 0; i <= 200; i++) {
        final offset = (i / 200 - 0.5) * 0.06;
        peak = peak.abs() > 0 ? peak : peak;
        final atBurst = TraceGeometry.sampleAt(
          position: bursts.first.anchor + offset,
          phase: i / 200,
          coherence: 1,
          bursts: bursts,
        ).abs();
        final atEdge = TraceGeometry.sampleAt(
          position: 0.02 + offset.abs(),
          phase: i / 200,
          coherence: 1,
          bursts: bursts,
        ).abs();
        if (atBurst > peak) peak = atBurst;
        if (atEdge > between) between = atEdge;
      }

      expect(peak, greaterThan(between));
    });

    test('a fully incoherent trace differs from a locked one', () {
      final bursts = _bursts();
      final locked = TraceGeometry.sampleAt(
        position: 0.5,
        phase: 0.1,
        coherence: 1,
        bursts: bursts,
      );
      final scanning = TraceGeometry.sampleAt(
        position: 0.5,
        phase: 0.1,
        coherence: 0,
        bursts: bursts,
      );

      expect(scanning, isNot(locked));
    });
  });
}
