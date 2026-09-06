import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/core/painting/coastline_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses polygon and multipolygon rings', () {
    const source = '''
      {
        "type": "FeatureCollection",
        "features": [
          {"geometry": {"type": "Polygon", "coordinates": [
            [[0, 0], [1, 0], [1, 1], [0, 0]]
          ]}},
          {"geometry": {"type": "MultiPolygon", "coordinates": [
            [[[2, 2], [3, 2], [2, 2]]]
          ]}}
        ]
      }
    ''';

    final rings = parseCoastlineGeoJson(source);

    expect(rings, hasLength(2));
    expect(rings.first.first, (latitude: 0, longitude: 0));
    expect(rings.last[1], (latitude: 2, longitude: 3));
  });

  test('rejects a collection without usable rings', () {
    expect(
      () => parseCoastlineGeoJson('{"type":"FeatureCollection","features":[]}'),
      throwsFormatException,
    );
  });

  test(
    'the bundled Natural Earth asset contains global land outlines',
    () async {
      final source = await rootBundle.loadString(
        'assets/maps/ne_110m_land.geojson',
      );

      final rings = parseCoastlineGeoJson(source);

      expect(rings.length, greaterThan(100));
      expect(rings.every((ring) => ring.length >= 2), isTrue);
    },
  );
}
