import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// Tiles of one width, in rows of one length.
///
/// Everything on this site that shows a set of small things — skills, tools,
/// services, social links, contact destinations — was a `Wrap` of
/// content-sized children. A `Wrap` gives each child exactly the width of its
/// own text and then fills each line until the next one does not fit, which
/// produces two faults the owner reported on four different pages in the same
/// breath.
///
/// Widths disagree: "Dart" is a third the width of "Adobe Premiere Pro", so
/// nothing lines up vertically and the block reads as rubble rather than a
/// grid. And rows disagree: eleven items in a line that fits eight leaves
/// eight and then three, or worse, eight and then one, which looks like a
/// mistake because it is indistinguishable from one.
///
/// So this measures the space, decides how many columns fit, and then — the
/// part `Wrap` cannot do — **spreads the items evenly over the rows it will
/// need anyway**. Eleven items in eight columns become six and five, not eight
/// and three. A row that is short is centred, so the block stays symmetrical
/// instead of trailing off to one side.
///
/// Every tile in a row is also given the same height, because a card that is
/// one line taller than its neighbour drags the row out of square.
class EvenGrid extends StatelessWidget {
  /// Lays [children] out in equal tiles at least [minTileWidth] wide.
  const EvenGrid({
    required this.children,
    required this.minTileWidth,
    this.spacing,
    this.runSpacing,
    this.maxColumns,
    this.stretch = false,
    super.key,
  });

  /// The tiles, in order.
  final List<Widget> children;

  /// The narrowest a tile may be before a column is dropped.
  ///
  /// This is what decides the column count, so it is the one number to tune
  /// per use: wide for cards with a sentence in them, narrow for chips.
  final double minTileWidth;

  /// Horizontal gap. Defaults to the theme's `space12`.
  final double? spacing;

  /// Vertical gap. Defaults to [spacing].
  final double? runSpacing;

  /// An upper bound on columns, for a set that should not stretch thin.
  final int? maxColumns;

  /// Whether tiles share out the whole row, or stay their declared size.
  ///
  /// False by default, and the default matters. The first version of this
  /// widget always stretched, and the owner's reaction to the result was the
  /// correct one: "Dart" became a 230px box with 170px of empty padding in it,
  /// because equalising widths and filling the row are two different jobs and
  /// only the first was asked for.
  ///
  /// True suits a card that is mostly a picture -- a service, an application,
  /// an interest -- where a wider tile means a bigger image. False suits
  /// anything that is a word in a box, where a wider tile means nothing but
  /// more space around the word.
  ///
  /// Below the compact breakpoint everything fills regardless: a card that
  /// keeps its desktop width on a phone sits against one edge with all the
  /// slack on the other, which is the fault this widget was built to fix.
  final bool stretch;

  /// How many columns [width] affords, and how many tiles go on each row.
  ///
  /// Separated out and exercised directly by tests: the arithmetic is the
  /// whole widget, and asserting it through a rendered tree would prove much
  /// less about the cases that actually went wrong.
  static ({int columns, int perRow, List<int> rowLengths, double tileWidth})
  measure({
    required double width,
    required int count,
    required double minTileWidth,
    required double spacing,
    int? maxColumns,
    bool stretch = false,
  }) {
    if (count <= 0 || width <= 0) {
      return (
        columns: 1,
        perRow: 1,
        rowLengths: const <int>[],
        tileWidth: math.max(width, 0),
      );
    }
    final fits = ((width + spacing) / (minTileWidth + spacing)).floor();
    var columns = fits.clamp(1, count);
    if (maxColumns != null) columns = math.min(columns, maxColumns);

    // The balancing step, and the reason this widget exists.
    //
    // `rows` is how many rows this many columns forces. The items are then
    // spread back over exactly those rows as evenly as they divide: thirteen
    // in four rows is 4-3-3-3, never 4-4-4-1. A first attempt used one
    // per-row figure for every row and produced exactly the 4-4-4-1 it was
    // written to prevent, which is worth remembering — "as many as fit, then
    // the remainder" is the fault, and capping it is not the fix.
    final rows = (count / columns).ceil();
    final base = count ~/ rows;
    final extra = count % rows;
    final rowLengths = <int>[
      for (var row = 0; row < rows; row++) base + (row < extra ? 1 : 0),
    ];

    // Every tile is one width across the whole grid.
    //
    // On a phone that width is the column, because a card narrower than the
    // screen leaves all its slack on one side. Anywhere else it is the size
    // the caller declared, unless it asked to stretch -- equalising widths and
    // filling a row are different jobs, and running them together is what
    // turned a row of short words into a row of mostly-empty boxes.
    final perRow = rowLengths.first;
    final filled = (width - (perRow - 1) * spacing) / perRow;
    final isPhone = width < Tokens.mediumBreakpoint;
    final tileWidth = isPhone || stretch
        ? filled
        : math.min(minTileWidth, filled);

    return (
      columns: columns,
      perRow: perRow,
      rowLengths: rowLengths,
      tileWidth: math.max(tileWidth, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;
    final gap = spacing ?? tokens.space12;
    final runGap = runSpacing ?? gap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite) {
          // Nothing to measure against — a horizontal scroller, usually. A row
          // of natural widths is wrong-looking but visible, which beats an
          // assertion in a release build.
          return Wrap(spacing: gap, runSpacing: runGap, children: children);
        }

        final layout = measure(
          width: width,
          count: children.length,
          minTileWidth: minTileWidth,
          spacing: gap,
          maxColumns: maxColumns,
          stretch: stretch,
        );

        final rows = <Widget>[];
        var start = 0;
        for (final length in layout.rowLengths) {
          final end = math.min(start + length, children.length);
          final slice = children.sublist(start, end);
          start = end;
          rows.add(
            IntrinsicHeight(
              child: Row(
                // Every row starts at the same edge, always. Centring a short
                // last row under left-aligned full ones was meant to look
                // balanced and read as a mistake instead: some rows began at
                // the margin and some began in the middle of the page.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < slice.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    SizedBox(width: layout.tileWidth, child: slice[i]),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: runGap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}
