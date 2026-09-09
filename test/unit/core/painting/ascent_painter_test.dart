import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/ascent_painter.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

AscentWorld _world({int frames = 200}) {
  var world = AscentWorld.seeded(best: 0, isPractice: true, seed: 3);
  for (var i = 0; i < frames; i++) {
    world = world.step(dt: 1 / 60, steer: i % 80 < 40 ? 0.7 : -0.7);
  }
  return world;
}

AscentPainter _painter({
  required AscentWorld world,
  double entrance = 1,
  bool isReducedMotion = false,
}) => AscentPainter(
  world: world,
  entrance: entrance,
  stone: nocturneTokens.instrument,
  cracked: nocturneTokens.instrumentDim,
  gold: nocturneTokens.beacon,
  glow: nocturneTokens.beaconGlow,
  wall: nocturneTokens.hairline,
  chamber: nocturneTokens.surfaceRaised,
  pier: nocturneTokens.void_,
  strokeWidth: Tokens.hairlineWidth,
  isReducedMotion: isReducedMotion,
);

int _operations(AscentPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final count = picture.approximateBytesUsed;
  picture.dispose();
  return count;
}

void main() {
  const shaft = Size(420, 560);

  test('paints the shaft, the climber and the wall', () {
    expect(_operations(_painter(world: _world()), shaft), greaterThan(0));
  });

  test('an empty canvas is survivable', () {
    expect(
      () => _operations(_painter(world: _world()), Size.zero),
      returnsNormally,
    );
  });

  test('a fresh world on the floor still draws', () {
    final start = AscentWorld.seeded(best: 0, isPractice: false, seed: 1);
    expect(_operations(_painter(world: start), shaft), greaterThan(0));
  });

  test('cost does not scale with how far the climb has gone', () {
    // Only the visible stretch is built. A climber a thousand metres up must
    // not cost more to draw than one on the floor, or the frame budget goes
    // with the altitude.
    final low = _operations(_painter(world: _world(frames: 120)), shaft);
    final high = _operations(_painter(world: _world(frames: 4000)), shaft);
    expect(high, lessThan(low * 2));
  });

  test('the opening is drawn over the shaft and then stops', () {
    // Mid-opening it covers the frame; once open it must add nothing at all.
    final opening = _operations(
      _painter(world: _world(), entrance: 0.4),
      shaft,
    );
    final open = _operations(_painter(world: _world()), shaft);
    expect(opening, greaterThan(open));
  });

  test('reduced motion drops the wake but keeps the climber', () {
    final still = _operations(
      _painter(world: _world(), isReducedMotion: true),
      shaft,
    );
    expect(still, greaterThan(0));
    expect(still, lessThan(_operations(_painter(world: _world()), shaft)));
  });

  test('repaints when the world moves', () {
    final a = _world(frames: 100);
    final b = _world(frames: 260);
    expect(_painter(world: a).shouldRepaint(_painter(world: a)), isFalse);
    expect(_painter(world: a).shouldRepaint(_painter(world: b)), isTrue);
    expect(
      _painter(world: a).shouldRepaint(_painter(world: a, entrance: 0.3)),
      isTrue,
    );
  });

  group('the shaft is a column, not the whole frame', () {
    // 0e.17: on a wide monitor the playfield was the entire surface, so the
    // climber had 1440 pixels of empty to drift through and the game looked
    // nothing like the one it is modelled on. Ice Tower is a narrow tower.
    test('a desktop frame gets piers either side', () {
      const size = Size(1440, 860);
      final shaft = AscentPainter.shaftOf(size);

      expect(shaft.width, lessThan(size.width * 0.5));
      expect(shaft.height, size.height);
      // Centred, so the two piers are equal and the column sits under the eye.
      expect(shaft.left, closeTo(size.width - shaft.right, 0.01));
      expect(shaft.left, greaterThan(0));
    });

    test('a phone gets the whole width', () {
      // Narrower than the frame would be a box inside a box, which is the
      // thing the owner objected to in the first place.
      for (final width in [320.0, 390.0, 430.0]) {
        final shaft = AscentPainter.shaftOf(Size(width, 720));
        expect(shaft.left, 0, reason: '$width');
        expect(shaft.width, width, reason: '$width');
      }
    });

    test('the column widens with the frame but never faster than it', () {
      // A shaft that grew at the frame's rate would put the walls back where
      // they were; one that never grew would look like a slot on a monitor.
      var previous = 0.0;
      for (final width in [600.0, 900.0, 1280.0, 1920.0, 2560.0]) {
        final shaft = AscentPainter.shaftOf(Size(width, 900));
        expect(shaft.width, greaterThan(previous), reason: '$width');
        expect(shaft.width / width, lessThan(0.85), reason: '$width');
        previous = shaft.width;
      }
    });
  });
}
