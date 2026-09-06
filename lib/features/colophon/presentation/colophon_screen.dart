import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/features/colophon/data/build_facts_provider.dart';
import 'package:nocturne/features/colophon/domain/build_facts.dart';
import 'package:nocturne/features/colophon/domain/collection_rules.dart';

/// `/how-it-was-built` — the page that turns "creative" into "hireable".
///
/// Roadmap 2.7. Two things make it worth reading rather than skimming, and
/// both are structural rather than editorial:
///
/// 1. **Every measurement is generated.** Coverage, test counts and the
///    Lighthouse floors are read from `assets/build_facts.json`, which
///    `tool/generate_build_facts.dart` derives from lcov, a machine-readable
///    test run and the CI workflow. A page claiming care cannot carry a
///    hand-typed number that went stale two commits ago.
/// 2. **The collection table is derived from the code that enforces it.** It
///    asks `AnalyticsClient.permits` at each tier rather than restating the
///    rules beside them, so the description and the behaviour cannot drift.
class ColophonScreen extends ConsumerWidget {
  /// Reads the generated measurements.
  const ColophonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final type = context.type;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.navHowItWasBuilt, style: type.displayM),
          SizedBox(height: tokens.space16),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              l10n.colophonIntro,
              style: type.bodyL.copyWith(color: tokens.textSecondary),
            ),
          ),
          SizedBox(height: tokens.space48),

          Text(l10n.colophonMeasured, style: type.heading),
          SizedBox(height: tokens.space16),
          switch (ref.watch(buildFactsProvider)) {
            AsyncData(value: final facts?) => _Measured(facts: facts),
            AsyncData() || AsyncError() => Text(
              l10n.colophonUnavailable,
              style: type.body.copyWith(color: tokens.textMuted),
            ),
            _ => const SizedBox.shrink(),
          },
          SizedBox(height: tokens.space48),

          Text(l10n.colophonArchitecture, style: type.heading),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              l10n.colophonArchitectureBody,
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ),
          SizedBox(height: tokens.space48),

          Text(l10n.colophonCollection, style: type.heading),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              l10n.colophonCollectionIntro,
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ),
          SizedBox(height: tokens.space16),
          const _CollectionTable(),
          SizedBox(height: tokens.space48),

          Text(l10n.colophonNeverHeading, style: type.heading),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              l10n.colophonNever,
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The generated figures, as instrument panels.
class _Measured extends StatelessWidget {
  const _Measured({required this.facts});

  final BuildFacts facts;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final type = context.type;
    final coverage = facts.coveragePercent;
    final performance = facts.lighthousePerformanceFloor;
    final accessibility = facts.lighthouseAccessibilityFloor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: tokens.space16,
          runSpacing: tokens.space16,
          children: [
            if (coverage != null)
              _Figure(
                value: '${coverage.toStringAsFixed(1)}%',
                label: l10n.colophonCoverage,
              ),
            _Figure(value: '${facts.dartTests}', label: l10n.colophonTests),
            _Figure(
              value: '${facts.workerTests}',
              label: l10n.colophonWorkerTests,
            ),
          ],
        ),
        if (performance != null && accessibility != null) ...[
          SizedBox(height: tokens.space16),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              l10n.colophonLighthouse(
                performance.toString(),
                accessibility.toString(),
              ),
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
        if (facts.generatedAt.isNotEmpty) ...[
          SizedBox(height: tokens.space8),
          Text(
            l10n.colophonGeneratedOn(facts.generatedAt),
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
        ],
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InstrumentPanel(
      child: Padding(
        padding: EdgeInsets.all(tokens.space16),
        child: SizedBox(
          width: tokens.consoleTileWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: context.type.displayM.copyWith(color: tokens.instrument),
              ),
              SizedBox(height: tokens.space4),
              Text(
                label,
                style: context.type.telemetryS.copyWith(
                  color: tokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every event the site can record, and the consent each one needs.
class _CollectionTable extends StatelessWidget {
  const _CollectionTable();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rule in collectionRules())
          Container(
            padding: EdgeInsets.symmetric(vertical: tokens.space8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    rule.event.name,
                    style: context.type.telemetry.copyWith(
                      color: tokens.instrument,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _label(context, rule.requires),
                    textAlign: TextAlign.end,
                    style: context.type.telemetryS.copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The weakest consent that permits the row, in plain language.
  ///
  /// `unresolved` and `aggregate` both read as "counted anonymously": from the
  /// viewer's side they are the same thing, which is exactly what §3 argues —
  /// a cookieless aggregate counter sits outside consent, so an unanswered
  /// banner and "essential only" behave identically.
  static String _label(BuildContext context, ConsentTier tier) =>
      switch (tier) {
        ConsentTier.none => context.l10n.colophonTierNone,
        ConsentTier.unresolved ||
        ConsentTier.aggregate => context.l10n.colophonTierAggregate,
        ConsentTier.session => context.l10n.colophonTierSession,
      };
}
