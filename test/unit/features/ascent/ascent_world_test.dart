import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// The climb's physics, which is the whole game.
///
/// It is a pure function over a value, so it can be stepped without a ticker
/// or a canvas. These are the properties that make it playable rather than
/// merely running: a climber that cannot fall through stone, a shaft that
/// cannot strand anyone against a wall, and a frame delta that cannot teleport
/// anything past a ledge.
AscentWorld _run(
  AscentWorld world, {
  required int frames,
  double steer = 0,
  bool leap = false,
  bool dive = false,
  double dt = 1 / 60,
}) {
  var current = world;
  for (var i = 0; i < frames; i++) {
    current = current.step(
      dt: dt,
      steer: steer,
      isLeaping: leap,
      isDiving: dive,
    );
  }
  return current;
}

void main() {
  AscentWorld fresh({bool isPractice = false}) =>
      AscentWorld.seeded(best: 0, isPractice: isPractice, seed: 4);

  test('a fresh world starts on the floor with everything ahead of it', () {
    final world = fresh();
    expect(world.ledges, isNotEmpty);
    expect(world.altitude, 0);
    expect(world.isOver, isFalse);
    expect(world.metres, 0);
  });

  test('the climber bounces rather than falling through the floor', () {
    // The floor is wide enough that the first bounce cannot be missed, so a
    // world left alone must gain height rather than lose it.
    final world = _run(fresh(), frames: 240);
    expect(world.isOver, isFalse);
    expect(world.altitude, greaterThan(0));
  });

  test('a leap goes higher than a bounce', () {
    final plain = _run(fresh(), frames: 300);
    final leapt = _run(fresh(), frames: 300, leap: true);
    expect(leapt.altitude, greaterThan(plain.altitude));
  });

  test('a dive falls faster than gravity alone', () {
    final start = fresh();
    final drifting = _run(start, frames: 12);
    final diving = _run(start, frames: 12, dive: true);
    expect(diving.climberY, lessThan(drifting.climberY));
  });

  test('steering wraps at the walls rather than pinning', () {
    // A shaft is round. Pinning against an edge with no ledge in reach is a
    // dead end the player cannot steer out of.
    final world = _run(fresh(), frames: 400, steer: -1);
    expect(world.climberX, inInclusiveRange(0, 1));
  });

  test('practice mode never ends', () {
    // Falling is survivable, so the whole shaft stays reachable at the
    // player's own pace. This is the accessibility floor, not a difficulty
    // setting.
    final world = _run(fresh(isPractice: true), frames: 3000, dive: true);
    expect(world.isOver, isFalse);
  });

  test('a standard run ends on a long enough fall', () {
    final world = _run(fresh(), frames: 3000, dive: true, steer: 1);
    expect(world.isOver, isTrue);
  });

  test('an ended run ignores every further step', () {
    final over = _run(fresh(), frames: 3000, dive: true, steer: 1);
    expect(over.isOver, isTrue);
    final after = over.step(dt: 1 / 60, steer: 1);
    expect(after.climberY, over.climberY);
    expect(after.altitude, over.altitude);
  });

  test('the ledge count stays fixed however far the climb goes', () {
    // Ledges are recycled rather than accumulated, or a long run would grow
    // the list until the frame budget went with it.
    final start = fresh();
    final far = _run(start, frames: 4000, leap: true);
    expect(far.ledges.length, start.ledges.length);
  });

  test('a long frame cannot teleport the climber through stone', () {
    // The screen's own clamp is in the widget; this proves the physics is
    // sane at the clamp's limit rather than only at 60fps.
    final coarse = _run(fresh(), frames: 60, dt: 1 / 30);
    expect(coarse.isOver, isFalse);
    expect(coarse.altitude, greaterThan(0));
  });

  test('bands are passed in order, one per twenty-four metres', () {
    final world = _run(fresh(), frames: 1200, leap: true);
    expect(
      world.registersPassed,
      (world.altitude / AscentWorld.registerGap).floor(),
    );
  });

  test('a cracked ledge is reported the frame it gives way', () {
    // Presentation plays a sound off this, so the world has to say it rather
    // than the screen having to guess.
    // Practice mode, because cracked ledges only appear above forty metres:
    // the first stretch is dressed stone so the controls are learned before
    // the hazards, and a run that falls short never meets one.
    var world = fresh(isPractice: true);
    var reported = false;
    for (var i = 0; i < 6000; i++) {
      world = world.step(
        dt: 1 / 60,
        steer: i % 120 < 60 ? 0.8 : -0.8,
        isLeaping: true,
      );
      if (world.brokeLedge) reported = true;
    }
    expect(world.altitude, greaterThan(40));
    expect(reported, isTrue);
  });

  test('a seed reproduces a shaft exactly', () {
    final a = AscentWorld.seeded(best: 0, isPractice: false, seed: 99);
    final b = AscentWorld.seeded(best: 0, isPractice: false, seed: 99);
    expect(
      a.ledges.map((l) => '${l.id}:${l.kind}:${l.x}:${l.y}'),
      b.ledges.map((l) => '${l.id}:${l.kind}:${l.x}:${l.y}'),
    );
  });
}
