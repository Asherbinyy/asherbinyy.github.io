import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/analytics/analytics_providers.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';

/// The same reversible choice on first visit and from the footer.
class AnalyticsConsent extends ConsumerWidget {
  /// [settings] exposes the controls even after a previous choice.
  const AnalyticsConsent({this.settings = false, super.key});

  /// Whether the owner of this browser reopened their settings.
  final bool settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(consentControllerProvider);
    if (!ref.watch(analyticsIsCollectingProvider) ||
        (!settings && consent.isResolved)) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;
    final copy = context.l10n;
    final controller = ref.read(consentControllerProvider.notifier);
    return Semantics(
      container: true,
      label: copy.footerConsent,
      child: Material(
        color: tokens.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                Tokens.sheetMaxHeightFraction,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(tokens.space16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.privacyHeading, style: context.type.heading),
                  if (consent.isResolved)
                    Text(
                      consent.allowsAggregate
                          ? copy.privacyCurrentAcceptAll
                          : copy.privacyCurrentRejected,
                      style: context.type.bodyS,
                    ),
                  SizedBox(height: tokens.space8),
                  Text(
                    [
                      copy.privacyFieldRoute,
                      copy.privacyFieldClicks,
                      copy.privacyFieldDwell,
                      copy.privacyFieldCountry,
                      copy.privacyFieldDevice,
                      copy.privacyFieldReferrer,
                    ].join(' · '),
                    style: context.type.bodyS,
                  ),
                  SizedBox(height: tokens.space12),
                  Wrap(
                    spacing: tokens.space12,
                    runSpacing: tokens.space8,
                    children: [
                      BeaconButton(
                        label: copy.consentAcceptAll,
                        onPressed: () {
                          controller.grantSession();
                          if (settings) Navigator.of(context).pop();
                        },
                      ),
                      BeaconButton(
                        label: copy.consentReject,
                        onPressed: () {
                          controller.collectNothing();
                          if (settings) Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => const _AnalyticsNotice(),
                        ),
                        child: Text(copy.privacyHeading),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsNotice extends StatelessWidget {
  const _AnalyticsNotice();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.privacyHeading),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.privacyBody),
          SizedBox(height: context.tokens.space16),
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              'Collection begins only after you accept. It covers page views, '
              'public app and link clicks, CV opens, gallery and audio '
              'actions, '
              'game starts and finishes, language and theme choices, active '
              'reading time and scroll quartiles. Only referrer host and an '
              'optional campaign slug are recorded; private query parameters '
              'and form contents are excluded. The request address and browser '
              'header are used briefly for a daily salted hash, then '
              'discarded. '
              'Daily hashes expire within two days and are never linked across '
              'days. Aggregate counts are kept for 24 months. Your choice is '
              'saved on this browser; an optional random identifier lasts only '
              'for this tab and is not stored on the server. Change your '
              'choice '
              'using Consent in the footer; rejecting stops future collection '
              'and clears the tab identifier. Ahmed Elsherbini operates this '
              'first-party service on Cloudflare. Use the contact details on '
              'About for privacy requests.',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(MaterialLocalizations.of(context).closeButtonLabel),
      ),
    ],
  );
}
