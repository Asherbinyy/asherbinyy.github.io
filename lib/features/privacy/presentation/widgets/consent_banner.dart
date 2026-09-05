import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/analytics/consent_controller.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/features/privacy/presentation/widgets/consent_controls.dart';

/// The consent prompt, shown on first visit until the viewer chooses.
///
/// A standard banner rather than a bespoke panel: somebody arriving at a
/// portfolio should meet the pattern they already know, and an unfamiliar
/// interface asking about data reads as stranger than a familiar one.
///
/// It does not block the page. Until a choice is made only Tier 0 runs, which
/// is the same as "essential only", so nothing is collected in the meantime
/// that a later refusal would have prevented.
class ConsentBanner extends ConsumerWidget {
  /// Sits above the footer, across the content column.
  const ConsentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(consentControllerProvider);
    if (tier.isResolved) return const SizedBox.shrink();

    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: tokens.hairlineStrong,
            width: tokens.hairlineWidth,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.platform.gutter,
          vertical: tokens.space16,
        ),
        child: Semantics(
          container: true,
          child: Wrap(
            spacing: tokens.space32,
            runSpacing: tokens.space16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.type.measureFor(context.type.bodyS),
                ),
                child: Text(
                  context.l10n.consentBannerBody,
                  style: context.type.bodyS,
                ),
              ),
              const ConsentControls(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades the banner away once a decision is made.
class AnimatedConsentBanner extends StatelessWidget {
  /// Wraps [ConsentBanner] in the site's standard transition.
  const AnimatedConsentBanner({super.key});

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: ReducedMotion.duration(context, Tokens.standard),
    curve: MotionCurves.emphasized,
    child: const ConsentBanner(),
  );
}
