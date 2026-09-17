import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/career_thread_painter.dart';
import 'package:nocturne/core/widgets/reveal_on_scroll.dart';
import 'package:nocturne/content/period.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/country_names.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/features/station/presentation/widgets/stop_mark.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';

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
    super.key,
  });

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

  @override
  Widget build(BuildContext context) => _Threaded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final role in _mostRecentFirst)
          KeyedSubtree(
            key: anchorRegistry.keyFor(role.id),
            // Each stop unrolls as the reader reaches it. The career is a
            // sequence and the page should read as one, rather than as six
            // entries that were all already there.
            child: RevealOnScroll(
              child: _CareerEntry(role: role, locale: locale),
            ),
          ),
      ],
    ),
  );
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
  const _CareerEntry({required this.role, required this.locale});

  final CareerRole role;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space32),
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
          Expanded(child: _entry(context, tokens, type)),
        ],
      ),
    );
  }

  /// Where it was, with the country named rather than coded. The content
  /// stores "EG" because the atlas keys on it; a reader is owed "Egypt".
  String get _place => '${role.city}, ${CountryNames.of(role.country, locale)}';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: tokens.hairlineWidth,
          width: tokens.heroRuleWidth,
          child: ColoredBox(color: tokens.hairline),
        ),
        SizedBox(height: tokens.space16),
        Text(
          formatPeriod(context.l10n, role.start, role.end),
          style: type.telemetryS.copyWith(color: tokens.textMuted),
        ),
        SizedBox(height: tokens.space8),
        if (company != null)
          Text(company, style: type.heading)
        else
          Text(_place, style: type.heading),
        if (title != null && role.id != 'freelance')
          Text(
            title.resolve(locale),
            style: type.body.copyWith(color: tokens.textSecondary),
          ),
        if (company != null)
          Text(role.id == 'freelance' ? 'Remote' : _place, style: type.meta),
        if (summary != null && role.id != 'freelance') ...[
          SizedBox(height: tokens.space12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: type.measureFor(type.body)),
            child: Text(summary.resolve(locale), style: type.body),
          ),
        ],
      ],
    );
  }
}
