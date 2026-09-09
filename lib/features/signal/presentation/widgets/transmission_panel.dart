import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/content/period.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// One station's transmission: what the content records about that role.
///
/// Presented beside the map on a pointer browser and as a bottom sheet on a
/// touch one — `01-DESIGN-SYSTEM.md` section 7 decides that once, in
/// `presentSecondary`, so this widget never asks which it is on.
class TransmissionPanel extends StatelessWidget {
  /// [role] is rendered exactly as the content states it.
  const TransmissionPanel({
    required this.role,
    required this.locale,
    super.key,
  });

  /// The selected career station.
  final CareerRole role;

  /// Active content channel.
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    // Five of the six roles carry no company, no title and no summary. Each
    // line appears only if the content has it; none is inferred.
    final company = role.company;
    final title = role.title;
    final summary = role.summary;

    return InstrumentPanel(
      // `surfaceRaised` is near-white on papyrus, which is why the owner read
      // this as a plain white card: the panel had no edge of its own against
      // the page. `surface` sits a step down from the page in Deshret and a
      // step up in Kemet, so the panel reads as a panel in both.
      fill: tokens.surface,
      padding: EdgeInsets.all(tokens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A gold rule above the name, short of the column. The same device
          // the hero uses under the name, so a selected stop announces itself
          // in the site's own vocabulary rather than with a heavier border.
          SizedBox(
            width: tokens.space48,
            height: tokens.hairlineWidth * 2,
            child: ColoredBox(color: tokens.beacon),
          ),
          SizedBox(height: tokens.space12),
          Text(
            company ?? role.city,
            style: type.heading.copyWith(color: tokens.beacon),
          ),
          SizedBox(height: tokens.space4),
          Text(
            '${role.city}, ${role.country}',
            style: type.telemetryS.copyWith(color: tokens.instrumentMid),
          ),
          Text(
            formatPeriod(context.l10n, role.start, role.end),
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          if (title != null) ...[
            SizedBox(height: tokens.space12),
            Text(
              title.resolve(locale),
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ],
          if (summary != null) ...[
            SizedBox(height: tokens.space12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
              child: Text(summary.resolve(locale), style: type.body),
            ),
          ],
          if (role.stack.isNotEmpty) ...[
            SizedBox(height: tokens.space16),
            Wrap(
              spacing: tokens.space8,
              runSpacing: tokens.space8,
              children: [
                for (final technology in role.stack)
                  _StackChip(label: technology),
              ],
            ),
          ],
          if (role.appIds.isNotEmpty) ...[
            SizedBox(height: tokens.space16),
            Text(
              l10n.signalAppsShipped(role.appIds.length),
              style: type.telemetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// One technology from the role's stack, as a hairline chip.
class _StackChip extends StatelessWidget {
  const _StackChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.tagRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space8,
          vertical: tokens.space4,
        ),
        child: Text(
          label,
          style: context.type.meta.copyWith(color: tokens.instrumentMid),
        ),
      ),
    );
  }
}
