import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// One of the three header controls.
///
/// Screen spec: 6px-radius controls, `--instrument-mid`, amber on active. The
/// hit target comes from the platform service rather than a breakpoint check,
/// so a phone browser gets 48px and a laptop 40px without this widget knowing
/// which it is on.
///
/// Hover and focus are held in a [WidgetStatesController] rather than local
/// state: the standards ban `setState`, and this is the framework's own
/// mechanism for exactly this, so it disposes cleanly and stays one pattern.
class ChromeControl extends StatefulWidget {
  /// [label] is the visible glyph or word; [semanticLabel] is what a screen
  /// reader announces, which is always a sentence rather than a glyph.
  const ChromeControl({
    required this.label,
    required this.semanticLabel,
    required this.isActive,
    required this.onPressed,
    super.key,
  });

  /// Short visible text.
  final String label;

  /// Full description for assistive technology.
  final String semanticLabel;

  /// Whether the control's state is currently on.
  final bool isActive;

  /// Invoked on tap, click, or Enter and Space when focused.
  final VoidCallback onPressed;

  @override
  State<ChromeControl> createState() => _ChromeControlState();
}

class _ChromeControlState extends State<ChromeControl> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final target = context.platform.minimumTarget;

    return Semantics(
      button: true,
      toggled: widget.isActive,
      label: widget.semanticLabel,
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final isFocused = _states.value.contains(WidgetState.focused);
          final isHovered = _states.value.contains(WidgetState.hovered);
          final colour = widget.isActive || isHovered
              ? tokens.beacon
              : tokens.instrumentMid;

          return FocusRing(
            isFocused: isFocused,
            child: InkWell(
              onTap: widget.onPressed,
              statesController: _states,
              borderRadius: BorderRadius.circular(tokens.controlRadius),
              // Hover states belong to pointer browsers only; the service
              // resolves that once so this never checks a viewport width.
              hoverColor: context.platform.isPointer
                  ? tokens.surfaceRaised
                  : Colors.transparent,
              mouseCursor: context.platform.isPointer
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: target,
                  minHeight: target,
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: ReducedMotion.duration(context, Motion.quick),
                    style: context.type.telemetry.copyWith(color: colour),
                    child: ExcludeSemantics(child: Text(widget.label)),
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
