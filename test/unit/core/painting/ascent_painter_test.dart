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
}
