import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/carrier_painter.dart';

CarrierPainter _painter({
  double phase = 0,
  double? burstCentre,
  TextDirection textDirection = TextDirection.ltr,
}) => CarrierPainter(
  phase: phase,
  colour: nocturneTokens.instrumentDim,
  strokeWidth: Tokens.hairlineWidth,
  textDirection: textDirection,
  burstCentre: burstCentre,
);

/// Runs a paint pass and reports whether it completed without throwing.
void _paint(CarrierPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  const loader = Size(Tokens.loaderWidth, Tokens.loaderHeight);

  test('draws the carrier at rest when no burst is placed', () {
    expect(() => _paint(_painter(), loader), returnsNormally);
  });

  test('draws a travelling burst when one is placed', () {
    expect(
      () => _paint(_painter(phase: 0.4, burstCentre: 0.4), loader),
      returnsNormally,
    );
  });

  test('travels start to end in both directions', () {
    expect(
      () => _paint(_painter(textDirection: TextDirection.rtl), loader),
      returnsNormally,
    );
  });

  test('early-returns on an empty canvas instead of dividing by zero', () {
    expect(() => _paint(_painter(), Size.zero), returnsNormally);
  });

  test('repaints only when an input actually changes', () {
    expect(_painter().shouldRepaint(_painter()), isFalse);
    expect(_painter().shouldRepaint(_painter(phase: 0.5)), isTrue);
    expect(_painter().shouldRepaint(_painter(burstCentre: 0.5)), isTrue);
    expect(
      _painter().shouldRepaint(_painter(textDirection: TextDirection.rtl)),
      isTrue,
    );
  });
}
