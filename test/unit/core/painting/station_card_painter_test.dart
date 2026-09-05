import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/projection.dart';
import 'package:nocturne/core/painting/station_card_painter.dart';

const _size = Size(320, 200);
const _field = Size(320 - Tokens.space16 * 2, 200 - Tokens.space16 * 2);

StationCardPainter _painter({
  String seedId = 'az-courses',
  double? latitude,
  double? longitude,
}) => StationCardPainter(
  seedId: seedId,
  nodeColour: nocturneTokens.instrumentDim,
  beaconColour: nocturneTokens.beacon,
  linkColour: nocturneTokens.hairlineStrong,
  hairlineWidth: Tokens.hairlineWidth,
  latitude: latitude,
  longitude: longitude,
);

void main() {
  test('the same application id always produces the same constellation', () {
    final first = _painter().nodesFor(_size);
    final second = _painter().nodesFor(_size);

    expect(first, second);
  });

  test('different applications produce different constellations', () {
    final courses = _painter().nodesFor(_size);
    final exams = _painter(seedId: 'az-exams').nodesFor(_size);

    expect(courses, isNot(exams));
  });

  test('node count stays inside the specified range', () {
    for (final id in ['tripster', 'mokaf', 'enjoy', 'malboos', 'tekrar']) {
      final nodes = _painter(seedId: id).nodesFor(_size);

      expect(
        nodes.length,
        inInclusiveRange(Tokens.stationNodeMin, Tokens.stationNodeMax),
      );
    }
  });

  test('every node sits inside the padded field', () {
    for (final node in _painter().nodesFor(_size)) {
      expect(
        node.centre.dx,
        inInclusiveRange(Tokens.space16, _size.width - Tokens.space16),
      );
      expect(
        node.centre.dy,
        inInclusiveRange(Tokens.space16, _size.height - Tokens.space16),
      );
    }
  });

  test('exactly one node is the beacon', () {
    final beacons = _painter().nodesFor(_size).where((n) => n.isBeacon);

    expect(beacons, hasLength(1));
  });

  test('a recorded country places the beacon at its projected position', () {
    // Mansoura, transcribed from career.json.
    final nodes = _painter(
      latitude: 31.0409,
      longitude: 31.3785,
    ).nodesFor(_size);
    final beacon = nodes.singleWhere((node) => node.isBeacon);
    final projected = Projection.toCanvas(
      latitude: 31.0409,
      longitude: 31.3785,
      size: _field,
    ).translate(Tokens.space16, Tokens.space16);

    expect(beacon.centre, projected);
  });

  test('a recorded country adds a node rather than moving a seeded one', () {
    final without = _painter().nodesFor(_size);
    final with_ = _painter(
      latitude: 31.0409,
      longitude: 31.3785,
    ).nodesFor(_size);

    expect(with_, hasLength(without.length + 1));
    expect(
      with_.take(without.length).map((node) => node.centre),
      without.map((node) => node.centre),
    );
  });

  test('an unrecorded country still marks one node', () {
    final nodes = _painter().nodesFor(_size);

    expect(nodes.first.isBeacon, isTrue);
  });

  test('a card too small for its own padding draws nothing', () {
    expect(_painter().nodesFor(const Size(8, 8)), isEmpty);
  });

  test('repaints only when an input actually changes', () {
    expect(_painter().shouldRepaint(_painter()), isFalse);
    expect(_painter().shouldRepaint(_painter(seedId: 'mokaf')), isTrue);
    expect(
      _painter().shouldRepaint(_painter(latitude: 1, longitude: 1)),
      isTrue,
    );
  });
}
