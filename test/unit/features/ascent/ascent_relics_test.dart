import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

const double _dt = AscentContract.tickSeconds;

/// A world with one ledge under the climber at [y] and [relic] floating over
/// another one straight above it, near enough to take on a jump.
AscentWorld _world({
  double y = 60,
  Relic? relic,
  int lives = 0,
  double eyeFor = 0,
  double featherFor = 0,
  double floorY = -14,
  double altitude = 60,
  double x = 0.5,
}) => AscentWorld(
  ledges: [
    Ledge(id: 1, kind: LedgeKind.stone, x: x, y: y, width: 0.3),
    Ledge(
      id: 2,
      kind: LedgeKind.stone,
      x: x,
      y: y + 1.5,
      width: 0.01,
      relic: relic,
    ),
  ],
  climberX: x,
  climberY: y,
  velocity: 0,
  altitude: altitude,
  best: 0,
  isPractice: false,
  isOver: false,
  nextLedgeId: 3,
  registersPassed: 0,
  isGrounded: true,
  lives: lives,
  eyeFor: eyeFor,
  featherFor: featherFor,
  floorY: floorY,
);

AscentWorld _run(
  AscentWorld world,
  int ticks, {
  double steer = 0,
  bool Function(int tick)? leaping,
}) {
  var next = world;
  for (var i = 0; i < ticks; i++) {
    next = next.step(
      dt: _dt,
      steer: steer,
      isLeaping: leaping?.call(i) ?? false,
    );
  }
  return next;
}

void main() {
  test('an ankh is an extra life, and they stop at three', () {
    final taken = _run(_world(relic: Relic.ankh), 30, leaping: (_) => true);
    expect(taken.lives, 1);
    expect(taken.relicsTaken, 1);

    final full = _run(
      _world(relic: Relic.ankh, lives: AscentWorld.maxLives),
      30,
      leaping: (_) => true,
    );
    expect(full.lives, AscentWorld.maxLives);
  });

  test('the eye slows the floor for ten seconds', () {
    // Well past the opening fifty metres, where the floor is moving.
    // The floor starts above the fourteen-metre line under the best height,
    // so what moves it is its own pace and nothing else.
    final plain = _run(_world(y: 300, altitude: 300, floorY: 290), 128);
    final slowed = _run(
      _world(
        y: 300,
        altitude: 300,
        floorY: 290,
        eyeFor: AscentWorld.eyeSeconds,
      ),
      128,
    );
    final risePlain = plain.floorY - 290;
    final riseSlowed = slowed.floorY - 290;
    expect(risePlain, greaterThan(0));
    expect(riseSlowed, closeTo(risePlain * AscentWorld.eyeSlow, 1e-9));
    expect(slowed.eyeFor, closeTo(AscentWorld.eyeSeconds - 1, 1e-9));
  });

  test('the feather gives two jumps in the air, and not a third', () {
    // Presses on ticks 0, 40, 80 and 120: the first from the ledge, two in
    // the air, and a fourth that does nothing.
    bool press(int tick) => tick % 40 < 2;
    final world = _world(featherFor: AscentWorld.featherSeconds);
    var next = world;
    var launches = 0;
    for (var i = 0; i < 160; i++) {
      final before = next.velocity;
      next = next.step(dt: _dt, steer: 0, isLeaping: press(i));
      if (next.velocity > before + 5) launches++;
    }
    expect(launches, 3);

    // Without it, a press in the air is not a jump: one press from the
    // ledge and one at the top of the rise give one launch, not two.
    bool twice(int tick) => tick < 2 || (tick >= 20 && tick < 22);
    int launchesOf(AscentWorld start) {
      var world = start;
      var count = 0;
      for (var i = 0; i < 40; i++) {
        final before = world.velocity;
        world = world.step(dt: _dt, steer: 0, isLeaping: twice(i));
        if (world.velocity > before + 5) count++;
      }
      return count;
    }

    expect(launchesOf(_world()), 1);
    expect(launchesOf(_world(featherFor: AscentWorld.featherSeconds)), 2);
  });

  test('a spent life puts the climber back on a ledge, above the floor', () {
    // Standing on nothing, with the floor just above: without a life this
    // would be the end of the run.
    final world = _world(lives: 1, floorY: 61, altitude: 64);
    final next = world.step(dt: _dt, steer: 0);
    expect(next.isOver, isFalse);
    expect(next.lostLife, isTrue);
    expect(next.lives, 0);
    expect(next.livesLost, 1);
    expect(next.climberY - next.floorY, greaterThanOrEqualTo(6 - 1e-9));

    final last = _world(floorY: 61, altitude: 64).step(dt: _dt, steer: 0);
    expect(last.isOver, isTrue);
    expect(last.won, isFalse);
  });

  test('reaching the summit ends the climb, and it is a win', () {
    final world = _world(
      y: AscentWorld.summit - 0.5,
      altitude: AscentWorld.summit - 0.5,
      floorY: AscentWorld.summit - 10,
    );
    final next = _run(world, 60, leaping: (_) => true);
    expect(next.isOver, isTrue);
    expect(next.won, isTrue);
    expect(next.metres, greaterThanOrEqualTo(800));
  });

  test('every level opens on a ledge the whole width of the shaft', () {
    for (var level = 1; level < AscentWorld.levelCount; level++) {
      // The first ledge height at or above the level's start.
      var y = 0.0;
      while (y < level * AscentWorld.levelHeight) {
        y += AscentWorld.ledgeGap;
      }
      final ledge = AscentWorld.generate(1000 + level, y, 7);
      expect(ledge.isLanding, isTrue, reason: 'level $level');
      expect(ledge.width, 1);
      expect(ledge.relic, isNull);
    }
  });

  test('the sands blow a jump off its line, and not a climber standing', () {
    final standing = _run(_world(y: 150, altitude: 150), 64);
    expect(standing.climberX, 0.5);

    final plain = _run(_world(y: 20, altitude: 20), 40, leaping: (_) => true);
    final windy = _run(_world(y: 150, altitude: 150), 40, leaping: (_) => true);
    expect((plain.climberX - 0.5).abs(), lessThan(1e-9));
    expect((windy.climberX - 0.5).abs(), greaterThan(0.001));
  });

  test('on the ice a climber slides where on stone they stop', () {
    AscentWorld moving(double y) =>
        _run(_world(y: y, altitude: y), 40, steer: 1);
    final onStone = _run(moving(20), 20);
    final onIce = _run(moving(250), 20);
    expect(
      onIce.horizontalVelocity.abs(),
      greaterThan(onStone.horizontalVelocity.abs()),
    );
  });

  test('the wind is a triangle, the same number every time it is asked', () {
    expect(AscentWorld.windAt(0), -AscentWorld.windMax);
    expect(
      AscentWorld.windAt(AscentWorld.windPeriod / 2),
      closeTo(AscentWorld.windMax, 1e-12),
    );
    expect(AscentWorld.windAt(1.25), AscentWorld.windAt(1.25));
  });
}
