import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/interest_painter.dart';

import '../../../support/content_readers.dart';

InterestPainter _painter(InterestScene scene, {double progress = 0.5}) =>
    InterestPainter(
      scene: scene,
      progress: progress,
      ink: nocturneTokens.instrumentMid,
      gold: nocturneTokens.beacon,
      strokeWidth: Tokens.hairlineWidth,
    );

int _operations(InterestPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final count = picture.approximateBytesUsed;
  picture.dispose();
  return count;
}

void main() {
  const plate = Size(168, 116);

  test('every scene draws something at every point of its animation', () {
    // A scene that vanishes at either end of its travel would read as a bug
    // to anyone who hovered slowly.
    for (final scene in InterestScene.values) {
      for (final progress in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(
          _operations(_painter(scene, progress: progress), plate),
          greaterThan(0),
          reason: '$scene at $progress drew nothing',
        );
      }
    }
  });

  test('an unknown interest still gets a mark', () {
    // Adding an interest to the content must never break the grid, so an id
    // with no scene of its own falls back rather than failing.
    expect(InterestScene.of('something-new'), InterestScene.seal);
    expect(_operations(_painter(InterestScene.seal), plate), greaterThan(0));
  });

  test('every interest in the content has a scene of its own', () {
    // Read from the shipped content rather than listed here. This held the
    // ids as literals, so renaming "esports" to "gaming" failed on the
    // spelling instead of catching the thing worth catching: an interest the
    // owner adds that quietly falls through to the generic seal.
    final interests =
        bundledJson('assets/content/interests.json')['interests'] as List;
    final scenes = <InterestScene>{};

    for (final interest in interests.cast<Map<String, dynamic>>()) {
      final id = interest['id'] as String;
      final scene = InterestScene.of(id);
      expect(
        scene,
        isNot(InterestScene.seal),
        reason: '$id has no scene and falls back to the generic mark',
      );
      expect(scenes.add(scene), isTrue, reason: '$id shares a scene');
    }
  });

  test('an empty plate is survivable', () {
    for (final scene in InterestScene.values) {
      expect(() => _operations(_painter(scene), Size.zero), returnsNormally);
    }
  });

  test('repaints only when something it draws has changed', () {
    expect(
      _painter(InterestScene.gym).shouldRepaint(_painter(InterestScene.gym)),
      isFalse,
    );
    expect(
      _painter(InterestScene.gym)
          .shouldRepaint(_painter(InterestScene.gym, progress: 0.9)),
      isTrue,
    );
    expect(
      _painter(InterestScene.gym).shouldRepaint(_painter(InterestScene.padel)),
      isTrue,
    );
  });
}
