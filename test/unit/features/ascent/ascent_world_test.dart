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
  double dt = 1 / 60,
}) {
  var current = world;
  for (var i = 0; i < frames; i++) {
    current = current.step(dt: dt, steer: steer, isLeaping: leap);
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

  test('a wall kick is taller than a standing jump', () {
    // The one move in the game that pays more than it costs, and the reason
    // to steer wide rather than straight up.
    final grounded = _run(fresh(), frames: 120);
    expect(grounded.isGrounded, isTrue);

    final jumped = grounded.step(dt: 1 / 60, steer: 0, isLeaping: true);
    var kicked = grounded.step(dt: 1 / 60, steer: 0, isLeaping: true);
    for (var i = 0; i < 60 && !kicked.kickedWall; i++) {
      kicked = kicked.step(dt: 1 / 60, steer: -1);
    }

    expect(kicked.kickedWall, isTrue);
    expect(kicked.velocity, greaterThan(jumped.velocity));
  });

  test('steering stops at the walls rather than wrapping', () {
    // It used to wrap, on the reasoning that a shaft is round. A wall is worth
    // something now, so leaving one side and arriving at the other would hand
    // out the kick for free.
    final world = _run(fresh(), frames: 400, steer: -1);
    expect(world.climberX, inInclusiveRange(0, 1));
    expect(world.climberX, 0);
  });

  test('practice mode never ends', () {
    // Falling is survivable, so the whole shaft stays reachable at the
    // player's own pace. This is the accessibility floor, not a difficulty
    // setting.
    final world = _run(fresh(isPractice: true), frames: 3000);
    expect(world.isOver, isFalse);
  });

  test('the opening stretch does not chase the player', () {
    // The floor is still on the first level on purpose: that is where the
    // controls are learned, and a floor rising under someone who has not
    // worked out the jump yet is a short run rather than a hard one.
    final world = _run(fresh(), frames: 3000);
    expect(world.level, 0);
    expect(world.isOver, isFalse);
  });

  test('the floor rises once the pace starts, and not before', () {
    // Built at altitude rather than climbed to: a standard run ends on a
    // fourteen-metre fall, so a climber cannot reach the second level and
    // then stand still long enough to be caught by anything else.
    AscentWorld at(double altitude) => AscentWorld(
      ledges: const [
        Ledge(id: 0, kind: LedgeKind.stone, x: 0.5, y: 0, width: 0.9),
      ],
      climberX: 0.5,
      climberY: altitude,
      velocity: 0,
      altitude: altitude,
      best: 0,
      isPractice: true,
      isOver: false,
      nextLedgeId: 1,
      registersPassed: 0,
      floorY: altitude - 10,
    );

    final opening = at(10);
    expect(opening.level, 0);
    expect(
      opening.step(dt: 1, steer: 0).floorY,
      opening.floorY,
      reason: 'the first level is where the controls are learned',
    );

    final paced = at(AscentWorld.levelHeight * 2);
    expect(paced.level, 2);
    expect(paced.step(dt: 1, steer: 0).floorY, greaterThan(paced.floorY));
  });

  test('an ended run ignores every further step', () {
    final over = _run(fresh(), frames: 3000, steer: 1);
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
    //
    // Built rather than climbed to. This used to steer a random shaft for a
    // hundred seconds and hope it met a cracked ledge above forty metres,
    // which made it a test of the seed: retuning the jump changed how high
    // that climb got and the test failed at 33 metres without anything being
    // wrong with the thing it names.
    const world = AscentWorld(
      ledges: [Ledge(id: 0, kind: LedgeKind.cracked, x: 0.5, y: 0, width: 0.9)],
      climberX: 0.5,
      climberY: 0.4,
      velocity: -1,
      altitude: 0.4,
      best: 0,
      isPractice: true,
      isOver: false,
      nextLedgeId: 1,
      registersPassed: 0,
    );

    // Stepped until it lands rather than once: falling the last 40cm takes
    // several frames, and the report is about the frame it touches down.
    var current = world;
    var reports = 0;
    for (var i = 0; i < 60; i++) {
      current = current.step(dt: 1 / 60, steer: 0);
      if (current.brokeLedge) reports++;
    }

    expect(reports, 1, reason: 'reported once, on the frame it gave way');
    expect(current.ledges.single.isBroken, isTrue);
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
