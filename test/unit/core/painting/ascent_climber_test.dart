import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/features/courtyard/game/domain/ascent_world.dart';

/// The climber's size, checked against the world it climbs.
///
/// It used to be a fraction of the shaft's width, which sounds reasonable and
/// produced a creature 3.06 metres tall in a world where ledges sit 2.6 metres
/// apart and a bounce rises 2.75. It was taller than its own jump, which is
/// why the owner said it was too big and why the bouncing looked frantic.
///
/// These are the relationships that were violated, written down. They are
/// about the world rather than about pixels, so they hold at every window
/// size, which the old rule could not.
void main() {
  // Kept in step with `AscentPainter`. Duplicated rather than exposed because
  // making a painting constant public to satisfy a test would be the test
  // shaping the code.
  const climberMetres = 1.15;

  test('the climber is shorter than the gap between ledges', () {
    expect(climberMetres, lessThan(AscentWorld.ledgeGap));
    // Comfortably shorter, not marginally: half a gap is the point at which a
    // creature reads as standing on a platform rather than wedged between two.
    expect(climberMetres / AscentWorld.ledgeGap, lessThan(0.5));
  });

  test('the climber is shorter than the height of its own bounce', () {
    // Derived from the physics rather than restated, so tuning the bounce
    // cannot silently make the climber too big again.
    var world = AscentWorld.seeded(best: 0, isPractice: false, seed: 1);
    var apex = world.climberY;
    for (var i = 0; i < 240; i++) {
      world = world.step(
        dt: 1 / 60,
        steer: 0,
        isLeaping: false,
        isDiving: false,
      );
      if (world.climberY > apex) apex = world.climberY;
      if (world.isOver) break;
    }

    expect(apex, greaterThan(climberMetres * 2));
  });

  test('a whole climber fits between two ledges with room to spare', () {
    final clearance = AscentWorld.ledgeGap - climberMetres;
    expect(
      clearance,
      greaterThan(climberMetres),
      reason: 'the gap should hold the climber twice over',
    );
  });
}
