import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';

/// The career, top to bottom, as the trace's burst anchors.
///
/// Section 6 runs the trace from the hero to the end of the career sequence, so
/// the sequence has to exist for the trace to have anything to travel over.
/// Kept deliberately quiet: hairline-separated rows carrying only what the
/// content states. The trace is the bold element and this must not compete.
class CareerSequence extends StatelessWidget {
  /// [roles] arrive in the content's own chronological order.
  const CareerSequence({
    required this.roles,
    required this.locale,
    required this.anchorRegistry,
    super.key,
  });

  /// Career stations.
  final List<CareerRole> roles;

  /// Active content channel.
  final AppLocale locale;

  /// Supplies the stable keys the fixed trace layer measures.
  final TraceAnchorRegistry anchorRegistry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final role in roles)
        KeyedSubtree(
          key: anchorRegistry.keyFor(role.id),
          child: _CareerEntry(role: role, locale: locale),
        ),
    ],
  );
}

class _CareerEntry extends StatelessWidget {
  const _CareerEntry({required this.role, required this.locale});

  final CareerRole role;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    // Only what the content actually carries. Five of the six roles have no
    // company or summary, and inventing either would be a claim about the
    // owner's career that nobody made.
    final company = role.company;
    final title = role.title;
    final summary = role.summary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: tokens.hairlineWidth,
            width: tokens.heroRuleWidth,
            child: ColoredBox(color: tokens.hairline),
          ),
          SizedBox(height: tokens.space16),
          Text(
            '${role.start} — ${role.end ?? ''}'.trim(),
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          SizedBox(height: tokens.space8),
          if (company != null)
            Text(company, style: type.heading)
          else
            Text('${role.city}, ${role.country}', style: type.heading),
          if (title != null)
            Text(
              title.resolve(locale),
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          if (company != null)
            Text('${role.city}, ${role.country}', style: type.meta),
          if (summary != null) ...[
            SizedBox(height: tokens.space12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
              child: Text(summary.resolve(locale), style: type.body),
            ),
          ],
        ],
      ),
    );
  }
}
