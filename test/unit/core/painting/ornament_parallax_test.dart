import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/ornament_field_painter.dart';

/// The carved field travels more slowly than the page in front of it.
void main() {
  OrnamentFieldPainter painter({double drift = 0}) => OrnamentFieldPainter(
    seed: 'field.home',
    colour: const Color(0xFFE3A93F),
    opacity: 0.04,
    hairlineWidth: 1,
    drift: drift,
  );

  test('a still page leaves the field where it was', () {
    expect(painter().drift, 0);
  });

  test('the field repaints when the drift changes and not otherwise', () {
    // Scroll is a per-frame signal, so a painter that always repaints would
    // redraw a tiled picture sixty times a second for nothing.
    expect(painter(drift: 40).shouldRepaint(painter(drift: 40)), isFalse);
    expect(painter(drift: 40).shouldRepaint(painter(drift: 41)), isTrue);
  });

  test('the drift is a fraction of the scroll, not all of it', () {
    // Matching the page exactly is what it did before, and reads as wallpaper
    // printed on the same sheet rather than a wall behind it.
    expect(Tokens.ornamentParallax, greaterThan(0));
    expect(
      Tokens.ornamentParallax,
      lessThan(1),
      reason: 'a field that keeps up with the text is not parallax',
    );
  });

  testWidgets('the field paints at every drift without complaint', (
    tester,
  ) async {
    // Including a drift far past one tile: the field is one tile repeated, so
    // the offset is taken modulo the tile and must not run away.
    for (final drift in [0.0, 1.0, 167.9, 168.0, 1000.0, 99999.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            painter: painter(drift: drift),
            size: const Size(400, 600),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'drift $drift threw');
    }
  });
}
