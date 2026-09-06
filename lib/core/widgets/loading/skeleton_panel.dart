import 'package:material_ui/material_ui.dart';

import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/loading/sweep_shimmer.dart';

/// An empty instrument waiting for a reading.
///
/// Section 11 rejects the grey rounded rectangle: a skeleton here is the panel
/// language with nothing in it, which is both truthful and better looking.
/// [width] and [height] are required because a skeleton whose geometry differs
/// from its replacement causes the layout shift the quality floor forbids.
class SkeletonPanel extends StatelessWidget {
  /// [child] holds skeleton lines when the panel has known internal structure.
  const SkeletonPanel({
    required this.width,
    required this.height,
    this.padding = EdgeInsets.zero,
    this.child,
    super.key,
  });

  /// Exact width of the content this stands in for.
  final double width;

  /// Exact height of the content this stands in for.
  final double height;

  /// Padding inside the hairline edge, matching the real panel.
  final EdgeInsetsGeometry padding;

  /// Optional internal skeleton structure.
  final Widget? child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SweepShimmer(
      child: SizedBox(
        width: width,
        height: height,
        child: InstrumentPanel(
          padding: padding,
          child: child ?? const SizedBox.expand(),
        ),
      ),
    ),
  );
}
