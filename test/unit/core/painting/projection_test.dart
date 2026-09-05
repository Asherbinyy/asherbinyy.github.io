import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/projection.dart';

/// Coordinates transcribed from `assets/content/career.json`.
const _manchester = (latitude: 53.4808, longitude: -2.2426);
const _mansoura = (latitude: 31.0409, longitude: 31.3785);
const _toronto = (latitude: 43.6532, longitude: -79.3832);

void main() {
  group('toUnitSquare', () {
    test('places the origin at the centre of the square', () {
      final point = Projection.toUnitSquare(latitude: 0, longitude: 0);

      expect(point.dx, closeTo(0.5, 1e-9));
      expect(point.dy, closeTo(0.5, 1e-9));
    });

    test('places the north-west corner of the world at the origin', () {
      final point = Projection.toUnitSquare(latitude: 90, longitude: -180);

      expect(point, Offset.zero);
    });

    test('places the south-east corner of the world at the far corner', () {
      final point = Projection.toUnitSquare(latitude: -90, longitude: 180);

      expect(point, const Offset(1, 1));
    });

    test('projects Manchester into the northern western quadrant', () {
      final point = Projection.toUnitSquare(
        latitude: _manchester.latitude,
        longitude: _manchester.longitude,
      );

      expect(point.dx, closeTo(0.49377, 1e-5));
      expect(point.dy, closeTo(0.20288, 1e-5));
    });

    test('orders the real stations east to west as they sit on the globe', () {
      final toronto = Projection.toUnitSquare(
        latitude: _toronto.latitude,
        longitude: _toronto.longitude,
      );
      final manchester = Projection.toUnitSquare(
        latitude: _manchester.latitude,
        longitude: _manchester.longitude,
      );
      final mansoura = Projection.toUnitSquare(
        latitude: _mansoura.latitude,
        longitude: _mansoura.longitude,
      );

      expect(toronto.dx, lessThan(manchester.dx));
      expect(manchester.dx, lessThan(mansoura.dx));
      // Manchester is the furthest north of the three, so the smallest y.
      expect(manchester.dy, lessThan(toronto.dy));
      expect(toronto.dy, lessThan(mansoura.dy));
    });

    test(
      'clamps an out-of-range coordinate to an edge rather than wrapping',
      () {
        final beyond = Projection.toUnitSquare(latitude: 120, longitude: 400);

        expect(beyond, const Offset(1, 0));
      },
    );
  });

  group('toCanvas', () {
    test('scales the unit square onto the canvas', () {
      final point = Projection.toCanvas(
        latitude: 0,
        longitude: 0,
        size: const Size(200, 100),
      );

      expect(point, const Offset(100, 50));
    });

    test('lands inside the canvas for every real station', () {
      const size = Size(320, 200);
      for (final station in [_manchester, _mansoura, _toronto]) {
        final point = Projection.toCanvas(
          latitude: station.latitude,
          longitude: station.longitude,
          size: size,
        );

        expect(point.dx, inInclusiveRange(0, size.width));
        expect(point.dy, inInclusiveRange(0, size.height));
      }
    });
  });
}
