import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/app_footer.dart';
import 'package:nocturne/app/chrome/app_header.dart';
import 'package:nocturne/app/chrome/app_nav.dart';
import 'package:nocturne/app/chrome/pointer_beacon.dart';
import 'package:nocturne/features/station/presentation/widgets/back_to_top.dart';
import 'package:nocturne/features/recruiter/presentation/recruiter_view.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/ornament_field_painter.dart';
import 'package:nocturne/core/widgets/cursor_trail.dart';
import 'package:nocturne/core/painting/grain_painter.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/platform/platform_service.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// The persistent frame every route renders inside.
///
/// Screen spec: header, rail, content column, footer. The rail is hidden below
/// the expanded breakpoint, where its scroll scale collapses into a 3px line
/// under the header, and it is absent entirely in Recruiter Mode, which has no
/// rail by definition.
class ChromeScaffold extends ConsumerStatefulWidget {
  /// [route] drives the nav's selected state and the rail's section name.
  const ChromeScaffold({
    required this.route,
    required this.child,
    this.backgroundBuilder,
    this.contentReveal,
    this.chromeReveal,
    super.key,
  });

  /// The route being displayed.
  final AppRoute route;

  /// Routed content.
  final Widget child;

  /// Beat-three opacity for routed content and its background trace.
  final Animation<double>? contentReveal;

  /// Beat-four opacity and edge movement for persistent chrome.
  final Animation<double>? chromeReveal;

  /// Painted behind the scrolling content, given the page scroll controller.
  ///
  /// The telemetry trace lives here rather than inside the scroll view: it
  /// needs the visible window to sample only what is on screen, which it
  /// cannot know from inside a viewport that has already scrolled it.
  final Widget Function(ScrollController controller)? backgroundBuilder;

  @override
  ConsumerState<ChromeScaffold> createState() => _ChromeScaffoldState();
}

class _ChromeScaffoldState extends ConsumerState<ChromeScaffold> {
  final ScrollController _scroll = ScrollController();

  /// Published separately from the widget tree so a scroll rebuilds the rail's
  /// tick scale alone rather than the whole page, which would repaint the
  /// trace and the map every frame.
  final ValueNotifier<double> _progress = ValueNotifier(0);

  /// Raw scroll pixels, for the field behind the page.
  ///
  /// Separate from [_progress] because they answer different questions: the
  /// rail wants "how far through", the parallax wants "how far down". Feeding
  /// the parallax a fraction would make the field drift at a rate that
  /// depended on the length of the page it happened to be behind.
  final ValueNotifier<double> _pixels = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _progress.dispose();
    _pixels.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final extent = _scroll.position.maxScrollExtent;
    _progress.value = extent <= 0 ? 0 : _scroll.position.pixels / extent;
    _pixels.value = _scroll.position.pixels;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isRecruiterMode = ref.watch(recruiterModeProvider);
    final hasRail =
        !isRecruiterMode &&
        context.platform.viewport.index >= ViewportClass.expanded.index;

    return Scaffold(
      backgroundColor: tokens.void_,
      body: CursorTrail(
        // Recruiter Mode is a quiet document; nothing decorative runs in it.
        isEnabled: !isRecruiterMode,
        child: _Grained(
          route: widget.route,
          isRecruiterMode: isRecruiterMode,
          pixels: _pixels,
          child: FocusTraversalGroup(
            // Reading order is header, then content, then footer, in both
            // directions; the ordering policy follows Directionality rather
            // than being reversed by hand.
            policy: ReadingOrderTraversalPolicy(),
            child: Column(
              children: [
                _ChromeReveal(
                  animation: widget.chromeReveal,
                  edge: _RevealEdge.top,
                  child: AppHeader(current: widget.route),
                ),
                if (!AppHeader.hasInlineNav(context) && !isRecruiterMode)
                  _ChromeReveal(
                    animation: widget.chromeReveal,
                    edge: _RevealEdge.top,
                    child: _NavRow(current: widget.route),
                  ),
                if (!hasRail && !isRecruiterMode)
                  _ChromeReveal(
                    animation: widget.chromeReveal,
                    edge: _RevealEdge.top,
                    child: _CollapsedProgress(progress: _progress),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      // The 56px rail that used to sit here is gone. It set
                      // the section name vertically and printed a trace state
                      // -- "standby" -- beside a tick scale, which imitated a
                      // machine readout without reporting anything. The owner
                      // named it as the kind of affectation he wants out of
                      // the site.
                      Expanded(
                        child: FadeTransition(
                          opacity:
                              widget.contentReveal ??
                              const AlwaysStoppedAnimation(1),
                          child: _ContentColumn(
                            controller: _scroll,
                            // Recruiter Mode has no trace: section 5 of
                            // the brief says no map, no trace, no motion.
                            background: isRecruiterMode
                                ? null
                                : widget.backgroundBuilder?.call(_scroll),
                            child: ChromeScrollScope(
                              progress: _progress,
                              controller: _scroll,
                              child: isRecruiterMode
                                  ? const RecruiterView()
                                  : widget.child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The rail's vertical label. Routes that are not nav destinations fall back
  /// to the route's own name rather than inventing a section title.
}

enum _RevealEdge { top, bottom, start }

/// Publishes the page's scroll progress to the routed content below it.
///
/// The rail already listens to this notifier, so a screen that needs scroll
/// position — the case study's pinned device frame, for instance — reads the
/// same value rather than attaching a second listener to the same controller.
/// It is a `ValueNotifier` rather than an inherited `double` on purpose: a
/// rebuild of the whole routed subtree on every scroll frame is what the
/// trace's and the map's frame budgets cannot afford.
///
/// A `ScrollNotification` would not do: routed content sits *inside* the
/// scroll view, and notifications travel outward from the scrollable, so a
/// listener under it never sees them.
class ChromeScrollScope extends InheritedWidget {
  /// Wraps [child] with the page's scroll [progress].
  const ChromeScrollScope({
    required this.progress,
    required this.controller,
    required super.child,
    super.key,
  });

  /// Scroll offset over max extent, clamped to 0 when the page does not scroll.
  final ValueNotifier<double> progress;

  /// The page's scroll controller, for content that needs pixels rather than
  /// a fraction — the case study's pinned device frame, which has to hold a
  /// position in the viewport rather than pick an index.
  final ScrollController controller;

  /// The nearest scope, or null outside the chrome — as on `/cv` and `/brief`.
  static ChromeScrollScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChromeScrollScope>();

  @override
  bool updateShouldNotify(ChromeScrollScope oldWidget) =>
      progress != oldWidget.progress || controller != oldWidget.controller;
}

/// Keeps chrome laid out at its final size while drawing it in from an edge.
class _ChromeReveal extends StatelessWidget {
  const _ChromeReveal({
    required this.animation,
    required this.edge,
    required this.child,
  });

  final Animation<double>? animation;
  final _RevealEdge edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reveal = animation;
    if (reveal == null) return child;
    final direction = Directionality.of(context);
    final offset = switch (edge) {
      _RevealEdge.top => const Offset(0, -1),
      _RevealEdge.bottom => const Offset(0, 1),
      _RevealEdge.start => Offset(direction == TextDirection.ltr ? -1 : 1, 0),
    };
    return FadeTransition(
      opacity: reveal,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: offset,
          end: Offset.zero,
        ).animate(reveal),
        child: child,
      ),
    );
  }
}

/// The scrolling content column between the rail and the footer.
///
/// Wrapped in a [SelectionArea] since milestone 4. Flutter paints text to a
/// canvas, so without this a visitor cannot select or copy anything on the
/// page — not a paragraph, and not the owner's own email address, which is the
/// single most likely thing a recruiter will want to take away. That is a
/// broken expectation of the web rather than a missing feature, so it is fixed
/// here rather than listed as polish.
///
/// It wraps the content column and not the whole frame deliberately. Selection
/// over the header, the rail and the toggles would let a drag that begins on a
/// control turn into a text drag, and none of that chrome is text anyone wants
/// to copy.
class _ContentColumn extends StatelessWidget {
  const _ContentColumn({
    required this.controller,
    required this.child,
    this.background,
  });

  final ScrollController controller;
  final Widget child;
  final Widget? background;

  /// The live pointer position, shared with whatever is drawn behind.
  static final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);

  @override
  Widget build(BuildContext context) {
    final layer = background;
    // Captured above the scrolling content, because the wall behind it is the
    // scroll view's sibling and would never see a hover of its own.
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onHover: (event) => _pointer.value = event.position,
      onExit: (_) => _pointer.value = null,
      child: PointerBeacon(
        position: _pointer,
        child: _buildStack(context, layer),
      ),
    );
  }

  /// The height a page can fill before the footer, which closes it, scrolls.
  double _pageHeight(BuildContext context, BoxConstraints constraints) =>
      math.max(0, constraints.maxHeight - context.tokens.footerHeight);

  Widget _buildStack(BuildContext context, Widget? layer) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          // The wall shares the content's frame rather than the window's.
          // Filling the viewport while the copy is centred inside a cap puts
          // the two in different coordinate systems, and the wall starts
          // drawing over the paragraph again on a wide monitor.
          if (layer != null)
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Tokens.contentMaxWidth,
                  ),
                  child: layer,
                ),
              ),
            ),
          SelectionArea(
            child: SingleChildScrollView(
              controller: controller,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                // Capped and centred on a wide monitor. Every page was laid
                // out from the leading edge with no ceiling, so at 1080p and
                // above the content sat against the left of the window with a
                // third of the screen empty beside it, which is the "not
                // centred on desktop" the owner reported.
                //
                // The cap is the frame, not the measure: paragraphs still cap
                // at their own reading width inside it. What this stops is the
                // frame itself growing until the page has no shape.
                //
                // The footer closes the page from inside the scroll. It was a
                // fixed row under the viewport, which cost every screen 48
                // pixels to show an empty bar -- on a phone, with the two-row
                // header, a fifth of the screen or more was chrome. Its stated
                // job was to end the content so a short page does not simply
                // stop, and that is a job for the end of the page.
                //
                // Content is held to at least the viewport less the footer, so
                // on a short page the rule still lands at the bottom of the
                // window, and on a long one it follows the last thing. No
                // intrinsic measurement: pages lay out with LayoutBuilder,
                // which cannot report one.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: _pageHeight(context, constraints),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: Tokens.contentMaxWidth,
                          ),
                          // The footer is part of the page now, so the page
                          // that fits itself to one screen -- the Journey map
                          // -- has to leave it room, or the map grows by the
                          // footer's height and pushes it below the fold.
                          child: ContentViewport(
                            height: _pageHeight(context, constraints),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ),
          // Above the scrolling content, not in it: it is a control on the
          // page rather than a thing at the end of the page.
          BackToTop(controller: controller),
        ],
      ),
    );
  }
}

/// Paints the static film grain behind the whole frame.
///
/// Design-system section 2: 3% opacity, rendered once as a tiled texture, in
/// both themes. It never animates, so it stays on under reduced motion. A
/// `RepaintBoundary` keeps it out of the trace's and the map's repaints.
class _Grained extends StatelessWidget {
  const _Grained({
    required this.child,
    required this.route,
    required this.isRecruiterMode,
    required this.pixels,
  });

  final Widget child;

  /// Which field to draw. Each route gets its own arrangement, so a viewer
  /// can tell one page from another before reading a word of it.
  final AppRoute route;

  /// Recruiter Mode is a quiet document and carries no field.
  final bool isRecruiterMode;

  /// How far the page has scrolled, for the field's parallax.
  final ValueListenable<double> pixels;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      fit: StackFit.expand,
      children: [
        // The inscription sits under the texture, not over it: two layers, in
        // that order, is what keeps them reading as separate rather than as
        // one muddy surface. Recruiter Mode has neither.
        if (!isRecruiterMode)
          RepaintBoundary(
            // The wall moves, slowly. Two planes travelling at different
            // speeds is the whole of the effect: the field used to scroll in
            // lockstep with the text, which reads as wallpaper printed on the
            // same sheet rather than as a surface the page is passing.
            //
            // A `ValueListenableBuilder` rather than a rebuild of the page:
            // this repaints one `CustomPaint` per frame of scroll and nothing
            // else, which is why the trace and the map are unaffected.
            //
            // Under reduced motion the field holds still. Parallax is
            // vestibular motion that nobody asked for, and the page is
            // perfectly legible without it.
            child: ValueListenableBuilder<double>(
              valueListenable: pixels,
              builder: (context, value, _) => CustomPaint(
                painter: OrnamentFieldPainter(
                  seed: 'field.${route.name}',
                  colour: tokens.ornamentField,
                  opacity: tokens.ornamentFieldAlpha,
                  hairlineWidth: tokens.hairlineWidth,
                  drift: ReducedMotion.of(context)
                      ? 0
                      : value * Tokens.ornamentParallax,
                ),
              ),
            ),
          ),
        RepaintBoundary(
          child: CustomPaint(
            painter: GrainPainter(
              colour: tokens.instrument,
              opacity: tokens.grainOpacity,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The footer.
///
/// Milestone 4 removed the coordinate readout that sat at the trailing edge.
/// It derived a latitude from whichever career role had not ended, which was
/// truthful but introduced the owner by a map reference — his objection, and a
/// fair one for a site whose milestone-4 goal is that there is a person here.
/// Nothing replaced it: the footer is one 48px row and the honest response to
/// a flourish that was not working is to remove it, not to substitute another.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const AppFooter();
}

/// The route links, on their own row when they do not fit in the header.
///
/// Scrolls horizontally rather than wrapping, so the row keeps a fixed height
/// and the content below it never shifts as the active route changes.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.current});

  final AppRoute current;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.void_,
        border: Border(
          bottom: BorderSide(
            color: tokens.hairline,
            width: tokens.hairlineWidth,
          ),
        ),
      ),
      child: _ScrollableNav(current: current),
    );
  }
}

/// The phone's navigation row, which says when it has more to show.
///
/// It has always scrolled sideways, so Courtyard was never unreachable — but
/// nothing said so. The row ended flush against the right edge on a 390px
/// phone with "About" as the last word anyone could see, which reads as the
/// end of the list rather than as the edge of a window onto it.
///
/// A fade over the trailing edge is the whole fix, and it is only drawn while
/// there is something behind it: a permanent gradient would dim the last item
/// once you had scrolled to it, which says the opposite of the truth.
class _ScrollableNav extends StatefulWidget {
  const _ScrollableNav({required this.current});

  final AppRoute current;

  @override
  State<_ScrollableNav> createState() => _ScrollableNavState();
}

class _ScrollableNavState extends State<_ScrollableNav> {
  final ScrollController _controller = ScrollController();
  final ValueNotifier<({bool before, bool after})> _hidden = ValueNotifier((
    before: false,
    after: false,
  ));
  final GlobalKey _active = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealActive();
      _check();
    });
  }

  @override
  void didUpdateWidget(_ScrollableNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActive());
    }
  }

  /// Brings the current page's link into view if the row has hidden it.
  ///
  /// On a phone the row is wider than the screen, and on About or the
  /// Courtyard the active link sat past the trailing edge -- so the row showed
  /// no page as current and the visitor lost their place. Only moves when the
  /// link is not already fully visible, and asks the viewport for the offsets
  /// so it is right in Arabic too, where the row runs the other way.
  void _revealActive() {
    if (!mounted || !_controller.hasClients) return;
    final item = _active.currentContext?.findRenderObject();
    if (item == null) return;
    final viewport = RenderAbstractViewport.maybeOf(item);
    if (viewport == null) return;
    final atLeading = viewport.getOffsetToReveal(item, 0).offset;
    final atTrailing = viewport.getOffsetToReveal(item, 1).offset;
    final offset = _controller.offset;
    final isVisible =
        offset >= math.min(atLeading, atTrailing) &&
        offset <= math.max(atLeading, atTrailing);
    if (isVisible) return;
    // Jumped, not animated: this is where the page opens, not a movement the
    // visitor asked for, so there is nothing to show happening.
    _controller.jumpTo(
      viewport
          .getOffsetToReveal(item, 0.5)
          .offset
          .clamp(0, _controller.position.maxScrollExtent),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_check)
      ..dispose();
    _hidden.dispose();
    super.dispose();
  }

  void _check() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    _hidden.value = (
      before: position.extentBefore > 1,
      after: position.extentAfter > 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scroller = SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.platform.gutter,
        ),
        child: AppNav(current: widget.current, activeKey: _active),
      ),
    );

    return NotificationListener<ScrollMetricsNotification>(
      // Fires when the row's extent changes without a scroll -- a rotation, a
      // text-size change -- which is when the fade would otherwise be stale.
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _check());
        return false;
      },
      // Faded at whichever edge has links past it. The row used to fade only
      // its trailing edge, so once the current page had been brought into
      // view the first link was cut through mid-word -- "urney" -- with
      // nothing to say it was a row that scrolls rather than a broken one.
      child: ValueListenableBuilder<({bool before, bool after})>(
        valueListenable: _hidden,
        builder: (context, hidden, child) => ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: AlignmentDirectional.centerStart.resolve(
              Directionality.of(context),
            ),
            end: AlignmentDirectional.centerEnd.resolve(
              Directionality.of(context),
            ),
            colors: [
              if (hidden.before) Colors.transparent else Colors.white,
              Colors.white,
              Colors.white,
              if (hidden.after) Colors.transparent else Colors.white,
            ],
            stops: const [0, Tokens.navEdgeFade, 1 - Tokens.navEdgeFade, 1],
          ).createShader(bounds),
          child: child,
        ),
        child: scroller,
      ),
    );
  }
}

/// The rail's tick scale, collapsed to a 3px line under the header.
class _CollapsedProgress extends StatelessWidget {
  const _CollapsedProgress({required this.progress});

  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: SizedBox(
        height: tokens.railProgressHeight,
        child: ColoredBox(
          color: tokens.hairline,
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: ColoredBox(color: tokens.beacon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
