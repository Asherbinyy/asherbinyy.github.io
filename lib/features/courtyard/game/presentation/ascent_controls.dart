import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/features/courtyard/game/domain/ascent_contract.dart';
import 'package:nocturne/core/platform/platform_scope.dart';

/// The touch controls: the left of the screen steers, the right jumps.
///
/// The owner's reference is Roblox, and his words were "big fat area for the
/// jump". The pad of three small keys it replaces had to be found with a
/// thumb every time; here there is nothing to find. Put a thumb down anywhere
/// on the left and a stick appears under it -- slide it to steer -- and touch
/// anywhere on the right to jump. The two work at once, one thumb each.
///
/// The stick floats: it is centred wherever the thumb lands, so steering is
/// always a short slide from where the thumb already is. At rest a faint ring
/// and a gold jump button show where the two halves are.
///
/// Pointer devices never see it. A keyboard does all of this better.
class AscentControls extends StatefulWidget {
  /// Reports the pressed state on every change.
  const AscentControls({required this.onChanged, super.key});

  /// Called whenever what the player is asking for changes.
  final ValueChanged<AscentInput> onChanged;

  @override
  State<AscentControls> createState() => _AscentControlsState();
}

class _AscentControlsState extends State<AscentControls> {
  /// The pointer steering, where it came down, and where it is now.
  int? _stick;
  Offset? _stickFrom;
  Offset _stickAt = Offset.zero;

  /// The pointers holding the jump. A set, so a second thumb landing on the
  /// right and lifting again does not end a jump the first is still holding.
  final Set<int> _jumps = {};

  double get _steer {
    final from = _stickFrom;
    if (from == null) return 0;
    final dx = _stickAt.dx - from.dx;
    if (dx.abs() < Tokens.ascentStickDead) return 0;
    return dx < 0 ? -1 : 1;
  }

  void _publish() => widget.onChanged(
    AscentInput.of(steer: _steer, isLeaping: _jumps.isNotEmpty),
  );

  void _down(PointerDownEvent event, double width) {
    final isStick = event.localPosition.dx < width * Tokens.ascentStickShare;
    setState(() {
      if (isStick && _stick == null) {
        _stick = event.pointer;
        _stickFrom = event.localPosition;
        _stickAt = event.localPosition;
      } else if (!isStick) {
        _jumps.add(event.pointer);
      }
    });
    _publish();
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _stick) return;
    final from = _stickFrom!;
    // The knob stays on its base, however far the thumb goes.
    const reach = Tokens.ascentStickBase / 2;
    final offset = event.localPosition - from;
    final clamped = offset.distance > reach
        ? offset / offset.distance * reach
        : offset;
    final before = _steer;
    setState(() => _stickAt = from + clamped);
    if (_steer != before) _publish();
  }

  void _up(PointerEvent event) {
    setState(() {
      if (event.pointer == _stick) {
        _stick = null;
        _stickFrom = null;
      }
      _jumps.remove(event.pointer);
    });
    _publish();
  }

  @override
  Widget build(BuildContext context) {
    // A pointer browser has a keyboard, which does all of this better.
    if (context.platform.isPointer) return const SizedBox.shrink();
    final tokens = context.tokens;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final resting = Offset(
          tokens.space24 + Tokens.ascentStickBase / 2,
          constraints.maxHeight - tokens.space32 - Tokens.ascentStickBase / 2,
        );
        final base = _stickFrom ?? resting;
        final knob = _stickFrom == null ? resting : _stickAt;
        final isSteering = _stickFrom != null;
        final isJumping = _jumps.isNotEmpty;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _down(event, width),
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: Stack(
            children: [
              // Named for a screen reader, which cannot see the two halves.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width * Tokens.ascentStickShare,
                child: Semantics(
                  label: '${l10n.ascentSteerLeft}, ${l10n.ascentSteerRight}',
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: width * (1 - Tokens.ascentStickShare),
                child: Semantics(
                  button: true,
                  label: l10n.ascentJump,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: base.dx - Tokens.ascentStickBase / 2,
                top: base.dy - Tokens.ascentStickBase / 2,
                child: IgnorePointer(
                  child: Container(
                    width: Tokens.ascentStickBase,
                    height: Tokens.ascentStickBase,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.void_.withValues(
                        alpha: Tokens.ascentTouchFill,
                      ),
                      border: Border.all(
                        color: isSteering
                            ? tokens.beacon
                            : tokens.hairlineStrong,
                        width: tokens.hairlineWidth * 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: knob.dx - Tokens.ascentStickKnob / 2,
                top: knob.dy - Tokens.ascentStickKnob / 2,
                child: IgnorePointer(
                  child: Container(
                    width: Tokens.ascentStickKnob,
                    height: Tokens.ascentStickKnob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSteering
                          ? tokens.beacon
                          : tokens.surfaceRaised.withValues(
                              alpha: Tokens.ascentTouchFill,
                            ),
                      border: Border.all(
                        color: tokens.hairlineStrong,
                        width: tokens.hairlineWidth,
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: tokens.space24,
                bottom: tokens.space32,
                child: IgnorePointer(
                  child: Container(
                    width: Tokens.ascentJumpSize,
                    height: Tokens.ascentJumpSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isJumping
                          ? tokens.beacon
                          : tokens.beacon.withValues(
                              alpha: Tokens.ascentJumpRest,
                            ),
                      border: Border.all(
                        color: tokens.beacon,
                        width: tokens.hairlineWidth * 2,
                      ),
                      boxShadow: isJumping
                          ? [
                              BoxShadow(
                                color: tokens.beaconGlow,
                                blurRadius: Tokens.contactGlowBlur,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.keyboard_double_arrow_up_rounded,
                      size: Tokens.ascentJumpIcon,
                      color: isJumping ? tokens.void_ : tokens.beacon,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
