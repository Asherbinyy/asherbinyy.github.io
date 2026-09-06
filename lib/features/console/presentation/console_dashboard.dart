import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/loading/carrier_loader.dart';
import 'package:nocturne/features/console/data/console_providers.dart';
import 'package:nocturne/features/console/data/console_repository.dart';
import 'package:nocturne/features/console/domain/console_summary.dart';
import 'package:nocturne/features/console/presentation/widgets/views_sparkline.dart';

/// The dashboard itself, behind the token gate.
///
/// This is the half of `/console` that is deferred: it is never loaded for a
/// public visitor, because a public visitor never gets past the gate.
class ConsoleDashboard extends ConsumerWidget {
  /// Reads the summary the token unlocked.
  const ConsoleDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return switch (ref.watch(consoleSummaryProvider)) {
      AsyncData(value: final summary?) => _Dashboard(summary: summary),
      AsyncError(error: ConsoleAuthException()) => _Message(
        text: l10n.consoleRejected,
        onDismiss: () => ref.read(consoleTokenProvider.notifier).state = null,
      ),
      AsyncError() => _Message(
        text: l10n.consoleUnavailable,
        onDismiss: () => ref.read(consoleTokenProvider.notifier).state = null,
      ),
      AsyncData() => const SizedBox.shrink(),
      _ => Padding(
        padding: EdgeInsets.only(top: tokens.space32),
        child: const CarrierLoader(),
      ),
    };
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.summary});

  final ConsoleSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.consoleHeading, style: context.type.displayM),
        SizedBox(height: tokens.space24),
        if (summary.isEmpty)
          Text(
            l10n.consoleNothingYet,
            style: context.type.bodyL.copyWith(color: tokens.textSecondary),
          )
        else ...[
          Wrap(
            spacing: tokens.space16,
            runSpacing: tokens.space16,
            children: [
              _Tile(value: '${summary.views}', label: l10n.consoleViews),
              _Tile(
                value: '${summary.uniqueVisitors}',
                label: l10n.consoleUnique,
              ),
              _Tile(value: '${summary.cvOpens}', label: l10n.consoleCvOpens),
              _Tile(
                value: _duration(summary.meanDwellSeconds),
                label: l10n.consoleMeanDwell,
              ),
            ],
          ),
          SizedBox(height: tokens.space32),
          Text(
            l10n.consoleDailyViews,
            style: context.type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          SizedBox(height: tokens.space8),
          ViewsSparkline(daily: summary.daily),
        ],
        SizedBox(height: tokens.space48),
        Text(l10n.consoleCampaigns, style: context.type.heading),
        SizedBox(height: tokens.space16),
        _Campaigns(rows: summary.campaigns),
        SizedBox(height: tokens.space48),
        BeaconButton(
          label: l10n.consoleSignOut,
          onPressed: () => ref.read(consoleTokenProvider.notifier).state = null,
        ),
      ],
    );
  }

  /// Whole minutes and seconds, in the spec's `2m14s` shape.
  static String _duration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m${(seconds % 60).toString().padLeft(2, '0')}s';
  }
}

/// One instrument panel carrying a single large mono numeral.
class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

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

/// The campaign table — the operationally useful part of the page.
class _Campaigns extends StatelessWidget {
  const _Campaigns({required this.rows});

  final List<CampaignRow> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    if (rows.isEmpty) {
      return Text(
        l10n.consoleNoCampaigns,
        style: context.type.body.copyWith(color: tokens.textSecondary),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(
          campaign: '',
          views: l10n.consoleColumnViews,
          cvOpens: l10n.consoleColumnCv,
          lastSeen: l10n.consoleColumnLastSeen,
          isHeader: true,
        ),
        for (final row in rows)
          _Row(
            campaign: row.campaign,
            views: '${row.views}',
            cvOpens: '${row.cvOpens}',
            lastSeen: row.lastSeen,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.campaign,
    required this.views,
    required this.cvOpens,
    required this.lastSeen,
    this.isHeader = false,
  });

  final String campaign;
  final String views;
  final String cvOpens;
  final String lastSeen;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final style = isHeader
        ? type.telemetryS.copyWith(color: tokens.textMuted)
        : type.telemetry.copyWith(color: tokens.instrument);

    return Container(
      padding: EdgeInsets.symmetric(vertical: tokens.space8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              campaign,
              style: isHeader
                  ? style
                  : type.bodyS.copyWith(color: tokens.textPrimary),
            ),
          ),
          Expanded(
            child: Text(views, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(cvOpens, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 2,
            child: Text(lastSeen, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// A rejected token or an unreachable endpoint, with a way to try again.
class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        style: context.type.body.copyWith(color: context.tokens.alert),
      ),
      SizedBox(height: context.tokens.space16),
      BeaconButton(label: context.l10n.consoleSignIn, onPressed: onDismiss),
    ],
  );
}
