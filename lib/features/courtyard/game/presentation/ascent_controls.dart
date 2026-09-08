import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// What the player is currently asking for.
typedef AscentInput = ({double steer, bool leap, bool dive});

/// The on-screen pad, for a thumb rather than a dragged finger.
///
/// Dragging across the playfield was the first design and it was wrong: the
/// hand covers the shaft it is steering through, and there is nowhere to put a
/// second action. This is a pad under the frame, which is where every game on
/// a phone puts one, and it leaves the playfield to be looked at.
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
  bool _dive = false;

  void _publish() {
    widget.onChanged((
      steer: (_right ? 1.0 : 0.0) - (_left ? 1.0 : 0.0),
      leap: _leap,
      dive: _dive,
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
              _Pad(
                glyph: '‹',
                label: l10n.ascentSteerLeft,
                onChanged: (down) => setState(() {
                  _left = down;
                  _publish();
                }),
              ),
              SizedBox(width: tokens.space12),
              _Pad(
                glyph: '›',
                label: l10n.ascentSteerRight,
                onChanged: (down) => setState(() {
                  _right = down;
                  _publish();
                }),
              ),
            ],
          ),
          Row(
            children: [
              _Pad(
                glyph: '▼',
                label: l10n.ascentDive,
                onChanged: (down) => setState(() {
                  _dive = down;
                  _publish();
                }),
              ),
              SizedBox(width: tokens.space12),
              _Pad(
                glyph: '▲',
                label: l10n.ascentLeap,
                isPrimary: true,
                onChanged: (down) => setState(() {
                  _leap = down;
                  _publish();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One key on the pad. Reports press and release rather than taps, because
/// steering is something you hold.
class _Pad extends StatefulWidget {
  const _Pad({
    required this.glyph,
    required this.label,
    required this.onChanged,
    this.isPrimary = false,
  });

  final String glyph;
  final String label;
  final ValueChanged<bool> onChanged;
  final bool isPrimary;

  @override
  State<_Pad> createState() => _PadState();
}

class _PadState extends State<_Pad> {
  bool _isDown = false;

  void _set(bool down) {
    if (_isDown == down) return;
    setState(() => _isDown = down);
    widget.onChanged(down);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = context.platform.minimumTarget * 1.35;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: ExcludeSemantics(
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _isDown
                    ? tokens.beacon.withValues(alpha: 0.22)
                    : tokens.surfaceRaised,
                border: Border.all(
                  color: _isDown ? tokens.beacon : tokens.hairlineStrong,
                  width: tokens.hairlineWidth,
                ),
                borderRadius: BorderRadius.circular(tokens.controlRadius),
              ),
              child: Center(
                child: Text(
                  widget.glyph,
                  style: context.type.heading.copyWith(
                    color: _isDown || widget.isPrimary
                        ? tokens.beacon
                        : tokens.instrument,
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
