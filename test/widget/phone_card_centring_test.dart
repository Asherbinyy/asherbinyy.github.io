import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/widgets/even_grid.dart';

import '../support/loading_harness.dart';

/// Cards sit square in their column on a phone, and line up on a desktop.
///
/// Two reports, and the second corrected the first. "On the phone, most of the
/// cards are on the left side not centered" was a card with a fixed width in
/// a wider column — a 200px stat panel in a 350px column left 150px of slack,
/// all of it on the right. Below the compact breakpoint a tile takes the
/// column.
///
/// The fix for that went too far: short rows were centred while full rows
/// filled, and the owner's second report was the right one — "you made some
/// start from the beginning then the rest start from the centre". So every row
/// starts at the same edge, always, and what a phone guarantees is that a full
/// row reaches both of them.
void main() {
  /// Renders [count] marked tiles in a [width]-wide box and reports each row's
  /// left and right margins.
  Future<List<({double left, double right})>> rowsOf(
    WidgetTester tester, {
    required int count,
    required double width,
    required double minTileWidth,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LoadingHarness(
        viewportWidth: width,
        child: SizedBox(
          width: width,
          child: EvenGrid(
            minTileWidth: minTileWidth,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(key: ValueKey('tile$i'), height: 40),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Group the tiles by their vertical position, which is what a row is.
    final byTop = <double, List<Rect>>{};
    for (var i = 0; i < count; i++) {
      final rect = tester.getRect(find.byKey(ValueKey('tile$i')));
      byTop.putIfAbsent(rect.top, () => []).add(rect);
    }

    final grid = tester.getRect(find.byType(EvenGrid));
    return [
      for (final row in byTop.values)
        (left: row.first.left - grid.left, right: grid.right - row.last.right),
    ];
  }

  group('a phone column', () {
    testWidgets('a full row reaches both edges rather than hugging one', (
      tester,
    ) async {
      // The exact case from the home page: a 200px stat panel on a 350px
      // phone, which used to leave 150px of slack entirely on the right.
      final rows = await rowsOf(
        tester,
        count: 2,
        width: 350,
        minTileWidth: 200,
      );
      for (final row in rows) {
        expect(row.left, closeTo(0, 0.5));
        expect(
          row.right,
          closeTo(0, 0.5),
          reason: 'a phone card left slack at one edge: ${row.right}px',
        );
      }
    });

    testWidgets('every row begins at the same edge', (tester) async {
      // Never centred, whatever the row holds. A short last row sitting in the
      // middle under left-aligned full ones reads as a mistake, not a balance.
      for (final width in [320.0, 360.0, 390.0, 414.0, 430.0]) {
        for (final count in [1, 2, 3, 5, 8, 13]) {
          final rows = await rowsOf(
            tester,
            count: count,
            width: width,
            minTileWidth: 160,
          );
          for (final row in rows) {
            expect(
              row.left,
              closeTo(0, 0.5),
              reason:
                  'a row was indented at width=$width count=$count: '
                  '${row.left}px',
            );
          }
        }
      }
    });
  });

  group('a wide screen', () {
    testWidgets('tiles keep their declared size instead of filling', (
      tester,
    ) async {
      // Equalising widths and filling a row are different jobs. Running them
      // together gave a short word a box three times its length.
      final rows = await rowsOf(
        tester,
        count: 2,
        width: 1440,
        minTileWidth: 160,
      );
      expect(rows.single.left, closeTo(0, 0.5));
      expect(rows.single.right, greaterThan(1000));
    });
  });
}
