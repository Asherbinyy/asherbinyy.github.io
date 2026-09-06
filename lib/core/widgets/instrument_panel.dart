import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/painting/corner_ticks_painter.dart';

/// The panel signature from section 4: a hairline edge plus corner ticks.
///
/// This replaces card shadows entirely across the site. The widget reserves the
/// tick offset on all four sides so the marks are never clipped, which means a
/// panel's outer size already includes them and callers can size content
/// against the same box a skeleton uses.
class InstrumentPanel extends StatelessWidget {
  /// [fill] stays null for skeletons, whose fill is transparent by section 11.
  const InstrumentPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.fill,
    super.key,
  });

  /// Panel contents.
  final Widget child;

  /// Inner padding applied inside the hairline edge.
  final EdgeInsetsGeometry padding;

  /// Panel fill; transparent when null.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return CustomPaint(
      painter: CornerTicksPainter(
        edgeColour: tokens.hairline,
        tickColour: tokens.beaconDim,
        strokeWidth: tokens.hairlineWidth,
        tickLength: tokens.cornerTickLength,
        inset: tokens.cornerTickOffset,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.cornerTickOffset),
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
