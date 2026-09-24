import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/app_maker.dart';
import 'package:nocturne/content/asset_content.dart';
import 'package:nocturne/content/content_media.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/content/work_domain_label.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/even_grid.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/core/widgets/loading/station_card.dart';
import 'package:nocturne/features/work/presentation/widgets/app_shots.dart';
import 'package:nocturne/features/work/presentation/widgets/store_links.dart';
import 'package:nocturne/features/work/presentation/widgets/work_card.dart';

/// What `/work/<id>` shows for an application with no written study.
///
/// The route used to answer every unwritten slug with "not written yet", which
/// is honest and useless: the site knows the name, the role, the metric, the
/// sector and the store links for all fourteen applications, and was refusing
/// to show any of it because a long-form case study did not exist.
///
/// A study, where one is ever written, still wins. This is the floor, not a
/// replacement -- but the owner asked for these pages to be fun, so the floor
/// is built like a page: the name and what he did beside the app's own screens
/// fanned open, the facts on cards of their own, the screens in a strip, and
/// the other apps built at the same place as a way on. It arrives in order,
/// each part rising a beat after the last, and under reduced motion it is
/// simply there.
class AppDetail extends ConsumerStatefulWidget {
  /// Renders [app] as a page.
  const AppDetail({required this.app, required this.locale, super.key});

  /// The application to describe.
  final ShippedApp app;

  /// Active content channel.
  final AppLocale locale;

  @override
  ConsumerState<AppDetail> createState() => _AppDetailState();
}

class _AppDetailState extends ConsumerState<AppDetail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: Tokens.appPageArrive,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ReducedMotion.of(context)) {
      _arrive.value = 1;
    } else if (_arrive.value == 0 && !_arrive.isAnimating) {
      _arrive.forward();
    }
  }

  @override
  void didUpdateWidget(AppDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another app's page, reached from "more from": it arrives again.
    if (oldWidget.app.id != widget.app.id && !ReducedMotion.of(context)) {
      _arrive.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final role = app.role?.resolve(widget.locale);
    final career = switch (ref.watch(careerProvider).valueOrNull) {
      ContentReady(:final data) => data,
      _ => const Career(roles: []),
    };
    final everyApp = switch (ref.watch(appsProvider).valueOrNull) {
      ContentReady(:final data) => data.apps,
      _ => const <ShippedApp>[],
    };
    final maker = AppMakers.resolve(app: app, career: career);
    // The other apps from the same place, in the ledger's order.
    String? madeAt(ShippedApp other) =>
        switch (AppMakers.resolve(app: other, career: career)) {
          MadeAt(:final name) => name,
          _ => null,
        };
    final siblings = switch (maker) {
      MadeAt(:final name) => [
        for (final other in everyApp)
          if (other.id != app.id && madeAt(other) == name) other,
      ],
      _ => const <ShippedApp>[],
    };
    final isWide =
        context.platform.viewport.index >= ViewportClass.expanded.index;

    Widget staged(int step, Widget child) =>
        _Staged(animation: _arrive, step: step, child: child);

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        staged(0, _BackLink(label: l10n.caseStudyBackToWork)),
        SizedBox(height: tokens.space24),
        staged(0, Text(app.name, style: type.displayM)),
        SizedBox(height: tokens.space8),
        staged(
          1,
          Wrap(
            spacing: tokens.space16,
            runSpacing: tokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (maker != null)
                MakerLine(
                  maker: maker,
                  style: type.body.copyWith(color: tokens.textSecondary),
                ),
              Text(
                app.domain.label(l10n),
                style: type.telemetry.copyWith(color: tokens.beacon),
              ),
            ],
          ),
        ),
        if (role != null) ...[
          SizedBox(height: tokens.space24),
          staged(
            2,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
              child: Text(role, style: type.bodyL),
            ),
          ),
        ],
        if (app.metric case final String metric) ...[
          SizedBox(height: tokens.space24),
          staged(3, _Headline(metric: metric)),
        ],
        if (app.store.isNotEmpty) ...[
          SizedBox(height: tokens.space32),
          staged(4, StoreLinks(app: app)),
        ],
      ],
    );

    // The screens, fanned open as the page arrives, or the seeded drawing
    // for an app with none to show.
    final art = staged(
      1,
      app.shots.isEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.cardRadius),
              child: StationCard(
                seedId: app.id,
                name: '',
                width: double.infinity,
                height: Tokens.appPageArtHeight,
              ),
            )
          : _OpeningFan(app: app, animation: _arrive),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: Tokens.appPageTextFlex, child: heading),
              SizedBox(width: tokens.space48),
              Expanded(flex: Tokens.appPageArtFlex, child: art),
            ],
          )
        else ...[
          heading,
          SizedBox(height: tokens.space32),
          art,
        ],
        SizedBox(height: tokens.space48),
        staged(
          5,
          _Facts(app: app, maker: maker, domain: app.domain.label(l10n)),
        ),
        if (app.shots.isNotEmpty) ...[
          SizedBox(height: tokens.space48),
          staged(6, _SectionTitle(text: l10n.workScreens)),
          SizedBox(height: tokens.space16),
          staged(6, AppShots(paths: app.shots, appName: app.name)),
        ],
        if (siblings.isNotEmpty && maker is MadeAt) ...[
          SizedBox(height: tokens.space48),
          staged(
            7,
            _SectionTitle(
              text: l10n.workMoreFrom(
                maker.isFreelance ? l10n.careerFreelance : maker.name,
              ),
            ),
          ),
          SizedBox(height: tokens.space16),
          staged(7, _Siblings(apps: siblings)),
        ],
        SizedBox(height: tokens.space48),
        BeaconButton(
          label: l10n.caseStudyBackToWork,
          onPressed: () => context.goNamed(AppRoute.work.name),
        ),
      ],
    );
  }
}

/// A part of the page that rises in on its [step] of [animation].
class _Staged extends StatelessWidget {
  const _Staged({
    required this.animation,
    required this.step,
    required this.child,
  });

  final Animation<double> animation;
  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (step * Tokens.appPageStep).clamp(0.0, 0.9);
    final curve = Interval(
      start,
      (start + Tokens.appPageRise).clamp(0.0, 1.0),
      curve: MotionCurves.emphasized,
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = curve.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * Tokens.revealRiseLift),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// "Back to the work", small, above the name: the way back is the first
/// thing on the page as well as the last.
class _BackLink extends StatefulWidget {
  const _BackLink({required this.label});

  final String label;

  @override
  State<_BackLink> createState() => _BackLinkState();
}

class _BackLinkState extends State<_BackLink> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      link: true,
      label: widget.label,
      excludeSemantics: true,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
          final colour = isLit ? tokens.beaconGlow : tokens.beacon;
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => context.goNamed(AppRoute.work.name),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSlide(
                      offset: isLit
                          ? Offset(isRtl ? 0.25 : -0.25, 0)
                          : Offset.zero,
                      duration: ReducedMotion.duration(context, Motion.quick),
                      curve: MotionCurves.emphasized,
                      child: Icon(
                        isRtl
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        size: Tokens.contactIconSize,
                        color: colour,
                      ),
                    ),
                    SizedBox(width: tokens.space8),
                    Text(
                      widget.label,
                      style: context.type.bodyS.copyWith(color: colour),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The metric, set large: the strongest single fact the page has.
class _Headline extends StatelessWidget {
  const _Headline({required this.metric});

  final String metric;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tokens.hairlineWidth * 3,
          height: Tokens.appPageHeadlineRule,
          child: ColoredBox(color: tokens.beacon),
        ),
        SizedBox(width: tokens.space16),
        Flexible(
          child: Text(
            metric,
            style: context.type.heading.copyWith(color: tokens.instrument),
          ),
        ),
      ],
    );
  }
}

/// The app's screens, fanned open as the page arrives, and opening further
/// under the pointer.
class _OpeningFan extends StatefulWidget {
  const _OpeningFan({required this.app, required this.animation});

  final ShippedApp app;
  final Animation<double> animation;

  @override
  State<_OpeningFan> createState() => _OpeningFanState();
}

class _OpeningFanState extends State<_OpeningFan> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final opened = const Interval(
          0.2,
          0.8,
          curve: MotionCurves.emphasized,
        ).transform(widget.animation.value);
        return ShotFan(
          app: widget.app,
          height: Tokens.appPageArtHeight,
          spread: _isHovered ? 1 : opened * Tokens.appPageFanRest,
        );
      },
    ),
  );
}

/// A heading for a part of the page, with the site's rule beside it.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        SizedBox(
          width: tokens.space24,
          height: tokens.hairlineWidth * 2,
          child: ColoredBox(color: tokens.beacon),
        ),
        SizedBox(width: tokens.space12),
        Flexible(child: Text(text, style: context.type.heading)),
      ],
    );
  }
}

/// The facts about the app, each on a card of its own.
class _Facts extends StatelessWidget {
  const _Facts({required this.app, required this.maker, required this.domain});

  final ShippedApp app;
  final AppMaker? maker;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final l10n = context.l10n;
    final maker = this.maker;
    final value = type.body.copyWith(color: tokens.textPrimary);
    final platforms = [
      for (final platform in app.platforms)
        switch (platform) {
          AppPlatform.ios => l10n.workAppStore,
          AppPlatform.android => l10n.workGooglePlay,
          AppPlatform.pub => l10n.workPubDev,
        },
    ];
    return EvenGrid(
      minTileWidth: Tokens.appFactWidth,
      spacing: tokens.space16,
      stretch: true,
      children: [
        if (maker != null)
          _Fact(
            icon: Icons.apartment_rounded,
            label: l10n.workFactMaker,
            child: MakerLine(maker: maker, style: value),
          ),
        if (platforms.isNotEmpty)
          _Fact(
            icon: Icons.install_mobile_rounded,
            label: l10n.workFactPlatforms,
            child: Text(platforms.join('\n'), style: value),
          ),
        _Fact(
          icon: Icons.category_outlined,
          label: l10n.workFactField,
          child: Text(domain, style: value),
        ),
      ],
    );
  }
}

/// One fact: its mark in a ring, what it is, and the fact itself.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Tokens.appFactMark,
              height: Tokens.appFactMark,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.beaconDim,
                  width: tokens.hairlineWidth,
                ),
              ),
              child: Icon(
                icon,
                size: Tokens.appFactMark * 0.5,
                color: tokens.beacon,
              ),
            ),
            SizedBox(width: tokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.type.meta.copyWith(color: tokens.textMuted),
                  ),
                  SizedBox(height: tokens.space4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The other apps from the same place, each a way to its own page.
class _Siblings extends StatelessWidget {
  const _Siblings({required this.apps});

  final List<ShippedApp> apps;

  @override
  Widget build(BuildContext context) => EvenGrid(
    minTileWidth: Tokens.appSiblingWidth,
    spacing: context.tokens.space16,
    stretch: true,
    balance: false,
    children: [for (final app in apps) _Sibling(app: app)],
  );
}

class _Sibling extends StatefulWidget {
  const _Sibling({required this.app});

  final ShippedApp app;

  @override
  State<_Sibling> createState() => _SiblingState();
}

class _SiblingState extends State<_Sibling> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final app = widget.app;
    final shot = app.shots.isEmpty ? null : app.shots.first;
    return Semantics(
      link: true,
      label: context.l10n.workOpenApp(app.name),
      excludeSemantics: true,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: () => context.goNamed(
                AppRoute.caseStudy.name,
                pathParameters: {'slug': app.id},
              ),
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: AnimatedContainer(
                duration: ReducedMotion.duration(context, Motion.quick),
                curve: MotionCurves.emphasized,
                padding: EdgeInsets.all(tokens.space12),
                decoration: BoxDecoration(
                  color: isLit ? tokens.surfaceRaised : tokens.surface,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: isLit ? tokens.beacon : tokens.hairline,
                    width: tokens.hairlineWidth,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedSlide(
                      offset: isLit
                          ? const Offset(0, -Tokens.appSiblingLift)
                          : Offset.zero,
                      duration: ReducedMotion.duration(context, Motion.quick),
                      curve: MotionCurves.emphasized,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          tokens.controlRadius,
                        ),
                        child: SizedBox(
                          width: Tokens.appSiblingThumb,
                          height:
                              Tokens.appSiblingThumb / Tokens.workShotAspect,
                          child: shot == null
                              // No screens to show: its initial, the way the
                              // career cards mark the same app.
                              ? ColoredBox(
                                  color: tokens.surfaceRaised,
                                  child: Center(
                                    child: Text(
                                      app.name.characters.first,
                                      style: context.type.heading.copyWith(
                                        color: tokens.beacon,
                                      ),
                                    ),
                                  ),
                                )
                              : Image(
                                  image: contentImage(context, shot),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.space12),
                    Expanded(
                      child: Text(
                        app.name,
                        style: context.type.body.copyWith(
                          color: isLit ? tokens.beacon : tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
