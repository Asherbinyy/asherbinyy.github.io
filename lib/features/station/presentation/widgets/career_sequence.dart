import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/career_thread_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';
import 'package:nocturne/core/widgets/reveal_on_scroll.dart';
import 'package:nocturne/content/period.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/country_names.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/features/station/presentation/widgets/stop_mark.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';
import 'package:go_router/go_router.dart';
import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/content/content_media.dart';
import 'package:nocturne/content/models/apps.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/features/station/presentation/widgets/career_stops.dart';
import 'package:nocturne/features/station/presentation/widgets/reach_row.dart';

/// The career, top to bottom, as the trace's burst anchors.
///
/// Section 6 runs the trace from the hero to the end of the career sequence, so
/// the sequence has to exist for the trace to have anything to travel over.
/// Kept deliberately quiet: hairline-separated rows carrying only what the
/// content states. The trace is the bold element and this must not compete.
class CareerSequence extends StatelessWidget {
  /// [roles] arrive in the content's own chronological order.
  const CareerSequence({
    required this.roles,
    required this.locale,
    required this.anchorRegistry,
    this.apps = const {},
    super.key,
  });

  /// The applications, by id, so a stop can show what was built there.
  final Map<String, ShippedApp> apps;

  /// Career stations.
  final List<CareerRole> roles;

  /// Active content channel.
  final AppLocale locale;

  /// Supplies the stable keys the fixed trace layer measures.
  final TraceAnchorRegistry anchorRegistry;

  /// The stops, most recent first.
  ///
  /// The content is stored oldest-first, which is the order a life happened
  /// in and the wrong order to introduce it in: a reader meeting this column
  /// wants to know where he is now, not where he started. Sorted by start
  /// date rather than reversed, so the display order does not depend on how
  /// the document happens to be written.
  List<CareerRole> get _mostRecentFirst =>
      [...roles]..sort((a, b) => b.start.compareTo(a.start));

  /// The whole career, from the first date the content gives to the last,
  /// which every card's register is drawn against.
  _Span get _span {
    var from = double.infinity;
    var to = double.negativeInfinity;
    for (final role in roles) {
      final start = _yearOf(role.start);
      final end = _yearOf(role.end ?? role.start);
      if (start < from) from = start;
      if (end > to) to = end;
    }
    return (from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    final span = _span;
    return _Threaded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final role in _mostRecentFirst)
            KeyedSubtree(
              key: anchorRegistry.keyFor(role.id),
              // Each stop rises in as the reader reaches it. The career is a
              // sequence and the page should read as one, rather than as six
              // entries that were all already there. Risen rather than
              // unrolled: these are cards now, and the owner found the quiet
              // unroll read as no motion at all.
              child: RevealOnScroll(
                style: RevealStyle.rise,
                child: _CareerEntry(
                  role: role,
                  locale: locale,
                  span: span,
                  apps: [
                    for (final id in role.appIds)
                      if (apps[id] case final app?) app,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The first and last dates of a career, as fractional years.
typedef _Span = ({double from, double to});

/// A content date, "YYYY-MM", as a fractional year: 2021-10 is 2021.75.
double _yearOf(String date) {
  final parts = date.split('-');
  final year = int.tryParse(parts.first) ?? 0;
  final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
  return year + (month - 1) / 12;
}

/// The frieze running down the career, drawn as far as the reader has got.
///
/// It replaces the plain rule that used to separate the entries. A connecting
/// line is what every timeline on the web uses and says nothing about this
/// site; this is the same reed-bundle vocabulary as the wall and the stop
/// marks, so the career reads as part of the building.
///
/// The progress is measured from this widget's own position in the viewport
/// rather than from the page's scroll fraction: the career is one section of a
/// long page, and a fraction of the whole page would have the frieze finish
/// drawing itself long before the reader reached the last stop.
class _Threaded extends StatefulWidget {
  const _Threaded({required this.child});

  final Widget child;

  @override
  State<_Threaded> createState() => _ThreadedState();
}

class _ThreadedState extends State<_Threaded> {
  final ValueNotifier<double> _drawn = ValueNotifier(0);
  ScrollController? _controller;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The page's controller, not a `ScrollNotification`: this sits inside the
    // scroll view and notifications travel outward, so a listener here would
    // never fire. `ChromeScrollScope` documents the trap and the first version
    // of this fell into it anyway.
    // `_resolved`, not a null check: on the first pass both sides are null
    // outside the chrome, and comparing them skips the fallback that draws the
    // frieze in full when there is no scroll to follow.
    final next = ChromeScrollScope.maybeOf(context)?.controller;
    if (_resolved && identical(next, _controller)) return;
    _resolved = true;
    _controller?.removeListener(_measure);
    _controller = next;
    if (next == null) {
      // Nothing to scroll: draw the frieze in full rather than not at all.
      _drawn.value = 1;
      return;
    }
    next.addListener(_measure);
  }

  @override
  void dispose() {
    _controller?.removeListener(_measure);
    _drawn.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || viewport == null || !box.hasSize || !viewport.hasSize) {
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final fold = viewport.size.height;
    // Drawn to wherever the fold has reached inside this section, so the
    // frieze arrives at each stop as the stop does. It only ever grows: a
    // frieze that unpicked itself on the way back up would be a page that
    // will not settle.
    final reached = (fold - top) / box.size.height;
    final next = reached.clamp(0.0, 1.0);
    if (next > _drawn.value) _drawn.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isReduced = ReducedMotion.of(context);
    // On a phone each entry draws its own stop on a line down the leading
    // edge (see [_PhoneStop]), which takes the frieze's place.
    if (context.platform.viewport == ViewportClass.compact) return widget.child;
    return Stack(
      children: [
        PositionedDirectional(
          top: 0,
          bottom: 0,
          start: 0,
          width: Tokens.careerThreadWidth,
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: _drawn,
                builder: (context, value, _) => CustomPaint(
                  painter: CareerThreadPainter(
                    // Drawn in full under reduced motion: the frieze is part
                    // of the page's furniture, and only its arrival is
                    // decoration.
                    progress: isReduced ? 1 : value,
                    colour: tokens.hairline,
                    accent: tokens.beaconDim,
                    strokeWidth: tokens.hairlineWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Indented past the frieze. Both the thread and the stop marks sat at
        // the start edge and drew on top of each other, which made a muddle of
        // the one column that is supposed to be legible at a glance.
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: Tokens.careerThreadWidth + Tokens.careerThreadGap,
          ),
          child: widget.child,
        ),
      ],
    );
  }
}

class _CareerEntry extends StatelessWidget {
  const _CareerEntry({
    required this.role,
    required this.locale,
    required this.span,
    this.apps = const [],
  });

  final CareerRole role;
  final AppLocale locale;

  /// The whole career, which this stop's register is drawn against.
  final _Span span;

  /// What was built at this stop, in the order the content lists it.
  final List<ShippedApp> apps;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    // On a phone the stops run down the leading edge, one beside each card:
    // the owner found the sideways strip of stops above the cards awkward on
    // a phone and asked for them to go vertical, next to the experience.
    if (context.platform.viewport == ViewportClass.compact) {
      return Stack(
        children: [
          // The line joining the stops, through the gaps between cards.
          PositionedDirectional(
            start: (Tokens.careerRailCompact - tokens.hairlineWidth * 2) / 2,
            top: 0,
            bottom: 0,
            width: tokens.hairlineWidth * 2,
            child: ColoredBox(color: tokens.hairlineStrong),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhoneStop(role: role),
                SizedBox(width: tokens.space8),
                Expanded(
                  child: _Card(
                    role: role,
                    span: span,
                    padding: tokens.space16,
                    child: _entry(context, tokens, type),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space12),
      // The sign runs down the leading edge, beside the entry rather than
      // above it, so a reader scanning the column can tell study from
      // employment from freelance without reading a word.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: tokens.space24),
            child: StopMark(role: role),
          ),
          SizedBox(width: tokens.space24),
          // On a card. The entries were bare text over the wall, and once the
          // wall became the pattern behind the whole page the owner asked for
          // them to have a ground of their own -- and for them to run the
          // full width, lined up with every other section.
          Expanded(
            child: _Card(
              role: role,
              span: span,
              padding: tokens.space24,
              child: _entry(context, tokens, type),
            ),
          ),
        ],
      ),
    );
  }

  /// Where it was, with the country named rather than coded. The content
  /// stores "EG" because the atlas keys on it; a reader is owed "Egypt".
  String get _place => '${role.city}, ${CountryNames.of(role.country, locale)}';

  /// The stop's flag, the same disc-less emoji the Home flags use.
  String get _flag => ReachRow.flagOf(role.country) ?? '';

  /// Only what the content actually carries. Five of the six roles have no
  /// company or summary, and inventing either would be a claim about the
  /// owner's career that nobody made.
  Widget _entry(
    BuildContext context,
    ThemeTokens tokens,
    NocturneTypography type,
  ) {
    final company = role.company;
    final title = role.title;
    final summary = role.summary;
    final hasSummary = summary != null && role.id != 'freelance';

    // Who and where on one side, what happened on the other, once the card is
    // wide enough for both to keep a readable line. The hairline that opened
    // each entry is gone: the card's own edge separates them now.
    final facts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: tokens.space8,
          runSpacing: tokens.space4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatPeriod(context.l10n, role.start, role.end),
              style: type.telemetryS.copyWith(color: tokens.textMuted),
            ),
            _Length(role: role),
          ],
        ),
        SizedBox(height: tokens.space8),
        if (company != null)
          Text(
            role.id == 'freelance' ? context.l10n.careerFreelance : company,
            style: type.heading,
          )
        else
          Text(_place, style: type.heading),
        if (title != null && role.id != 'freelance')
          Text(
            title.resolve(locale),
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        if (company != null)
          Text(
            role.id == 'freelance'
                ? context.l10n.careerRemote
                : '$_flag  $_place'.trim(),
            style: type.meta,
          ),
      ],
    );
    if (!hasSummary && apps.isEmpty) return facts;

    // What happened, and what was built: the second half of the card. A stop
    // with no sentence of its own -- freelance -- still has its apps, so its
    // card is no longer half empty.
    final story = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasSummary)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            // The first sentence only. The owner found the whole paragraph
            // too much for Home: the CV and the brief carry the rest.
            child: Text(
              _firstSentence(summary.resolve(locale)),
              style: type.body,
            ),
          ),
        if (hasSummary && apps.isNotEmpty) SizedBox(height: tokens.space16),
        if (apps.isNotEmpty) _BuiltHere(apps: apps),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Tokens.careerCardSplitWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              facts,
              SizedBox(height: tokens.space12),
              story,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: Tokens.careerFactsFlex, child: facts),
            SizedBox(width: tokens.space32),
            Expanded(flex: Tokens.careerStoryFlex, child: story),
          ],
        );
      },
    );
  }
}

/// A stop's card: the panel, the stop's sign cut into its trailing corner,
/// and across its head the register -- the whole career as a band, a tick a
/// year, with this stop's stretch of it inked in as the card arrives.
///
/// The owner found the plain cards boring and the sparse ones empty. Both
/// additions carry something: the register says where in the career this
/// stop sits and how long it lasted, which a date range makes the reader
/// work out; the relief says what kind of stop it was, and on a phone, where
/// the mark beside the card is dropped, it is the only place that still does.
class _Card extends StatelessWidget {
  const _Card({
    required this.role,
    required this.span,
    required this.padding,
    required this.child,
  });

  final CareerRole role;
  final _Span span;
  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const bleed = Tokens.careerReliefSize * Tokens.careerReliefBleed;
    return InstrumentPanel(
      fill: tokens.surface,
      child: ClipRect(
        child: Stack(
          children: [
            PositionedDirectional(
              end: -bleed,
              bottom: -bleed,
              child: _Rising(child: StopRelief(role: role)),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The relief, rising a little further than the card around it as the card
/// arrives, so the two settle as layers rather than as one flat sheet.
class _Rising extends StatelessWidget {
  const _Rising({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reveal = RevealOnScroll.of(context);
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) {
        final away = 1 - MotionCurves.emphasized.transform(reveal.value);
        return Transform.translate(
          offset: Offset(0, away * Tokens.revealRiseLift),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// The apps built at a stop, each a way into its page on /work.
class _BuiltHere extends StatelessWidget {
  const _BuiltHere({required this.apps});

  final List<ShippedApp> apps;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.careerBuiltHere,
          style: type.telemetryS.copyWith(color: tokens.textMuted),
        ),
        SizedBox(height: tokens.space8),
        Wrap(
          spacing: tokens.space8,
          runSpacing: tokens.space8,
          children: [for (final app in apps) _AppChip(app: app)],
        ),
      ],
    );
  }
}

/// One app: its own screen in a disc, its name, and a way to its page.
class _AppChip extends StatefulWidget {
  const _AppChip({required this.app});

  final ShippedApp app;

  @override
  State<_AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<_AppChip> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final shot = widget.app.shots.isEmpty ? null : widget.app.shots.first;
    return Semantics(
      link: true,
      label: context.l10n.careerOpenApp(widget.app.name),
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
                pathParameters: {'slug': widget.app.id},
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
                constraints: BoxConstraints(
                  minHeight: context.platform.minimumTarget,
                ),
                padding: EdgeInsetsDirectional.only(
                  start: tokens.space8,
                  end: tokens.space12,
                  top: tokens.space4,
                  bottom: tokens.space4,
                ),
                decoration: BoxDecoration(
                  color: tokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: Border.all(
                    color: isLit ? tokens.beacon : tokens.hairline,
                    width: tokens.hairlineWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: Tokens.careerAppThumb,
                      height: Tokens.careerAppThumb,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.surface,
                        border: Border.all(
                          color: tokens.hairlineStrong,
                          width: tokens.hairlineWidth,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: shot == null
                          ? Center(
                              child: Text(
                                widget.app.name.characters.first,
                                style: type.bodyS.copyWith(
                                  color: tokens.beacon,
                                ),
                              ),
                            )
                          : Image(
                              image: contentImage(context, shot),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                    ),
                    SizedBox(width: tokens.space8),
                    Text(
                      widget.app.name,
                      style: type.bodyS.copyWith(
                        color: isLit
                            ? tokens.textPrimary
                            : tokens.textSecondary,
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

/// [text] up to and including its first full stop, or all of it if it has
/// only one sentence.
String _firstSentence(String text) {
  final match = RegExp(r'^.*?[.!?؟](?=\s|$)').firstMatch(text.trim());
  return match?.group(0) ?? text;
}

/// How long a stop lasted, as a small gold-edged badge beside its dates --
/// or "Now" while it is still going. It replaced a band that drew the stop
/// against the whole career, which the owner found odd rather than useful:
/// the one thing that band said was how long, so this says it in words.
class _Length extends StatelessWidget {
  const _Length({required this.role});

  final CareerRole role;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final end = role.end;
    final String text;
    if (end == null) {
      text = l10n.careerNow;
    } else {
      int months(String date) {
        final parts = date.split('-');
        final year = int.tryParse(parts.first) ?? 0;
        final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
        return year * 12 + month;
      }

      final total = months(end) - months(role.start) + 1;
      final years = total ~/ 12;
      final rest = total % 12;
      text = [
        if (years > 0) l10n.careerYears(years),
        if (rest > 0) l10n.careerMonths(rest),
      ].join(' ');
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(
          color: tokens.beaconDim,
          width: tokens.hairlineWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space8,
          vertical: tokens.space4 / 2,
        ),
        child: Text(
          text,
          style: context.type.telemetryS.copyWith(
            color: end == null ? tokens.beacon : tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// One stop on a phone: its year, and a mark for what it was, on the line
/// down the leading edge of the career.
class _PhoneStop extends StatelessWidget {
  const _PhoneStop({required this.role});

  final CareerRole role;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: SizedBox(
        width: Tokens.careerRailCompact,
        child: Column(
          children: [
            SizedBox(height: tokens.space12),
            DecoratedBox(
              // The page behind the year, so the line does not run through it.
              decoration: BoxDecoration(color: tokens.void_),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space4),
                child: Text(
                  role.start.split('-').first,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
            Container(
              width: Tokens.careerRailNode,
              height: Tokens.careerRailNode,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceRaised,
                border: Border.all(
                  color: tokens.hairlineStrong,
                  width: tokens.hairlineWidth * 1.5,
                ),
              ),
              child: Icon(
                CareerStops.markFor(role),
                size: Tokens.careerRailNode / 2,
                color: tokens.beacon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
