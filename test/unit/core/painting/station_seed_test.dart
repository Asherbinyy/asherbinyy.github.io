import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/station_seed.dart';

void main() {
  test('the same id always produces the same stream', () {
    final first = StationSeed('az-courses');
    final second = StationSeed('az-courses');

    final a = [for (var i = 0; i < 20; i++) first.nextDouble()];
    final b = [for (var i = 0; i < 20; i++) second.nextDouble()];

    expect(a, b);
  });

  test('different ids produce different streams', () {
    final courses = StationSeed('az-courses');
    final exams = StationSeed('az-exams');

    expect(courses.nextDouble(), isNot(exams.nextDouble()));
  });

  test('every draw stays within the unit interval', () {
    final seed = StationSeed('mokaf');

    for (var i = 0; i < 500; i++) {
      expect(seed.nextDouble(), inInclusiveRange(0, 1));
    }
  });

  test('an empty id still yields a usable stream', () {
    // The FNV offset basis stands in so the xorshift state is never zero.
    final seed = StationSeed('');

    expect(seed.nextDouble(), greaterThan(0));
  });

  test('nextRange stays inside its bounds', () {
    final seed = StationSeed('tiara-beauty');

    for (var i = 0; i < 200; i++) {
      expect(seed.nextRange(16, 304), inInclusiveRange(16, 304));
    }
  });

  test('nextInt stays below its exclusive maximum', () {
    final seed = StationSeed('wasset');

    for (var i = 0; i < 200; i++) {
      expect(seed.nextInt(5), inInclusiveRange(0, 4));
    }
  });

  test('nextInt of a non-positive maximum returns zero', () {
    final seed = StationSeed('snunu');

    expect(seed.nextInt(0), 0);
    expect(seed.nextInt(-3), 0);
  });
}
