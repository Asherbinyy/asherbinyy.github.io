import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// How much weight a call to action carries.
enum ButtonEmphasis {
  /// The one amber action on a screen. Section 2 reserves amber for what the
  /// viewer can act on, and spending it twice on one screen spends it nowhere.
  primary,

  /// A hairline ghost: same size, no fill, no chroma.
  ghost,
}

/// The site's call to action.
///
/// Never carries a trailing arrow — section 8 bans appending an arrow to link
/// or button text — and its label must name its outcome, per section 9, so a
/// button that navigates does not say "download".
class BeaconButton extends StatefulWidget {
  /// [onPressed] is required: a button that does nothing is not a button.
  const BeaconButton({
    required this.label,
    required this.onPressed,
    this.emphasis = ButtonEmphasis.ghost,
    super.key,
  });

  /// Visible text, which is also the accessible name.
  final String label;

  /// Invoked on tap, click, or Enter and Space when focused.
  final VoidCallback onPressed;

  /// Primary or ghost.
  final ButtonEmphasis emphasis;

  @override
  State<BeaconButton> createState() => _BeaconButtonState();
}

class _BeaconButtonState extends State<BeaconButton> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isPrimary = widget.emphasis == ButtonEmphasis.primary;

    return Semantics(
      button: true,
      label: widget.label,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isHovered = _states.value.contains(WidgetState.hovered);
          final fill = isPrimary
              ? (isHovered ? tokens.beaconGlow : tokens.beacon)
              : Colors.transparent;
          final edge = isPrimary
              ? fill
              : (isHovered ? tokens.hairlineStrong : tokens.hairline);
          final text = isPrimary
              ? tokens.void_
              : (isHovered ? tokens.textPrimary : tokens.textSecondary);

          return FocusRing(
            isFocused: _states.value.contains(WidgetState.focused),
            child: AnimatedContainer(
              duration: ReducedMotion.duration(context, Motion.quick),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(tokens.controlRadius),
                border: Border.all(color: edge, width: tokens.hairlineWidth),
              ),
              child: InkWell(
                onTap: widget.onPressed,
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
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: tokens.space24,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: ExcludeSemantics(
                        child: Text(
                          widget.label,
                          style: context.type.bodyS.copyWith(color: text),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
