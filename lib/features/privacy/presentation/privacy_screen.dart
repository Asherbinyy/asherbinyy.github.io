import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/features/privacy/presentation/widgets/consent_controls.dart';

/// The privacy notice: what is collected, what never is, and how to change it.
///
/// Plain language, not a dashboard. The field-by-field readout belongs on
/// `/how-it-was-built`, where it demonstrates the pipeline to somebody who came
/// to read about it rather than confronting a visitor who did not.
class PrivacyScreen extends ConsumerWidget {
  /// Reads the current consent and the owner's contact address.
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final tier = ref.watch(consentControllerProvider);
    final email = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady(:final data) => data.contact.email,
      ContentFallback(:final profile) => profile.contact.email,
      _ => null,
    };
    final measure = BoxConstraints(maxWidth: type.measureFor(type.body));

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
          Text(l10n.navPrivacy, style: type.displayM),
          SizedBox(height: tokens.space24),
          ConstrainedBox(
            constraints: measure,
            child: Text(l10n.privacyBody, style: type.body),
          ),
          SizedBox(height: tokens.space24),
          Text(
            consentSummary(context, tier),
            style: type.telemetry.copyWith(color: tokens.instrument),
          ),
          SizedBox(height: tokens.space24),
          const ConsentControls(),
          SizedBox(height: tokens.space32),
          ConstrainedBox(
            constraints: measure,
            child: Text(
              l10n.privacyRetention,
              style: type.bodyS.copyWith(color: tokens.textSecondary),
            ),
          ),
          if (email != null) ...[
            SizedBox(height: tokens.space12),
            ConstrainedBox(
              constraints: measure,
              child: Text(
                l10n.privacyContact(email),
                style: type.bodyS.copyWith(color: tokens.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
