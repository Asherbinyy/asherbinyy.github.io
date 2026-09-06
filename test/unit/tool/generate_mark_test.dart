import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/carrier_wave.dart';

// The generator has no package: URI — it lives in tool/, not lib/ — so this is
// the one place a relative import is unavoidable.
// ignore: avoid_relative_lib_imports
import '../../../tool/generate_mark.dart' as generator;

/// `--void`, the field colour, channel by channel.
const int voidR = 0x05;
const int voidG = 0x07;
const int voidB = 0x0A;

/// `--beacon`, the mark colour, channel by channel.
const int beaconR = 0xF2;
const int beaconG = 0xA8;
const int beaconB = 0x3B;

/// Whether a pixel is closer to the mark than to the field.
bool _isInk(Uint8List pixels, int index) =>
    pixels[index] > (voidR + beaconR) ~/ 2;

String _projectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}

void main() {
  group('curve', () {
    test('matches the app carrier exactly, so the two cannot drift', () {
      // Section 12 requires the mark to be a frame lifted from the trace's own
      // curve. The generator cannot import CarrierWave — that library reaches
      // tokens.dart, which imports material_ui, and the generator runs as plain
      // `dart run` — so this is what holds the copy honest.
      for (var i = 0; i <= 400; i++) {
        final position = -1 + i / 200;
        expect(
          generator.burstEnvelope(position: position, centre: 0.5),
          CarrierWave.burstEnvelope(position: position, centre: 0.5),
          reason: 'position $position',
        );
      }
    });

    test('mirrors the burst width token', () {
      expect(generator.burstWidth, Tokens.carrierBurstWidth);
    });

    test('mirrors the mark tokens', () {
      expect(generator.nativeSize, Tokens.markNativeSize);
      expect(generator.nativeStroke, Tokens.markStroke);
      expect(generator.markCurveSigmas, Tokens.markCurveSigmas);
    });
  });

  group('mark.svg', () {
    late String svg;

    setUpAll(() {
      svg = File('${_projectRoot()}/assets/brand/mark.svg').readAsStringSync();
    });

    test('is the single committed vector source', () {
      expect(svg, contains('<svg'));
      expect(svg, contains('viewBox="0 0 32 32"'));
    });

    test('is one unfilled stroked path', () {
      expect('<path'.allMatches(svg).length, 1);
      expect(svg, contains('fill="none"'));
      expect(svg, contains('stroke-width="2.0"'));
    });

    test('inherits its colour rather than hard-coding one', () {
      // Section 12: beacon on dark, the darkened beacon on light, monochrome
      // elsewhere. currentColor lets one file serve all three.
      expect(svg, contains('stroke="currentColor"'));
      expect(svg, isNot(contains('#')));
    });

    test('carries an accessible name', () {
      expect(svg, contains('<title>'));
      expect(svg, contains('role="img"'));
    });
  });

  group('raster', () {
    test('the field is the void colour, never transparent', () {
      // A transparent favicon vanishes into light browser chrome, which
      // section 12 calls the commonest favicon failure.
      final pixels = generator.rasterise(size: 32, isMaskable: false);

      expect(pixels[0], voidR);
      expect(pixels[1], voidG);
      expect(pixels[2], voidB);
      for (var i = 3; i < pixels.length; i += 4) {
        expect(pixels[i], 255, reason: 'every pixel is opaque');
      }
    });

    test('the mark is drawn in the beacon', () {
      final pixels = generator.rasterise(size: 64, isMaskable: false);
      var peakInk = 0;

      for (var i = 0; i < pixels.length; i += 4) {
        if (pixels[i] == beaconR &&
            pixels[i + 1] == beaconG &&
            pixels[i + 2] == beaconB) {
          peakInk++;
        }
      }

      expect(peakInk, greaterThan(0));
    });

    test('stays legible at favicon size rather than collapsing to noise', () {
      const size = 16;
      final pixels = generator.rasterise(size: size, isMaskable: false);
      var ink = 0;
      for (var i = 0; i < pixels.length; i += 4) {
        if (_isInk(pixels, i)) ink++;
      }
      final coverage = ink / (size * size);

      // Too little and the mark disappears; too much and it is a blob.
      expect(coverage, greaterThan(0.05));
      expect(coverage, lessThan(0.35));
    });

    test('has a burst above flat shoulders, not a bare hill', () {
      const size = 64;
      final pixels = generator.rasterise(size: size, isMaskable: false);

      int topInkRow(int column) {
        for (var y = 0; y < size; y++) {
          if (_isInk(pixels, (y * size + column) * 4)) return y;
        }
        return size;
      }

      final centre = topInkRow(size ~/ 2);
      final leftShoulder = topInkRow(2);
      final rightShoulder = topInkRow(size - 3);

      // The burst rises well above the carrier either side of it.
      expect(centre, lessThan(leftShoulder - size ~/ 4));
      expect(centre, lessThan(rightShoulder - size ~/ 4));
      // And the shoulders sit at the same height, being one flat line.
      expect((leftShoulder - rightShoulder).abs(), lessThanOrEqualTo(1));
    });

    test('a maskable icon keeps its content inside the safe zone', () {
      const size = 128;
      final pixels = generator.rasterise(size: size, isMaskable: true);
      final margin = (size * (1 - generator.maskableSafeZone) / 2).floor();

      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final isOutside =
              x < margin ||
              y < margin ||
              x >= size - margin ||
              y >= size - margin;
          if (!isOutside) continue;
          expect(
            _isInk(pixels, (y * size + x) * 4),
            isFalse,
            reason: 'ink at ($x, $y) would be cropped by a circular mask',
          );
        }
      }
    });
  });

  group('generated files', () {
    test('every declared icon exists and is a valid PNG', () {
      final root = _projectRoot();
      for (final entry in {
        'web/favicon.png': 32,
        'web/icons/icon-192.png': 192,
        'web/icons/icon-512.png': 512,
        'web/icons/icon-maskable-512.png': 512,
      }.entries) {
        final bytes = File('$root/${entry.key}').readAsBytesSync();

        expect(bytes.take(8), [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ], reason: '${entry.key} is a PNG');
        // IHDR width and height are the two big-endian words at offset 16.
        final width =
            (bytes[16] << 24) |
            (bytes[17] << 16) |
            (bytes[18] << 8) |
            bytes[19];
        final height =
            (bytes[20] << 24) |
            (bytes[21] << 16) |
            (bytes[22] << 8) |
            bytes[23];
        expect(width, entry.value, reason: '${entry.key} width');
        expect(height, entry.value, reason: '${entry.key} height');
      }
    });
  });
}
