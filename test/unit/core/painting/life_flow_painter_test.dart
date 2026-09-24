import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nocturne/core/painting/life_flow_painter.dart';

const _size = Size(300, 560);
const _count = 6;

void main() {
  test('the nodes sit on the ankh, in the order the run reaches them', () {
    Offset at(int index) => LifeFlowPainter.centreOf(index, _count, _size);
    // The day starts at the foot of the stem, the lowest point of the sign.
    for (var i = 1; i < _count; i++) {
      expect(at(0).dy, greaterThan(at(i).dy), reason: 'the foot is lowest');
    }
    // The two ends of the bar are level, either side of the stem.
    expect(at(1).dy, at(5).dy);
    expect(at(1).dx, lessThan(at(0).dx));
    expect(at(5).dx, greaterThan(at(0).dx));
    // The loop sits above the bar: its sides level, its top highest.
    expect(at(2).dy, at(4).dy);
    expect(at(2).dy, lessThan(at(1).dy));
    expect(at(3).dy, lessThan(at(2).dy));
    expect(at(3).dx, closeTo(at(0).dx, 0.001), reason: 'loop over the stem');
  });

  test('a wide column gets a wider margin, not a squashed ankh', () {
    const wide = Size(900, 560);
    final narrow = LifeFlowPainter.ankhIn(_size);
    final broad = LifeFlowPainter.ankhIn(wide);
    expect(broad.rx, lessThanOrEqualTo(wide.height * 0.74 * 0.24 + 0.001));
    expect(broad.loop.dx, wide.width / 2);
    expect(narrow.loop.dx, _size.width / 2);
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
