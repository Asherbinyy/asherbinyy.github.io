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
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/core/platform/static_route.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/station/presentation/widgets/career_sequence.dart';
import 'package:nocturne/features/station/presentation/widgets/hero_content.dart';

/// The ground station: the acquisition sequence, then the settled hero.
class StationScreen extends ConsumerWidget {
  /// Reads identity from the content layer, falling back to the bundled
  /// minimum rather than showing an error for a recoverable failure.
  const StationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final profile = ref.watch(profileProvider);

    return Padding(
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
              ),
              AsyncError() => const _Unavailable(),
              _ => const _Loading(),
            },
            _Career(locale: locale),
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

    return Padding(
      padding: EdgeInsets.only(top: context.tokens.space96),
      child: CareerSequence(roles: roles, locale: locale),
    );
  }
}

/// Content arrived, whether as the real profile or the bundled fallback.
class _Resolved extends StatelessWidget {
  const _Resolved({required this.result, required this.locale});

  final ContentResult<Profile> result;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) => switch (result) {
    // A fallback still carries the owner's real name, positioning and contact,
    // so it renders as the hero rather than as an error.
    ContentReady(:final data) => HeroContent(profile: data, locale: locale),
    ContentFallback(:final profile) => HeroContent(
      profile: profile,
      locale: locale,
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
      BeaconButton(
        label: context.l10n.heroReadTheCv,
        onPressed: () => openStaticRoute(AppRoute.cv.path),
      ),
    ],
  );
}
