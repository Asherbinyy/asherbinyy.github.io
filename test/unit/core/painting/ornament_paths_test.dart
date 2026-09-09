import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/ornament_paths.dart';

void main() {
  test('every motif draws something', () {
    for (final ornament in Ornament.values) {
      final strokes = OrnamentPaths.strokes(ornament, 100);
      expect(strokes, isNotEmpty, reason: ornament.name);
      for (final stroke in strokes) {
        // A one-point stroke is a moveTo with no lineTo after it, which draws
        // nothing and costs a path segment.
        expect(stroke.length, greaterThanOrEqualTo(2), reason: ornament.name);
      }
    }
  });

  test('every motif stays inside the box it was given', () {
    // The painters lay these out on a grid and rely on the box being the
    // footprint. A motif that overflows would collide with its neighbours, and
    // the field is drawn once into a cached tile, so it would be wrong
    // everywhere and forever.
    const size = 100.0;
    for (final ornament in Ornament.values) {
      for (final stroke in OrnamentPaths.strokes(ornament, size)) {
        for (final point in stroke) {
          expect(
            point.x,
            inInclusiveRange(0, size),
            reason: '${ornament.name} x',
          );
          expect(
            point.y,
            inInclusiveRange(0, size),
            reason: '${ornament.name} y',
          );
        }
      }
    }
  });

  test('motifs scale with the box rather than drifting', () {
    // Called at whatever size the surface gives it, from a few tens of pixels
    // in a background tile to a card mark, so the geometry has to be a pure
    // function of the box.
    for (final ornament in Ornament.values) {
      final small = OrnamentPaths.strokes(ornament, 10);
      final large = OrnamentPaths.strokes(ornament, 40);
      expect(large.length, small.length, reason: ornament.name);

      for (var i = 0; i < small.length; i++) {
        expect(large[i].length, small[i].length, reason: ornament.name);
        for (var j = 0; j < small[i].length; j++) {
          expect(
            large[i][j].x,
            closeTo(small[i][j].x * 4, 1e-9),
            reason: ornament.name,
          );
          expect(
            large[i][j].y,
            closeTo(small[i][j].y * 4, 1e-9),
            reason: ornament.name,
          );
        }
      }
    }
  });

  test('a zero box produces no geometry to divide by', () {
    for (final ornament in Ornament.values) {
      for (final stroke in OrnamentPaths.strokes(ornament, 0)) {
        for (final point in stroke) {
          expect(point.x, 0, reason: ornament.name);
          expect(point.y, 0, reason: ornament.name);
        }
      }
    }
  });

  test('the set carries no phonetic sign', () {
    // The point of this file. The field, the cards, the wall and the game used
    // to pick at random from the Egyptian uniliteral signs, which are letters,
    // and the result spelled nonsense. Ornament has no sound value, so there
    // is nothing for a random arrangement to say.
    //
    // Asserted as a count rather than a list of names so that adding a motif
    // is a deliberate act with a test to update, not a silent one.
    expect(Ornament.values, hasLength(5));
  });
}
