import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/widgets/even_grid.dart';

import '../support/loading_harness.dart';

/// Cards sit square in their column, at every width.
///
/// The owner's report was "on the phone, most of the cards are on the left side
/// not centered". Every instance had the same shape: a card with a fixed width
/// inside a column wider than it, so all the slack fell on one side — a 200px
/// stat panel in a 350px phone column left 150px of it, all on the right.
///
/// This measures the thing that was wrong. A grid's tiles must either fill the
/// row or sit with equal space on both sides; there is no arrangement where one
/// edge gets the remainder.
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
    testWidgets('one card fills it rather than hugging the left edge', (
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
        expect(
          row.left,
          closeTo(row.right, 0.5),
          reason: 'a card sat off-centre: ${row.left} left, ${row.right} right',
        );
      }
    });

    testWidgets('a short last row is centred, not left behind', (tester) async {
      final rows = await rowsOf(
        tester,
        count: 5,
        width: 360,
        minTileWidth: 160,
      );
      expect(rows, hasLength(3), reason: 'two columns over five tiles');
      for (final row in rows) {
        expect(row.left, closeTo(row.right, 0.5));
      }
    });
  });

  group('every phone width, not just the one that was reported', () {
    testWidgets('no row ever favours one edge', (tester) async {
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
              closeTo(row.right, 0.5),
              reason:
                  'off-centre at width=$width count=$count: '
                  '${row.left} left, ${row.right} right',
            );
          }
        }
      }
    });
  });

  group('a wide screen keeps the block against the reading edge', () {
    testWidgets('a couple of cards start at the left, not in the middle', (
      tester,
    ) async {
      // The opposite failure, and it is not the same bug: under a left-aligned
      // heading, two cards floated to the centre of a 1440 monitor look
      // detached from it. Narrow screens centre because the tile fills; wide
      // ones align, because there the block genuinely is narrower than the
      // page.
      final rows = await rowsOf(
        tester,
        count: 2,
        width: 1440,
        minTileWidth: 160,
      );
      expect(rows.single.left, closeTo(0, 0.5));
      expect(rows.single.right, greaterThan(100));
    });
  });
}
