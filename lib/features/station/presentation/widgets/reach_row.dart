import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';

/// Where the work has been, as a line of flags.
///
/// Seven countries in one line says more about a career than a sentence about
/// it would, and it is the one fact on this page a stranger cannot get from a
/// job title.
///
/// The flags are emoji rather than images: a regional-indicator pair is two
/// characters, renders from the system font on every platform this ships to,
/// and costs nothing to download. Bundling seven PNGs to say the same thing
/// would be the wrong trade.
class ReachRow extends StatelessWidget {
  /// Renders [countries] as ISO 3166-1 alpha-2 codes.
  const ReachRow({required this.countries, super.key});

  /// The codes to draw, in the order the owner set.
  final List<String> countries;

  /// Turns "EG" into its flag.
  ///
  /// Regional indicator symbols sit at U+1F1E6 for A, so a country code maps
  /// to them by offset. Anything that is not two ASCII letters is skipped
  /// rather than rendered as tofu.
  static String? flagOf(String code) {
    if (code.length != 2) return null;
    final upper = code.toUpperCase();
    final points = <int>[];
    for (final unit in upper.codeUnits) {
      if (unit < 0x41 || unit > 0x5A) return null;
      points.add(0x1F1E6 + (unit - 0x41));
    }
    return String.fromCharCodes(points);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final flags = [
      for (final code in countries)
        if (flagOf(code) case final String flag) (code: code, flag: flag),
    ];
    if (flags.isEmpty) return const SizedBox.shrink();

    return Semantics(
      // The codes, not the flags: a screen reader reading seven flag emoji
      // aloud is noise, and the country names are the information.
      label: '${context.l10n.heroReach} ${flags.map((e) => e.code).join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        spacing: tokens.space12,
        runSpacing: tokens.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.l10n.heroReach,
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          for (final entry in flags)
            Text(entry.flag, style: type.body.copyWith(height: 1)),
        ],
      ),
    );
  }
}
