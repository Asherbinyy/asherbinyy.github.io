import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/analytics/consent.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';

/// The three consent options, presented with equal weight.
///
/// Section 5: accept all, essential only, reject. None of them is amber —
/// weighting "accept" would be a dark pattern, and it is the one thing a
/// consent control must not do.
class ConsentControls extends ConsumerWidget {
  /// [onChosen] fires after a decision, so a banner can dismiss itself.
  const ConsentControls({this.onChosen, super.key});

  /// Called once the viewer has chosen.
  final VoidCallback? onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(consentControllerProvider.notifier);

    void choose(void Function() decision) {
      decision();
      onChosen?.call();
    }

    return Wrap(
      spacing: context.tokens.space12,
      runSpacing: context.tokens.space12,
      children: [
        BeaconButton(
          label: l10n.consentAcceptAll,
          onPressed: () => choose(controller.grantSession),
        ),
        BeaconButton(
          label: l10n.consentEssentialOnly,
          onPressed: () => choose(controller.withdrawToAggregate),
        ),
        BeaconButton(
          label: l10n.consentReject,
          onPressed: () => choose(controller.collectNothing),
        ),
      ],
    );
  }
}

/// Names the setting currently in force, in plain language.
String consentSummary(BuildContext context, ConsentTier tier) {
  final l10n = context.l10n;
  return switch (tier) {
    ConsentTier.session => l10n.privacyCurrentAcceptAll,
    ConsentTier.aggregate => l10n.privacyCurrentEssential,
    ConsentTier.none => l10n.privacyCurrentRejected,
    ConsentTier.unresolved => l10n.privacyCurrentUnset,
  };
}
