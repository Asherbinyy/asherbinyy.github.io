import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nocturne/app/chrome/chrome_scaffold.dart';
import 'package:nocturne/app/chrome/pointer_beacon.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/theme_controller.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/core/motion/curves.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';
import 'package:nocturne/core/painting/hero_scene_painter.dart';
import 'package:nocturne/core/platform/platform_scope.dart';
import 'package:nocturne/core/widgets/focus_ring.dart';

/// The picture on the right of the hero, on a screen wide enough for one.
///
/// Night on the dark theme and day on the light one, and the change between
/// them is the sun setting or rising rather than a cut: the owner asked for a
/// sun that moves, and the theme is the one thing on this site that already
/// means day or night. The sun -- or the moon, once it has set -- is also a
/// button that changes the theme, so the picture answers the viewer instead
/// of performing at them.
///
/// Its idle motion (stars, the river, the cursor, the steam) runs only while
/// it is on screen and never under reduced motion; there the sun is simply
/// where the theme puts it.
class HeroScene extends ConsumerStatefulWidget {
  /// Draws the scene for the current theme.
  const HeroScene({super.key});

  @override
  ConsumerState<HeroScene> createState() => _HeroSceneState();
}

class _HeroSceneState extends ConsumerState<HeroScene>
    with TickerProviderStateMixin {
  late final AnimationController _sun = AnimationController(
    vsync: this,
    duration: Tokens.heroSunTravel,
  );
  late final Ticker _idle = createTicker(_onIdle);
  final ValueNotifier<double> _time = ValueNotifier(0);
  final ValueNotifier<Offset> _parallax = ValueNotifier(Offset.zero);
  final GlobalKey _sceneKey = GlobalKey(debugLabel: 'hero-scene');
  final WidgetStatesController _states = WidgetStatesController();

  /// Idle time banked across pauses, so a star does not jump when the picture
  /// scrolls back into view.
  double _banked = 0;
  Offset _aim = Offset.zero;
  ValueNotifier<Offset?>? _beacon;
  ScrollController? _scroll;
  bool _isReduced = false;
  bool _isOnScreen = true;

  /// Whether the page is showing its day palette, as last seen. Null until the
  /// first build, which places the sun without animating it there.
  bool? _isDay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final beacon = PointerBeacon.notifierOf(context);
    if (beacon != _beacon) {
      _beacon?.removeListener(_onPointer);
      _beacon = beacon?..addListener(_onPointer);
    }
    final scroll = ChromeScrollScope.maybeOf(context)?.controller;
    if (scroll != _scroll) {
      _scroll?.removeListener(_checkOnScreen);
      _scroll = scroll?..addListener(_checkOnScreen);
    }
    _isReduced = ReducedMotion.of(context);
    if (_isReduced) _parallax.value = Offset.zero;

    // Day or night from the palette actually on screen, not from the stored
    // choice: the two can differ -- the app takes a theme from outside for
    // the admin's preview -- and the picture must match the page around it.
    final isDay = Theme.of(context).brightness == Brightness.light;
    if (_isDay == null || _isReduced) {
      _sun.value = isDay ? 1 : 0;
    } else if (isDay != _isDay) {
      _sun.animateTo(isDay ? 1 : 0, curve: MotionCurves.emphasized);
    }
    _isDay = isDay;
    _updateIdle();
  }

  @override
  void dispose() {
    _beacon?.removeListener(_onPointer);
    _scroll?.removeListener(_checkOnScreen);
    _idle.dispose();
    _sun.dispose();
    _time.dispose();
    _parallax.dispose();
    _states.dispose();
    super.dispose();
  }

  /// Runs the idle motion only when there is someone to see it.
  void _updateIdle() {
    final wanted = !_isReduced && _isOnScreen;
    if (wanted && !_idle.isActive) {
      _idle.start();
    } else if (!wanted && _idle.isActive) {
      _banked = _time.value;
      _idle.stop();
    }
  }

  void _onIdle(Duration elapsed) {
    _time.value =
        _banked + elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    // Eased toward the pointer rather than snapped to it, so the depth reads
    // as weight and a flick across the screen is not a jolt.
    final current = _parallax.value;
    final next = Offset.lerp(current, _aim, Tokens.heroParallaxEase)!;
    if ((next - current).distance > 0.001) _parallax.value = next;
  }

  void _onPointer() {
    if (_isReduced || !mounted) return;
    final box = _sceneKey.currentContext?.findRenderObject();
    final global = _beacon?.value;
    if (global == null || box is! RenderBox || !box.hasSize) {
      _aim = Offset.zero;
      return;
    }
    final local = box.globalToLocal(global);
    final size = box.size;
    _aim = Offset(
      ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  void _checkOnScreen() {
    if (!mounted) return;
    final box = _sceneKey.currentContext?.findRenderObject();
    // Measured against the page's own viewport, the same way the career
    // frieze measures itself: the window is not what scrolls.
    final viewport =
        Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box is! RenderBox || !box.hasSize || viewport == null) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final onScreen = top + box.size.height > 0 && top < viewport.size.height;
    if (onScreen == _isOnScreen) return;
    _isOnScreen = onScreen;
    _updateIdle();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isDay = _isDay ?? false;

    return AspectRatio(
      aspectRatio: Tokens.heroSceneAspect,
      // No frame. The owner asked for the picture to be part of the page
      // rather than an image placed on it, in both themes, so its edges fade
      // into whatever is behind them: the sky's top is already the page's own
      // colour, and the sides and the foot of the desk dissolve into it.
      child: ClipRect(
        child: _EdgeFade(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return AnimatedBuilder(
                animation: Listenable.merge([_sun, _time, _parallax]),
                builder: (context, _) {
                  // The button sits on whichever light is up: the sun by
                  // day, the moon once the sun has gone.
                  final onSun = _sun.value > 0.5;
                  final centre = onSun
                      ? HeroScenePainter.sunCentre(size, _sun.value)
                      : HeroScenePainter.moonCentre(size);
                  final radius = onSun
                      ? HeroScenePainter.sunRadiusIn(size)
                      : HeroScenePainter.moonRadiusIn(size);
                  final target = math.max(
                    radius * Tokens.heroSunTargetScale,
                    context.platform.minimumTarget,
                  );

                  // The picture keeps its own time of day. The page changes
                  // theme at once; the sky follows the sun up or down, so a
                  // switch is a dawn or a dusk rather than a cut. Both
                  // palettes are the site's own, blended by how high the sun
                  // is.
                  final daylight = Curves.easeInOut.transform(_sun.value);
                  Color at(
                    Color Function(ThemeTokens) day, {
                    Color Function(ThemeTokens)? night,
                  }) => Color.lerp(
                    (night ?? day)(nocturneTokens),
                    day(daybreakTokens),
                    daylight,
                  )!;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            key: _sceneKey,
                            painter: HeroScenePainter(
                              sun: _sun.value,
                              time: _isReduced ? 0 : _time.value,
                              parallax: _parallax.value,
                              skyTop: at((t) => t.void_),
                              skyHorizon: at((t) => t.surfaceRaised),
                              water: at((t) => t.surface),
                              ground: at((t) => t.surface),
                              stone: at(
                                (t) => t.hairline,
                                night: (t) => t.surface,
                              ),
                              edge: at((t) => t.hairlineStrong),
                              lit: at((t) => t.instrumentDim),
                              ink: at((t) => t.textSecondary),
                              faint: at((t) => t.textMuted),
                              gold: at((t) => t.beacon),
                              goldDim: at((t) => t.beaconDim),
                              goldGlow: at((t) => t.beaconGlow),
                              halo: at(
                                (t) => t.surfaceRaised,
                                night: (t) => t.beaconGlow,
                              ),
                              screen: at((t) => t.void_),
                              strokeWidth: tokens.hairlineWidth,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: centre.dx - target / 2,
                        top: centre.dy - target / 2,
                        width: target,
                        height: target,
                        child: _SunButton(
                          label: isDay
                              ? l10n.heroSceneSunset
                              : l10n.heroSceneSunrise,
                          states: _states,
                          onPressed: () => ref
                              .read(themeControllerProvider.notifier)
                              .toggle(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The light in the sky, as a control.
///
/// Invisible at rest -- the painting is the control's face -- with a faience
/// ring on hover and the site's focus ring on keyboard focus, so it is plainly
/// something to press the moment anyone reaches for it.
class _SunButton extends StatelessWidget {
  const _SunButton({
    required this.label,
    required this.states,
    required this.onPressed,
  });

  final String label;
  final WidgetStatesController states;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ListenableBuilder(
        listenable: states,
        builder: (context, _) {
          final isHovered = states.value.contains(WidgetState.hovered);
          final isFocused = states.value.contains(WidgetState.focused);
          return FocusRing(
            isFocused: isFocused,
            radius: Tokens.heroSunFocusRadius,
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                statesController: states,
                customBorder: const CircleBorder(),
                hoverColor: Colors.transparent,
                splashColor: tokens.faience.withValues(
                  alpha: Tokens.heroSunSplashAlpha,
                ),
                mouseCursor: context.platform.isPointer
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: AnimatedContainer(
                  duration: ReducedMotion.duration(context, Tokens.quick),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovered
                          ? tokens.faience
                          : tokens.faience.withValues(alpha: 0),
                      width: tokens.hairlineWidth * 2,
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

/// Fades a child out at its edges, so it sits in the page instead of on it.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.child});

  final Widget child;

  static Shader _fade(Rect bounds, Axis axis, double start, double end) =>
      LinearGradient(
        begin: axis == Axis.horizontal
            ? Alignment.centerLeft
            : Alignment.topCenter,
        end: axis == Axis.horizontal
            ? Alignment.centerRight
            : Alignment.bottomCenter,
        colors: const [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, start, 1 - end, 1],
      ).createShader(bounds);

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) => _fade(
      bounds,
      Axis.horizontal,
      Tokens.heroSceneFadeSides,
      Tokens.heroSceneFadeSides,
    ),
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => _fade(
        bounds,
        Axis.vertical,
        Tokens.heroSceneFadeTop,
        Tokens.heroSceneFadeBottom,
      ),
      child: child,
    ),
  );
}
