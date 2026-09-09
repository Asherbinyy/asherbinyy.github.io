import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/analytics/events.dart';
import 'package:nocturne/core/analytics/interactions.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/painting/coastline_data.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/secondary_surface.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_panel.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/signal/presentation/widgets/chronology_scrubber.dart';
import 'package:nocturne/features/signal/presentation/widgets/propagation_map.dart';
import 'package:nocturne/features/signal/presentation/widgets/transmission_panel.dart';

/// The propagation map: where the work happened.
class SignalScreen extends ConsumerStatefulWidget {
  /// Reads the career from the content layer.
  const SignalScreen({super.key});

  @override
  ConsumerState<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends ConsumerState<SignalScreen> {
  /// Selection is local to the screen and ephemeral, so it rides a notifier
  /// rather than a provider — the standards ban `setState`, and nothing outside
  /// this screen needs to know which station is open.
  final ValueNotifier<int> _selected = ValueNotifier(-1);

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  void _select(int index, List<CareerRole> roles, AppLocale locale) {
    _selected.value = index;
    ref.recordInteraction(
      AnalyticsEvent.mapNodeOpened,
      route: AppRoute.journey.path,
      inputMode: context.platform.inputMode,
    );
    // Section 7 decides the surface once: a side panel on pointer, a bottom
    // sheet on touch. This screen never asks which it is on.
    if (context.platform.isTouch) {
      unawaited(
        context.presentSecondary<void>(
          child: TransmissionPanel(role: roles[index], locale: locale),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final career = ref.watch(careerProvider);
    final coastlines = ref.watch(coastlineRingsProvider);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: context.tokens.space48,
        bottom: context.tokens.space64,
      ),
      child: switch ((career, coastlines)) {
        (
          AsyncData(value: ContentReady(:final data)),
          AsyncData(:final value),
        ) =>
          _Map(
            roles: data.roles,
            coastlines: value,
            locale: locale,
            selected: _selected,
            onSelected: (index) => _select(index, data.roles, locale),
          ),
        (AsyncData() || AsyncError(), _) ||
        (_, AsyncError()) => const _Unavailable(),
        _ => const _Loading(),
      },
    );
  }
}

/// The map, the scrubber, and the panel beside them on a pointer browser.
class _Map extends StatelessWidget {
  const _Map({
    required this.roles,
    required this.coastlines,
    required this.locale,
    required this.selected,
    required this.onSelected,
  });

  final List<CareerRole> roles;
  final List<CoastlineRing> coastlines;
  final AppLocale locale;
  final ValueNotifier<int> selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final stations = [
      for (final role in roles)
        (
          id: role.id,
          latitude: role.coords.first,
          longitude: role.coords.length > 1 ? role.coords[1] : 0.0,
          // Evri sits on the map as a smaller node with no arc weight: present
          // and factual, not featured.
          isMinor: role.traceWeight == null && role.appIds.isEmpty,
        ),
    ];
    final isWide =
        context.platform.viewport.index >= ViewportClass.expanded.index;

    return ValueListenableBuilder<int>(
      valueListenable: selected,
      builder: (context, index, _) {
        final map = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PropagationMap(
              stations: stations,
              selectedIndex: index,
              labels: {
                for (final role in roles)
                  role.id: l10n.signalStationLabel(role.city, role.country),
              },
              coastlines: coastlines,
              onSelected: onSelected,
            ),
            SizedBox(height: tokens.space24),
            ChronologyScrubber(
              marks: [for (final role in roles) role.start.split('-').first],
              // The company where the content records one, the city where it
              // does not -- the same rule the transmission panel heads with,
              // so the scrubber names a stop the way the panel does.
              places: [for (final role in roles) role.company ?? role.city],
              selectedIndex: index,
              onSelected: onSelected,
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.signalHeading, style: context.type.displayM),
            SizedBox(height: tokens.space32),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: map),
                  SizedBox(width: tokens.space32),
                  Expanded(
                    child: index < 0
                        ? const SizedBox.shrink()
                        : TransmissionPanel(role: roles[index], locale: locale),
                  ),
                ],
              )
            else
              map,
          ],
        );
      },
    );
  }
}

/// Skeleton geometry matching the map, so nothing shifts when it arrives.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SweepScope(
    child: LayoutBuilder(
      builder: (context, constraints) => SkeletonPanel(
        width: constraints.maxWidth,
        height: constraints.maxWidth / context.tokens.mapAspectRatio,
      ),
    ),
  );
}

/// The career could not be read, so there are no stations to plot.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) =>
      CarrierEmptyState(direction: context.l10n.heroContentUnavailable);
}
