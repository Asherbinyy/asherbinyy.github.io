import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/features/courtyard/game/presentation/game_control.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// What the player is currently asking for.
///
/// Diving is gone. It existed because landing bounced on its own, so the only
/// way to come down deliberately was to force it; now that a jump is a press,
/// not jumping is how you stay put.
typedef AscentInput = ({double steer, bool leap});

/// The on-screen pad, for a thumb rather than a dragged finger.
///
/// Dragging across the playfield was the first design and it was wrong: the
/// hand covers the shaft it is steering through, and there is nowhere to put a
/// second action. This is a pad under the frame, which is where every game on
/// a phone puts one, and it leaves the playfield to be looked at.
///
/// Three controls, not four: left, right, and a wide jump bar standing in for
/// the space bar. Up and down went on the owner's instruction once landing
/// stopped bouncing by itself.
///
/// Pointer devices never see it. A keyboard has all four keys and a mouse has
/// none of these problems, so drawing a pad for them would be clutter.
class AscentControls extends StatefulWidget {
  /// Reports the pressed state on every change.
  const AscentControls({required this.onChanged, super.key});

  /// Called whenever what the player is asking for changes.
  final ValueChanged<AscentInput> onChanged;

  @override
  State<AscentControls> createState() => _AscentControlsState();
}

class _AscentControlsState extends State<AscentControls> {
  bool _left = false;
  bool _right = false;
  bool _leap = false;

  void _publish() {
    widget.onChanged((
      steer: (_right ? 1.0 : 0.0) - (_left ? 1.0 : 0.0),
      leap: _leap,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // A pointer browser has a keyboard, which does all of this better.
    if (context.platform.isPointer) return const SizedBox.shrink();
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(top: tokens.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GameControl.key(
                glyph: '‹',
                semanticLabel: l10n.ascentSteerLeft,
                onHeld: (down) => setState(() {
                  _left = down;
                  _publish();
                }),
              ),
              SizedBox(width: tokens.space12),
              GameControl.key(
                glyph: '›',
                semanticLabel: l10n.ascentSteerRight,
                onHeld: (down) => setState(() {
                  _right = down;
                  _publish();
                }),
              ),
            ],
          ),
          // One button, and it is the one the keyboard has. Up and down are
          // gone on the owner's instruction: landing no longer bounces on its
          // own, so "up" is the whole game and a separate dive button was a
          // third thing to learn for a move nobody used.
          GameControl.jump(
            label: l10n.ascentJump,
            onHeld: (down) => setState(() {
              _leap = down;
              _publish();
            }),
          ),
        ],
      ),
    );
  }
}

/// One key on the pad. Reports press and release rather than taps, because
/// steering is something you hold.
