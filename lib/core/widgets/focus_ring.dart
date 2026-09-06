import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';

/// A visible keyboard focus indicator, drawn outside the child's own edge.
///
/// The quality floor in `00-PROJECT-BRIEF.md` section 9 requires visible focus
/// on every interactive element, and Material's default focus fill is a
/// coloured overlay that this palette has no room for. Amber is correct here:
/// design-system section 2 reserves it for anything the viewer can act on, and
/// the focused control is exactly that.
class FocusRing extends StatelessWidget {
  /// [radius] should match the control's own radius so the ring stays
  /// concentric with it.
  const FocusRing({
    required this.isFocused,
    required this.child,
    this.radius = Tokens.controlRadius,
    super.key,
  });

  /// Whether the wrapped control currently holds focus.
  final bool isFocused;

  /// Corner radius of the control being ringed.
  final double radius;

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + tokens.space4),
        border: Border.all(
          // Transparent rather than absent so the control's geometry does not
          // change when focus arrives, which would shift the whole row.
          color: isFocused ? tokens.beacon : Colors.transparent,
          width: tokens.hairlineWidth * 2,
        ),
      ),
      child: Padding(padding: EdgeInsets.all(tokens.space4), child: child),
    );
  }
}
