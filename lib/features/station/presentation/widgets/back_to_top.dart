import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The way back up, once there is a way back up to want.
///
/// Home is long: the hero, the stops, eight career entries and the contact
/// block. A reader who has reached the bottom has no way back to the top but
/// the scroll wheel, and on a trackpad that is a lot of wheel.
///
/// It appears only after the page has moved far enough that returning is a
/// real errand, and it fades rather than appearing, so it never flickers in
/// and out while somebody is reading near the threshold.
class BackToTop extends StatefulWidget {
  /// Watches [controller] and scrolls it home when pressed.
  const BackToTop({required this.controller, super.key});

  /// The page's own scroll controller.
  final ScrollController controller;

  @override
  State<BackToTop> createState() => _BackToTopState();
}

class _BackToTopState extends State<BackToTop> {
  final WidgetStatesController _states = WidgetStatesController();
  bool _isShown = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _states.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    // Measured against the viewport rather than a fixed pixel count: "past
    // the cards" is a screenful and a half on any size of screen, and a
    // number that is right on a laptop is wrong on a phone.
    final position = widget.controller.position;
    final shown =
        position.pixels > position.viewportDimension * Tokens.backToTopAfter;
    if (shown == _isShown) return;
    setState(() => _isShown = shown);
  }

  void _goUp() {
    if (!widget.controller.hasClients) return;
    final duration = ReducedMotion.duration(context, Motion.considered);
    if (duration == Duration.zero) {
      widget.controller.jumpTo(0);
      return;
    }
    widget.controller.animateTo(
      0,
      duration: duration,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = context.l10n.stationBackToTop;

    return PositionedDirectional(
      end: context.platform.gutter,
      bottom: tokens.space32,
      child: IgnorePointer(
        ignoring: !_isShown,
        child: AnimatedOpacity(
          opacity: _isShown ? 1 : 0,
          duration: ReducedMotion.duration(context, Motion.standard),
          curve: MotionCurves.emphasized,
          child: Semantics(
            button: true,
            label: label,
            child: ListenableBuilder(
              listenable: _states,
              builder: (context, _) {
                final isLit = _states.value.contains(WidgetState.hovered);
                return FocusRing(
                  isFocused: _states.value.contains(WidgetState.focused),
                  child: Tooltip(
                    message: label,
                    waitDuration: Motion.considered,
                    textStyle: context.type.meta.copyWith(
                      color: tokens.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(tokens.controlRadius),
                      border: Border.all(
                        color: tokens.hairline,
                        width: tokens.hairlineWidth,
                      ),
                    ),
                    child: InkWell(
                      onTap: _goUp,
                      statesController: _states,
                      customBorder: const CircleBorder(),
                      mouseCursor: context.platform.isPointer
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      child: AnimatedContainer(
                        duration: ReducedMotion.duration(context, Motion.quick),
                        width: Tokens.backToTopSize,
                        height: Tokens.backToTopSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLit ? tokens.beacon : tokens.surface,
                          border: Border.all(
                            color: isLit
                                ? tokens.beacon
                                : tokens.hairlineStrong,
                            width: tokens.hairlineWidth,
                          ),
                          boxShadow: isLit
                              ? [
                                  BoxShadow(
                                    color: tokens.beacon.withValues(
                                      alpha: Tokens.contactGlowAlpha,
                                    ),
                                    blurRadius: Tokens.contactGlowBlur,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: Tokens.chromeIconSize,
                          color: isLit ? tokens.void_ : tokens.beacon,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
