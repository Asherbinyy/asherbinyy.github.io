import 'package:flutter/painting.dart';

/// Equirectangular (plate carrée) projection of geographic coordinates.
///
/// `03-ARCHITECTURE.md` rules out a map SDK, so the propagation map and the
/// procedural station card share this one linear projection. Linear is the
/// right choice here: the map is a diagram of six stations, not a navigational
/// surface, and a conformal projection would buy accuracy nobody reads.
abstract final class Projection {
  /// Southern latitude bound, in degrees.
  static const double minLatitude = -90;

  /// Northern latitude bound, in degrees.
  static const double maxLatitude = 90;

  /// Western longitude bound, in degrees.
  static const double minLongitude = -180;

  /// Eastern longitude bound, in degrees.
  static const double maxLongitude = 180;

  /// Normalises a coordinate onto the unit square.
  ///
  /// x grows east from the antimeridian and y grows south from the north pole,
  /// which already matches the canvas' top-left origin, so no flip is needed
  /// downstream. Out-of-range input is clamped rather than wrapped: a bad
  /// coordinate should land on an edge, not on the opposite side of the world.
  static Offset toUnitSquare({
    required double latitude,
    required double longitude,
  }) {
    final lat = latitude.clamp(minLatitude, maxLatitude);
    final lon = longitude.clamp(minLongitude, maxLongitude);
    return Offset(
      (lon - minLongitude) / (maxLongitude - minLongitude),
      (maxLatitude - lat) / (maxLatitude - minLatitude),
    );
  }

  /// Projects a coordinate onto a canvas of [size].
  static Offset toCanvas({
    required double latitude,
    required double longitude,
    required Size size,
  }) {
    final unit = toUnitSquare(latitude: latitude, longitude: longitude);
    return Offset(unit.dx * size.width, unit.dy * size.height);
  }
}
