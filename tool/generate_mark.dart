// ignore_for_file: avoid_print
/// Build-time generator for the mark and the favicon set.
///
/// Design-system section 12: the mark is one waveform burst frozen at its peak,
/// lifted from the trace's own curve rather than designed separately, and
/// `assets/brand/mark.svg` is the single source every other size is generated
/// from at build time.
///
/// The curve here is a copy of `CarrierWave.burstEnvelope`, which cannot be
/// imported: that library reaches `tokens.dart`, which imports `material_ui`,
/// and this runs as plain `dart run`. A test asserts the two agree sample for
/// sample, so they cannot drift silently.
///
/// Outputs:
///   - `assets/brand/mark.svg`          the single vector source
///   - `web/favicon.png`                32x32
///   - `web/icons/icon-192.png`         192x192
///   - `web/icons/icon-512.png`         512x512
///   - `web/icons/icon-maskable-512.png` 512x512, Android safe zone
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nocturne/core/painting/ankh_geometry.dart';

import 'png_writer.dart';

/// Burst envelope width, mirroring `Tokens.carrierBurstWidth`.
const double burstWidth = 0.18;

/// The mark's native square and stroke, mirroring the mark tokens.
const int nativeSize = 32;

/// Stroke width at the native size, mirroring `Tokens.markStroke`.
const double nativeStroke = 2;

/// Standard deviations of the burst the mark spans, mirroring
/// `Tokens.markCurveSigmas`. This is what puts flat carrier either side of the
/// hump, which is the shape section 12 draws.
const double markCurveSigmas = 5;

/// `--void`, the favicon background. Section 12 is explicit that it is not
/// transparent: a transparent favicon disappears into light browser chrome,
/// which is the commonest favicon failure.
const int backgroundR = 0x05;

/// `--void`, green channel.
const int backgroundG = 0x07;

/// `--void`, blue channel.
const int backgroundB = 0x0A;

/// `--beacon`, the mark itself.
const int markR = 0xF2;

/// `--beacon`, green channel.
const int markG = 0xA8;

/// `--beacon`, blue channel.
const int markB = 0x3B;

/// Android maskable icons must keep their content inside the central 80%.
const double maskableSafeZone = 0.8;

/// The Gaussian window that turns a stretch of carrier into a burst.
///
/// Must stay identical to `CarrierWave.burstEnvelope`.
double burstEnvelope({
  required double position,
  required double centre,
  double width = burstWidth,
}) {
  if (width <= 0) return position == centre ? 1 : 0;
  final offset = position - centre;
  return math.exp(-(offset * offset) / (2 * width * width));
}

void main() {
  final root = _projectRoot();

  _write(File('$root/assets/brand/mark.svg'), _svg());
  print('  wrote $root/assets/brand/mark.svg');

  for (final icon in <({String path, int size, bool isMaskable})>[
    (path: 'web/favicon.png', size: 32, isMaskable: false),
    (path: 'web/icons/icon-192.png', size: 192, isMaskable: false),
    (path: 'web/icons/icon-512.png', size: 512, isMaskable: false),
    (path: 'web/icons/icon-maskable-512.png', size: 512, isMaskable: true),
  ]) {
    File('$root/${icon.path}')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(
        PngWriter.encode(
          width: icon.size,
          height: icon.size,
          pixels: rasterise(size: icon.size, isMaskable: icon.isMaskable),
        ),
      );
    print('  wrote $root/${icon.path}');
  }

  print('Mark and favicon set generated.');
}

/// Emits the ankh as an SVG path in the mark's native 32x32 box.
///
/// One subpath per stroke. A single run would draw a line from the crossbar to
/// the loop that is not part of the sign.
String _svg() {
  final path = StringBuffer();
  for (final stroke in AnkhGeometry.strokes(
    size: nativeSize.toDouble(),
    strokeWidth: nativeStroke,
  )) {
    if (path.isNotEmpty) path.write(' ');
    path.write('M ${_n(stroke.first.x)} ${_n(stroke.first.y)}');
    for (final point in stroke.skip(1)) {
      path.write(' L ${_n(point.x)} ${_n(point.y)}');
    }
  }

  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $nativeSize $nativeSize" width="$nativeSize" height="$nativeSize" role="img" aria-label="Ahmed Elsherbini">
  <title>Ahmed Elsherbini</title>
  <path d="$path" fill="none" stroke="currentColor" stroke-width="$nativeStroke" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
}

/// A point on the mark's curve, in the target box's pixel coordinates.
typedef MarkPoint = ({double x, double y});

/// Renders the mark on the ground field at [size], as 8-bit RGBA.
///
/// Distance to the sampled strokes, supersampled 2x2, which is enough to keep
/// the stroke smooth. Section 12 requires the mark to stay legible at 16px,
/// which is what fixes the ankh's proportions in [AnkhGeometry].
Uint8List rasterise({required int size, required bool isMaskable}) {
  final scale = size / nativeSize;
  final stroke = nativeStroke * scale;
  // A maskable icon's content must survive a circular crop, so it is drawn
  // into the central safe zone rather than edge to edge.
  final content = isMaskable ? size * maskableSafeZone : size.toDouble();
  // Optical padding inside that, so the sign is not flush to the tile edge.
  final drawn = content * _markInset;
  final origin = (size - drawn) / 2;

  final strokes = [
    for (final polyline in AnkhGeometry.strokes(
      size: drawn,
      strokeWidth: stroke,
    ))
      [
        for (final point in polyline)
          (x: point.x + origin, y: point.y + origin),
      ],
  ];

  final pixels = Uint8List(size * size * 4);
  final half = stroke / 2;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var covered = 0;
      for (var sy = 0; sy < 2; sy++) {
        for (var sx = 0; sx < 2; sx++) {
          final px = x + (sx + 0.5) / 2;
          final py = y + (sy + 0.5) / 2;
          if (_distanceToStrokes(strokes, px, py) <= half) covered++;
        }
      }
      final alpha = covered / 4;
      final index = (y * size + x) * 4;
      pixels[index] = _mix(backgroundR, markR, alpha);
      pixels[index + 1] = _mix(backgroundG, markG, alpha);
      pixels[index + 2] = _mix(backgroundB, markB, alpha);
      pixels[index + 3] = 255;
    }
  }
  return pixels;
}

/// How much of the tile the sign occupies, leaving optical padding around it.
const double _markInset = 0.78;

int _mix(int background, int foreground, double alpha) =>
    (background + (foreground - background) * alpha).round().clamp(0, 255);

/// Shortest distance from a point to any of the sampled strokes.
///
/// No x-window shortcut here. The previous mark was a single curve and a
/// function of x, so segments far in x could be skipped; an ankh is neither.
/// Its loop has two y for most x and its stem is vertical, and that
/// optimisation would have quietly eaten both.
double _distanceToStrokes(List<List<MarkPoint>> strokes, double px, double py) {
  var best = double.infinity;
  for (final points in strokes) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final lengthSquared = dx * dx + dy * dy;
      final t = lengthSquared == 0
          ? 0.0
          : (((px - a.x) * dx + (py - a.y) * dy) / lengthSquared).clamp(
              0.0,
              1.0,
            );
      final cx = a.x + t * dx;
      final cy = a.y + t * dy;
      final distance = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
      if (distance < best) best = distance;
    }
  }
  return best;
}

String _n(double value) => value.toStringAsFixed(3);

void _write(File file, String content) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _projectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 10; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return Directory.current.path;
}
