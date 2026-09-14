import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

AscentWorld floor({double y = 0, double velocity = 0, bool grounded = true}) =>
    AscentWorld(
      ledges: const [
        Ledge(id: 0, kind: LedgeKind.stone, x: 0.5, y: 0, width: 0.4),
      ],
      climberX: 0.5,
      climberY: y,
      velocity: velocity,
      altitude: y,
      best: 0,
      isPractice: false,
      isOver: false,
      nextLedgeId: 1,
      registersPassed: 0,
      isGrounded: grounded,
    );

void main() {
  test('holding toward the same wall cannot farm repeated boosts', () {
    var world = floor().step(dt: 1 / 60, steer: 0, isLeaping: true);
    var kicks = 0;
    for (var i = 0; i < 180; i++) {
      world = world.step(dt: 1 / 60, steer: -1, isLeaping: true);
      if (world.kickedWall) kicks++;
      if (world.landed) break;
    }
    expect(kicks, 1);
  });

  test('holding jump causes one launch, release permits the next', () {
    var world = floor();
    var launches = 0;
    for (var i = 0; i < 240; i++) {
      final next = world.step(dt: 1 / 60, steer: 0, isLeaping: true);
      if (next.velocity > 0 && world.velocity <= 0) launches++;
      world = next;
    }
    expect(launches, 1);
    expect(world.isGrounded, isTrue);
    world = world.step(dt: 1 / 60, steer: 0);
    expect(
      world.step(dt: 1 / 60, steer: 0, isLeaping: true).velocity,
      greaterThan(0),
    );
  });

  test('a tap just before landing is buffered even after release', () {
    var world = floor(y: 0.2, velocity: -2, grounded: false);
    world = world.step(dt: 1 / 60, steer: 0, isLeaping: true);
    for (var i = 0; i < 6 && world.velocity <= 0; i++) {
      world = world.step(dt: 1 / 60, steer: 0);
    }
    expect(world.velocity, greaterThan(0));
  });

  test('a late press after leaving a ledge still jumps', () {
    var world = floor();
    for (var i = 0; i < 60; i++) {
      world = world.step(dt: 1 / 60, steer: 1);
      if (!world.isGrounded) break;
    }
    expect(world.isGrounded, isFalse);
    expect(
      world.step(dt: 1 / 60, steer: 0, isLeaping: true).velocity,
      greaterThan(0),
    );
  });

  test('an old buffered tap cannot launch from midair', () {
    var world = floor(y: 3, grounded: false);
    world = world.step(dt: 1 / 60, steer: 0, isLeaping: true);
    for (var i = 0; i < 90; i++) {
      world = world.step(dt: 1 / 60, steer: 0);
      expect(world.velocity, lessThanOrEqualTo(0));
    }
  });

  test('releasing jump early produces a lower apex than holding', () {
    double apex({required bool hold}) {
      var world = floor().step(dt: 1 / 60, steer: 0, isLeaping: true);
      for (var i = 0; i < 90; i++) {
        world = world.step(dt: 1 / 60, steer: 0, isLeaping: hold);
      }
      return world.altitude;
    }

    expect(apex(hold: true), greaterThan(apex(hold: false)));
  });

  test('released steering brakes smoothly and then stops', () {
    var world = floor();
    for (var i = 0; i < 5; i++) {
      world = world.step(dt: 1 / 60, steer: 1);
    }
    final before = world.horizontalVelocity;
    world = world.step(dt: 1 / 60, steer: 0);
    expect(world.horizontalVelocity, inExclusiveRange(0, before));
    for (var i = 0; i < 30; i++) {
      world = world.step(dt: 1 / 60, steer: 0);
    }
    expect(world.horizontalVelocity, 0);
  });
}
