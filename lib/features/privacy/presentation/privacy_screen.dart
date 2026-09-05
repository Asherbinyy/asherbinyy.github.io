import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/l10n/generated/app_localizations.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// Whether a field is collected, and whether it ever could be.
enum FieldStatus {
  /// Currently being collected.
  on,

  /// Available but switched off.
  off,

  /// Never collected, under any consent.
  never,
}

/// One row of the live readout.
typedef PrivacyField = ({
  String name,
  String? tier,
  FieldStatus status,
  String value,
});

/// The consent panel as a designed page, not a banner.
///
/// The live "your value" column is the whole point: a visitor watching their
/// own data is a stronger demonstration of governance literacy than any badge.
/// The `never` rows matter as much as the `on` rows.
class PrivacyScreen extends ConsumerWidget {
  /// Reads consent and reports the viewer's own current session state.
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final consent = ref.watch(consentControllerProvider);

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
          Text(l10n.privacyHeading, style: context.type.displayM),
          SizedBox(height: tokens.space32),
          InstrumentPanel(
            padding: EdgeInsets.all(tokens.space16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fieldsFor(
                  consent: consent,
                  l10n: l10n,
                  route: GoRouterState.of(context).uri.path,
                  viewport: context.platform.viewport,
                  isTouch: context.platform.isTouch,
                ))
                  _FieldRow(field: field),
              ],
            ),
          ),
          SizedBox(height: tokens.space32),
          // Both controls carry equal weight and neither is amber. Making
          // "accept" the amber one would be a dark pattern on a page whose
          // entire subject is not using them.
          Wrap(
            spacing: tokens.space16,
            runSpacing: tokens.space16,
            children: [
              BeaconButton(
                label: consent.allowsSessionEvents
                    ? l10n.privacyWithdrawSession
                    : l10n.privacyGrantSession,
                onPressed: () {
                  final controller = ref.read(
                    consentControllerProvider.notifier,
                  );
                  if (consent.allowsSessionEvents) {
                    controller.withdrawToAggregate();
                  } else {
                    controller.grantSession();
                  }
                },
              ),
              BeaconButton(
                label: l10n.privacyCollectNothing,
                onPressed: ref
                    .read(consentControllerProvider.notifier)
                    .collectNothing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The readout, reflecting the consent actually in force.
  ///
  /// Exposed so a test can assert the table matches the client's behaviour
  /// rather than compare two independent descriptions of it.
  static List<PrivacyField> fieldsFor({
    required ConsentTier consent,
    required AppLocalizations l10n,
    required String route,
    required ViewportClass viewport,
    required bool isTouch,
  }) {
    final aggregate = consent.allowsAggregate;
    final session = consent.allowsSessionEvents;

    return [
      (
        name: l10n.privacyFieldRoute,
        tier: l10n.privacyTierAggregate,
        status: aggregate ? FieldStatus.on : FieldStatus.off,
        value: aggregate ? route : l10n.privacyNotCollected,
      ),
      (
        name: l10n.privacyFieldCountry,
        tier: l10n.privacyTierAggregate,
        status: aggregate ? FieldStatus.on : FieldStatus.off,
        // Resolved server-side from the request and discarded in the same
        // invocation, so the client genuinely does not know it.
        value: aggregate
            ? l10n.privacyResolvedServerSide
            : l10n.privacyNotCollected,
      ),
      (
        name: l10n.privacyFieldDevice,
        tier: l10n.privacyTierAggregate,
        status: aggregate ? FieldStatus.on : FieldStatus.off,
        value: aggregate
            ? (isTouch ? 'touch' : 'pointer')
            : l10n.privacyNotCollected,
      ),
      (
        name: l10n.privacyFieldReferrer,
        tier: l10n.privacyTierAggregate,
        status: aggregate ? FieldStatus.on : FieldStatus.off,
        value: aggregate
            ? l10n.privacyResolvedServerSide
            : l10n.privacyNotCollected,
      ),
      // The never rows are as important as the on rows.
      (
        name: l10n.privacyFieldAddress,
        tier: null,
        status: FieldStatus.never,
        value: l10n.privacyNotCollected,
      ),
      (
        name: l10n.privacyFieldDwell,
        tier: l10n.privacyTierSession,
        status: session ? FieldStatus.on : FieldStatus.off,
        value: session ? l10n.privacyOn : l10n.privacyNotCollected,
      ),
      (
        name: l10n.privacyFieldClicks,
        tier: l10n.privacyTierSession,
        status: session ? FieldStatus.on : FieldStatus.off,
        value: session ? l10n.privacyOn : l10n.privacyNotCollected,
      ),
      (
        name: l10n.privacyFieldDemographics,
        tier: null,
        status: FieldStatus.never,
        value: l10n.privacyNotCollected,
      ),
    ];
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final PrivacyField field;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final label = switch (field.status) {
      FieldStatus.on => l10n.privacyOn,
      FieldStatus.off => l10n.privacyOff,
      FieldStatus.never => l10n.privacyNever,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(field.name, style: type.bodyS)),
          Expanded(
            child: Text(
              field.tier ?? '',
              style: type.telemetryS.copyWith(color: tokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: type.telemetryS.copyWith(
                // Success is monochrome here too: an active field is not
                // green, it is simply legible.
                color: field.status == FieldStatus.on
                    ? tokens.instrument
                    : tokens.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              field.value,
              style: type.telemetryS.copyWith(color: tokens.instrumentMid),
            ),
          ),
        ],
      ),
    );
  }
}
