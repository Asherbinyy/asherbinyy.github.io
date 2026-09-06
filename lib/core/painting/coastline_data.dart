import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One geographic point in degrees.
typedef GeographicPoint = ({double latitude, double longitude});

/// One closed land-ring outline.
typedef CoastlineRing = List<GeographicPoint>;

/// Loads the bundled public-domain Natural Earth outline once.
final coastlineRingsProvider = FutureProvider<List<CoastlineRing>>((ref) async {
  final source = await rootBundle.loadString(
    'assets/maps/ne_110m_land.geojson',
  );
  return parseCoastlineGeoJson(source);
});

/// Parses Polygon and MultiPolygon rings from a GeoJSON feature collection.
List<CoastlineRing> parseCoastlineGeoJson(String source) {
  final root = jsonDecode(source);
  if (root is! Map<String, dynamic> || root['features'] is! List<dynamic>) {
    throw const FormatException('Expected a GeoJSON feature collection.');
  }
  final rings = <CoastlineRing>[];
  for (final feature in root['features'] as List<dynamic>) {
    if (feature is! Map<String, dynamic>) continue;
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) continue;
    final coordinates = geometry['coordinates'];
    switch (geometry['type']) {
      case 'Polygon':
        _appendPolygon(rings, coordinates);
      case 'MultiPolygon':
        if (coordinates is! List<dynamic>) continue;
        for (final polygon in coordinates) {
          _appendPolygon(rings, polygon);
        }
    }
  }
  if (rings.isEmpty) {
    throw const FormatException('GeoJSON contains no polygon rings.');
  }
  return rings;
}

void _appendPolygon(List<CoastlineRing> target, Object? coordinates) {
  if (coordinates is! List<dynamic>) return;
  for (final ringSource in coordinates) {
    if (ringSource is! List<dynamic>) continue;
    final ring = <GeographicPoint>[];
    for (final coordinate in ringSource) {
      if (coordinate is! List<dynamic> || coordinate.length < 2) continue;
      final longitude = coordinate.first;
      final latitude = coordinate[1];
      if (longitude is! num || latitude is! num) continue;
      ring.add((
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ));
    }
    if (ring.length >= 2) target.add(ring);
  }
}
