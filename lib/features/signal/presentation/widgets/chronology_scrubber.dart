import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The career chronology, as a scrubber under the map.
///
/// Screen spec: this is the primary control on touch, where tapping a small
/// node precisely is awkward. Dragging it moves through the career in order and
/// the map follows.
class ChronologyScrubber extends StatelessWidget {
  /// [marks] are the year labels under each stop, in chronological order.
  const ChronologyScrubber({
    required this.marks,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// One label per station.
  final List<String> marks;

  /// Currently selected stop, or -1.
  final int selectedIndex;

  /// Called as the viewer drags or taps.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Semantics(
      // Its own node: the stops and year labels below would otherwise merge
      // into the surrounding page and the control would lose its name.
      container: true,
      slider: true,
      label: context.l10n.signalScrubberLabel,
      value: selectedIndex >= 0 ? marks[selectedIndex] : null,
      child: LayoutBuilder(
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
              // The stops and year marks are the visual scale; the slider's own
              // value announces which station is selected, so reading all six
              // years as part of its name would be noise.
              child: ExcludeSemantics(
                child: _Scale(marks: marks, selectedIndex: selectedIndex),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The scrubber's visible scale: a row of stops over a row of year marks.
class _Scale extends StatelessWidget {
  const _Scale({required this.marks, required this.selectedIndex});

  final List<String> marks;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            for (var i = 0; i < marks.length; i++)
              Expanded(child: _Stop(isSelected: i == selectedIndex)),
          ],
        ),
        SizedBox(height: tokens.space8),
        Row(
          children: [
            for (final mark in marks)
              Expanded(
                child: Text(
                  mark,
                  textAlign: TextAlign.center,
                  style: context.type.telemetryS.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One stop on the scrubber: a node on a hairline rail.
class _Stop extends StatelessWidget {
  const _Stop({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: tokens.hairlineWidth,
          child: ColoredBox(color: tokens.hairline),
        ),
        FocusRing(
          isFocused: false,
          radius: tokens.tagRadius,
          child: SizedBox(
            width: tokens.space8,
            height: tokens.space8,
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
        ),
      ],
    );
  }
}
