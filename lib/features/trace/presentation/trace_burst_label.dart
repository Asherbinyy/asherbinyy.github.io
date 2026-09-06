import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/widgets/instrument_panel.dart';

/// What a burst says when the signal locks onto it.
typedef TraceLabel = ({String id, String title, String meta});

/// One burst's readout, shown while the signal is locked onto it.
class TraceBurstLabel extends StatelessWidget {
  /// Places a content readout beside its measured burst.
  const TraceBurstLabel({
    required this.label,
    required this.top,
    required this.isVisible,
    super.key,
  });

  /// The role content, when available.
  final TraceLabel? label;

  /// Viewport position of the label.
  final double top;

  /// Whether the signal is locked or reduced motion shows all labels.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final content = label;
    if (content == null) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Positioned(
      top: top,
      left: 0,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: ReducedMotion.duration(context, Motion.standard),
        curve: MotionCurves.emphasized,
        child: InstrumentPanel(
          fill: tokens.surface,
          padding: EdgeInsets.all(tokens.space12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: context.type.bodyS.copyWith(color: tokens.beacon),
              ),
              Text(content.meta, style: context.type.telemetryS),
            ],
          ),
        ),
      ),
    );
  }
}
