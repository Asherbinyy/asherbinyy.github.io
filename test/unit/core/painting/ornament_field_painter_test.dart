import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/ornament_field_painter.dart';

OrnamentFieldPainter _painter({required String seed}) => OrnamentFieldPainter(
  seed: seed,
  colour: nocturneTokens.instrumentDim,
  opacity: Tokens.ornamentFieldOpacity,
  hairlineWidth: Tokens.hairlineWidth,
);

void main() {
  setUp(OrnamentFieldPainter.clearCache);

  test('the tile is built once and reused across paints', () {
    final painter = _painter(seed: 'field.station');
    const size = Size(1600, 1000);

    // A fresh recorder each time: one recorder cannot back two canvases, and
    // three paints is the point -- this is what a few scroll frames look like.
    for (var i = 0; i < 3; i++) {
      painter.paint(Canvas(ui.PictureRecorder()), size);
    }

    // The field is painted on every scroll frame. Rebuilding its paths each
    // time is the performance risk 12-MOTIF-LIBRARY.md section 4 names as the
    // largest in the redesign, so the guarantee that matters is that repeated
    // paints add no cache entries.
    expect(OrnamentFieldPainter.cacheSize, 1);
  });

  test('each route gets its own field', () {
    _painter(seed: 'field.station')
        .paint(Canvas(ui.PictureRecorder()), const Size(400, 400));
    _painter(seed: 'field.work')
        .paint(Canvas(ui.PictureRecorder()), const Size(400, 400));

    expect(OrnamentFieldPainter.cacheSize, 2);
  });

  test('an identical field does not repaint', () {
    const station = 'field.station';
    expect(
      _painter(seed: station).shouldRepaint(_painter(seed: station)),
      isFalse,
    );
    expect(
      _painter(seed: 'field.work').shouldRepaint(_painter(seed: station)),
      isTrue,
    );
  });

  test('an empty surface paints nothing rather than dividing by zero', () {
    expect(
      () =>
          _painter(seed: 'field.station')
              .paint(Canvas(ui.PictureRecorder()), Size.zero),
      returnsNormally,
    );
    expect(OrnamentFieldPainter.cacheSize, 0);
  });
}
