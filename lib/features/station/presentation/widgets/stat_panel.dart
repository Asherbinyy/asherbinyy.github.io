import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/telemetry_value.dart';

/// One of the hero's instrument panels: a large mono numeral and its label.
///
/// The screen spec calls these the fastest thing on the page to read, which is
/// deliberate — a recruiter's first sixty seconds is the whole game.
class StatPanel extends StatelessWidget {
  /// [locale] resolves the label's channel without a `BuildContext` lookup.
  const StatPanel({required this.stat, required this.locale, super.key});

  /// The owner-supplied value and label.
  final ProfileStat stat;

  /// Active content channel.
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InstrumentPanel(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space16,
        vertical: tokens.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TelemetryNumeral(value: stat.value),
          Text(
            stat.label.resolve(locale),
            maxLines: 1,
            style: context.type.meta,
          ),
        ],
      ),
    );
  }
}
