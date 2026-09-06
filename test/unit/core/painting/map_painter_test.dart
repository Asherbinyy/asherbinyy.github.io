import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/map_painter.dart';

/// The six real stations, transcribed from `assets/content/career.json`.
const List<MapStation> _stations = [
  (id: 'ci-company', latitude: 31.0409, longitude: 31.3785, isMinor: false),
  (id: 'minextstep', latitude: 43.6532, longitude: -79.3832, isMinor: false),
  (id: 'hwzn-tech', latitude: 24.7136, longitude: 46.6753, isMinor: false),
  (id: 'ar-plus-plus', latitude: 40.1792, longitude: 44.4991, isMinor: false),
  (id: 'techlabs', latitude: 25.2854, longitude: 51.531, isMinor: false),
  (id: 'evri', latitude: 53.4808, longitude: -2.2426, isMinor: true),
];

MapPainter _painter({int selectedIndex = -1, double drawProgress = 1}) =>
    MapPainter(
      stations: _stations,
      selectedIndex: selectedIndex,
      drawProgress: drawProgress,
      pulse: 0,
      coastlines: const [],
      landColour: nocturneTokens.hairlineStrong,
      graticuleColour: nocturneTokens.hairline,
      arcColour: nocturneTokens.instrumentDim,
      activeColour: nocturneTokens.beacon,
      nodeColour: nocturneTokens.instrumentDim,
      hairlineWidth: Tokens.hairlineWidth,
    );

void _paint(MapPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  const surface = Size(800, 400);

  group('projection of the real stations', () {
    test('every station lands inside the map surface', () {
      for (final station in _stations) {
        final point = MapPainter.positionOf(station, surface);

        expect(point.dx, inInclusiveRange(0, surface.width));
        expect(point.dy, inInclusiveRange(0, surface.height));
      }
    });

    test('places the six stations where the globe puts them', () {
      Offset at(String id) => MapPainter.positionOf(
        _stations.firstWhere((s) => s.id == id),
        surface,
      );

      // Toronto is west of Manchester, which is west of Mansoura.
      expect(at('minextstep').dx, lessThan(at('evri').dx));
      expect(at('evri').dx, lessThan(at('ci-company').dx));
      // Manchester is the furthest north, Riyadh the furthest south.
      expect(at('evri').dy, lessThan(at('ci-company').dy));
      expect(at('hwzn-tech').dy, greaterThan(at('ar-plus-plus').dy));
    });
  });

  group('hit testing', () {
    test('finds the station under a tap', () {
      final target = MapPainter.positionOf(_stations[2], surface);

      expect(MapPainter.nearestTo(target, _stations, surface), 2);
    });

    test('ignores a tap on empty ocean', () {
      expect(
        MapPainter.nearestTo(
          const Offset(5, 395),
          _stations,
          surface,
          within: 8,
        ),
        isNull,
      );
    });

    test('finds nothing when there are no stations', () {
      expect(MapPainter.nearestTo(Offset.zero, const [], surface), isNull);
    });
  });

  group('painting', () {
    test('draws the graticule, arcs and nodes', () {
      expect(() => _paint(_painter(), surface), returnsNormally);
    });

    test('draws nothing on an empty canvas', () {
      expect(() => _paint(_painter(), Size.zero), returnsNormally);
    });

    test('draws no arcs before the sequence starts', () {
      expect(() => _paint(_painter(drawProgress: 0), surface), returnsNormally);
    });

    test('a single station has no arcs to draw', () {
      final painter = MapPainter(
        stations: [_stations.first],
        selectedIndex: -1,
        drawProgress: 1,
        pulse: 0,
        coastlines: const [],
        landColour: nocturneTokens.hairlineStrong,
        graticuleColour: nocturneTokens.hairline,
        arcColour: nocturneTokens.instrumentDim,
        activeColour: nocturneTokens.beacon,
        nodeColour: nocturneTokens.instrumentDim,
        hairlineWidth: Tokens.hairlineWidth,
      );

      expect(() => _paint(painter, surface), returnsNormally);
    });

    test('repaints only when an input actually changes', () {
      expect(_painter().shouldRepaint(_painter()), isFalse);
      expect(_painter().shouldRepaint(_painter(selectedIndex: 2)), isTrue);
      expect(_painter().shouldRepaint(_painter(drawProgress: 0.5)), isTrue);
    });
  });
}
