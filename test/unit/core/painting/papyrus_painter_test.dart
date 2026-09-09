import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/papyrus_painter.dart';

PapyrusPainter _painter({ThemeTokens? tokens}) {
  final palette = tokens ?? nocturneTokens;
  return PapyrusPainter(
    sheet: palette.surfaceRaised,
    fibre: palette.hairline,
    edge: palette.hairlineStrong,
    hairlineWidth: Tokens.hairlineWidth,
  );
}

void main() {
  test('the sheet draws', () {
    final recorder = ui.PictureRecorder();
    _painter().paint(Canvas(recorder), const Size(800, 420));
    expect(recorder.endRecording().approximateBytesUsed, greaterThan(0));
  });

  test(
    'an empty surface paints nothing rather than tearing a zero-size edge',
    () {
      expect(
        () => _painter().paint(Canvas(ui.PictureRecorder()), Size.zero),
        returnsNormally,
      );
    },
  );

  test('the tear is the same tear on every paint', () {
    // A deckle dealt fresh each frame would read as the page flickering. The
    // seed is fixed rather than derived from the size, so this also holds
    // while a window is being dragged.
    const size = Size(640, 360);
    final first = ui.PictureRecorder();
    final second = ui.PictureRecorder();
    _painter().paint(Canvas(first), size);
    _painter().paint(Canvas(second), size);
    expect(
      first.endRecording().approximateBytesUsed,
      second.endRecording().approximateBytesUsed,
    );
  });

  test('repaints only when the palette changes', () {
    expect(_painter().shouldRepaint(_painter()), isFalse);
    expect(_painter(tokens: daybreakTokens).shouldRepaint(_painter()), isTrue);
  });

  test('both themes hand it a sheet distinct from the ground', () {
    // The whole design of this painter is that the papyrus is texture and edge
    // rather than a new colour, so it leans on surfaceRaised actually being
    // raised. If a palette ever set it equal to the page, the sheet would
    // vanish and only the tear would remain.
    for (final palette in [nocturneTokens, daybreakTokens]) {
      expect(palette.surfaceRaised, isNot(palette.void_));
    }
  });
}
