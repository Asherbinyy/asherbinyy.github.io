import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/content/period.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/country_names.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/features/station/presentation/widgets/stop_mark.dart';
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

  /// The stops, most recent first.
  ///
  /// The content is stored oldest-first, which is the order a life happened
  /// in and the wrong order to introduce it in: a reader meeting this column
  /// wants to know where he is now, not where he started. Sorted by start
  /// date rather than reversed, so the display order does not depend on how
  /// the document happens to be written.
  List<CareerRole> get _mostRecentFirst =>
      [...roles]..sort((a, b) => b.start.compareTo(a.start));

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final role in _mostRecentFirst)
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

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space32),
      // The sign runs down the leading edge, beside the entry rather than
      // above it, so a reader scanning the column can tell study from
      // employment from freelance without reading a word.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: tokens.space24),
            child: StopMark(role: role),
          ),
          SizedBox(width: tokens.space24),
          Expanded(child: _entry(context, tokens, type)),
        ],
      ),
    );
  }

  /// Where it was, with the country named rather than coded. The content
  /// stores "EG" because the atlas keys on it; a reader is owed "Egypt".
  String get _place => '${role.city}, ${CountryNames.of(role.country, locale)}';

  /// Only what the content actually carries. Five of the six roles have no
  /// company or summary, and inventing either would be a claim about the
  /// owner's career that nobody made.
  Widget _entry(
    BuildContext context,
    ThemeTokens tokens,
    NocturneTypography type,
  ) {
    final company = role.company;
    final title = role.title;
    final summary = role.summary;

    return Column(
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
          formatPeriod(context.l10n, role.start, role.end),
          style: type.telemetryS.copyWith(color: tokens.textMuted),
        ),
        SizedBox(height: tokens.space8),
        if (company != null)
          Text(company, style: type.heading)
        else
          Text(_place, style: type.heading),
        if (title != null && role.id != 'freelance')
          Text(
            title.resolve(locale),
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        if (company != null)
          Text(role.id == 'freelance' ? 'Remote' : _place, style: type.meta),
        if (summary != null && role.id != 'freelance') ...[
          SizedBox(height: tokens.space12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(summary.resolve(locale), style: type.body),
          ),
        ],
      ],
    );
  }
}
