import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/hero_scene_painter.dart';

const _size = Size(540, 560);

HeroScenePainter _painter({double sun = 0, double time = 0}) =>
    HeroScenePainter(
      sun: sun,
      time: time,
      parallax: Offset.zero,
      skyTop: const Color(0xFF000000),
      skyHorizon: const Color(0xFF111111),
      water: const Color(0xFF222222),
      ground: const Color(0xFF333333),
      stone: const Color(0xFF444444),
      edge: const Color(0xFF555555),
      lit: const Color(0xFF666666),
      ink: const Color(0xFF777777),
      faint: const Color(0xFF888888),
      gold: const Color(0xFF999999),
      goldDim: const Color(0xFFAAAAAA),
      goldGlow: const Color(0xFFBBBBBB),
      halo: const Color(0xFFCCCCCC),
      screen: const Color(0xFFDDDDDD),
      strokeWidth: 1,
    );

void main() {
  test('a set sun is below the far bank', () {
    final centre = HeroScenePainter.sunCentre(_size, 0);
    expect(centre.dy, greaterThan(_size.height * HeroScenePainter.horizon));
  });

  test('a risen sun is high in the sky', () {
    final centre = HeroScenePainter.sunCentre(_size, 1);
    expect(centre.dy, lessThan(_size.height * HeroScenePainter.horizon / 2));
    expect(centre.dx, inInclusiveRange(0, _size.width));
  });

  test('the sun climbs the whole way, never dipping on the way up', () {
    var previous = double.infinity;
    for (var i = 0; i <= 20; i++) {
      final y = HeroScenePainter.sunCentre(_size, i / 20).dy;
      expect(y, lessThanOrEqualTo(previous + 0.001));
      previous = y;
    }
  });

  test('the night shows only while the sun is low', () {
    expect(HeroScenePainter.nightFor(0), 1);
    expect(HeroScenePainter.nightFor(1), 0);
  });

  test('repaints for the sun and the clock, not otherwise', () {
    expect(_painter().shouldRepaint(_painter()), isFalse);
    expect(_painter(sun: 0.5).shouldRepaint(_painter()), isTrue);
    expect(_painter(time: 1).shouldRepaint(_painter()), isTrue);
  });
}
