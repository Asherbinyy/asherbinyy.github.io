import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
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
import 'package:nocturne/features/station/presentation/widgets/app_being_built.dart';
import 'package:nocturne/features/services/presentation/services_screen.dart';
import 'package:nocturne/features/station/presentation/widgets/career_sequence.dart';
import 'package:nocturne/features/station/presentation/widgets/career_stops.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/skill_groups.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_content.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_scene.dart';
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

    // The wall is the faint pattern behind the whole page at every size. On
    // a phone it used to keep a strip of the trailing edge, and the page
    // stopped short of it -- a quarter of a 390px screen, so everything sat
    // against the left. The owner asked for the phone to be centred.
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsetsDirectional.only(
          start: context.platform.gutter,
          end: context.platform.gutter,
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
/// One panel the width of everything above it, laid out like the "Wanna
/// chat?" panel on Services so the two pages close the same way. The owner
/// found its left half empty and its words machine-made, so the ask now says
/// plainly what to send and what comes back, lists what he builds, and -- on
/// a screen wide enough -- stands beside a phone whose app is put together in
/// front of the reader, which is the offer drawn rather than described.
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
    final services = profile?.services ?? const <String>[];

    final ask = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.homeServices, style: type.heading),
        SizedBox(height: tokens.space12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
          child: Text(
            l10n.homeServicesBody,
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        ),
        if (services.isNotEmpty) ...[
          SizedBox(height: tokens.space24),
          Text(
            l10n.homeServicesList,
            style: type.meta.copyWith(color: tokens.textMuted),
          ),
          SizedBox(height: tokens.space12),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            children: [
              for (final service in services) _ServiceTag(name: service),
            ],
          ),
        ],
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
              final hasRoom =
                  constraints.maxWidth >= Tokens.closingIllustrationFrom;
              // Centred against the contact column, which is the taller: at
              // the top, the ask left an empty band under it the owner
              // pointed at.
              return Row(
                children: [
                  if (hasRoom) ...[
                    const AppBeingBuilt(),
                    SizedBox(width: tokens.space32),
                  ],
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

/// One of the services, named with the mark the Services page gives it.
///
/// A label, not a link: eight tab stops that all go to the same page would be
/// a chore for anyone moving through by keyboard, and the button under them
/// already goes there.
class _ServiceTag extends StatelessWidget {
  const _ServiceTag({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space12,
          vertical: tokens.space8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              serviceIcon(name),
              size: Tokens.serviceTagIconSize,
              color: tokens.beaconDim,
            ),
            SizedBox(width: tokens.space8),
            Flexible(
              child: Text(
                name,
                style: context.type.bodyS.copyWith(color: tokens.textPrimary),
              ),
            ),
          ],
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
    // The apps, so each stop can show what was built there. A stop whose apps
    // have not loaded yet simply shows none; nothing waits on them.
    final apps = switch (ref.watch(appsProvider).valueOrNull) {
      ContentReady(:final data) => {for (final app in data.apps) app.id: app},
      _ => const <String, ShippedApp>{},
    };
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
          // On a phone the stops run down beside the cards instead.
          if (context.platform.viewport != ViewportClass.compact) ...[
            CareerStops(roles: ordered, anchorRegistry: anchorRegistry),
            SizedBox(height: context.tokens.space48),
          ],
          CareerSequence(
            roles: ordered,
            locale: locale,
            anchorRegistry: anchorRegistry,
            apps: apps,
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
          child: SkillGroups(profile: profile, locale: locale),
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
