import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:nocturne/app/l10n/app_locale.dart';
import 'package:nocturne/app/l10n/localizations_context.dart';
import 'package:nocturne/app/theme/tokens.dart';
import 'package:nocturne/app/theme/typography.dart';
import 'package:nocturne/content/country_names.dart';
import 'package:nocturne/core/motion/durations.dart';
import 'package:nocturne/core/motion/reduced_motion.dart';

/// Where the work has been, as a line of flags.
///
/// Seven countries in one line says more about a career than a sentence about
/// it would, and it is the one fact on this page a stranger cannot get from a
/// job title.
///
/// The flags are emoji rather than images: a regional-indicator pair is two
/// characters, renders from the system font on every platform this ships to,
/// and costs nothing to download. Bundling seven PNGs to say the same thing
/// would be the wrong trade.
class ReachRow extends StatelessWidget {
  /// Renders [countries] as ISO 3166-1 alpha-2 codes.
  const ReachRow({required this.countries, required this.locale, super.key});

  /// The codes to draw, in the order the owner set.
  final List<String> countries;

  /// Which channel names the countries.
  final AppLocale locale;

  /// Turns "EG" into its flag.
  ///
  /// Regional indicator symbols sit at U+1F1E6 for A, so a country code maps
  /// to them by offset. Anything that is not two ASCII letters is skipped
  /// rather than rendered as tofu.
  static String? flagOf(String code) {
    if (code.length != 2) return null;
    final upper = code.toUpperCase();
    final points = <int>[];
    for (final unit in upper.codeUnits) {
      if (unit < 0x41 || unit > 0x5A) return null;
      points.add(0x1F1E6 + (unit - 0x41));
    }
    return String.fromCharCodes(points);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final type = context.type;
    final flags = [
      for (final code in countries)
        if (flagOf(code) case final String flag) (code: code, flag: flag),
    ];
    if (flags.isEmpty) return const SizedBox.shrink();

    return Semantics(
      // The codes, not the flags: a screen reader reading seven flag emoji
      // aloud is noise, and the country names are the information.
      label: '${context.l10n.heroReach} ${flags.map((e) => e.code).join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        spacing: tokens.space12,
        runSpacing: tokens.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.l10n.heroReach,
            style: type.telemetryS.copyWith(color: tokens.textMuted),
          ),
          for (final entry in flags)
            _Flag(flag: entry.flag, name: CountryNames.of(entry.code, locale)),
        ],
      ),
    );
  }
}

/// One flag, cut to a disc and named on hover -- and, under the pointer, in
/// the wind.
///
/// A row of emoji flags is a row of little rectangles with different aspect
/// ratios and different national colours fighting each other; discs of one
/// size read as a set. The emoji is scaled to overflow the circle and clipped,
/// so what shows is the middle of the flag rather than a letterboxed one.
///
/// The owner asked for the flags to do something when a hand reaches them.
/// A flag's own motion is to fly, so that is what it does: the disc lifts and
/// the flag ripples like cloth -- the flag cut into strips, each strip riding
/// a travelling wave, with the folds shaded as they pass. It only moves while
/// it is held; a tap on a phone sets it flying for a moment; under reduced
/// motion it keeps still and simply names itself.
class _Flag extends StatefulWidget {
  const _Flag({required this.flag, required this.name});

  final String flag;
  final String name;

  @override
  State<_Flag> createState() => _FlagState();
}

class _FlagState extends State<_Flag> with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: Tokens.flagWavePeriod,
  );
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: Motion.quick,
  );

  @override
  void dispose() {
    _wave.dispose();
    _lift.dispose();
    super.dispose();
  }

  void _fly(bool on) {
    if (ReducedMotion.of(context)) return;
    if (on) {
      _lift.forward();
      if (!_wave.isAnimating) _wave.repeat();
    } else {
      _lift.reverse().whenComplete(() {
        if (mounted && !_lift.isAnimating) _wave.stop();
      });
    }
  }

  /// A phone has no hover: a tap flies the flag for a moment instead.
  void _flutter() {
    _fly(true);
    Future<void>.delayed(Tokens.flagTapFlight, () {
      if (mounted) _fly(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Tooltip(
      message: widget.name,
      waitDuration: Motion.quick,
      textStyle: context.type.meta.copyWith(color: tokens.textPrimary),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: tokens.hairline, width: tokens.hairlineWidth),
      ),
      child: MouseRegion(
        onEnter: (_) => _fly(true),
        onExit: (_) => _fly(false),
        child: GestureDetector(
          onTap: _flutter,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([_wave, _lift]),
            builder: (context, _) {
              final lift = Curves.easeOut.transform(_lift.value);
              return Transform.translate(
                offset: Offset(0, -lift * Tokens.flagLift),
                child: Transform.scale(
                  scale: 1 + lift * Tokens.flagLiftScale,
                  child: Container(
                    width: Tokens.flagDiameter,
                    height: Tokens.flagDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(
                          tokens.hairline,
                          tokens.beacon,
                          lift,
                        )!,
                        width: tokens.hairlineWidth,
                      ),
                      boxShadow: lift > 0
                          ? [
                              BoxShadow(
                                color: tokens.void_.withValues(
                                  alpha: Tokens.flagShadowAlpha * lift,
                                ),
                                blurRadius: Tokens.flagShadowBlur,
                                offset: Offset(0, Tokens.flagLift * lift),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: _Cloth(
                        flag: widget.flag,
                        phase: _wave.value,
                        strength: lift,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The flag itself, flat or rippling.
class _Cloth extends StatelessWidget {
  const _Cloth({
    required this.flag,
    required this.phase,
    required this.strength,
  });

  final String flag;

  /// Where the wave is, 0..1 of one period.
  final double phase;

  /// How hard the wind is blowing, 0 still to 1 full.
  final double strength;

  Widget _face() => OverflowBox(
    maxWidth: Tokens.flagDiameter * Tokens.flagOverscan,
    maxHeight: Tokens.flagDiameter * Tokens.flagOverscan,
    child: Center(
      child: Text(
        flag,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: Tokens.flagDiameter * Tokens.flagOverscan,
          height: 1,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) return _face();
    const strips = Tokens.flagStrips;
    const width = Tokens.flagDiameter;
    final turn = phase * 2 * math.pi;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < strips; i++)
          ClipRect(
            clipper: _Strip(index: i, count: strips),
            child: Transform.translate(
              // A travelling wave: each strip a step further through it, so
              // the ripple runs from the hoist to the fly.
              offset: Offset(
                0,
                math.sin(turn - i * Tokens.flagWaveStep) *
                    Tokens.flagWaveHeight *
                    strength,
              ),
              child: _face(),
            ),
          ),
        // The folds: light and shadow travelling with the wave.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                tileMode: TileMode.repeated,
                transform: _Slide(phase),
                colors: [
                  Colors.white.withValues(
                    alpha: Tokens.flagFoldLight * strength,
                  ),
                  Colors.black.withValues(
                    alpha: Tokens.flagFoldShade * strength,
                  ),
                  Colors.white.withValues(
                    alpha: Tokens.flagFoldLight * strength,
                  ),
                ],
              ),
            ),
            child: const SizedBox(width: width, height: width),
          ),
        ),
      ],
    );
  }
}

/// One vertical slice of the flag.
class _Strip extends CustomClipper<Rect> {
  const _Strip({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Rect getClip(Size size) {
    final width = size.width / count;
    // Half a pixel either side, so the strips never show a hairline gap.
    return Rect.fromLTWH(index * width - 0.5, 0, width + 1, size.height);
  }

  @override
  bool shouldReclip(_Strip old) => old.index != index || old.count != count;
}

/// Moves the fold shading along with the wave.
class _Slide extends GradientTransform {
  const _Slide(this.phase);

  final double phase;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(-phase * bounds.width, 0, 0);
}
