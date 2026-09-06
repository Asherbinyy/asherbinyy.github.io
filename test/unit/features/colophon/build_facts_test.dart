import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/colophon/domain/build_facts.dart';

void main() {
  group('parsing generated build facts', () {
    test('reads every figure the tool writes', () {
      final facts = parseBuildFacts(const {
        'generatedAt': '2026-09-06',
        'coveragePercent': 89.39,
        'coveredLines': 4422,
        'totalLines': 4947,
        'dartTests': 523,
        'workerTests': 25,
        'lighthousePerformanceFloor': 0.85,
        'lighthouseAccessibilityFloor': 0.9,
      });

      expect(facts.coveragePercent, 89.39);
      expect(facts.dartTests, 523);
      expect(facts.workerTests, 25);
      expect(facts.lighthousePerformanceFloor, 0.85);
    });

    test('treats a missing figure as absent rather than zero', () {
      // A page about how carefully this was built must omit a measurement it
      // does not have, not print a confident 0%.
      final facts = parseBuildFacts(const {'generatedAt': '2026-09-06'});

      expect(facts.coveragePercent, isNull);
      expect(facts.lighthousePerformanceFloor, isNull);
    });

    test('ignores a figure of the wrong type', () {
      final facts = parseBuildFacts(const {'coveragePercent': 'lots'});

      expect(facts.coveragePercent, isNull);
      expect(facts.generatedAt, '');
    });
  });
}
