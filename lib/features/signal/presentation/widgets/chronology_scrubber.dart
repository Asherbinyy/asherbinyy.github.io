import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The journey, as a timeline under the map.
///
/// This was six unlabelled dots over six years, each drawing its own short
/// rail inside its own column, so the rail never joined up and nothing on
/// screen said the control could be dragged at all. The owner reported it as
/// unclear, and a golden confirmed it: the stops read as decoration.
///
/// Three things fix it, and none of them is an instruction to the viewer.
/// The rail is now continuous, so the stops read as points on one line rather
/// than six separate marks. The selected stop is named above the line, so
/// moving the control visibly does something. And it is flanked by two
/// buttons, which is the part that makes it obviously operable — on a phone,
/// with a mouse, and from the keyboard, without anyone having to guess that a
/// thin row of dots accepts a drag.
class ChronologyScrubber extends StatelessWidget {
  /// [marks] are the year labels, and [places] the names, in journey order.
  const ChronologyScrubber({
    required this.marks,
    required this.places,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// One year label per stop.
  final List<String> marks;

  /// One place name per stop, shown for the selected one.
  final List<String> places;

  /// Currently selected stop, or -1.
  final int selectedIndex;

  /// Called as the viewer drags, taps, or steps.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;
    final l10n = context.l10n;
    final last = marks.length - 1;

    // Stepping from nothing selected starts at the beginning rather than
    // doing nothing, so the first press of either button always responds.
    final current = selectedIndex < 0 ? -1 : selectedIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reserved whether or not a stop is selected, so selecting one does
        // not push the map upward.
        SizedBox(
          height: context.type.body.fontSize,
          child: current >= 0 && current < places.length
              ? Text(
                  places[current],
                  style: context.type.body.copyWith(color: tokens.beacon),
                )
              : Text(
                  l10n.signalScrubberHint,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
        ),
        SizedBox(height: tokens.space8),
        Row(
          children: [
            _Step(
              label: l10n.signalPreviousStop,
              glyph: '‹',
              onPressed: current <= 0 ? null : () => onSelected(current - 1),
            ),
            Expanded(
              child: Semantics(
                container: true,
                slider: true,
                label: l10n.signalScrubberLabel,
                value: current >= 0 ? marks[current] : null,
                child: _Rail(
                  marks: marks,
                  selectedIndex: current,
                  onSelected: onSelected,
                ),
              ),
            ),
            _Step(
              label: l10n.signalNextStop,
              glyph: '›',
              onPressed: current >= last
                  ? null
                  : () => onSelected(current < 0 ? 0 : current + 1),
            ),
          ],
        ),
      ],
    );
  }
}

/// One end of the scrubber: a labelled control that steps by one stop.
///
/// Disabled rather than hidden at the ends, so the row never changes width and
/// the rail never shifts under the pointer mid-drag.
class _Step extends StatefulWidget {
  const _Step({required this.label, required this.glyph, this.onPressed});

  final String label;
  final String glyph;
  final VoidCallback? onPressed;

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = widget.onPressed != null;

    // Hover and focus are tracked here rather than through a
    // WidgetStatesController. An InkWell writes `disabled` into a controller
    // during its own build, so a ListenableBuilder watching that controller
    // gets marked dirty mid-build -- which is a framework assertion, not a
    // cosmetic problem, and it took out every test on this screen.
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: FocusRing(
        isFocused: _isFocused,
        radius: tokens.controlRadius,
        child: FocusableActionDetector(
          enabled: isEnabled,
          onShowHoverHighlight: (value) => setState(() => _isHovered = value),
          onShowFocusHighlight: (value) => setState(() => _isFocused = value),
          mouseCursor: isEnabled && context.platform.isPointer
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: widget.onPressed,
            behavior: HitTestBehavior.opaque,
            child: ExcludeSemantics(
              child: SizedBox(
                width: context.platform.minimumTarget,
                height: context.platform.minimumTarget,
                child: Center(
                  child: Text(
                    widget.glyph,
                    style: context.type.heading.copyWith(
                      color: !isEnabled
                          ? tokens.instrumentDim
                          : (_isHovered ? tokens.beacon : tokens.instrumentMid),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The continuous rail, its stops, and the year under each.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.marks,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> marks;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        void select(Offset local) {
          final step = constraints.maxWidth / marks.length;
          final index = (local.dx / step).floor().clamp(0, marks.length - 1);
          onSelected(index);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => select(details.localPosition),
          onHorizontalDragUpdate: (details) => select(details.localPosition),
          child: SizedBox(
            height: context.platform.minimumTarget + tokens.space24,
            // The rail and years are the visible scale; the slider's own value
            // announces the selection, so reading every year as part of its
            // name would be noise.
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // One rule across the whole control. Previously each
                      // stop drew its own segment inside its own column, which
                      // is why the line never read as a line.
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: tokens.space16,
                        ),
                        child: SizedBox(
                          // Width matters: a Stack gives its non-positioned
                          // children loose constraints, so a SizedBox with
                          // only a height wraps a ColoredBox that has no
                          // intrinsic size and the rail renders zero pixels
                          // wide. It did exactly that on the first pass, and
                          // the golden showed the stops floating unconnected —
                          // which is the defect this redesign existed to fix.
                          width: double.infinity,
                          height: tokens.hairlineWidth,
                          child: ColoredBox(color: tokens.hairlineStrong),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < marks.length; i++)
                            Expanded(
                              child: _Stop(isSelected: i == selectedIndex),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.space8),
                  Row(
                    children: [
                      for (var i = 0; i < marks.length; i++)
                        Expanded(
                          child: Text(
                            marks[i],
                            textAlign: TextAlign.center,
                            style: context.type.telemetryS.copyWith(
                              color: i == selectedIndex
                                  ? tokens.beacon
                                  : tokens.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One stop on the rail.
///
/// The selected one is a filled disc at the map's own active node radius, so
/// the control and the map agree about what "selected" looks like.
class _Stop extends StatelessWidget {
  const _Stop({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final diameter = isSelected
        ? Tokens.stationNodeActiveRadius * 2
        : Tokens.stationNodeRadius * 2;

    return Center(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? tokens.beacon : tokens.void_,
            border: Border.all(
              color: isSelected ? tokens.beacon : tokens.instrumentDim,
              width: tokens.hairlineWidth,
            ),
          ),
        ),
      ),
    );
  }
}
