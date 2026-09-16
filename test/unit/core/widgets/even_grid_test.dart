import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nocturne/core/widgets/even_grid.dart';

/// The arithmetic behind every grid of chips and cards on the site.
///
/// Asserted directly rather than through a rendered tree, because the fault
/// the owner reported four times — "no line would have 8 and the other only
/// has 1 or 2" — is a counting fault, and counting is what this checks.
void main() {
  ({
    int columns,
    int perRow,
    List<int> rowLengths,
    double tileWidth,
    bool fillsWidth,
  })
  layout(
    int count,
    double width, {
    double minTileWidth = 100,
    double spacing = 12,
    int? maxColumns,
  }) => EvenGrid.measure(
    width: width,
    count: count,
    minTileWidth: minTileWidth,
    spacing: spacing,
    maxColumns: maxColumns,
  );

  group('columns follow the space available', () {
    test('as many as fit, and no more', () {
      // 700 wide, tiles at least 100 with 12 between: 6 fit (6*100 + 5*12).
      expect(layout(6, 700).columns, 6);
      expect(layout(6, 300).columns, 2);
      expect(layout(6, 90).columns, 1, reason: 'narrower than one tile');
    });

    test('never more columns than there are things to put in them', () {
      expect(layout(3, 2000).columns, 3);
      expect(layout(1, 2000).columns, 1);
    });

    test('a cap is respected', () {
      expect(layout(12, 2000, maxColumns: 4).columns, 4);
    });
  });

  group('rows are balanced, which is the whole point', () {
    test('eleven items in eight columns become six and five', () {
      final result = layout(11, 1000, minTileWidth: 110);
      expect(result.columns, 8);
      expect(
        result.perRow,
        6,
        reason: 'eight then three is the fault being fixed',
      );
    });

    test('nine items never leave one alone on the last row', () {
      final result = layout(9, 1000, minTileWidth: 110);
      expect(result.columns, 8);
      expect(result.perRow, 5, reason: 'eight then one looks like a bug');
    });

    test('the services grid splits 8 into 4 and 4', () {
      // The owner's words: "cards on top and bottom should have same number
      // so 5-5 or 4-4".
      final result = layout(8, 1180, minTileWidth: 210);
      expect(result.columns, 5);
      expect(result.perRow, 4);
    });

    test('thirteen skills over four columns are 4-3-3-3, never 4-4-4-1', () {
      // The fault this widget exists to prevent, caught in its own first
      // implementation: capping every row at one figure leaves the remainder
      // stranded. Thirteen chips in a four-column column is the real case
      // from the About page.
      final result = layout(13, 470, minTileWidth: 110, spacing: 8);
      expect(result.columns, 4);
      expect(result.rowLengths, [4, 3, 3, 3]);
      expect(result.rowLengths.reduce((a, b) => a + b), 13);
    });

    test('every row length is within one of every other', () {
      for (var count = 1; count <= 40; count++) {
        for (final width in [300.0, 620.0, 980.0, 1400.0]) {
          final result = layout(count, width, minTileWidth: 120);
          final lengths = result.rowLengths;
          expect(
            lengths.reduce((a, b) => a + b),
            count,
            reason: 'lost or gained a tile at count=$count width=$width',
          );
          final spread = lengths.reduce(math.max) - lengths.reduce(math.min);
          expect(
            spread,
            lessThanOrEqualTo(1),
            reason: 'ragged rows $lengths at count=$count width=$width',
          );
        }
      }
    });

    test('an exact fit is left alone', () {
      final result = layout(10, 1000, minTileWidth: 110);
      expect(result.columns, 8);
      expect(result.perRow, 5, reason: 'five and five');
    });

    test('everything fitting on one row stays on one row', () {
      final result = layout(4, 1000, minTileWidth: 110);
      expect(result.columns, 4);
      expect(result.perRow, 4);
    });
  });

  group('a tile does not stretch forever', () {
    test('two cards in a wide row stay card-sized', () {
      // "Email" and "WhatsApp" each took half a monitor, which is the ragged
      // width fault wearing the opposite costume.
      final result = layout(2, 1600, minTileWidth: 132);
      expect(result.tileWidth, lessThanOrEqualTo(132 * 1.75));
      expect(result.fillsWidth, isFalse, reason: 'should align, not stretch');
    });

    test('a row that genuinely fills the width still fills it', () {
      final result = layout(8, 1180, minTileWidth: 210);
      expect(result.fillsWidth, isTrue);
      expect(result.tileWidth * 4 + 12 * 3, closeTo(1180, 0.001));
    });
  });

  group('tiles', () {
    test('share the width exactly, gaps included', () {
      final result = layout(4, 1000, minTileWidth: 240);
      expect(result.perRow, 4);
      expect(result.tileWidth * 4 + 12 * 3, closeTo(1000, 0.001));
    });

    test('are one width, however different their contents', () {
      // The other half of the complaint: "Dart" and "Adobe Premiere Pro" have
      // to occupy the same box or nothing lines up.
      final result = layout(13, 900, minTileWidth: 120);
      final rows = (13 / result.perRow).ceil();
      expect(rows * result.perRow, greaterThanOrEqualTo(13));
      expect(result.tileWidth, greaterThan(0));
    });
  });

  group('degenerate input does not throw', () {
    test('no children', () {
      expect(layout(0, 500).perRow, 1);
    });

    test('no width', () {
      expect(layout(5, 0).tileWidth, 0);
    });

    test('a negative width is clamped rather than propagated', () {
      expect(layout(5, -40).tileWidth, greaterThanOrEqualTo(0));
    });
  });
}
