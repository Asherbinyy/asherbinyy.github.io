import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/locale_controller.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/content_result.dart';
import 'package:nocturne/content/models/study.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/beacon_button.dart';
import 'package:nocturne/core/widgets/loading/carrier_empty_state.dart';
import 'package:nocturne/core/widgets/loading/skeleton_text.dart';
import 'package:nocturne/core/widgets/loading/sweep_scope.dart';
import 'package:nocturne/features/work/data/study_providers.dart';
import 'package:nocturne/features/work/presentation/widgets/device_frame.dart';
import 'package:nocturne/features/work/presentation/widgets/prototype_embed.dart';

/// `/work/:slug` — context, problem, approach, outcome, in that order.
///
/// The screen spec gives each section roughly one screen-height and pins the
/// device frame to the right column, scrubbing it as the left column scrolls.
///
/// **No study files exist yet.** `assets/content/studies/` is empty: the three
/// studies are the owner's to write and `09-ROADMAP.md` says outright that an
/// agent cannot invent them. So this screen is complete and tested against
/// fixtures, and in production it renders an honest "not written yet" rather
/// than placeholder prose about real client work — which would be a claim the
/// owner never made, on a page a recruiter reads as fact.
class CaseStudyScreen extends ConsumerWidget {
  /// [slug] comes from the route's path parameter.
  const CaseStudyScreen({required this.slug, super.key});

  /// The study's id, as it appears in the URL.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.platform.gutter,
        end: context.platform.gutter,
        top: tokens.space48,
        bottom: tokens.space64,
      ),
      child: switch (ref.watch(studyProvider(slug))) {
        AsyncData(value: ContentReady(data: final study)) => _Study(
          study: study,
          locale: ref.watch(localeControllerProvider),
        ),
        // A fallback result means the slug had no file and the repository
        // resolved the shared fallback instead, which is not a study.
        AsyncData() || AsyncError() => const _NotWritten(),
        _ => const _Loading(),
      },
    );
  }
}

class _Study extends StatefulWidget {
  const _Study({required this.study, required this.locale});

  final Study study;
  final AppLocale locale;

  @override
  State<_Study> createState() => _StudyState();
}

class _StudyState extends State<_Study> {
  /// Measures the two-column row, which is what bounds the frame's travel.
  final GlobalKey _rowKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final study = widget.study;
    final locale = widget.locale;
    final tokens = context.tokens;
    final isTwoColumn =
        context.platform.viewport.index >= ViewportClass.expanded.index;

    final scroll = ChromeScrollScope.maybeOf(context);
    final narrative = _Narrative(study: study, locale: locale);
    final frame = DeviceFrame(
      screens: study.screens,
      progress: scroll?.progress,
      locale: locale,
      seedId: study.id,
      title: study.title.resolve(locale),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(study.title.resolve(locale), style: context.type.displayM),
        SizedBox(height: tokens.space32),
        if (study.prototype case final prototype?) ...[
          PrototypeEmbed(
            url: prototype.url,
            status: prototype.status.resolve(locale),
            title: study.title.resolve(locale),
          ),
          SizedBox(height: tokens.space48),
        ],
        if (isTwoColumn)
          Row(
            key: _rowKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: narrative),
              SizedBox(width: tokens.space48),
              // Sticky within the scrolling page: the frame keeps its place in
              // the viewport while the narrative moves past it.
              _Pinned(
                controller: scroll?.controller,
                rowKey: _rowKey,
                child: frame,
              ),
            ],
          )
        else ...[
          frame,
          SizedBox(height: tokens.space32),
          narrative,
        ],
      ],
    );
  }
}

/// Holds the device frame in view while the narrative column scrolls past.
///
/// The page is one `SingleChildScrollView`, so vertical constraints here are
/// unbounded and the frame cannot learn the narrative's height from layout.
/// It measures its own row after layout instead — the same technique the
/// telemetry trace uses to anchor bursts to rendered career entries — and then
/// translates by the scroll offset, clamped so it never leaves the span of the
/// column it belongs to.
///
/// Translating rather than re-laying-out means a scroll costs a transform, not
/// a layout pass, and the image inside is gated separately on index change.
class _Pinned extends StatefulWidget {
  const _Pinned({
    required this.controller,
    required this.rowKey,
    required this.child,
  });

  final ScrollController? controller;

  /// The row whose height bounds how far the frame may travel.
  final GlobalKey rowKey;

  final Widget child;

  @override
  State<_Pinned> createState() => _PinnedState();
}

class _PinnedState extends State<_Pinned> {
  final GlobalKey _key = GlobalKey();

  /// How far the frame may travel before it reaches the end of its column.
  double _travel = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_Pinned oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// Available travel is the row's height less the frame's own.
  void _measure() {
    if (!mounted) return;
    final frame = _key.currentContext?.findRenderObject() as RenderBox?;
    final row = widget.rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (frame == null || row == null || !frame.hasSize || !row.hasSize) return;

    final travel = (row.size.height - frame.size.height).clamp(
      0.0,
      double.infinity,
    );
    if ((travel - _travel).abs() > 0.5) setState(() => _travel = travel);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final child = KeyedSubtree(key: _key, child: widget.child);
    if (controller == null || _travel <= 0) return child;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, inner) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        return Transform.translate(
          offset: Offset(0, offset.clamp(0.0, _travel)),
          child: inner,
        );
      },
      child: child,
    );
  }
}

/// The four sections, in the order the spec fixes them.
class _Narrative extends StatelessWidget {
  const _Narrative({required this.study, required this.locale});

  final Study study;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Section(
          heading: l10n.caseStudyContext,
          body: study.context.resolve(locale),
        ),
        _Section(
          heading: l10n.caseStudyProblem,
          body: study.problem.resolve(locale),
        ),
        _Section(
          heading: l10n.caseStudyApproach,
          body: study.approach.resolve(locale),
        ),
        // Outcome carries a number where one honestly exists; where none does,
        // the content describes the change qualitatively. Nothing here invents
        // a percentage.
        _Section(
          heading: l10n.caseStudyOutcome,
          body: study.outcome.resolve(locale),
        ),
        if (study.stack.isNotEmpty) ...[
          Text(
            l10n.caseStudyStack,
            style: context.type.heading.copyWith(color: tokens.textPrimary),
          ),
          SizedBox(height: tokens.space8),
          Text(
            study.stack.join(' · '),
            style: context.type.telemetryS.copyWith(color: tokens.instrument),
          ),
          SizedBox(height: tokens.space32),
        ],
        BeaconButton(
          label: l10n.caseStudyBackToWork,
          onPressed: () => context.goNamed(AppRoute.work.name),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading,
            style: type.heading.copyWith(color: tokens.textPrimary),
          ),
          SizedBox(height: tokens.space8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(
              body,
              style: type.body.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown for a slug with no study file — which today is every slug.
class _NotWritten extends StatelessWidget {
  const _NotWritten();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      CarrierEmptyState(direction: context.l10n.caseStudyUnavailable),
      SizedBox(height: context.tokens.space32),
      BeaconButton(
        label: context.l10n.caseStudyBackToWork,
        onPressed: () => context.goNamed(AppRoute.work.name),
      ),
    ],
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => SweepScope(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonText(lines: 1, style: context.type.displayM),
        SizedBox(height: context.tokens.space32),
        SkeletonText(lines: 12, style: context.type.body),
      ],
    ),
  );
}
