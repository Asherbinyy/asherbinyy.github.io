import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// Views per day as a monochrome bar ramp, with only the peak in amber.
///
/// `01-DESIGN-SYSTEM.md` §2: charts are monochrome ramps from
/// `--instrument-dim` to `--instrument`, with at most one series in
/// `--beacon` — the one the viewer is meant to read first. Here that is the
/// busiest day, which is the bar worth finding.
class ViewsSparkline extends StatelessWidget {
  /// [daily] is one count per day, oldest first.
  const ViewsSparkline({required this.daily, super.key});

  /// Views per day.
  final List<int> daily;

  /// Declared, never inferred.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final peak = daily.isEmpty ? 0 : daily.reduce((a, b) => a > b ? a : b);
    // Only the first busiest day is amber. Spending the one chroma on several
    // bars would spend it nowhere.
    final peakIndex = peak == 0 ? -1 : daily.indexOf(peak);

    return SizedBox(
      height: height,
      child: Semantics(
        // The shape is decoration; the numbers above it are the content.
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, count) in daily.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.space4 / 4),
                  child: _Bar(
                    // A zero day still draws a hairline, so a gap reads as
                    // "no views" rather than as missing data.
                    fraction: peak == 0 ? 0 : count / peak,
                    isPeak: index == peakIndex,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.isPeak});

  final double fraction;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: fraction <= 0 ? 0.02 : fraction.clamp(0.02, 1.0),
      child: ColoredBox(
        color: isPeak
            ? tokens.beacon
            : Color.lerp(tokens.instrumentDim, tokens.instrument, fraction)!,
        child: const SizedBox.expand(),
      ),
    );
  }
}
