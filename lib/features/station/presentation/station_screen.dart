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
import 'package:nocturne/features/station/presentation/widgets/hero_content.dart';
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
              // The forward-looking half. Everything above this is what has
              // already happened; this is the one line on Home that answers
              // "can you build me one?".
              const _ServicesDoor(),
              // The way to reach him, at the foot of the page he lands on. A
              // visitor who has read to the bottom of Home should not have to
              // find About to send an email.
              const _Reach(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The door to the services page.
class _ServicesDoor extends StatelessWidget {
  const _ServicesDoor();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: context.platform.sectionGap),
      // Wrapped, because on a phone the question and the button do not share
      // a line and a Row would push one of them off the screen.
      child: Wrap(
        spacing: tokens.space16,
        runSpacing: tokens.space16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.l10n.homeServices,
            style: context.type.heading.copyWith(color: tokens.textSecondary),
          ),
          BeaconButton(
            label: context.l10n.homeServicesAction,
            emphasis: ButtonEmphasis.primary,
            onPressed: () => context.goNamed(AppRoute.services.name),
          ),
        ],
      ),
    );
  }
}

/// Contact, at the end of Home.
class _Reach extends ConsumerWidget {
  const _Reach();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = switch (ref.watch(profileProvider).valueOrNull) {
      ContentReady<Profile>(:final data) => data.contact,
      ContentFallback<Profile>(:final profile) => profile.contact,
      _ => null,
    };
    if (contact == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: context.platform.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.aboutContact, style: context.type.heading),
          SizedBox(height: context.tokens.space24),
          // Capped to the same measure the copy uses. Left to run the frame's
          // full width the row reached under the wall, which is the rule the
          // rest of this page already keeps.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.type.measureFor(context.type.body),
            ),
            child: ContactLinks(contact: contact),
          ),
        ],
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
  Widget build(BuildContext context) => switch (result) {
    // A fallback still carries the owner's real name, positioning and contact,
    // so it renders as the hero rather than as an error.
    ContentReady(:final data) => HeroContent(
      profile: data,
      locale: locale,
      acquisitionReveal: acquisitionReveal,
    ),
    ContentFallback(:final profile) => HeroContent(
      profile: profile,
      locale: locale,
      acquisitionReveal: acquisitionReveal,
    ),
    ContentUnavailable() => const _Unavailable(),
  };
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
