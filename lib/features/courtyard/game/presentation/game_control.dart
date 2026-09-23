import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// One control surface for the whole game.
///
/// There were two. The stage chrome drew square-cornered buttons over a
/// translucent fill; the thumb pad drew rounded ones over an opaque fill, at a
/// different lit alpha again. On the same screen, at the same time, which is
/// what the owner meant by the buttons having no consistency.
///
/// The differences were never decisions, they were two people-shaped moments a
/// month apart. This is the single answer: same radius, same border, same
/// fill, same lit treatment, and one place to change any of them.
class GameControl extends StatefulWidget {
  /// A labelled button, sized to its text.
  const GameControl({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    super.key,
  }) : glyph = null,
       onHeld = null,
       semanticLabel = null,
       _isBar = false,
       _isIcon = false;

  /// A compact glyph button for the chrome around the game.
  ///
  /// The restart, mute and leave controls were full labelled buttons sitting
  /// across the top of the playfield, which is exactly where the climber is
  /// heading. A glyph at one target square says the same thing and leaves the
  /// shaft to be looked at.
  const GameControl.icon({
    required String this.glyph,
    required String this.semanticLabel,
    required VoidCallback this.onPressed,
    super.key,
  }) : label = null,
       onHeld = null,
       isPrimary = false,
       _isBar = false,
       _isIcon = true;

  /// The jump button: the touch stand-in for the space bar.
  ///
  /// Deliberately much bigger than a steering key, and round. It is the only
  /// action in the game and the one a thumb has to find without looking, which
  /// is exactly why every phone game with a jump in it draws a fat circle in
  /// the bottom corner — the owner's reference was Roblox and Roblox is right.
  const GameControl.jump({
    required String this.label,
    required ValueChanged<bool> this.onHeld,
    super.key,
  }) : glyph = null,
       semanticLabel = null,
       onPressed = null,
       isPrimary = true,
       _isBar = true,
       _isIcon = false;

  /// A square key that reports press and release, for steering.
  const GameControl.key({
    required String this.glyph,
    required String this.semanticLabel,
    required ValueChanged<bool> this.onHeld,
    this.isPrimary = false,
    super.key,
  }) : label = null,
       onPressed = null,
       _isBar = false,
       _isIcon = false;

  /// Text on a labelled button.
  final String? label;

  /// The mark on a key.
  final String? glyph;

  /// What a key announces, which its glyph cannot say.
  final String? semanticLabel;

  /// Fired once, on a labelled button.
  final VoidCallback? onPressed;

  /// Fired on press and again on release, for a held key.
  final ValueChanged<bool>? onHeld;

  /// Whether this reads as lit when idle.
  final bool isPrimary;

  /// Whether this is the wide jump bar rather than a key or a labelled button.
  final bool _isBar;

  /// Whether this is a compact glyph button in the chrome.
  final bool _isIcon;

  @override
  State<GameControl> createState() => _GameControlState();
}

class _GameControlState extends State<GameControl> {
  bool _isActive = false;

  void _setActive(bool active) {
    if (_isActive == active) return;
    setState(() => _isActive = active);
    widget.onHeld?.call(active);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isKey = widget.glyph != null;
    final isBar = widget._isBar;
    final isIcon = widget._isIcon;
    final isLit = _isActive || widget.isPrimary;
    final target = context.platform.minimumTarget;

    // Inside the border, not around it.
    //
    // The padding used to wrap the whole decorated box, which insets the
    // *button* from its neighbours and leaves the label sitting against its
    // own frame. That is what the owner was pointing at in every screenshot:
    // the buttons had no padding, and adding more of the kind already there
    // would only have spread them further apart.
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: isLit
            ? tokens.beacon.withValues(alpha: 0.18)
            : tokens.surfaceRaised,
        border: Border.all(
          color: isLit ? tokens.beacon : tokens.hairlineStrong,
          // A touch control is held rather than read, so its edge is drawn to
          // be found by a thumb at the corner of an eye rather than to match
          // the hairline the rest of the site is ruled with.
          width: isBar || isKey
              ? tokens.hairlineWidth * 2
              : tokens.hairlineWidth,
        ),
        shape: isBar || isKey ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isBar || isKey
            ? null
            : BorderRadius.circular(tokens.controlRadius),
      ),
      child: Padding(
        padding: isKey || isBar || isIcon
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(
                // Wider than tall, the proportion a label wants. A square of
                // padding round a line of text reads as a box someone forgot
                // to fill.
                horizontal: tokens.space24,
                vertical: tokens.space12,
              ),
        child: Center(
          widthFactor: isKey || isBar || isIcon ? null : 1,
          child: Text(
            // A mark, not a word, on the jump button. It is the only thing on
            // the screen a thumb has to hit while looking somewhere else, and
            // an arrow is read in the peripheral vision that a word is not.
            // The word survives as what it announces.
            isBar ? '▲' : widget.glyph ?? widget.label!,
            style:
                (isKey || isIcon || isBar
                        ? context.type.heading
                        : context.type.telemetry)
                    .copyWith(color: isLit ? tokens.beacon : tokens.instrument),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: context.platform.isPointer
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: isKey ? null : (_) => _setActive(true),
        onExit: isKey ? null : (_) => _setActive(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          // A key reports both edges, because steering has to stop.
          onTapDown: widget.onHeld != null ? (_) => _setActive(true) : null,
          onTapUp: widget.onHeld != null ? (_) => _setActive(false) : null,
          onTapCancel: widget.onHeld != null ? () => _setActive(false) : null,
          child: isBar
              // Round and fat. It was a 4x-wide bar running most of the frame,
              // which is the shape of a space key rather than of the thing a
              // thumb rests on, and it made the two steering keys look like an
              // afterthought at the other end of it.
              ? SizedBox(
                  width: target * 1.9,
                  height: target * 1.9,
                  child: surface,
                )
              : isIcon
              ? SizedBox(width: target, height: target, child: surface)
              : isKey
              ? SizedBox(
                  width: target * 1.45,
                  height: target * 1.45,
                  child: surface,
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(minHeight: target),
                  child: surface,
                ),
        ),
      ),
    );
  }
}
