import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/features/station/presentation/widgets/cv_button.dart';
import 'package:nocturne/features/station/presentation/widgets/name_pronunciation.dart';
import 'package:nocturne/features/station/presentation/widgets/reach_row.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/features/station/presentation/widgets/papyrus_stat_panel.dart';
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

  /// How many of the figures are drawn on papyrus.
  ///
  /// Two: the years and the degree. Named rather than written as a bare 2 at
  /// the call site so the reason survives the next person to read it.
  static const int rollingStats = 2;

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
        // One line, and it contains the name. The first pass put a greeting
        // above the name and printed both, so the page said "Ahmed" twice
        // before it said anything else. The greeting is the heading now, and
        // the separate name line is gone.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: _AcquiredName(
            name: (profile.greeting ?? profile.shownName).resolve(locale),
            style: type.displayL,
            reveal: acquisitionReveal,
          ),
        ),
        SizedBox(height: tokens.space12),
        // The rule under the name is gone on the owner's instruction. The
        // pronunciation control sits directly under the name now, which is
        // also where it belongs: it is about the name, and the rule was
        // separating it from the thing it refers to.
        const NamePronunciation(),
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
        if (profile.reach.isNotEmpty) ...[
          SizedBox(height: tokens.space24),
          ReachRow(countries: profile.reach, locale: locale),
        ],
        if (profile.stats.isNotEmpty) ...[
          SizedBox(height: tokens.space32),
          // A grid rather than a wrap: on a phone these two 200px panels sat
          // in a 350px column with every spare pixel on the right, which is
          // the "cards are on the left" the owner reported. They share the
          // width now and a single column fills it.
          EvenGrid(
            minTileWidth: PapyrusStatPanel.width,
            spacing: tokens.space16,
            children: [
              // The first two figures are drawn on papyrus and roll up when
              // they are clicked, by the owner's instruction. Anything he adds
              // after them is an ordinary panel: the treatment is for these
              // two, not for every number on the site.
              for (final (index, stat) in profile.stats.indexed)
                if (index < HeroContent.rollingStats)
                  PapyrusStatPanel(stat: stat, locale: locale)
                else
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
            const CvButton(route: AppRoute.home),
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
