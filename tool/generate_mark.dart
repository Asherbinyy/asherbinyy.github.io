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

/// Samples the curve into an SVG path in the mark's native 32x32 box.
String _svg() {
  final points = _curve(nativeSize.toDouble(), inset: nativeStroke / 2);
  final path = StringBuffer('M ${_n(points.first.x)} ${_n(points.first.y)}');
  for (final point in points.skip(1)) {
    path.write(' L ${_n(point.x)} ${_n(point.y)}');
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

/// Samples the curve across a box of [size], inset by [inset] on all sides.
List<MarkPoint> _curve(double size, {required double inset}) {
  final box = size - inset * 2;
  final samples = math.max(64, size.ceil());
  // The window spans the burst plus the flat carrier either side of it, so the
  // mark reads as a burst on a line rather than as a bare hill.
  const window = burstWidth * markCurveSigmas * 2;
  const start = 0.5 - window / 2;
  return [
    for (var i = 0; i <= samples; i++)
      () {
        final fraction = i / samples;
        final lobe = burstEnvelope(
          position: start + fraction * window,
          centre: 0.5,
        );
        return (x: inset + fraction * box, y: inset + box - lobe * box);
      }(),
  ];
}

/// Renders the mark on the void field at [size], as 8-bit RGBA.
///
/// Distance to the sampled curve, supersampled 2x2, which is enough to keep the
/// stroke smooth. Section 12 requires the mark to stay legible at 16px, so the
/// shape is deliberately two curves and nothing more.
Uint8List rasterise({required int size, required bool isMaskable}) {
  final scale = size / nativeSize;
  final stroke = nativeStroke * scale;
  // A maskable icon's content must survive a circular crop, so it is drawn
  // into the central safe zone rather than edge to edge.
  final content = isMaskable ? size * maskableSafeZone : size.toDouble();
  final origin = (size - content) / 2;
  final points = [
    for (final point in _curve(content, inset: stroke / 2 + content * 0.15))
      (x: point.x + origin, y: point.y + origin),
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
          if (_distanceToCurve(points, px, py, half + 1) <= half) covered++;
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

int _mix(int background, int foreground, double alpha) =>
    (background + (foreground - background) * alpha).round().clamp(0, 255);

/// Shortest distance from a point to the sampled polyline.
///
/// Only segments whose x lies within [window] of the point are considered; the
/// curve is a function of x, so anything further cannot be the nearest.
double _distanceToCurve(
  List<MarkPoint> points,
  double px,
  double py,
  double window,
) {
  var best = double.infinity;
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    if (math.max(a.x, b.x) < px - window) continue;
    if (math.min(a.x, b.x) > px + window) break;
    best = math.min(best, _distanceToSegment(px, py, a, b));
  }
  return best;
}

double _distanceToSegment(double px, double py, MarkPoint a, MarkPoint b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return _hypot(px - a.x, py - a.y);
  final t = (((px - a.x) * dx + (py - a.y) * dy) / lengthSquared).clamp(
    0.0,
    1.0,
  );
  return _hypot(px - (a.x + t * dx), py - (a.y + t * dy));
}

double _hypot(double x, double y) => math.sqrt(x * x + y * y);

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
