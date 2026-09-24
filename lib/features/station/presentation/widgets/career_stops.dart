import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/models/career.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';
import 'package:nocturne/features/trace/presentation/trace_anchor_registry.dart';

/// The itinerary: every career stop, and a way to get to one directly.
///
/// The career below is long, and the only way to reach the stop a viewer
/// actually came for was to scroll past every other one. This is the index for
/// it, and it also fills the ground the owner marked as empty in the
/// bottom-left of Home.
///
/// It is drawn as a line of stations rather than a list of links because the
/// site already calls these stops, draws them as cartouches on the atlas, and
/// runs a wall of carved stone down the other side of the page. A column of
/// underlined text here would belong to a different site.
class CareerStops extends StatelessWidget {
  /// [roles] arrive most recent first; this widget does not reorder them.
  const CareerStops({
    required this.roles,
    required this.anchorRegistry,
    super.key,
  });

  /// The stops, in the order the career sequence prints them.
  ///
  /// No locale: a stop is named by its company, or by where it was, and the
  /// content carries both as plain strings. The title, which is the only
  /// translated field on a role, belongs to the entry rather than the index.
  final List<CareerRole> roles;

  /// Supplies the keys the career entries are mounted under.
  final TraceAnchorRegistry anchorRegistry;

  @override
  Widget build(BuildContext context) {
    if (roles.length < 2) return const SizedBox.shrink();
    final tokens = context.tokens;
    final type = context.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: tokens.space16,
              height: tokens.hairlineWidth * 2,
              child: ColoredBox(color: tokens.beacon),
            ),
            SizedBox(width: tokens.space8),
            Text(
              context.l10n.stationStops,
              style: type.telemetryS.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
        SizedBox(height: tokens.space16),
        // Across, not down. As a column of thin rows it read as a stray
        // sidebar -- the owner called it a thin random column -- and it left
        // the width it was supposed to be filling empty. As cards it is a row
        // of places, which is what it is.
        //
        // The full width of the page, in even rows. It was capped to the
        // copy's measure while the wall owned the trailing part of the page;
        // the wall is the background now, and the owner asked for every
        // section to share one width, edges lined up top to bottom.
        // A timeline, not a grid of cards: the stops are a sequence, and a
        // line through them says so. The owner found the cards dull and
        // their mark meaningless, so each stop's marker is now what it was
        // -- study, a job, freelance -- and the years sit above the line.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final share = width / roles.length;
            final item = share < Tokens.stopItemWidth
                ? Tokens.stopItemWidth
                : share;
            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, role) in roles.indexed)
                  SizedBox(
                    width: item,
                    child: _Stop(
                      role: role,
                      anchorRegistry: anchorRegistry,
                      isFirst: index == 0,
                      isLast: index == roles.length - 1,
                    ),
                  ),
              ],
            );
            // On a phone the line runs on past the edge and scrolls.
            if (item * roles.length <= width) return row;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            );
          },
        ),
      ],
    );
  }
}

class _Stop extends StatefulWidget {
  const _Stop({
    required this.role,
    required this.anchorRegistry,
    required this.isFirst,
    required this.isLast,
  });

  final CareerRole role;
  final TraceAnchorRegistry anchorRegistry;
  final bool isFirst;
  final bool isLast;

  @override
  State<_Stop> createState() => _StopState();
}

class _StopState extends State<_Stop> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  String get _name {
    final company = widget.role.company;
    if (company != null) {
      return widget.role.id == 'freelance'
          ? context.l10n.careerFreelance
          : company;
    }
    return '${widget.role.city}, ${widget.role.country}';
  }

  String get _year => widget.role.start.split('-').first;

  /// What kind of stop this was, as a mark anyone reads: a cap for study, a
  /// briefcase for a job, a laptop for freelance.
  IconData get _mark {
    if (widget.role.id == 'freelance') return Icons.laptop_mac_rounded;
    return switch (widget.role.kind) {
      StopKind.study => Icons.school_rounded,
      StopKind.role => Icons.work_rounded,
    };
  }

  void _goThere() {
    final target = widget.anchorRegistry.keyFor(widget.role.id).currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: ReducedMotion.duration(context, Motion.considered),
      curve: Curves.easeInOutCubic,
      alignment: 0.12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final line = SizedBox(
      height: tokens.hairlineWidth * 2,
      child: ColoredBox(color: tokens.hairlineStrong),
    );

    return Semantics(
      button: true,
      label: context.l10n.stationStopGoTo(_name),
      excludeSemantics: true,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isLit =
              _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.focused);
          final quick = ReducedMotion.duration(context, Motion.quick);
          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: InkWell(
              onTap: _goThere,
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              hoverColor: Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: quick,
                      style: type.telemetryS.copyWith(
                        color: isLit ? tokens.beacon : tokens.textMuted,
                      ),
                      child: Text(_year),
                    ),
                    SizedBox(height: tokens.space8),
                    Row(
                      children: [
                        Expanded(
                          child: widget.isFirst ? const SizedBox() : line,
                        ),
                        AnimatedScale(
                          scale: isLit ? Tokens.stopNodeLift : 1,
                          duration: quick,
                          curve: MotionCurves.emphasized,
                          child: AnimatedContainer(
                            duration: quick,
                            width: Tokens.stopNodeSize,
                            height: Tokens.stopNodeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLit ? tokens.beacon : tokens.surface,
                              border: Border.all(
                                color: isLit
                                    ? tokens.beacon
                                    : tokens.hairlineStrong,
                                width: tokens.hairlineWidth * 1.5,
                              ),
                            ),
                            child: Icon(
                              _mark,
                              size: Tokens.stopNodeSize * 0.5,
                              color: isLit ? tokens.void_ : tokens.beacon,
                            ),
                          ),
                        ),
                        Expanded(
                          child: widget.isLast ? const SizedBox() : line,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.space8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tokens.space4),
                      child: AnimatedDefaultTextStyle(
                        duration: quick,
                        style: type.bodyS.copyWith(
                          color: isLit
                              ? tokens.textPrimary
                              : tokens.textSecondary,
                        ),
                        child: Text(
                          _name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
