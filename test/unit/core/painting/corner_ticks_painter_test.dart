import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/corner_ticks_painter.dart';

CornerTicksPainter _painter({double inset = Tokens.cornerTickOffset}) =>
    CornerTicksPainter(
      edgeColour: nocturneTokens.hairline,
      tickColour: nocturneTokens.beaconDim,
      strokeWidth: Tokens.hairlineWidth,
      tickLength: Tokens.cornerTickLength,
      inset: inset,
    );

void _paint(CornerTicksPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  test('draws an edge and four corner marks', () {
    expect(() => _paint(_painter(), const Size(320, 200)), returnsNormally);
  });

  test('early-returns on an empty canvas', () {
    expect(() => _paint(_painter(), Size.zero), returnsNormally);
  });

  test('draws nothing when the inset consumes the whole panel', () {
    expect(
      () => _paint(_painter(inset: 200), const Size(40, 40)),
      returnsNormally,
    );
  });

  test('repaints only when an input actually changes', () {
    expect(_painter().shouldRepaint(_painter()), isFalse);
    expect(_painter().shouldRepaint(_painter(inset: 12)), isTrue);
  });
}
