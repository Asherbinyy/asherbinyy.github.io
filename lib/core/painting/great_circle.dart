import 'dart:math' as math;

/// Great-circle interpolation between two points on the globe.
///
/// The propagation arcs are the shortest real path between two stations, not
/// straight lines on a flat projection: Toronto to Mansoura bows north on an
/// equirectangular map, and drawing it straight would be a different journey.
/// Spherical linear interpolation gives the true path, which is then projected
/// point by point.
abstract final class GreatCircle {
  /// Interpolates [count] points from one coordinate to another, inclusive.
  ///
  /// Returns `[latitude, longitude]` pairs in degrees.
  static List<({double latitude, double longitude})> path({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    int count = 48,
  }) {
    final samples = math.max(2, count);
    final from = _toCartesian(fromLatitude, fromLongitude);
    final to = _toCartesian(toLatitude, toLongitude);

    final dot = (from.x * to.x + from.y * to.y + from.z * to.z).clamp(
      -1.0,
      1.0,
    );
    final angle = math.acos(dot);
    // Coincident or antipodal stations have no unique arc; a straight
    // interpolation is the only honest answer and never divides by zero.
    if (angle.abs() < 1e-9) {
      return [
        for (var i = 0; i < samples; i++)
          (latitude: fromLatitude, longitude: fromLongitude),
      ];
    }

    final sinAngle = math.sin(angle);
    return [
      for (var i = 0; i < samples; i++)
        () {
          final t = i / (samples - 1);
          final a = math.sin((1 - t) * angle) / sinAngle;
          final b = math.sin(t * angle) / sinAngle;
          return _toDegrees((
            x: a * from.x + b * to.x,
            y: a * from.y + b * to.y,
            z: a * from.z + b * to.z,
          ));
        }(),
    ];
  }

  static ({double x, double y, double z}) _toCartesian(
    double latitude,
    double longitude,
  ) {
    final lat = latitude * math.pi / 180;
    final lon = longitude * math.pi / 180;
    return (
      x: math.cos(lat) * math.cos(lon),
      y: math.cos(lat) * math.sin(lon),
      z: math.sin(lat),
    );
  }

  static ({double latitude, double longitude}) _toDegrees(
    ({double x, double y, double z}) point,
  ) {
    final hypotenuse = math.sqrt(point.x * point.x + point.y * point.y);
    return (
      latitude: math.atan2(point.z, hypotenuse) * 180 / math.pi,
      longitude: math.atan2(point.y, point.x) * 180 / math.pi,
    );
  }
}
