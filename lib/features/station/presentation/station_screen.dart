import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/models/profile.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/features/station/presentation/widgets/cq_response.dart';
import 'package:nocturne/features/station/presentation/widgets/cv_button.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/about/presentation/widgets/contact_links.dart';
import 'package:nocturne/features/station/presentation/widgets/career_sequence.dart';
import 'package:nocturne/features/station/presentation/widgets/career_stops.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/profile_skills.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_content.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_scene.dart';
import 'package:nocturne/features/trace/presentation/telemetry_trace.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';

/// The ground station: the acquisition sequence, then the settled hero.
class StationScreen extends ConsumerWidget {
  /// Reads identity from the content layer, falling back to the bundled
  /// minimum rather than showing an error for a recoverable failure.
  const StationScreen({this.acquisitionReveal, super.key});

  /// Beat-three progress used only to reveal the name on first acquisition.
  final Animation<double>? acquisitionReveal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final profile = ref.watch(profileProvider);

    // The wall runs down the trailing edge behind this page. On a desk the
    // copy is measure-limited and clears it on its own; on a phone it fills
    // the width, so it has to be told to stop where the wall starts.
    final isCompact = context.platform.viewport == ViewportClass.compact;

    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsetsDirectional.only(
          start: context.platform.gutter,
          end: isCompact
              ? TelemetryTrace.compactFootprint(constraints.maxWidth) +
                    context.tokens.space12
              : context.platform.gutter,
          top: context.tokens.space64,
          bottom: context.tokens.space64,
        ),
        child: Align(
          // Left-aligned to the rail. The screen spec is explicit that nothing
          // in the hero is centred.
          alignment: AlignmentDirectional.topStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              switch (profile) {
                AsyncData(:final value) => _Resolved(
                  result: value,
                  locale: locale,
                  acquisitionReveal: acquisitionReveal,
                ),
                AsyncError() => const _Unavailable(),
                _ => const _Loading(),
              },
              // Roadmap 3.4's one easter egg. Silent and invisible until a
              // viewer types CQ; its height is reserved either way so an answer
              // never reflows the page.
              const CqResponse(),
              _Career(locale: locale),
              // The forward-looking half and the way to reach him, together:
              // everything above this is what has already happened, and this
              // is the one place on Home that answers "can you build me one?"
              // and says how to ask.
              const _Closing(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The end of Home: the ask, and the ways of reaching him.
///
/// It was a line with a button and then a heading over a list, each its own
/// width -- the question as wide as its words, the links capped to the copy's
/// measure -- so the page ended on three different edges. One panel the width
/// of everything above it, laid out like the "Wanna chat?" panel on Services
/// so the two pages close the same way.
class _Closing extends ConsumerWidget {
  const _Closing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final profile = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady<Profile>(:final data) => data,
      ContentFallback<Profile>(:final profile) => profile,
      _ => null,
    };

    final ask = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.homeServices, style: type.heading),
        SizedBox(height: tokens.space12),
        // The Services page's own sentence, not a new one: it says what to
        // send and what comes back, which is what this half of the panel is
        // for, and it balances the column of ways to reach him beside it.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: Text(
            l10n.servicesChatBody,
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        ),
        SizedBox(height: tokens.space24),
        BeaconButton(
          label: l10n.homeServicesAction,
          emphasis: ButtonEmphasis.primary,
          onPressed: () => context.goNamed(AppRoute.services.name),
        ),
      ],
    );

    final reach = profile == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.aboutContact, style: type.heading),
              SizedBox(height: tokens.space16),
              ContactLinks(contact: profile.contact, links: profile.links),
            ],
          );

    return Padding(
      padding: EdgeInsets.only(top: context.platform.sectionGap),
      child: SizedBox(
        width: double.infinity,
        child: InstrumentPanel(
          fill: tokens.surface,
          // A phone's column is already narrow beside the wall's strip; the
          // desk inset would leave the contact links no room at all.
          padding: EdgeInsets.all(
            context.platform.viewport == ViewportClass.compact
                ? tokens.space16
                : tokens.space32,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Side by side where each half still has room for a sentence;
              // stacked below that, which is how a phone always had it.
              if (reach == null) return ask;
              if (constraints.maxWidth < Tokens.mediumBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ask,
                    SizedBox(height: tokens.space32),
                    reach,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ask),
                  SizedBox(width: tokens.space48),
                  Expanded(child: reach),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The career sequence, which is what the telemetry trace travels over.
class _Career extends ConsumerWidget {
  const _Career({required this.locale});

  final AppLocale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = switch (ref.watch(careerProvider).valueOrNull) {
      ContentReady(:final data) => data.roles,
      _ => const <CareerRole>[],
    };
    if (roles.isEmpty) return const SizedBox.shrink();

    final anchorRegistry = ref.watch(traceAnchorRegistryProvider);
    // Most recent first, computed once and handed to both: the index and the
    // sequence have to agree about the order or clicking the third stop lands
    // on the fourth entry.
    final ordered = [...roles]..sort((a, b) => b.start.compareTo(a.start));

    return Padding(
      padding: EdgeInsets.only(top: context.platform.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CareerStops(roles: ordered, anchorRegistry: anchorRegistry),
          SizedBox(height: context.tokens.space48),
          CareerSequence(
            roles: ordered,
            locale: locale,
            anchorRegistry: anchorRegistry,
          ),
        ],
      ),
    );
  }
}

/// Content arrived, whether as the real profile or the bundled fallback.
class _Resolved extends StatelessWidget {
  const _Resolved({
    required this.result,
    required this.locale,
    required this.acquisitionReveal,
  });

  final ContentResult<Profile> result;
  final AppLocale locale;
  final Animation<double>? acquisitionReveal;

  @override
  Widget build(BuildContext context) {
    // A fallback still carries the owner's real name, positioning and contact,
    // so it renders as the hero rather than as an error.
    final profile = switch (result) {
      ContentReady(:final data) => data,
      ContentFallback(:final profile) => profile,
      ContentUnavailable() => null,
    };
    if (profile == null) return const _Unavailable();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Hero(
          copy: HeroContent(
            profile: profile,
            locale: locale,
            acquisitionReveal: acquisitionReveal,
          ),
        ),
        SizedBox(height: context.tokens.space32),
        // The whole width, like every section below it. It used to sit at the
        // foot of the hero, capped to the copy's measure, which made it the
        // first of several edges on this page that did not line up.
        SizedBox(
          width: double.infinity,
          child: ProfileSkills(profile: profile),
        ),
      ],
    );
  }
}

/// The hero's copy, and the picture beside it where there is room.
///
/// The owner asked for the right of the hero to stop being the wall and to
/// hold a picture that stands for him instead; the wall became the pattern
/// behind the whole page. On anything narrower than [Tokens.heroSceneMinWidth]
/// the copy needs the width more than the picture needs the space, so a phone
/// keeps the hero it had.
class _Hero extends StatelessWidget {
  const _Hero({required this.copy});

  final Widget copy;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < Tokens.heroSceneMinWidth) return copy;
      return Row(
        children: [
          Expanded(flex: Tokens.heroCopyFlex, child: copy),
          SizedBox(width: context.tokens.space48),
          const Expanded(flex: Tokens.heroSceneFlex, child: HeroScene()),
        ],
      );
    },
  );
}

/// Skeleton geometry matching the settled hero, so nothing shifts on arrival.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    return SweepScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonText(lines: 1, style: type.displayXl),
          SizedBox(height: tokens.space16),
          SizedBox(
            width: tokens.heroRuleWidth,
            height: tokens.heroRuleHeight,
            child: ColoredBox(color: tokens.hairline),
          ),
          SizedBox(height: tokens.space24),
          SkeletonText(lines: 2, style: type.displayM),
        ],
      ),
    );
  }
}

/// Both the content and its bundled fallback failed to parse.
///
/// Section 11: errors state what happened and what to do, and they do not
/// apologise. The carrier at rest carries the state, the line says what to do,
/// and the CV route still works without any of this.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      CarrierEmptyState(direction: context.l10n.heroContentUnavailable),
      SizedBox(height: context.tokens.space24),
      const CvButton(route: AppRoute.home),
    ],
  );
}
