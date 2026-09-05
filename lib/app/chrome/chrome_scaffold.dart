import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/app_route.dart';
import 'package:nocturne/app/chrome/app_footer.dart';
import 'package:nocturne/app/chrome/app_header.dart';
import 'package:nocturne/app/chrome/app_nav.dart';
import 'package:nocturne/app/chrome/app_rail.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
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
  const ChromeScaffold({required this.route, required this.child, super.key});

  /// The route being displayed.
  final AppRoute route;

  /// Routed content.
  final Widget child;

  @override
  ConsumerState<ChromeScaffold> createState() => _ChromeScaffoldState();
}

class _ChromeScaffoldState extends ConsumerState<ChromeScaffold> {
  final ScrollController _scroll = ScrollController();

  /// Published separately from the widget tree so a scroll rebuilds the rail's
  /// tick scale alone rather than the whole page, which would repaint the
  /// trace and the map every frame.
  final ValueNotifier<double> _progress = ValueNotifier(0);

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
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final extent = _scroll.position.maxScrollExtent;
    _progress.value = extent <= 0 ? 0 : _scroll.position.pixels / extent;
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
      body: FocusTraversalGroup(
        // Reading order is header, then content, then footer, in both
        // directions; the ordering policy follows Directionality rather than
        // being reversed by hand.
        policy: ReadingOrderTraversalPolicy(),
        child: Column(
          children: [
            AppHeader(current: widget.route),
            if (!AppHeader.hasInlineNav(context) && !isRecruiterMode)
              _NavRow(current: widget.route),
            if (!hasRail && !isRecruiterMode)
              _CollapsedProgress(progress: _progress),
            Expanded(
              child: Row(
                children: [
                  if (hasRail)
                    ValueListenableBuilder<double>(
                      valueListenable: _progress,
                      builder: (context, progress, _) => AppRail(
                        sectionName: _sectionName(context),
                        progress: progress,
                      ),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        controller: _scroll,
                        // Short pages still fill the frame, so the footer sits
                        // at the bottom of the viewport rather than floating
                        // under a half-height column.
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  /// The rail's vertical label. Routes that are not nav destinations fall back
  /// to the route's own name rather than inventing a section title.
  String _sectionName(BuildContext context) {
    for (final destination in NavDestination.values) {
      if (destination.route == widget.route) {
        return destination.label(context.l10n);
      }
    }
    return '';
  }
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.platform.gutter,
          ),
          child: AppNav(current: current),
        ),
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
