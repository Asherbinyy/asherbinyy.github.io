import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/features/station/presentation/widgets/cv_button.dart';
import 'package:nocturne/features/station/presentation/widgets/name_pronunciation.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/features/station/presentation/widgets/stat_panel.dart';

/// The settled hero.
///
/// Everything is left-aligned to the rail; the screen spec is explicit that
/// nothing here is centred, because centred text belongs to marketing pages and
/// an instrument panel aligns to a rail. It also names four things not to add —
/// a gradient mesh, floating particles, a job-title typewriter loop and a
/// scroll-down chevron — and none of them are here.
class HeroContent extends StatelessWidget {
  /// [profile] is already resolved, so this widget never awaits.
  const HeroContent({
    required this.profile,
    required this.locale,
    this.acquisitionReveal,
    super.key,
  });

  /// Identity and positioning.
  final Profile profile;

  /// Active content channel.
  final AppLocale locale;

  /// First-load beat-three progress; absent in the settled route.
  final Animation<double>? acquisitionReveal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AcquiredName(
          name: profile.shownName.resolve(locale),
          style: type.displayXl,
          reveal: acquisitionReveal,
        ),
        SizedBox(height: tokens.space16),
        // Wrapped rather than a row: at 360px the mark and the control are
        // 18px wider than the column, and a Row simply overflows. On a phone
        // the control drops to its own line instead.
        Wrap(
          spacing: tokens.space16,
          runSpacing: tokens.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Short on purpose: a full-width rule reads as a divider, a 120px
            // one reads as a mark.
            SizedBox(
              width: tokens.heroRuleWidth,
              height: tokens.heroRuleHeight,
              child: ColoredBox(color: tokens.beacon),
            ),
            // Beside the mark rather than beside the name: the name is set in
            // the largest type on the site and anything level with it competes
            // with it.
            const NamePronunciation(),
          ],
        ),
        SizedBox(height: tokens.space24),
        ConstrainedBox(
          // Section 3 caps the measure and says to enforce it with a
          // max-width rather than guesswork.
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: Text(
            profile.positioning.resolve(locale),
            style: type.displayM.copyWith(color: tokens.textSecondary),
          ),
        ),
        if (profile.stats.isNotEmpty) ...[
          SizedBox(height: tokens.space32),
          Wrap(
            spacing: tokens.space16,
            runSpacing: tokens.space16,
            children: [
              for (final stat in profile.stats)
                StatPanel(stat: stat, locale: locale),
            ],
          ),
        ],
        SizedBox(height: tokens.space32),
        Wrap(
          spacing: tokens.space16,
          runSpacing: tokens.space16,
          children: [
            BeaconButton(
              label: l10n.heroSeeTheWork,
              emphasis: ButtonEmphasis.primary,
              onPressed: () => context.goNamed(AppRoute.work.name),
            ),
            const CvButton(route: AppRoute.station),
          ],
        ),
      ],
    );
  }
}

/// Types the name by revealing its laid-out glyph run without changing size.
class _AcquiredName extends StatelessWidget {
  const _AcquiredName({
    required this.name,
    required this.style,
    required this.reveal,
  });

  final String name;
  final TextStyle style;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    final animation = reveal;
    if (animation == null) return Text(name, style: style);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => animation.isCompleted
          ? child ?? const SizedBox.shrink()
          : ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: animation.value,
                child: child,
              ),
            ),
      child: Text(name, style: style),
    );
  }
}
