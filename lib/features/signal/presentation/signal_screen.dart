import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
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
      target: 'journey:${roles[index].id}',
    );
    // Inline details need a wide pointer layout. Other layouts use the
    // platform's secondary surface so a narrow desktop never loses details.
    if (context.platform.isTouch ||
        context.platform.viewport.index < ViewportClass.expanded.index) {
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
    final compact = context.platform.viewport == ViewportClass.compact;
    final topPadding = compact
        ? context.tokens.space24
        : context.tokens.space48;
    final bottomPadding = compact
        ? context.tokens.space24
        : context.tokens.space64;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: topPadding,
        bottom: bottomPadding,
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
            verticalPadding: topPadding + bottomPadding,
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
    required this.verticalPadding,
  });

  final List<CareerRole> roles;
  final List<CoastlineRing> coastlines;
  final AppLocale locale;
  final ValueNotifier<int> selected;
  final ValueChanged<int> onSelected;
  final double verticalPadding;

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
        context.platform.isPointer &&
        context.platform.viewport.index >= ViewportClass.expanded.index;

    return ValueListenableBuilder<int>(
      valueListenable: selected,
      builder: (context, index, _) {
        final map = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Center(
                heightFactor: 1,
                child: PropagationMap(
                  stations: stations,
                  selectedIndex: index,
                  labels: {
                    for (final role in roles)
                      role.id: l10n.signalStationLabel(role.city, role.country),
                  },
                  coastlines: coastlines,
                  onSelected: onSelected,
                ),
              ),
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

        // Reserve chrome and page padding before allocating the map. The
        // heading and timeline take their natural heights; only the map flexes.
        // Short windows and enlarged text retain a scrollable minimum.
        final visibleHeight = ContentViewport.heightOf(context);
        final minimumHeight = MediaQuery.textScalerOf(context)
            .scale(Tokens.journeyMinContentHeight);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: visibleHeight == null
                ? double.infinity
                : (visibleHeight - verticalPadding).clamp(
                    minimumHeight,
                    double.infinity,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.signalHeading, style: context.type.displayM),
              SizedBox(height: tokens.space32),
              Flexible(
                child: isWide
                    // Selection shares the bounded row with a detail panel.
                    ? _MapAndPanel(
                        map: map,
                        panel: index < 0
                            ? null
                            : TransmissionPanel(
                                role: roles[index],
                                locale: locale,
                                onClose: () => selected.value = -1,
                              ),
                      )
                    : map,
              ),
            ],
          ),
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

/// The map, and the panel that takes room from it once a stop is chosen.
///
/// Widths rather than flex factors, because flex is an integer and this has to
/// move: the panel opens from nothing to a third of the row, and the map gives
/// up exactly that much. Under reduced motion the change is instant.
class _MapAndPanel extends StatelessWidget {
  const _MapAndPanel({required this.map, required this.panel});

  final Widget map;
  final Widget? panel;

  /// How much of the row the panel takes when it is open.
  static const double _panelFraction = 0.34;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final gap = tokens.space32;

    return LayoutBuilder(
      builder: (context, constraints) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: panel == null ? 0 : 1),
        duration: ReducedMotion.duration(context, Tokens.standard),
        curve: Tokens.emphasized,
        builder: (context, open, _) {
          final panelWidth = constraints.maxWidth * _panelFraction * open;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth - panelWidth - gap * open,
                child: map,
              ),
              SizedBox(width: gap * open),
              // Clipped while it opens, so the panel slides out from behind
              // the map's edge rather than reflowing its own text on every
              // frame of the animation.
              //
              // `Align`'s width factor rather than an `OverflowBox`: the page
              // is inside a scroll view, so an overflow box has no bounded
              // height to work with and asserts. A width factor scales the
              // slot to a fraction of the child and leaves height alone.
              ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: open,
                  child: SizedBox(
                    width: constraints.maxWidth * _panelFraction,
                    child: SingleChildScrollView(
                      child: panel ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
