import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/great_circle.dart';

/// Real stations, transcribed from `assets/content/career.json`.
const _mansoura = (latitude: 31.0409, longitude: 31.3785);
const _toronto = (latitude: 43.6532, longitude: -79.3832);
const _manchester = (latitude: 53.4808, longitude: -2.2426);

List<({double latitude, double longitude})> _path(
  ({double latitude, double longitude}) from,
  ({double latitude, double longitude}) to, {
  int count = 48,
}) => GreatCircle.path(
  fromLatitude: from.latitude,
  fromLongitude: from.longitude,
  toLatitude: to.latitude,
  toLongitude: to.longitude,
  count: count,
);

void main() {
  test('starts and ends exactly on its endpoints', () {
    final path = _path(_mansoura, _toronto);

    expect(path.first.latitude, closeTo(_mansoura.latitude, 1e-9));
    expect(path.first.longitude, closeTo(_mansoura.longitude, 1e-9));
    expect(path.last.latitude, closeTo(_toronto.latitude, 1e-9));
    expect(path.last.longitude, closeTo(_toronto.longitude, 1e-9));
  });

  test('returns the requested number of points', () {
    expect(_path(_mansoura, _toronto, count: 12), hasLength(12));
  });

  test('a degenerate count still yields a drawable segment', () {
    expect(
      _path(_mansoura, _toronto, count: 0).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('bows toward the pole rather than running straight', () {
    // This is the whole point of a great circle: the shortest real path from
    // Manchester to Toronto passes north of the straight line on a flat map.
    final path = _path(_manchester, _toronto);
    final midpoint = path[path.length ~/ 2];
    final straight = (_manchester.latitude + _toronto.latitude) / 2;

    expect(midpoint.latitude, greaterThan(straight));
  });

  test('stays within valid geographic bounds throughout', () {
    for (final point in _path(_toronto, _mansoura)) {
      expect(point.latitude, inInclusiveRange(-90, 90));
      expect(point.longitude, inInclusiveRange(-180, 180));
    }
  });

  test('is symmetric: the same arc travelled either way', () {
    final forward = _path(_mansoura, _manchester, count: 9);
    final backward = _path(_manchester, _mansoura, count: 9).reversed.toList();

    for (var i = 0; i < forward.length; i++) {
      expect(forward[i].latitude, closeTo(backward[i].latitude, 1e-9));
      expect(forward[i].longitude, closeTo(backward[i].longitude, 1e-9));
    }
  });

  test('coincident stations produce no arc rather than dividing by zero', () {
    final path = _path(_mansoura, _mansoura);

    for (final point in path) {
      expect(point.latitude, closeTo(_mansoura.latitude, 1e-9));
    }
  });

  test('advances monotonically along the arc', () {
    // Each step moves further from the origin, so the arc never doubles back.
    final path = _path(_mansoura, _toronto);
    var previous = -1.0;
    for (final point in path) {
      final distance = _angularDistance(_mansoura, point);
      expect(distance, greaterThanOrEqualTo(previous - 1e-9));
      previous = distance;
    }
  });
}

/// Angle between two coordinates, in radians.
double _angularDistance(
  ({double latitude, double longitude}) a,
  ({double latitude, double longitude}) b,
) {
  double radians(double degrees) => degrees * math.pi / 180;
  final lat1 = radians(a.latitude);
  final lat2 = radians(b.latitude);
  final deltaLon = radians(b.longitude - a.longitude);
  return math.acos(
    (math.sin(lat1) * math.sin(lat2) +
            math.cos(lat1) * math.cos(lat2) * math.cos(deltaLon))
        .clamp(-1.0, 1.0),
  );
}
