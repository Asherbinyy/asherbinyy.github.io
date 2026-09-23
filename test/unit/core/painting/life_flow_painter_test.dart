import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/life_flow_painter.dart';

const _size = Size(300, 560);
const _count = 6;

void main() {
  test('the nodes zigzag down the column', () {
    for (var i = 0; i < _count - 1; i++) {
      final here = LifeFlowPainter.centreOf(i, _count, _size);
      final next = LifeFlowPainter.centreOf(i + 1, _count, _size);
      expect(next.dy, greaterThan(here.dy), reason: 'step $i goes down');
      expect(
        next.dx == here.dx,
        isFalse,
        reason: 'step $i changes side, so the wire can curve',
      );
    }
  });

  test('every node sits inside the column', () {
    for (var i = 0; i < _count; i++) {
      final centre = LifeFlowPainter.centreOf(i, _count, _size);
      expect(centre.dx, inInclusiveRange(0, _size.width));
      expect(centre.dy, inInclusiveRange(0, _size.height));
    }
  });

  test('repaints as the run moves, not otherwise', () {
    LifeFlowPainter painter(double progress) => LifeFlowPainter(
      count: _count,
      progress: progress,
      nodeSize: 56,
      wire: const Color(0xFF111111),
      done: const Color(0xFF222222),
      packet: const Color(0xFF333333),
      glow: const Color(0xFF444444),
      strokeWidth: 1,
    );
    expect(painter(1).shouldRepaint(painter(1)), isFalse);
    expect(painter(1.5).shouldRepaint(painter(1)), isTrue);
  });
}
